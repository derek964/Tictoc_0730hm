from pathlib import Path

profile_path = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
# Read current and surgically replace permissionItem usage + builders
# Easier to rewrite full file with PermissionRow component

src = r'''import { PinSecurity } from '../security/PinSecurity';
import { PermissionManager, PermissionSnapshot } from '../permission/PermissionManager';
import { ThemeColor } from '../ui/Theme';

@Component
struct PermissionStatusRow {
  @Prop title: string = '';
  @Prop granted: boolean = false;
  @Prop offSubtitle: string = '';
  @Prop isLast: boolean = true;
  onTap: () => void = () => {};

  build() {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text(this.title)
            .fontSize(16)
            .fontColor(ThemeColor.title)
          Text(this.granted ? '已开启' : this.offSubtitle)
            .fontSize(12)
            .fontColor(ThemeColor.subtitle)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.granted ? '已开启' : '去开启')
          .fontSize(14)
          .fontColor(this.granted ? ThemeColor.subtitle : ThemeColor.danger)
          .fontWeight(this.granted ? FontWeight.Normal : FontWeight.Bold)
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .width('100%')
      .onClick(() => this.onTap())

      if (!this.isLast) {
        Divider()
          .color(ThemeColor.divider)
          .margin({ left: 16 })
      }
    }
    .width('100%')
  }
}

@Component
export struct ProfilePage {
  @Prop @Watch('onAuthorizedChange') authorized: boolean = false;
  @Prop @Watch('onNotifyChange') notifyEnabled: boolean = false;
  @Prop @Watch('onBackgroundChange') backgroundGranted: boolean = false;
  @Prop pinSalt: string = '';
  @Prop pinHash: string = '';
  onRequestAuth: () => void = () => {};
  onRequestNotify: () => void = () => {};
  onOpenBackground: () => void = () => {};
  onReleaseAll: () => void = () => {};
  onRefreshPermissions: () => void = () => {};
  onPinChanged: (salt: string, hash: string) => void = (_salt: string, _hash: string) => {};
  onToast: (message: string) => void = (_message: string) => {};

  @State private showSheet: boolean = false;
  @State private sheetKind: string = 'none';
  @State private oldPin: string = '';
  @State private newPin: string = '';
  @State private confirmPin: string = '';
  @State private releasePin: string = '';
  @State private authGranted: boolean = false;
  @State private notifyGranted: boolean = false;
  @State private backgroundOk: boolean = false;

  aboutToAppear(): void {
    this.syncLocalFlags();
    this.onRefreshPermissions();
  }

  onAuthorizedChange(): void {
    this.authGranted = this.authorized;
  }

  onNotifyChange(): void {
    this.notifyGranted = this.notifyEnabled;
  }

  onBackgroundChange(): void {
    this.backgroundOk = this.backgroundGranted;
  }

  private syncLocalFlags(): void {
    this.authGranted = this.authorized;
    this.notifyGranted = this.notifyEnabled;
    this.backgroundOk = this.backgroundGranted;
  }

  private snapshot(): PermissionSnapshot {
    return {
      screenTimeAuthorized: this.authGranted,
      hasManagedApps: false,
      notificationEnabled: this.notifyGranted,
      backgroundGranted: this.backgroundOk
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
              this.openSheet('password');
            })
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)
          .margin({ left: 16, right: 16 })

          this.sectionHeader('核心权限管理')
          Column() {
            PermissionStatusRow({
              title: '屏幕时间守护授权',
              granted: this.authGranted,
              offSubtitle: '授权后系统才能执行管控规则。应用选择与时长在「管控设置」中完成。',
              isLast: true,
              onTap: () => this.onRequestAuth()
            })
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)
          .margin({ left: 16, right: 16 })

          this.sectionHeader('增强功能与守护')
          Column() {
            PermissionStatusRow({
              title: '保持后台运行',
              granted: this.backgroundOk,
              offSubtitle: '对应安卓忽略电池优化，减少被系统挂起',
              isLast: false,
              onTap: () => this.onOpenBackground()
            })
            PermissionStatusRow({
              title: '允许发送通知',
              granted: this.notifyGranted,
              offSubtitle: '及时接收重要提醒',
              isLast: true,
              onTap: () => this.onRequestNotify()
            })
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)
          .margin({ left: 16, right: 16 })

          this.sectionHeader('紧急操作')
          Column() {
            this.rowItem('解除全部限制', '需验证家长密码，清除本应用创建的全部管控规则', true, () => {
              this.releasePin = '';
              this.openSheet('release');
            }, '>', true)
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)
          .margin({ left: 16, right: 16 })

          Text('顶部守护状态只看屏幕时间守护授权。右侧「去开启 / 已开启」会随真实权限状态刷新。解除全部限制会清空本应用下发的规则，不会自动关闭系统侧的守护授权开关。')
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
    .bindSheet($$this.showSheet, this.sheetContent(), {
      height: this.sheetKind === 'password' ? 420 : 320,
      dragBar: true,
      showClose: true,
      onDisappear: () => {
        this.sheetKind = 'none';
      }
    })
  }

  @Builder
  private securityCard() {
    Row({ space: 16 }) {
      Column() {
        Text(this.coreGranted() ? 'OK' : '!')
          .fontSize(22)
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
          '屏幕时间守护已授权，可在管控设置中配置规则' :
          '请先完成屏幕时间守护授权')
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
  private sheetContent() {
    if (this.sheetKind === 'password') {
      this.passwordSheet()
    } else if (this.sheetKind === 'release') {
      this.releasePinSheet()
    } else {
      Column() {
        Text('')
      }
      .width('100%')
      .height(1)
    }
  }

  private openSheet(kind: string): void {
    this.sheetKind = kind;
    this.showSheet = true;
  }

  private closeSheet(): void {
    this.showSheet = false;
    this.sheetKind = 'none';
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
          .onClick(() => this.closeSheet())
        Button('确定')
          .layoutWeight(1)
          .onClick(() => this.confirmChangePin())
      }
    }
    .padding(24)
    .width('100%')
  }

  @Builder
  private releasePinSheet() {
    Column({ space: 12 }) {
      Text('验证家长密码')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColor.title)
      Text('解除全部限制将清除本应用创建的管控规则，需先验证家长密码。')
        .fontSize(13)
        .fontColor(ThemeColor.subtitle)
      TextInput({ text: this.releasePin, placeholder: '请输入家长密码' })
        .type(InputType.NUMBER_PASSWORD)
        .maxLength(6)
        .height(48)
        .backgroundColor(ThemeColor.pageBg)
        .onChange((value: string) => this.releasePin = value)
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor(ThemeColor.pageBg)
          .fontColor(ThemeColor.title)
          .onClick(() => this.closeSheet())
        Button('确认解除')
          .layoutWeight(1)
          .backgroundColor(ThemeColor.danger)
          .onClick(() => this.confirmReleaseAll())
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
      this.closeSheet();
      this.onToast('密码修改成功');
    } catch (_) {
      this.onToast('密码保存失败，请重试');
    }
  }

  private async confirmReleaseAll(): Promise<void> {
    if (!await PinSecurity.verify(this.releasePin, this.pinSalt, this.pinHash)) {
      this.onToast('密码错误');
      return;
    }
    this.closeSheet();
    this.releasePin = '';
    this.onReleaseAll();
  }
}
'''

# Ensure Chinese is real: write as UTF-8 from unicode-aware string
# The r''' above has Chinese as real chars if the file encoding is utf-8 when PowerShell writes it.
# PowerShell Set-Content -Encoding utf8 should preserve Chinese in the heredoc.

profile_path.write_text(src, encoding='utf-8', newline='\n')
text = profile_path.read_text(encoding='utf-8')
print('PermissionStatusRow', 'struct PermissionStatusRow' in text)
print('authGranted', 'authGranted' in text)
print('去开启', '去开启' in text)
print('literal \\u', '\\u5df2' in text)
print('Watch authorized', "@Watch('onAuthorizedChange')" in text)
