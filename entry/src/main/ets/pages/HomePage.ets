import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppLimitEntry, SettingsStore } from '../data/SettingsStore';
import { GuardActionResult, TictocGuardManager } from '../guard/TictocGuardManager';
import { AlwaysAllowedPage } from './AlwaysAllowedPage';
import { ControlPage } from './ControlPage';
import { DashboardPage } from './DashboardPage';
import { ProfilePage } from './ProfilePage';
import { PermissionManager } from '../permission/PermissionManager';
import { PinSecurity } from '../security/PinSecurity';
import { ThemeColor } from '../ui/Theme';
import { TimeUtils } from '../util/TimeUtils';

@Entry
@Component
struct HomePage {
  private context: common.UIAbilityContext =
    this.getUIContext().getHostContext() as common.UIAbilityContext;
  private settings: SettingsStore = new SettingsStore();
  private guard: TictocGuardManager = new TictocGuardManager();
  private unlockSeq: number = 0;
  private systemFlowActive: boolean = false;

  @State private loading: boolean = true;
  @State private initializationError: string = '';
  @State private hasPin: boolean = false;
  @State private isUnlocked: boolean = false;
  @State private pinSalt: string = '';
  @State private pinHash: string = '';
  @State private pinInput: string = '';
  @State private failedPinAttempts: number = 0;
  @State private lockUntil: number = 0;
  @State private setupPin: string = '';
  @State private setupConfirmPin: string = '';

  @State private authorized: boolean = false;
  @State private appLimits: AppLimitEntry[] = [];
  @State private whitelistTokens: string[] = [];
  @State private immediateTokens: string[] = [];
  @State private downtime: string = '';
  @State private downtimeStart: string = '22:00';
  @State private downtimeEnd: string = '07:00';
  @State private configuredStrategies: number = 0;
  @State private notifyEnabled: boolean = false;
  @State private backgroundGranted: boolean = false;
  @State private busy: boolean = false;
  @State private currentTab: number = 0;
  @State private showAlwaysAllowed: boolean = false;
  private tabController: TabsController = new TabsController();

  aboutToAppear(): void {
    this.initialize();
  }

  onPageShow(): void {
    if (!this.loading && this.hasPin && this.isUnlocked) {
      this.refreshRuntimeState(false);
      this.refreshPermissions();
    }
  }

  private async initialize(): Promise<void> {
    try {
      await this.settings.initialize(this.context);
      const saved = await this.settings.load();
      this.appLimits = saved.appLimits;
      this.whitelistTokens = saved.whitelistTokens;
      this.immediateTokens = saved.immediateTokens;
      this.downtime = saved.downtime;
      this.downtimeStart = saved.downtimeStart;
      this.downtimeEnd = saved.downtimeEnd;
      this.pinSalt = saved.pinSalt;
      this.pinHash = saved.pinHash;

      if (PinSecurity.isCorruptCredential(this.pinSalt, this.pinHash)) {
        await this.settings.clearPin();
        this.pinSalt = '';
        this.pinHash = '';
      }
      this.hasPin = PinSecurity.isCompleteCredential(this.pinSalt, this.pinHash);
      await this.refreshRuntimeState(false);
      await this.refreshPermissions();
      if (this.immediateTokens.length > 0 && this.authorized) {
        await this.guard.releaseImmediate(this.immediateTokens);
        this.immediateTokens = [];
        await this.settings.saveImmediateTokens([]);
      }
    } catch (error) {
      const err = error as BusinessError;
      this.initializationError = `无法读取本机设置：${err.message}`;
    } finally {
      this.loading = false;
    }
  }

  private async refreshRuntimeState(updateToast: boolean): Promise<void> {
    const state = await this.guard.queryState();
    this.authorized = state.authorized;
    this.configuredStrategies = state.configuredStrategies;
    if (updateToast && state.errorMessage.length > 0) {
      this.toast(state.errorMessage);
    }
  }

  private async refreshPermissions(): Promise<void> {
    const snapshot = await PermissionManager.load(this.authorized, this.appLimits.length);
    this.notifyEnabled = snapshot.notificationEnabled;
    this.backgroundGranted = snapshot.backgroundGranted;
  }

  /** Same idea as Android ON_RESUME: re-read auth + notify + background for Profile. */
  private async refreshProfilePermissions(): Promise<void> {
    await this.refreshRuntimeState(false);
    await this.refreshPermissions();
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message, duration: 2500 });
  }

  private async unlockFromInput(value: string, force: boolean = false): Promise<void> {
    if (this.busy || this.isUnlocked) {
      return;
    }
    const seq = ++this.unlockSeq;
    const now = Date.now();
    if (now < this.lockUntil) {
      if (force || value.length >= 4) {
        const waitSeconds = Math.ceil((this.lockUntil - now) / 1000);
        this.toast(`尝试次数过多，请等待 ${waitSeconds} 秒`);
      }
      return;
    }
    if (!PinSecurity.isValidFormat(value)) {
      if (force) {
        this.toast('请输入 4-6 位数字密码');
      }
      return;
    }
    if (!force && value.length < 6) {
      return;
    }
    this.busy = true;
    try {
      const matched = await PinSecurity.verify(value, this.pinSalt, this.pinHash);
      if (seq !== this.unlockSeq) {
        return;
      }
      if (matched) {
        this.isUnlocked = true;
        this.failedPinAttempts = 0;
        this.pinInput = '';
        await this.refreshRuntimeState(false);
        await this.refreshPermissions();
      } else {
        this.failedPinAttempts++;
        this.pinInput = '';
        if (this.failedPinAttempts >= 5) {
          this.lockUntil = Date.now() + 30000;
          this.failedPinAttempts = 0;
          this.toast('密码错误次数过多，已暂停 30 秒');
        } else {
          this.toast('密码错误');
        }
      }
    } catch (error) {
      if (seq === this.unlockSeq) {
        this.toast('PIN 校验失败，请重试');
      }
    } finally {
      if (seq === this.unlockSeq) {
        this.busy = false;
      }
    }
  }

  private async runSystemFlow(action: () => Promise<void>): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    this.systemFlowActive = true;
    try {
      await action();
    } finally {
      this.systemFlowActive = false;
      this.busy = false;
    }
  }

  private async requestAuthorization(): Promise<void> {
    await this.runSystemFlow(async () => {
      const result = await this.guard.requestAuthorization(this.context);
      await this.refreshRuntimeState(false);
      await this.refreshPermissions();
      this.toast(result.message);
    });
  }

  private async pickManagedApps(): Promise<string[]> {
    if (!this.authorized) {
      this.toast('请先开启系统守护授权');
      return [];
    }
    let added: string[] = [];
    await this.runSystemFlow(async () => {
      try {
        const current: string[] = [];
        for (let index = 0; index < this.appLimits.length; index++) {
          current.push(this.appLimits[index].token);
        }
        const tokens = await this.guard.pickApps(this.context, current);
        added = [];
        for (let i = 0; i < tokens.length; i++) {
          if (current.indexOf(tokens[i]) < 0) {
            added.push(tokens[i]);
          }
        }
        this.appLimits = this.mergeLimits(this.appLimits, tokens);
        await this.settings.saveAppLimits(this.appLimits);
        await this.syncRules(added.length > 0 ? '已选好应用，请继续设置每天时长' : '已更新管控应用');
      } catch (error) {
        const err = error as BusinessError;
        added = [];
        this.toast(`应用选择未完成，错误码 ${err.code}。`);
      }
    });
    return added;
  }

  private async pickWhitelistApps(): Promise<void> {
    if (!this.authorized) {
      this.toast('请先开启系统守护授权');
      return;
    }
    await this.runSystemFlow(async () => {
      try {
        const tokens = await this.guard.pickApps(this.context, this.whitelistTokens);
        this.whitelistTokens = tokens;
        await this.settings.saveWhitelistTokens(tokens);
        await this.syncRules('已更新始终允许应用');
      } catch (error) {
        const err = error as BusinessError;
        this.toast(`应用选择未完成（错误码 ${err.code}）`);
      }
    });
  }

  private mergeLimits(current: AppLimitEntry[], tokens: string[]): AppLimitEntry[] {
    const next: AppLimitEntry[] = [];
    for (let index = 0; index < tokens.length; index++) {
      const token = tokens[index];
      let minutes = 0;
      let label = '';
      for (let look = 0; look < current.length; look++) {
        if (current[look].token === token) {
          minutes = current[look].minutes;
          label = current[look].label;
          break;
        }
      }
      next.push({ token: token, minutes: minutes, label: label });
    }
    return next;
  }


  private async toggleDowntime(enabled: boolean): Promise<void> {
    const next = enabled ? `${this.downtimeStart}-${this.downtimeEnd}` : '';
    const previous = this.downtime;
    this.downtime = next;
    await this.settings.saveDowntime(next, this.downtimeStart, this.downtimeEnd);
    const result = await this.syncRules('');
    if (!result.success) {
      this.downtime = previous;
      await this.settings.saveDowntime(previous, this.downtimeStart, this.downtimeEnd);
    }
  }

  private async setDowntimeClock(start: string, end: string): Promise<void> {
    this.downtimeStart = start;
    this.downtimeEnd = end;
    if (this.downtime.length > 0) {
      this.downtime = `${start}-${end}`;
    }
    await this.settings.saveDowntime(this.downtime, start, end);
    if (this.downtime.length > 0) {
      await this.syncRules('');
    }
  }

  private async removeManagedApp(token: string): Promise<void> {
    const next: AppLimitEntry[] = [];
    for (let index = 0; index < this.appLimits.length; index++) {
      if (this.appLimits[index].token !== token) {
        next.push(this.appLimits[index]);
      }
    }
    this.appLimits = next;
    await this.settings.saveAppLimits(next);
    await this.syncRules('已移除管控应用');
  }

  private async setAppLimit(token: string, minutes: number): Promise<void> {
    const next: AppLimitEntry[] = [];
    for (let index = 0; index < this.appLimits.length; index++) {
      const item = this.appLimits[index];
      if (item.token === token) {
        next.push({ token: token, minutes: minutes, label: item.label });
      } else {
        next.push(item);
      }
    }
    this.appLimits = next;
    await this.settings.saveAppLimits(next);
    await this.syncRules('已更新应用限额');
  }

  private async setAppLabel(token: string, label: string): Promise<void> {
    const next: AppLimitEntry[] = [];
    for (let index = 0; index < this.appLimits.length; index++) {
      const item = this.appLimits[index];
      if (item.token === token) {
        next.push({ token: token, minutes: item.minutes, label: label });
      } else {
        next.push(item);
      }
    }
    this.appLimits = next;
    await this.settings.saveAppLimits(next);
  }

  private async syncRules(successToast: string): Promise<GuardActionResult> {
    if (!this.authorized) {
      const result: GuardActionResult = { success: false, message: '请先开启系统守护授权' };
      this.toast(result.message);
      return result;
    }
    const result = await this.guard.syncControlRules(this.appLimits, this.whitelistTokens, this.downtime);
    await this.refreshRuntimeState(false);
    if (successToast.length > 0 && result.success) {
      this.toast(successToast);
    } else if (!result.success) {
      this.toast(result.message);
    }
    return result;
  }

  private async requestNotify(): Promise<void> {
    try {
      await PermissionManager.requestNotification(this.context);
    } catch (error) {
      const err = error as BusinessError;
      this.toast(`无法申请通知权限（错误码 ${err.code}）`);
    }
    await this.refreshPermissions();
  }

  private async openBackground(): Promise<void> {
    try {
      await PermissionManager.requestBackground(this.context);
    } catch (_) {
      try {
        await PermissionManager.openAppSettings(this.context);
      } catch (error) {
        const err = error as BusinessError;
        this.toast(`请在系统设置中允许 Tictoc 后台运行（${err.message}）`);
      }
    }
    await this.refreshPermissions();
  }

  private async releaseAll(): Promise<void> {
    this.busy = true;
    try {
      const result = await this.guard.releaseAll(this.immediateTokens);
      this.immediateTokens = [];
      this.appLimits = [];
      this.whitelistTokens = [];
      this.downtime = '';
      await this.settings.saveImmediateTokens([]);
      await this.settings.saveAppLimits([]);
      await this.settings.saveWhitelistTokens([]);
      await this.settings.saveDowntime('', this.downtimeStart, this.downtimeEnd);
      await this.refreshRuntimeState(true);
      await this.refreshPermissions();
      this.toast(result.success ? '已解除全部管控规则，授权状态已刷新' : result.message);
    } finally {
      this.busy = false;
    }
  }

  private async lockSettings(): Promise<void> {
    await this.syncRules('管控规则已同步到系统');
    this.isUnlocked = false;
    this.pinInput = '';
    this.toast('已进入管控。之后打开 Tictoc 或修改设置，都要验证家长密码。');
  }

  private async saveNewPin(salt: string, hash: string): Promise<void> {
    await this.settings.savePin(salt, hash);
    this.pinSalt = salt;
    this.pinHash = hash;
  }

  private limitSummary(): string {
    if (this.appLimits.length === 0) {
      return '';
    }
    let min = this.appLimits[0].minutes;
    let max = this.appLimits[0].minutes;
    for (let index = 1; index < this.appLimits.length; index++) {
      const minutes = this.appLimits[index].minutes;
      if (minutes < min) {
        min = minutes;
      }
      if (minutes > max) {
        max = minutes;
      }
    }
    return min === max ? `${min} 分钟` : `${min}-${max} 分钟`;
  }

  private guardStatus(): string {
    return TimeUtils.guardStatus(this.authorized, this.downtime, this.appLimits.length);
  }

  build() {
    Stack() {
      if (this.loading) {
        Column({ space: 16 }) {
          LoadingProgress().width(48).height(48)
          Text('正在读取本机管控状态…')
            .fontSize(16)
            .fontColor(ThemeColor.subtitle)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.initializationError.length > 0) {
        Column({ space: 12 }) {
          Text('本机设置读取失败')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          Text(this.initializationError)
            .fontSize(15)
            .fontColor(ThemeColor.danger)
        }
        .padding(32)
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (!this.hasPin) {
        this.pinSetupView()
      } else if (!this.isUnlocked) {
        this.pinUnlockView()
      } else if (this.showAlwaysAllowed) {
        AlwaysAllowedPage({
          extraCount: this.whitelistTokens.length,
          onBack: () => this.showAlwaysAllowed = false,
          onPickApps: () => this.pickWhitelistApps()
        })
      } else {
        this.mainTabs()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColor.pageBg)
  }


  @Builder
  private pinSetupView() {
    Column({ space: 18 }) {
      Text('设置家长密码')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColor.title)
      Text('首次使用请设置 4-6 位数字密码，用于保护管控设置')
        .fontSize(15)
        .fontColor(ThemeColor.subtitle)
        .textAlign(TextAlign.Center)
      TextInput({ text: this.setupPin, placeholder: '请输入新密码' })
        .type(InputType.NUMBER_PASSWORD)
        .maxLength(6)
        .width(220)
        .height(52)
        .backgroundColor(ThemeColor.card)
        .borderRadius(14)
        .onChange((value: string) => {
          if (value.length <= 6) {
            this.setupPin = value;
          }
        })
      TextInput({ text: this.setupConfirmPin, placeholder: '请再次输入确认' })
        .type(InputType.NUMBER_PASSWORD)
        .maxLength(6)
        .width(220)
        .height(52)
        .backgroundColor(ThemeColor.card)
        .borderRadius(14)
        .onChange((value: string) => {
          if (value.length <= 6) {
            this.setupConfirmPin = value;
          }
        })
      Button('完成设置')
        .width(220)
        .height(48)
        .enabled(!this.busy)
        .onClick(() => {
          this.confirmPinSetup();
        })
    }
    .padding(32)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private async confirmPinSetup(): Promise<void> {
    if (this.busy) {
      return;
    }
    if (!PinSecurity.isValidFormat(this.setupPin)) {
      this.toast('密码需为 4-6 位数字');
      return;
    }
    if (this.setupPin !== this.setupConfirmPin) {
      this.toast('两次输入的密码不一致');
      return;
    }
    this.busy = true;
    try {
      const credential = await PinSecurity.createCredential(this.setupPin);
      await this.settings.savePin(credential.salt, credential.hash);
      this.pinSalt = credential.salt;
      this.pinHash = credential.hash;
      this.hasPin = true;
      this.isUnlocked = true;
      this.setupPin = '';
      this.setupConfirmPin = '';
      await this.refreshRuntimeState(false);
      await this.refreshPermissions();
      this.toast('家长密码已设置');
    } catch (_) {
      this.toast('密码保存失败，请重试');
    } finally {
      this.busy = false;
    }
  }

  @Builder
  private pinUnlockView() {
    Column({ space: 18 }) {
      Text('Tictoc 家长锁')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColor.title)
      Text('请输入家长密码以修改设置')
        .fontSize(15)
        .fontColor(ThemeColor.subtitle)
      TextInput({ text: this.pinInput, placeholder: '请输入4-6位数字密码' })
        .type(InputType.NUMBER_PASSWORD)
        .maxLength(6)
        .width(220)
        .height(52)
        .backgroundColor(ThemeColor.card)
        .borderRadius(14)
        .onChange((value: string) => {
          if (value.length <= 6) {
            this.pinInput = value;
            this.unlockFromInput(value, false);
          }
        })
      Button('解锁')
        .width(220)
        .height(48)
        .enabled(!this.busy)
        .margin({ top: 8 })
        .onClick(() => {
          this.unlockFromInput(this.pinInput, true);
        })
    }
    .padding(32)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private mainTabs() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabController, index: this.currentTab }) {
      TabContent() {
        DashboardPage({
          guardStatus: this.guardStatus(),
          authorized: this.authorized,
          managedCount: this.appLimits.length,
          downtimeText: this.downtime,
          limitSummary: this.limitSummary(),
          strategyCount: this.configuredStrategies
        })
      }
      .tabBar(this.tabBarItem('仪表盘', 0))

      TabContent() {
        ControlPage({
          appLimits: $appLimits,
          downtime: $downtime,
          downtimeStart: $downtimeStart,
          downtimeEnd: $downtimeEnd,
          whitelistCount: this.whitelistTokens.length,
          authorized: this.authorized,
          busy: this.busy,
          onToggleDowntime: (enabled: boolean) => this.toggleDowntime(enabled),
          onSetDowntimeClock: (start: string, end: string) => this.setDowntimeClock(start, end),
          onPickApps: () => this.pickManagedApps(),
          onOpenAlwaysAllowed: () => this.showAlwaysAllowed = true,
          onRemoveApp: (token: string) => this.removeManagedApp(token),
          onSetLimit: (token: string, minutes: number): Promise<void> => this.setAppLimit(token, minutes),
          onSetLabel: (token: string, label: string): Promise<void> => this.setAppLabel(token, label),
          onEnterControl: async (): Promise<void> => await this.lockSettings()
        })
      }
      .tabBar(this.tabBarItem('管控设置', 1))

      TabContent() {
        ProfilePage({
          authorized: $authorized,
          notifyEnabled: $notifyEnabled,
          backgroundGranted: $backgroundGranted,
          pinSalt: this.pinSalt,
          pinHash: this.pinHash,
          onRequestAuth: () => this.requestAuthorization(),
          onRequestNotify: () => this.requestNotify(),
          onOpenBackground: () => this.openBackground(),
          onReleaseAll: async (): Promise<void> => await this.releaseAll(),
          onRefreshPermissions: async (): Promise<void> => await this.refreshProfilePermissions(),
          onPinChanged: (salt: string, hash: string) => this.saveNewPin(salt, hash),
          onToast: (message: string) => this.toast(message)
        })
      }
      .tabBar(this.tabBarItem('个人中心', 2))
    }
    .barMode(BarMode.Fixed)
    .barBackgroundColor(ThemeColor.card)
    .onChange((index: number) => {
      this.currentTab = index;
      this.refreshRuntimeState(false);
      this.refreshPermissions();
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  private tabBarItem(title: string, index: number) {
    Column({ space: 2 }) {
      Text(index === 0 ? '▣' : (index === 1 ? '⚙' : '☺'))
        .fontSize(18)
        .fontColor(this.currentTab === index ? ThemeColor.primary : ThemeColor.subtitle)
      Text(title)
        .fontSize(11)
        .fontColor(this.currentTab === index ? ThemeColor.primary : ThemeColor.subtitle)
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
  }
}
