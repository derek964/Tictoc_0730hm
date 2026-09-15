import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { appPicker, guardService } from '@kit.ScreenTimeGuardKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export interface GuardActionResult {
  success: boolean;
  message: string;
}

export interface GuardRuntimeState {
  errorMessage: string;
  authorized: boolean;
  configuredStrategies: number;
}

export class TictocGuardManager {
  private static readonly DOMAIN: number = 0x0000;
  private static readonly TAG: string = 'TictocGuard';
  private static readonly STRATEGY_PREFIX: string = 'tictoc_';
  private static readonly DOWNTIME_STRATEGY: string = 'tictoc_downtime';
  private static readonly DAILY_QUOTA_STRATEGY: string = 'tictoc_daily_quota';

  public async queryState(): Promise<GuardRuntimeState> {
    let authorized = false;
    let configuredStrategies = 0;
    try {
      authorized = await guardService.getUserAuthStatus() === guardService.AuthStatus.AUTH_GRANTED;
      if (authorized) {
        const strategies = await guardService.queryGuardStrategies();
        configuredStrategies = strategies.filter((item: guardService.GuardStrategy) =>
          item.name.startsWith(TictocGuardManager.STRATEGY_PREFIX)).length;
      }
    } catch (error) {
      this.logError('queryState', error as BusinessError);
      return { authorized: false, configuredStrategies: -1,
        errorMessage: this.toFailure('系统状态查询失败', error as BusinessError).message };
    }
    return { authorized: authorized, configuredStrategies: configuredStrategies, errorMessage: '' };
  }

  public async requestAuthorization(context: common.UIAbilityContext): Promise<GuardActionResult> {
    try {
      const status = await guardService.getUserAuthStatus();
      if (status !== guardService.AuthStatus.AUTH_GRANTED) {
        await guardService.requestUserAuth(context);
      }
      const currentStatus = await guardService.getUserAuthStatus();
      if (currentStatus !== guardService.AuthStatus.AUTH_GRANTED) {
        return { success: false, message: '尚未完成屏幕时间守护授权' };
      }
      return { success: true, message: '屏幕时间守护授权已开启' };
    } catch (error) {
      return this.toFailure('未获得系统守护授权', error as BusinessError);
    }
  }

  public async pickApps(context: common.UIAbilityContext, currentTokens: string[]): Promise<string[]> {
    return await appPicker.startAppPicker(context, { appTokens: currentTokens });
  }

  public async applyImmediateRestriction(previousTokens: string[], tokens: string[]): Promise<GuardActionResult> {
    if (tokens.length === 0) {
      return { success: false, message: '请先选择要管控的应用' };
    }
    try {
      if (previousTokens.length > 0) {
        await guardService.releaseAppsRestriction(
          { appTokens: previousTokens },
          guardService.RestrictionType.BLOCKLIST_TYPE
        );
      }
      await guardService.setAppsRestriction(
        { appTokens: tokens },
        guardService.RestrictionType.BLOCKLIST_TYPE
      );
      return { success: true, message: '已立即限制所选应用' };
    } catch (error) {
      return this.toFailure('立即限制失败', error as BusinessError);
    }
  }

  public async applyDowntime(tokens: string[], startTime: string,
    endTime: string): Promise<GuardActionResult> {
    if (tokens.length === 0) {
      return { success: false, message: '请先选择要管控的应用' };
    }
    if (!this.isValidTime(startTime) || !this.isValidTime(endTime) || startTime === endTime) {
      return { success: false, message: '请输入有效且不同的开始、结束时间，例如 22:00 和 07:00' };
    }
    const strategy: guardService.GuardStrategy = {
      name: TictocGuardManager.DOWNTIME_STRATEGY,
      timeStrategy: {
        type: guardService.TimeStrategyType.START_END_TIME_TYPE,
        startTime: startTime,
        endTime: endTime,
        repeat: [1, 2, 3, 4, 5, 6, 7]
      },
      appInfo: { appTokens: tokens },
      appRestrictionType: guardService.RestrictionType.BLOCKLIST_TYPE
    };
    return await this.replaceAndStart(strategy, '每日停用时间已启用');
  }

  public async applyDailyQuota(tokens: string[], minutes: number): Promise<GuardActionResult> {
    if (tokens.length === 0) {
      return { success: false, message: '请先选择要管控的应用' };
    }
    if (!Number.isInteger(minutes) || minutes < 1 || minutes > 1440) {
      return { success: false, message: '每日额度必须是 1 到 1440 分钟的整数' };
    }
    const strategy: guardService.GuardStrategy = {
      name: TictocGuardManager.DAILY_QUOTA_STRATEGY,
      timeStrategy: {
        type: guardService.TimeStrategyType.INCLUSIVE_DURATION_TYPE,
        totalDuration: minutes,
        repeat: [1, 2, 3, 4, 5, 6, 7]
      },
      appInfo: { appTokens: tokens },
      // Screen Time Guard Kit requires TRUSTLIST_TYPE for shared-duration strategies.
      appRestrictionType: guardService.RestrictionType.TRUSTLIST_TYPE
    };
    return await this.replaceAndStart(strategy, `每日共享额度 ${minutes} 分钟已启用`);
  }

  public async releaseAll(tokens: string[]): Promise<GuardActionResult> {
    let changed = false;
    let directReleaseError: BusinessError | undefined = undefined;
    if (tokens.length > 0) {
      try {
        await guardService.releaseAppsRestriction(
          { appTokens: tokens },
          guardService.RestrictionType.BLOCKLIST_TYPE
        );
        changed = true;
      } catch (error) {
        directReleaseError = error as BusinessError;
        this.logError('releaseAppsRestriction', directReleaseError);
      }
    }

    try {
      const strategies = await guardService.queryGuardStrategies();
      for (const strategy of strategies) {
        if (!strategy.name.startsWith(TictocGuardManager.STRATEGY_PREFIX)) {
          continue;
        }
        try {
          await guardService.stopGuardStrategy(strategy.name);
        } catch (error) {
          this.logError(`stopGuardStrategy:${strategy.name}`, error as BusinessError);
        }
        await guardService.removeGuardStrategy(strategy.name);
        changed = true;
      }
      if (directReleaseError !== undefined) {
        return this.toFailure('定时策略已处理，但立即限制解除失败', directReleaseError);
      }
      return {
        success: true,
        message: changed ? '已解除 Tictoc 创建的全部限制' : '当前没有 Tictoc 管控规则'
      };
    } catch (error) {
      return this.toFailure('解除限制失败', error as BusinessError);
    }
  }

  private async replaceAndStart(strategy: guardService.GuardStrategy,
    successMessage: string): Promise<GuardActionResult> {
    try {
      const strategies = await guardService.queryGuardStrategies();
      const existing = strategies.find((item: guardService.GuardStrategy) => item.name === strategy.name);
      if (existing !== undefined) {
        try {
          await guardService.stopGuardStrategy(strategy.name);
        } catch (error) {
          const stopError = error as BusinessError;
          if (stopError.code !== 1019000008) {
            return this.toFailure('停止原规则失败，未继续替换', stopError);
          }
        }
        await guardService.updateGuardStrategy(strategy.name, strategy);
      } else {
        await guardService.addGuardStrategy(strategy);
      }
      await guardService.startGuardStrategy(strategy.name);
      return { success: true, message: successMessage };
    } catch (error) {
      return this.toFailure('启动管控策略失败', error as BusinessError);
    }
  }

  private isValidTime(value: string): boolean {
    const matched = /^(\d{2}):(\d{2})$/.exec(value);
    if (matched === null) {
      return false;
    }
    const hour = Number(matched[1]);
    const minute = Number(matched[2]);
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  private toFailure(prefix: string, error: BusinessError): GuardActionResult {
    this.logError(prefix, error);
    switch (error.code) {
      case 201:
        return { success: false, message: `${prefix}：当前安装包缺少系统管控权限` };
      case 801:
        return { success: false, message: `${prefix}：当前系统版本不支持此能力` };
      case 1019000001:
        return { success: false, message: `${prefix}：系统内部错误（1019000001），需结合设备日志排查，不能仅据此判定为签名问题` };
      case 1019000002:
        return { success: false, message: `${prefix}：用户尚未授权` };
      case 1019000003:
        return { success: false, message: `${prefix}：用户取消了系统操作` };
      default:
        return { success: false, message: `${prefix}（错误码 ${error.code}）` };
    }
  }

  private logError(operation: string, error: BusinessError): void {
    hilog.error(TictocGuardManager.DOMAIN, TictocGuardManager.TAG,
      `${operation}, code=${error.code}, message=${error.message}`);
  }
}
