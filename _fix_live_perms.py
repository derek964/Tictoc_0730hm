from pathlib import Path
import re

home_path = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets")
profile_path = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
ht = home_path.read_text(encoding="utf-8")

# 1) Change Profile wiring to @Link for the three flags
old = re.search(r"        ProfilePage\(\{[\s\S]*?\n        \}\)", ht)
if not old:
    raise SystemExit("ProfilePage wire not found")
print("OLD WIRE:\n", old.group(0)[:400])

new_wire = """        ProfilePage({
          authorized: $authorized,
          notifyEnabled: $notifyEnabled,
          backgroundGranted: $backgroundGranted,
          pinSalt: this.pinSalt,
          pinHash: this.pinHash,
          onRequestAuth: () => this.requestAuthorization(),
          onRequestNotify: () => this.requestNotify(),
          onOpenBackground: () => this.openBackground(),
          onReleaseAll: () => this.releaseAll(),
          onRefreshPermissions: () => this.refreshProfilePermissions(),
          onPinChanged: (salt: string, hash: string) => this.saveNewPin(salt, hash),
          onToast: (message: string) => this.toast(message)
        })"""
ht = ht[:old.start()] + new_wire + ht[old.end():]

# 2) Make requestAuthorization/requestNotify/openBackground return after refresh (already do)
# Add refreshProfilePermissions that refreshes runtime+permissions - Profile will await it
if "refreshProfilePermissions" not in ht:
    needle = "  private async refreshPermissions(): Promise<void> {"
    insert = """  private async refreshProfilePermissions(): Promise<void> {
    await this.refreshRuntimeState(false);
    await this.refreshPermissions();
  }

  private async refreshPermissions(): Promise<void> {"""
    if needle not in ht:
        raise SystemExit("refreshPermissions missing")
    ht = ht.replace(needle, insert, 1)
    print("added refreshProfilePermissions")

# Ensure request* methods are Promise and complete refresh before return - already are.
# Change signatures of callbacks used by Profile to return Promise - Home methods already async.

home_path.write_text(ht, encoding="utf-8", newline="\n")
print("Home wired with $authorized/$notify/$background")

# 3) Rewrite ProfilePage following Android: display from @Link; child row uses @Watch/@State;
# after each action await refresh; aboutToAppear refresh like ON_RESUME
profile = '''import { PinSecurity } from '../security/PinSecurity';
import { PermissionManager, PermissionSnapshot } from '../permission/PermissionManager';
import { ThemeColor } from '../ui/Theme';

/**
 * Permission row mirrors Android PermissionItem:
 * trailing and subtitle both come from the same granted flag.
 * granted is copied into @State so the Text nodes always rebuild when it flips.
 */
@Component
struct PermissionStatusRow {
  @Prop title: string = '';
  @Prop @Watch('onGrantedChanged') granted: boolean = false;
  @Prop offSubtitle: string = '';
  @Prop isLast: boolean = true;
  onTap: () => void = () => {};
  @State private isOn: boolean = false;

  aboutToAppear(): void {
    this.isOn = this.granted;
  }

  onGrantedChanged(): void {
    this.isOn = this.granted;
  }

  build() {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text(this.title)
            .fontSize(16)
            .fontColor(ThemeColor.title)
          Text(this.isOn ? '已开启' : this.offSubtitle)
            .fontSize(12)
            .fontColor(ThemeColor.subtitle)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.isOn ? '已开启' : '去开启')
          .fontSize(14)
          .fontColor(this.isOn ? ThemeColor.subtitle : ThemeColor.danger)
          .fontWeight(this.isOn ? FontWeight.Normal : FontWeight.Bold)
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
  // Same source of truth as Android local mutableState, linked to Home so resume/refresh updates both card and rows.
  @Link authorized: boolean;
  @Link notifyEnabled: boolean;
  @Link backgroundGranted: boolean;
  @Prop pinSalt: string = '';
  @Prop pinHash: string = '';
  onRequestAuth: () => Promise<void> = async () => {};
  onRequestNotify: () => Promise<void> = async () => {};
  onOpenBackground: () => Promise<void> = async () => {};
  onReleaseAll: () => void = () => {};
  onRefreshPermissions: () => Promise<void> = async () => {};
  onPinChanged: (salt: string, hash: string) => void = (_salt: string, _hash: string) => {};
  onToast: (message: string) => void = (_message: string) => {};

  @State private showSheet: boolean = false;
  @State private sheetKind: string = 'none';
  @State private oldPin: string = '';
  @State private newPin: string = '';
  @State private confirmPin: string = '';
  @State private releasePin: string = '';
  @State private busyAction: boolean = false;

  aboutToAppear(): void {
    // Android ON_RESUME equivalent when the profile tab content is created / shown again.
    this.reloadPermissions();
  }

  private coreGranted(): boolean {
    return this.authorized;
  }

  private async reloadPermissions(): Promise<void> {
    await this.onRefreshPermissions();
  }

  private async handleAuthTap(): Promise<void> {
    if (this.busyAction) {
      return;
    }
    this.busyAction = true;
    try {
      await this.onRequestAuth();
      await this.reloadPermissions();
    } finally {
      this.busyAction = false;
    }
  }

  private async handleBackgroundTap(): Promise<void> {
    if (this.busyAction) {
      return;
    }
    this.busyAction = true;
    try {
      await this.onOpenBackground();
      await this.reloadPermissions();
    } finally {
      this.busyAction = false;
    }
  }

  private async handleNotifyTap(): Promise<void> {
    if (this.busyAction) {
      return;
    }
    this.busyAction = true;
    try {
      await this.onRequestNotify();
      await this.reloadPermissions();
    } finally {
      this.busyAction = false;
    }
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
              granted: this.authorized,
              offSubtitle: '授权后系统才能执行管控规则。应用选择与时长在「管控设置」中完成。',
              isLast: true,
              onTap: () => {
                this.handleAuthTap();
              }
            })
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)
          .margin({ left: 16, right: 16 })

          this.sectionHeader('增强功能与守护')
          Column() {
            PermissionStatusRow({
              title: '保持后台运行',
              granted: this.backgroundGranted,
              offSubtitle: '对应安卓忽略电池优化，减少被系统挂起',
              isLast: false,
              onTap: () => {
                this.handleBackgroundTap();
              }
            })
            PermissionStatusRow({
              title: '允许发送通知',
              granted: this.notifyEnabled,
              offSubtitle: '及时接收重要提醒',
              isLast: true,
              onTap: () => {
                this.handleNotifyTap();
              }
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

          Text('权限行与顶部守护状态使用同一组实时状态：授权、后台、通知。从系统页返回或点完开关后会重新读取并刷新「去开启 / 已开启」。')
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
    await this.reloadPermissions();
  }
}
'''
profile_path.write_text(profile, encoding='utf-8', newline='\n')
print('Profile written', profile_path.stat().st_size)
print('has @Link authorized', '@Link authorized' in profile)
print('has onGrantedChanged', 'onGrantedChanged' in profile)
print('has $authorized in home', 'authorized: $authorized' in home_path.read_text(encoding='utf-8'))

# Ensure unused import PermissionSnapshot still ok - used? snapshot removed - remove unused import
pt = profile_path.read_text(encoding='utf-8')
if 'PermissionSnapshot' in pt and 'PermissionSnapshot {' not in pt.replace('import { PermissionManager, PermissionSnapshot }', ''):
    # PermissionSnapshot only in import - remove from import
    if 'PermissionSnapshot' not in pt.split('import')[1].split('\n')[0] if False else True:
        pass
# Check if PermissionSnapshot used in body
body = pt.split('from \'../permission/PermissionManager\';',1)[1]
if 'PermissionSnapshot' not in body:
    pt = pt.replace('import { PermissionManager, PermissionSnapshot }', 'import { PermissionManager }')
    # PermissionManager might also be unused now - coreGranted doesn't use it
    if 'PermissionManager' not in pt.split('import { PermissionManager }')[1]:
        pt = pt.replace("import { PermissionManager } from '../permission/PermissionManager';\n", '')
    profile_path.write_text(pt, encoding='utf-8', newline='\n')
    print('cleaned unused imports')
