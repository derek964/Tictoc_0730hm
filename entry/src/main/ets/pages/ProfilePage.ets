import { PinSecurity } from '../security/PinSecurity';
import { PermissionManager, PermissionSnapshot } from '../permission/PermissionManager';
import { ThemeColor } from '../ui/Theme';

@Component
export struct ProfilePage {
  @Prop authorized: boolean = false;
  @Prop managedCount: number = 0;
  @Prop notifyEnabled: boolean = false;
  @Prop backgroundGranted: boolean = false;
  @Prop pinSalt: string = '';
  @Prop pinHash: string = '';
  onRequestAuth: () => void = () => {};
  onSelectApps: () => void = () => {};
  onRequestNotify: () => void = () => {};
  onOpenBackground: () => void = () => {};
  onReleaseAll: () => void = () => {};
  onPinChanged: (salt: string, hash: string) => void = (_salt: string, _hash: string) => {};
  onToast: (message: string) => void = (_message: string) => {};

  @State private showPasswordDialog: boolean = false;
  @State private oldPin: string = '';
  @State private newPin: string = '';
  @State private confirmPin: string = '';

  private snapshot(): PermissionSnapshot {
    return {
      screenTimeAuthorized: this.authorized,
      hasManagedApps: this.managedCount > 0,
      notificationEnabled: this.notifyEnabled,
      backgroundGranted: this.backgroundGranted
    };
  }

  private coreGranted(): boolean {
    return PermissionManager.corePermissionsGranted(this.snapshot());
  }

  build() {
    Column() {
      Text('个人中心')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColor.title)
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 8 }) {
          this.securityCard()

          this.sectionHeader('账号与基础配置')
          Column() {
            this.rowItem('修改家长密码', '', true, () => {
              this.oldPin = '';
              this.newPin = '';
              this.confirmPin = '';
              this.showPasswordDialog = true;
            })
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)
          .margin({ left: 16, right: 16 })

          this.sectionHeader('核心权限管理')
          Column() {
            this.permissionItem('使用情况访问权限', this.authorized,
              '获取应用使用时长（鸿蒙由屏幕时间守护提供）', false, () => this.onRequestAuth())
            this.permissionItem('系统守护执行', this.authorized,
              '对应安卓无障碍服务，由系统拦截受管应用', false, () => this.onRequestAuth())
            this.permissionItem('系统拦截页', this.authorized,
              '对应安卓悬浮窗；鸿蒙使用系统限制页，无需叠层窗口', false, () => this.onRequestAuth())
            this.permissionItem('读取应用列表', this.authorized,
              this.managedCount > 0 ? `已选择 ${this.managedCount} 个受管应用` : '通过系统应用选择器识别应用',
              true, () => this.onSelectApps())
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)
          .margin({ left: 16, right: 16 })

          this.sectionHeader('增强功能与守护')
          Column() {
            this.permissionItem('保持后台运行', this.backgroundGranted,
              '对应安卓忽略电池优化，减少被系统挂起', false, () => this.onOpenBackground())
            this.permissionItem('允许发送通知', this.notifyEnabled,
              '及时接收重要提醒', false, () => this.onRequestNotify())
            this.permissionItem('防卸载守护', this.authorized,
              '对应安卓设备管理器；授权后由系统管控策略约束卸载', true, () => this.onRequestAuth())
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)
          .margin({ left: 16, right: 16 })

          this.sectionHeader('紧急操作')
          Column() {
            this.rowItem('解除全部限制', '停止 Tictoc 创建的系统规则', true, () => this.onReleaseAll())
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)
          .margin({ left: 16, right: 16 })

          Text('核心权限与安卓一一对应：使用情况、无障碍、悬浮窗在鸿蒙合并为屏幕时间守护授权；应用列表走系统选择器。')
            .fontSize(12)
            .fontColor(ThemeColor.subtitle)
            .margin({ left: 20, right: 20, top: 8, bottom: 28 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColor.pageBg)
    .bindSheet($$this.showPasswordDialog, this.passwordSheet(), {
      height: 420,
      dragBar: true,
      showClose: true
    })
  }

  @Builder
  private securityCard() {
    Row({ space: 16 }) {
      Column() {
        Text(this.coreGranted() ? '✓' : '!')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.coreGranted() ? ThemeColor.primary : ThemeColor.danger)
      .borderRadius(24)

      Column({ space: 4 }) {
        Text(this.coreGranted() ? '守护状态：正常' : '守护状态：受限')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.coreGranted() ? ThemeColor.primary : ThemeColor.danger)
        Text(this.coreGranted() ?
          '所有核心权限已开启，Tictoc 正在持续守护中' :
          '部分核心权限未开启，管控可能失效，请及时处理')
          .fontSize(12)
          .fontColor(ThemeColor.subtitle)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .padding(20)
    .margin({ left: 16, right: 16, top: 8 })
    .backgroundColor(ThemeColor.card)
    .borderRadius(16)
    .width('100%')
  }

  @Builder
  private sectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(ThemeColor.primary)
      .margin({ left: 20, top: 16, bottom: 8 })
      .width('100%')
  }

  @Builder
  private permissionItem(title: string, granted: boolean, subtitle: string, last: boolean, onClick: () => void) {
    this.rowItem(title, granted ? '已开启' : subtitle, last, onClick, granted ? '已开启' : '去开启', granted)
  }

  @Builder
  private rowItem(title: string, subtitle: string, last: boolean, onClick: () => void,
    trailing: string = '>', granted: boolean = true) {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text(title)
            .fontSize(16)
            .fontColor(ThemeColor.title)
          if (subtitle.length > 0) {
            Text(subtitle)
              .fontSize(12)
              .fontColor(ThemeColor.subtitle)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(trailing)
          .fontSize(14)
          .fontColor(granted ? ThemeColor.subtitle : ThemeColor.danger)
          .fontWeight(granted ? FontWeight.Normal : FontWeight.Bold)
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .width('100%')
      .onClick(onClick)

      if (!last) {
        Divider()
          .color(ThemeColor.divider)
          .margin({ left: 16 })
      }
    }
    .width('100%')
  }

  @Builder
  private passwordSheet() {
    Column({ space: 12 }) {
      Text('修改家长密码')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColor.title)
      TextInput({ text: this.oldPin, placeholder: '旧密码 (4-6位数字)' })
        .type(InputType.NUMBER_PASSWORD)
        .maxLength(6)
        .height(48)
        .backgroundColor(ThemeColor.pageBg)
        .onChange((value: string) => this.oldPin = value)
      TextInput({ text: this.newPin, placeholder: '新密码 (4-6位数字)' })
        .type(InputType.NUMBER_PASSWORD)
        .maxLength(6)
        .height(48)
        .backgroundColor(ThemeColor.pageBg)
        .onChange((value: string) => this.newPin = value)
      TextInput({ text: this.confirmPin, placeholder: '确认新密码 (4-6位数字)' })
        .type(InputType.NUMBER_PASSWORD)
        .maxLength(6)
        .height(48)
        .backgroundColor(ThemeColor.pageBg)
        .onChange((value: string) => this.confirmPin = value)
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor(ThemeColor.pageBg)
          .fontColor(ThemeColor.title)
          .onClick(() => this.showPasswordDialog = false)
        Button('确定')
          .layoutWeight(1)
          .onClick(() => this.confirmChangePin())
      }
    }
    .padding(24)
    .width('100%')
  }

  private async confirmChangePin(): Promise<void> {
    if (!await PinSecurity.verify(this.oldPin, this.pinSalt, this.pinHash)) {
      this.onToast('旧密码错误');
      return;
    }
    if (this.newPin !== this.confirmPin || !PinSecurity.isValidFormat(this.newPin)) {
      this.onToast('新密码不匹配或长度应为4-6位');
      return;
    }
    try {
      const credential = await PinSecurity.createCredential(this.newPin);
      this.onPinChanged(credential.salt, credential.hash);
      this.showPasswordDialog = false;
      this.onToast('密码修改成功');
    } catch (_) {
      this.onToast('密码保存失败，请重试');
    }
  }
}
