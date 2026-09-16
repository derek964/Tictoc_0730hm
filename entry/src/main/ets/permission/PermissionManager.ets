import { abilityAccessCtrl, bundleManager, common, Permissions, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { notificationManager } from '@kit.NotificationKit';

export interface PermissionSnapshot {
  screenTimeAuthorized: boolean;
  hasManagedApps: boolean;
  notificationEnabled: boolean;
  backgroundGranted: boolean;
}

export class PermissionManager {
  private static readonly BACKGROUND_PERMISSION: Permissions = 'ohos.permission.KEEP_BACKGROUND_RUNNING';

  public static async load(authorized: boolean, managedCount: number): Promise<PermissionSnapshot> {
    return {
      screenTimeAuthorized: authorized,
      hasManagedApps: managedCount > 0,
      notificationEnabled: await PermissionManager.isNotificationEnabled(),
      backgroundGranted: PermissionManager.isBackgroundGranted()
    };
  }

  public static async isNotificationEnabled(): Promise<boolean> {
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (_) {
      return false;
    }
  }

  public static isBackgroundGranted(): boolean {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const status = atManager.checkAccessTokenSync(bundleInfo.appInfo.accessTokenId,
        PermissionManager.BACKGROUND_PERMISSION);
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (_) {
      return false;
    }
  }

  public static async requestNotification(context: common.UIAbilityContext): Promise<void> {
    await notificationManager.requestEnableNotification(context);
  }

  public static async requestBackground(context: common.UIAbilityContext): Promise<void> {
    const atManager = abilityAccessCtrl.createAtManager();
    await atManager.requestPermissionsFromUser(context, [PermissionManager.BACKGROUND_PERMISSION]);
  }

  public static async openAppSettings(context: common.UIAbilityContext): Promise<void> {
    const want: Want = {
      action: 'action.settings.app.info',
      parameters: {
        settingsParam: context.abilityInfo.bundleName
      }
    };
    try {
      await context.startAbility(want);
    } catch (error) {
      const err = error as BusinessError;
      throw new Error(`无法打开应用设置（错误码 ${err.code}）`);
    }
  }

  public static corePermissionsGranted(snapshot: PermissionSnapshot): boolean {
    return snapshot.screenTimeAuthorized;
  }
}
