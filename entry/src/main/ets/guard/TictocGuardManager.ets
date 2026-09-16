import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { appPicker, guardService } from '@kit.ScreenTimeGuardKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppLimitEntry } from '../data/SettingsStore';
import { TimeUtils } from '../util/TimeUtils';

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
  private static readonly LIMIT_PREFIX: string = 'tictoc_limit_';

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
      return {
        authorized: false,
        configuredStrategies: -1,
        errorMessage: this.toFailure('系统状态查询失败', error as BusinessError).message
      };
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

  public restrictedTokens(managed: AppLimitEntry[], whitelist: string[]): string[] {
    const result: string[] = [];
    for (let index = 0; index < managed.length; index++) {
      const token = managed[index].token;
      if (whitelist.indexOf(token) < 0 && result.indexOf(token) < 0) {
        result.push(token);
      }
    }
    return result;
  }

  public async syncControlRules(managed: AppLimitEntry[], whitelist: string[],
    downtime: string): Promise<GuardActionResult> {
    const tokens = this.restrictedTokens(managed, whitelist);
    const downtimeResult = await this.syncDowntime(tokens, downtime);
    if (!downtimeResult.success) {
      return downtimeResult;
    }
    const limitResult = await this.syncAppLimits(managed, whitelist);
    if (!limitResult.success) {
      return limitResult;
    }
    return { success: true, message: '管控设置已同步到系统' };
  }

  public async syncDowntime(tokens: string[], downtime: string): Promise<GuardActionResult> {
    if (downtime.length === 0) {
      return await this.removeNamedStrategy(TictocGuardManager.DOWNTIME_STRATEGY, '已关闭停用时间');
    }
    const parts = downtime.split('-');
    if (parts.length !== 2 || !TimeUtils.isValidClock(parts[0]) || !TimeUtils.isValidClock(parts[1]) ||
      parts[0] === parts[1]) {
      return { success: false, message: '请输入有效且不同的开始、结束时间，例如 22:00 和 07:00' };
    }
    if (tokens.length === 0) {
      return { success: false, message: '请先添加管控应用后再开启停用时间' };
    }
    const strategy: guardService.GuardStrategy = {
      name: TictocGuardManager.DOWNTIME_STRATEGY,
      timeStrategy: {
        type: guardService.TimeStrategyType.START_END_TIME_TYPE,
        startTime: parts[0],
        endTime: parts[1],
        repeat: [1, 2, 3, 4, 5, 6, 7]
      },
      appInfo: { appTokens: tokens },
      appRestrictionType: guardService.RestrictionType.BLOCKLIST_TYPE
    };
    return await this.replaceAndStart(strategy, '每日停用时间已启用');
  }

  public async syncAppLimits(managed: AppLimitEntry[], whitelist: string[]): Promise<GuardActionResult> {
    const keepNames: string[] = [];
    for (let index = 0; index < managed.length; index++) {
      const item = managed[index];
      if (whitelist.indexOf(item.token) >= 0 || item.minutes < 1 || item.minutes > 1440) {
        continue;
      }
      const name = this.limitStrategyName(item.token);
      keepNames.push(name);
      const strategy: guardService.GuardStrategy = {
        name: name,
        timeStrategy: {
          type: guardService.TimeStrategyType.INCLUSIVE_DURATION_TYPE,
          totalDuration: item.minutes,
          repeat: [1, 2, 3, 4, 5, 6, 7]
        },
        appInfo: { appTokens: [item.token] },
        appRestrictionType: guardService.RestrictionType.TRUSTLIST_TYPE
      };
      const result = await this.replaceAndStart(strategy, '应用限额已更新');
      if (!result.success) {
        return result;
      }
    }
    return await this.removeOrphanLimitStrategies(keepNames);
  }

  public async releaseImmediate(tokens: string[]): Promise<GuardActionResult> {
    if (tokens.length === 0) {
      return { success: true, message: '没有立即限制需要解除' };
    }
    try {
      await guardService.releaseAppsRestriction(
        { appTokens: tokens },
        guardService.RestrictionType.BLOCKLIST_TYPE
      );
      return { success: true, message: '已解除立即限制' };
    } catch (error) {
      return this.toFailure('立即限制解除失败', error as BusinessError);
    }
  }

  public async releaseAll(immediateTokens: string[]): Promise<GuardActionResult> {
    let changed = false;
    let directReleaseError: BusinessError | undefined = undefined;
    if (immediateTokens.length > 0) {
      try {
        await guardService.releaseAppsRestriction(
          { appTokens: immediateTokens },
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
      const quotaCleanup = await this.removeNamedStrategy(TictocGuardManager.DAILY_QUOTA_STRATEGY, '');
      if (directReleaseError !== undefined) {
        return this.toFailure('定时策略已处理，但立即限制解除失败', directReleaseError);
      }
      if (!quotaCleanup.success && quotaCleanup.message.indexOf('1019000005') < 0) {
        return quotaCleanup;
      }
      return {
        success: true,
        message: changed ? '已解除 Tictoc 创建的全部限制' : '当前没有 Tictoc 管控规则'
      };
    } catch (error) {
      return this.toFailure('解除限制失败', error as BusinessError);
    }
  }

  private async removeOrphanLimitStrategies(keepNames: string[]): Promise<GuardActionResult> {
    try {
      const strategies = await guardService.queryGuardStrategies();
      for (const strategy of strategies) {
        if (!strategy.name.startsWith(TictocGuardManager.LIMIT_PREFIX) &&
          strategy.name !== TictocGuardManager.DAILY_QUOTA_STRATEGY) {
          continue;
        }
        if (keepNames.indexOf(strategy.name) >= 0) {
          continue;
        }
        try {
          await guardService.stopGuardStrategy(strategy.name);
        } catch (error) {
          this.logError(`stopGuardStrategy:${strategy.name}`, error as BusinessError);
        }
        await guardService.removeGuardStrategy(strategy.name);
      }
      return { success: true, message: '应用限额已更新' };
    } catch (error) {
      return this.toFailure('清理旧限额失败', error as BusinessError);
    }
  }

  private async removeNamedStrategy(name: string, successMessage: string): Promise<GuardActionResult> {
    try {
      const strategies = await guardService.queryGuardStrategies();
      const existing = strategies.find((item: guardService.GuardStrategy) => item.name === name);
      if (existing === undefined) {
        return { success: true, message: successMessage.length > 0 ? successMessage : '规则不存在' };
      }
      try {
        await guardService.stopGuardStrategy(name);
      } catch (error) {
        const stopError = error as BusinessError;
        if (stopError.code !== 1019000008) {
          return this.toFailure('停止原规则失败', stopError);
        }
      }
      await guardService.removeGuardStrategy(name);
      return { success: true, message: successMessage.length > 0 ? successMessage : '已删除规则' };
    } catch (error) {
      return this.toFailure('删除规则失败', error as BusinessError);
    }
  }

  private limitStrategyName(token: string): string {
    let hash = 2166136261;
    for (let index = 0; index < token.length; index++) {
      hash ^= token.charCodeAt(index);
      hash = (hash * 16777619) | 0;
    }
    const unsigned = hash >>> 0;
    return `${TictocGuardManager.LIMIT_PREFIX}${unsigned.toString(16)}${token.length.toString(16)}`;
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

  private toFailure(prefix: string, error: BusinessError): GuardActionResult {
    this.logError(prefix, error);
    switch (error.code) {
      case 201:
        return { success: false, message: `${prefix}：当前安装包缺少系统管控权限` };
      case 801:
        return { success: false, message: `${prefix}：当前系统版本不支持此能力` };
      case 1019000001:
        return {
          success: false,
          message: `${prefix}：系统内部错误（1019000001），需结合设备日志排查`
        };
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
