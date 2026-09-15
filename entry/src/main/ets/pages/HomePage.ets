import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SettingsStore } from '../data/SettingsStore';
import { GuardActionResult, TictocGuardManager } from '../guard/TictocGuardManager';
import { PinSecurity } from '../security/PinSecurity';

@Entry
@Component
struct HomePage {
  private context: common.UIAbilityContext =
    this.getUIContext().getHostContext() as common.UIAbilityContext;
  private settings: SettingsStore = new SettingsStore();
  private guard: TictocGuardManager = new TictocGuardManager();
  private systemFlowActive: boolean = false;

  @State private loading: boolean = true;
  @State private initializationError: string = '';
  @State private hasPin: boolean = false;
  @State private isUnlocked: boolean = false;
  @State private changingPin: boolean = false;
  @StorageLink('tictocBackgroundEpoch') @Watch('onBackgroundEpochChanged')
  private backgroundEpoch: number = 0;
  @State private pinSalt: string = '';
  @State private pinHash: string = '';
  @State private pinInput: string = '';
  @State private pinConfirm: string = '';
  @State private failedPinAttempts: number = 0;
  @State private lockUntil: number = 0;

  @State private authorized: boolean = false;
  @State private selectedTokens: string[] = [];
  @State private immediateTokens: string[] = [];
  @State private configuredStrategies: number = 0;
  @State private downtimeStart: string = '22:00';
  @State private downtimeEnd: string = '07:00';
  @State private dailyMinutesText: string = '60';
  @State private busy: boolean = false;
  @State private lastMessage: string = '尚未检查系统状态';
  @State private lastActionSucceeded: boolean = true;

  aboutToAppear(): void {
    this.initialize();
  }

  onPageHide(): void {
    this.lockManagementView();
  }

  private onBackgroundEpochChanged(): void {
    this.lockManagementView();
  }

  private lockManagementView(): void {
    if (this.hasPin) {
      this.isUnlocked = false;
      this.changingPin = false;
      this.pinInput = '';
      this.pinConfirm = '';
    }
  }

  private async initialize(): Promise<void> {
    try {
      await this.settings.initialize(this.context);
      const saved = await this.settings.load();
      this.selectedTokens = saved.appTokens;
      this.immediateTokens = saved.immediateTokens;
      this.downtimeStart = saved.downtimeStart;
      this.downtimeEnd = saved.downtimeEnd;
      this.dailyMinutesText = saved.dailyMinutes.toString();
      this.pinSalt = saved.pinSalt;
      this.pinHash = saved.pinHash;
      if ((this.pinSalt.length === 0) !== (this.pinHash.length === 0)) {
        throw new Error('PIN 数据不完整，已阻止重新设置以保护现有规则');
      }
      this.hasPin = this.pinSalt.length > 0 && this.pinHash.length > 0;
      await this.refreshRuntimeState();
    } catch (error) {
      const err = error as BusinessError;
      this.initializationError = `无法读取本机设置：${err.message}`;
      this.showResult({ success: false, message: `初始化失败：${err.message}` });
    } finally {
      this.loading = false;
    }
  }

  private async refreshRuntimeState(updateMessage: boolean = true): Promise<void> {
    const state = await this.guard.queryState();
    this.authorized = state.authorized;
    this.configuredStrategies = state.configuredStrategies;
    if (updateMessage) {
      this.lastMessage = state.errorMessage.length > 0 ? state.errorMessage :
        (state.authorized ? '系统守护授权有效' : '需要先完成系统守护授权');
      this.lastActionSucceeded = state.authorized;
    }
  }

  private async setupPin(): Promise<void> {
    if (this.busy || (this.hasPin && !this.isUnlocked)) { return; }
    const epoch = this.backgroundEpoch;
    if (!PinSecurity.isValidFormat(this.pinInput)) {
      this.showResult({ success: false, message: 'PIN 必须是 6 位数字' });
      return;
    }
    if (this.pinInput !== this.pinConfirm) {
      this.showResult({ success: false, message: '两次输入的 PIN 不一致' });
      return;
    }
    this.busy = true;
    try {
      const credential = await PinSecurity.createCredential(this.pinInput);
      await this.settings.savePin(credential.salt, credential.hash);
      this.pinSalt = credential.salt;
      this.pinHash = credential.hash;
      this.hasPin = true;
      this.isUnlocked = epoch === this.backgroundEpoch;
      this.changingPin = false;
      this.pinInput = '';
      this.pinConfirm = '';
      this.showResult({ success: true, message: '管理 PIN 已设置' });
    } catch (error) {
      const err = error as BusinessError;
      this.showResult({ success: false, message: `PIN 保存失败：${err.message}` });
    } finally {
      this.busy = false;
    }
  }

  private async unlock(): Promise<void> {
    if (this.busy) { return; }
    const epoch = this.backgroundEpoch;
    const now = Date.now();
    if (now < this.lockUntil) {
      const waitSeconds = Math.ceil((this.lockUntil - now) / 1000);
      this.showResult({ success: false, message: `尝试次数过多，请等待 ${waitSeconds} 秒` });
      return;
    }
    if (!PinSecurity.isValidFormat(this.pinInput)) {
      this.showResult({ success: false, message: '请输入 6 位数字 PIN' });
      return;
    }
    this.busy = true;
    try {
      if (await PinSecurity.verify(this.pinInput, this.pinSalt, this.pinHash)) {
        this.isUnlocked = epoch === this.backgroundEpoch;
        this.failedPinAttempts = 0;
        this.pinInput = '';
        await this.refreshRuntimeState();
      } else {
        this.failedPinAttempts++;
        if (this.failedPinAttempts >= 5) {
          this.lockUntil = Date.now() + 30000;
          this.failedPinAttempts = 0;
          this.showResult({ success: false, message: 'PIN 错误次数过多，已暂停 30 秒' });
        } else {
          this.showResult({ success: false, message: `PIN 错误，还可尝试 ${5 - this.failedPinAttempts} 次` });
        }
      }
    } catch (error) {
      this.isUnlocked = false;
      this.showResult({ success: false, message: 'PIN 校验失败，请重试' });
    } finally {
      this.busy = false;
    }
  }

  private async requestAuthorization(): Promise<void> {
    if (this.busy || !this.isUnlocked) { return; }
    this.busy = true;
    this.systemFlowActive = true;
    try {
      const result = await this.guard.requestAuthorization(this.context);
      await this.refreshRuntimeState(false);
      this.showResult(result);
    } finally {
      this.systemFlowActive = false;
      this.busy = false;
    }
  }

  private async selectApps(): Promise<void> {
    if (this.busy || !this.isUnlocked) { return; }
    if (!this.authorized) {
      this.showResult({ success: false, message: '请先开启系统守护授权' });
      return;
    }
    this.busy = true;
    this.systemFlowActive = true;
    try {
      const tokens = await this.guard.pickApps(this.context, this.selectedTokens);
      await this.settings.saveAppTokens(tokens);
      this.selectedTokens = tokens;
      this.showResult({ success: true, message: `已选择 ${tokens.length} 个应用` });
    } catch (error) {
      const err = error as BusinessError;
      this.showResult({ success: false, message: `应用选择未完成（错误码 ${err.code}）` });
    } finally {
      this.systemFlowActive = false;
      this.busy = false;
    }
  }

  private async saveInputs(): Promise<number> {
    const minutes = Number(this.dailyMinutesText);
    await this.settings.saveRuleInputs(this.downtimeStart, this.downtimeEnd,
      Number.isFinite(minutes) ? minutes : 60);
    return minutes;
  }

  private async applyImmediate(): Promise<void> {
    await this.runGuardAction(async () => {
      const result = await this.guard.applyImmediateRestriction(this.immediateTokens, this.selectedTokens);
      if (result.success) {
        this.immediateTokens = this.selectedTokens.slice();
        await this.settings.saveImmediateTokens(this.immediateTokens);
      }
      return result;
    });
  }

  private async applyDowntime(): Promise<void> {
    await this.runGuardAction(async () => {
      await this.saveInputs();
      return await this.guard.applyDowntime(this.selectedTokens, this.downtimeStart, this.downtimeEnd);
    });
  }

  private async applyDailyQuota(): Promise<void> {
    await this.runGuardAction(async () => {
      const minutes = await this.saveInputs();
      return await this.guard.applyDailyQuota(this.selectedTokens, minutes);
    });
  }

  private async releaseAll(): Promise<void> {
    await this.runGuardAction(async () => {
      const result = await this.guard.releaseAll(this.immediateTokens);
      if (result.success) {
        this.immediateTokens = [];
        await this.settings.saveImmediateTokens([]);
      }
      return result;
    });
  }

  private async runGuardAction(action: () => Promise<GuardActionResult>): Promise<void> {
    if (this.busy || !this.isUnlocked) { return; }
    if (!this.authorized) {
      this.showResult({ success: false, message: '请先开启系统守护授权' });
      return;
    }
    this.busy = true;
    try {
      const result = await action();
      await this.refreshRuntimeState(false);
      this.showResult(result);
    } catch (error) {
      this.showResult({ success: false,
        message: '操作或本机保存失败，系统规则可能已变更，请刷新状态并检查限制' });
    } finally {
      this.busy = false;
    }
  }

  private async resetPin(): Promise<void> {
    if (this.busy || !this.isUnlocked) { return; }
    this.pinInput = '';
    this.pinConfirm = '';
    this.changingPin = true;
    this.showResult({ success: true, message: '请设置新的管理 PIN' });
  }

  private showResult(result: GuardActionResult): void {
    this.lastMessage = result.message;
    this.lastActionSucceeded = result.success;
    this.getUIContext().getPromptAction().showToast({ message: result.message, duration: 2500 });
  }

  build() {
    Stack() {
      if (this.loading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(48)
            .height(48)
          Text('正在读取本机管控状态…')
            .fontSize(16)
            .fontColor('#667085')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.initializationError.length > 0) {
        Column({ space: 12 }) {
          Text('本机设置读取失败')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
          Text(this.initializationError)
            .fontSize(15)
            .fontColor('#B42318')
          Text('请关闭应用后重新打开；保留本机数据以便排查和恢复已有规则。')
            .fontSize(14)
            .fontColor('#667085')
        }
        .padding(32)
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (!this.hasPin || this.changingPin) {
        this.pinSetupView()
      } else if (!this.isUnlocked) {
        this.pinUnlockView()
      } else {
        this.controlView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  @Builder
  private pageHeader(title: string, subtitle: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
      Text(subtitle)
        .fontSize(15)
        .fontColor('#667085')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  private pinField(placeholder: string, confirm: boolean) {
    TextInput({ text: confirm ? this.pinConfirm : this.pinInput, placeholder: placeholder })
      .type(InputType.NUMBER_PASSWORD)
      .maxLength(6)
      .height(52)
      .backgroundColor('#FFFFFF')
      .borderRadius(14)
      .onChange((value: string) => {
        if (confirm) {
          this.pinConfirm = value;
        } else {
          this.pinInput = value;
        }
      })
  }

  @Builder
  private pinSetupView() {
    Column({ space: 18 }) {
      this.pageHeader('设置管理 PIN', 'PIN 用于保护规则修改和解除操作，仅保存在本机。')
      this.pinField('输入 6 位数字 PIN', false)
      this.pinField('再次输入 PIN', true)
      Button('保存并进入')
        .width('100%')
        .height(52)
        .enabled(!this.busy)
        .onClick(() => this.setupPin())
      Text('请妥善保存 PIN。当前版本不提供绕过 PIN 的本地找回入口。')
        .fontSize(13)
        .fontColor('#C2410C')
    }
    .padding({ left: 24, right: 24 })
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }

  @Builder
  private pinUnlockView() {
    Column({ space: 18 }) {
      this.pageHeader('Tictoc 管理入口', '输入管理 PIN 后才能修改或解除管控规则。')
      this.pinField('输入 6 位数字 PIN', false)
      Button('解锁')
        .width('100%')
        .height(52)
        .enabled(!this.busy)
        .onClick(() => this.unlock())
      if (!this.lastActionSucceeded) {
        Text(this.lastMessage)
          .fontSize(14)
          .fontColor('#B42318')
      }
    }
    .padding({ left: 24, right: 24 })
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }

  @Builder
  private sectionTitle(title: string, description: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
      Text(description)
        .fontSize(13)
        .fontColor('#667085')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private controlView() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 10 }) {
          this.pageHeader('Tictoc', '专为 HarmonyOS 设计的屏幕时间管理')
          Button('锁定')
            .type(ButtonType.Normal)
            .fontSize(14)
            .onClick(() => {
              this.isUnlocked = false;
              this.pinInput = '';
            })
            .alignSelf(ItemAlign.End)
        }
        .width('100%')

        Column({ space: 14 }) {
          this.sectionTitle('1. 系统授权', '授权后可向系统提交规则，请在目标应用中验证限制效果。')
          Row({ space: 8 }) {
            Text(this.authorized ? '已授权' : '未授权')
              .fontColor(this.authorized ? '#067647' : '#B42318')
              .fontWeight(FontWeight.Bold)
            Text(this.configuredStrategies < 0 ? '管控规则：未知' : `管控规则：${this.configuredStrategies} 条`)
              .fontColor('#667085')
            Text(`立即限制：${this.immediateTokens.length} 个应用`)
              .fontColor('#667085')
          }
          Button(this.authorized ? '重新检查授权' : '开启系统守护授权')
            .width('100%')
            .enabled(!this.busy)
            .onClick(() => this.requestAuthorization())
        }
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)

        Column({ space: 14 }) {
          this.sectionTitle('2. 选择应用', '通过系统页面选择需要管理的应用，选择结果仅保存在本机。')
          Text(`已选择 ${this.selectedTokens.length} 个应用`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
          Button('选择需要管理的应用')
            .width('100%')
            .enabled(!this.busy && this.authorized)
            .onClick(() => this.selectApps())
        }
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)

        Column({ space: 14 }) {
          this.sectionTitle('3. 每日停用时间', '每天在设定时段限制所选应用，结束时间小于开始时间时跨越午夜。')
          Row({ space: 12 }) {
            TextInput({ text: this.downtimeStart, placeholder: '22:00' })
              .layoutWeight(1)
              .maxLength(5)
              .onChange((value: string) => this.downtimeStart = value)
            Text('至').fontColor('#667085')
            TextInput({ text: this.downtimeEnd, placeholder: '07:00' })
              .layoutWeight(1)
              .maxLength(5)
              .onChange((value: string) => this.downtimeEnd = value)
          }
          Button('启用每日停用时间')
            .width('100%')
            .enabled(!this.busy && this.authorized && this.selectedTokens.length > 0)
            .onClick(() => this.applyDowntime())
        }
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)

        Column({ space: 14 }) {
          this.sectionTitle('4. 每日共享额度', '所选应用共同消耗这一额度；额度耗尽后由系统限制访问。')
          Row({ space: 10 }) {
            TextInput({ text: this.dailyMinutesText, placeholder: '60' })
              .type(InputType.Number)
              .layoutWeight(1)
              .maxLength(4)
              .onChange((value: string) => this.dailyMinutesText = value)
            Text('分钟').fontColor('#667085')
          }
          Button('启用每日共享额度')
            .width('100%')
            .enabled(!this.busy && this.authorized && this.selectedTokens.length > 0)
            .onClick(() => this.applyDailyQuota())
        }
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)

        Column({ space: 12 }) {
          this.sectionTitle('5. 临时管控', '立即限制所选应用，或解除本应用创建的全部限制。')
          Button('立即限制所选应用')
            .width('100%')
            .enabled(!this.busy && this.authorized && this.selectedTokens.length > 0)
            .onClick(() => this.applyImmediate())
          Button('解除全部限制')
            .width('100%')
            .backgroundColor('#FEE4E2')
            .fontColor('#B42318')
            .enabled(!this.busy && this.authorized)
            .onClick(() => this.releaseAll())
        }
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)

        Column({ space: 12 }) {
          Text(this.lastMessage)
            .fontSize(14)
            .fontColor(this.lastActionSucceeded ? '#067647' : '#B42318')
          Row({ space: 12 }) {
            Button('刷新状态')
              .layoutWeight(1)
              .enabled(!this.busy)
              .onClick(() => this.refreshRuntimeState())
            Button('修改 PIN')
              .layoutWeight(1)
              .backgroundColor('#EAECF0')
              .fontColor('#344054')
              .enabled(!this.busy)
              .onClick(() => this.resetPin())
          }
          Text('策略由 HarmonyOS 系统执行。卸载应用、撤销系统授权或不支持的空间会影响管控。')
            .fontSize(12)
            .fontColor('#667085')
        }
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
      }
      .padding({ top: 24, bottom: 32, left: 16, right: 16 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
