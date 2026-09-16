import { AppLimitEntry } from '../data/SettingsStore';
import { TimeUtils } from '../util/TimeUtils';
import { ThemeColor } from '../ui/Theme';

@Component
export struct ControlPage {
  @Link appLimits: AppLimitEntry[];
  @Link downtime: string;
  @Link downtimeStart: string;
  @Link downtimeEnd: string;
  @Prop whitelistCount: number = 0;
  @Prop authorized: boolean = false;
  @Prop busy: boolean = false;
  onToggleDowntime: (enabled: boolean) => void = (_enabled: boolean) => {};
  onSetDowntimeClock: (start: string, end: string) => void = (_s: string, _e: string) => {};
  onPickApps: () => Promise<string[]> = async (): Promise<string[]> => [];
  onOpenAlwaysAllowed: () => void = () => {};
  onRemoveApp: (token: string) => void = (_token: string) => {};
  onSetLimit: (token: string, minutes: number) => Promise<void> = async (_token: string, _minutes: number): Promise<void> => {};
  onSetLabel: (token: string, label: string) => Promise<void> = async (_token: string, _label: string): Promise<void> => {};
  onEnterControl: () => Promise<void> = async () => {};

  @State private showSheet: boolean = false;
  @State private sheetKind: string = 'none';
  @State private durationCommitted: boolean = false;
  @State private editingToken: string = '';
  @State private editingHours: number = 1;
  @State private editingMinutes: number = 0;
  @State private editingLabel: string = '';
  @State private labelCommitted: boolean = false;
  @State private pickerDate: Date = new Date();
  @State private addSessionTokens: string[] = [];
  @State private addSessionIndex: number = 0;
  @State private addSessionTotal: number = 0;
  @State private inAddSession: boolean = false;
  private hourRange: string[] = ControlPage.buildRange(0, 23);
  private minuteRange: string[] = ControlPage.buildRange(0, 59);

  private static buildRange(from: number, to: number): string[] {
    const values: string[] = [];
    for (let value = from; value <= to; value++) {
      values.push(TimeUtils.pad2(value));
    }
    return values;
  }

  private downtimeEnabled(): boolean {
    return this.downtime.length > 0;
  }

  private isAddSession(): boolean {
    return this.inAddSession && this.addSessionTokens.length > 0;
  }

  build() {
    Column() {
      Text('管控设置')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColor.title)
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Button('进入管控')
        .width('100%')
        .height(48)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(ThemeColor.primary)
        .margin({ left: 16, right: 16, bottom: 4 })
        .onClick(() => this.onEnterControl())
      Text('规则已由系统执行。点击后锁定 Tictoc，修改需验证家长密码（对齐安卓打开应用先输 PIN）。')
        .fontSize(12)
        .fontColor(ThemeColor.subtitle)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })

      Scroll() {
        Column({ space: 16 }) {
          this.sectionLabel('停用时间 (Downtime)')
          Column() {
            this.switchRow('启用停用时间', this.downtimeEnabled(), (checked: boolean) => {
              this.onToggleDowntime(checked);
            })
            Text('时段内除「始终允许」白名单外，其他应用默认受控；不必先添加管控应用。')
              .fontSize(12)
              .fontColor(ThemeColor.subtitle)
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 10 })
            if (this.downtimeEnabled()) {
              Divider().color(ThemeColor.divider).margin({ left: 16 })
              this.valueRow('开始时间', this.downtimeStart, () => this.openStartPicker())
              Divider().color(ThemeColor.divider).margin({ left: 16 })
              this.valueRow('结束时间', this.downtimeEnd, () => this.openEndPicker())
            }
            Divider().color(ThemeColor.divider).margin({ left: 16 })
            this.valueRow('始终允许应用', `已选${this.whitelistCount}个`, () => this.onOpenAlwaysAllowed())
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)

          this.sectionLabel('应用限额')
          Column() {
            Row() {
              Text(this.appLimits.length > 0 ? `已选 ${this.appLimits.length} 个` : '尚未选择')
                .fontSize(14)
                .fontColor(ThemeColor.subtitle)
              Blank()
              Text('名称和图标在系统选择页查看')
                .fontSize(12)
                .fontColor(ThemeColor.subtitle)
            }
            .padding({ left: 16, right: 16, top: 12, bottom: 8 })
            .width('100%')

            Divider().color(ThemeColor.divider)

            if (this.appLimits.length === 0) {
              Text('还没有单独限额的应用。停用时段不依赖这里；若要给某应用设每天时长，请用下方搜索添加。')
                .fontSize(13)
                .fontColor(ThemeColor.subtitle)
                .width('100%')
                .padding({ left: 16, right: 16, top: 16, bottom: 8 })
            } else {
              ForEach(this.appLimits, (item: AppLimitEntry, index: number) => {
                Column() {
                  Row() {
                    Column({ space: 4 }) {
                      Text(item.label.length > 0 ? item.label : `管控应用 ${index + 1}`)
                        .fontSize(16)
                        .fontColor(ThemeColor.title)
                      Text(item.minutes > 0 ? `每天 ${item.minutes} 分钟 · 点名称改备注` : '尚未设置每天时长 · 点右侧设置')
                        .fontSize(12)
                        .fontColor(ThemeColor.subtitle)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .onClick(() => this.openLabelEditor(item))

                    Text(item.minutes > 0 ? `${item.minutes}分钟` : '未设时长')
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(ThemeColor.primary)
                      .onClick(() => this.openDuration(item, false))
                    Text('删除')
                      .fontSize(13)
                      .fontColor(ThemeColor.danger)
                      .margin({ left: 12 })
                      .onClick(() => this.onRemoveApp(item.token))
                  }
                  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                  .width('100%')
                  if (index < this.appLimits.length - 1) {
                    Divider().color(ThemeColor.divider).margin({ left: 16 })
                  }
                }
              }, (item: AppLimitEntry) => `${item.token}#${item.minutes}#${item.label}`)
            }

            Divider().color(ThemeColor.divider)
            Row() {
              Column({ space: 4 }) {
                Text('搜索并添加应用')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ThemeColor.primary)
                Text(this.authorized ? '打开系统选择页，可搜索应用名并勾选' : '需先在个人中心开启屏幕时间守护授权')
                  .fontSize(12)
                  .fontColor(ThemeColor.subtitle)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Text('去选择')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(ThemeColor.primary)
            }
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .width('100%')
            .opacity(this.busy ? 0.5 : 1)
            .onClick(() => {
              if (!this.busy) {
                this.startAddSession();
              }
            })
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)

          Text('添加走系统选择页（支持搜索）；选完后仍回到本页设置每天时长。列表无法显示真实名称，要核对已选请再点「搜索并添加应用」。')
            .fontSize(12)
            .fontColor(ThemeColor.subtitle)
            .margin({ bottom: 24 })
        }
        .padding({ left: 16, right: 16, bottom: 12 })
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
      height: this.sheetKind === 'duration' ? 400 : (this.sheetKind === 'label' ? 280 : 360),
      dragBar: true,
      showClose: true,
      onDisappear: () => {
        this.handleSheetDisappear();
      }
    })
  }

  @Builder
  private sectionLabel(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor(ThemeColor.primary)
      .margin({ left: 8, bottom: 4 })
      .width('100%')
  }

  @Builder
  private switchRow(title: string, checked: boolean, onChange: (value: boolean) => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(ThemeColor.title)
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: checked })
        .onChange(onChange)
        .selectedColor(ThemeColor.primary)
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .width('100%')
  }

  @Builder
  private valueRow(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(ThemeColor.title)
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColor.primary)
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .width('100%')
    .onClick(() => onClick())
  }

  @Builder
  private sheetContent() {
    if (this.sheetKind === 'start') {
      this.clockSheetContent('选择开始时间', true)
    } else if (this.sheetKind === 'end') {
      this.clockSheetContent('选择结束时间', false)
    } else if (this.sheetKind === 'label') {
      this.labelSheet()
    } else if (this.sheetKind === 'duration') {
      this.durationSheet()
    } else {
      Column() {
        Text('')
      }
      .width('100%')
      .height(1)
    }
  }

  @Builder
  private clockSheetContent(title: string, isStart: boolean) {
    Column({ space: 16 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      TimePicker({ selected: this.pickerDate })
        .useMilitaryTime(true)
        .onChange((value: TimePickerResult) => {
          const next = new Date(this.pickerDate.getTime());
          next.setHours(Number(value.hour), Number(value.minute), 0, 0);
          this.pickerDate = next;
        })
      Button('确定')
        .width('100%')
        .onClick(() => {
          const clock = TimeUtils.formatClock(this.pickerDate.getHours(), this.pickerDate.getMinutes());
          if (isStart) {
            this.onSetDowntimeClock(clock, this.downtimeEnd);
          } else {
            this.onSetDowntimeClock(this.downtimeStart, clock);
          }
          this.closeSheet();
        })
    }
    .padding(24)
    .width('100%')
  }

  @Builder
  private durationSheet() {
    Column({ space: 16 }) {
      Text(this.isAddSession() ?
        (this.addSessionTotal > 1 ?
          `添加流程：设置每天时长（${this.addSessionIndex}/${this.addSessionTotal}）` :
          '添加流程：设置每天时长') :
        '设置每天可用时长')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      if (this.isAddSession()) {
        Text('这是管控设置里「选应用再到设时长」的第二步')
          .fontSize(12)
          .fontColor(ThemeColor.subtitle)
      }
      Row({ space: 24 }) {
        Column() {
          TextPicker({ range: this.hourRange, selected: this.editingHours })
            .onChange((_value: string | string[], index: number | number[]) => {
              this.editingHours = index as number;
            })
            .height(150)
            .width(80)
          Text('小时').fontSize(12).fontColor(ThemeColor.subtitle)
        }
        Column() {
          TextPicker({ range: this.minuteRange, selected: this.editingMinutes })
            .onChange((_value: string | string[], index: number | number[]) => {
              this.editingMinutes = index as number;
            })
            .height(150)
            .width(80)
          Text('分钟').fontSize(12).fontColor(ThemeColor.subtitle)
        }
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      Button('确定')
        .width('100%')
        .enabled(this.editingHours > 0 || this.editingMinutes > 0)
        .onClick(() => {
          this.confirmDuration();
        })
    }
    .padding(24)
    .width('100%')
  }

  private async startAddSession(): Promise<void> {
    try {
      const added = await this.onPickApps();
      if (added.length === 0) {
        this.clearAddSession();
        return;
      }
      this.addSessionTokens = added;
      this.addSessionTotal = added.length;
      this.addSessionIndex = 1;
      this.inAddSession = true;
      this.openLabelForToken(added[0], true);
    } catch (_) {
      this.clearAddSession();
    }
  }

  private advanceAddSession(): void {
    if (!this.inAddSession) {
      return;
    }
    const remain: string[] = [];
    for (let index = 0; index < this.addSessionTokens.length; index++) {
      if (this.addSessionTokens[index] !== this.editingToken) {
        remain.push(this.addSessionTokens[index]);
      }
    }
    this.addSessionTokens = remain;
    if (remain.length === 0) {
      this.clearAddSession();
      return;
    }
    this.addSessionIndex = this.addSessionIndex + 1;
    this.openLabelForToken(remain[0], true);
  }

  private clearAddSession(): void {
    this.addSessionTokens = [];
    this.addSessionTotal = 0;
    this.addSessionIndex = 0;
    this.inAddSession = false;
  }

  private async confirmDuration(): Promise<void> {
    const minutes = this.editingHours * 60 + this.editingMinutes;
    if (minutes <= 0 || this.editingToken.length === 0) {
      return;
    }
    const token = this.editingToken;
    const continueAdd = this.isAddSession();
    this.durationCommitted = true;
    await this.onSetLimit(token, minutes);
    if (continueAdd) {
      this.advanceAddSession();
    } else {
      this.closeSheet();
    }
  }


  @Builder
  private labelSheet() {
    Column({ space: 16 }) {
      Text(this.isAddSession() && this.addSessionTotal > 1 ?
        `给第 ${this.addSessionIndex} 个应用起个备注名` : '给这个应用起个备注名')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      Text('系统选择页不返回应用名。备注只存在本机，方便你分辨限额。例如：抖音、微信。')
        .fontSize(12)
        .fontColor(ThemeColor.subtitle)
      TextInput({ text: this.editingLabel, placeholder: '例如：抖音' })
        .maxLength(20)
        .onChange((value: string) => {
          this.editingLabel = value;
        })
      Button('保存备注')
        .width('100%')
        .enabled(this.editingLabel.trim().length > 0)
        .onClick(() => {
          this.confirmLabel();
        })
    }
    .padding(24)
    .width('100%')
  }

  private displayName(item: AppLimitEntry, index: number): string {
    if (item.label.length > 0) {
      return item.label;
    }
    return `管控应用 ${index + 1}`;
  }

  private openLabelEditor(item: AppLimitEntry): void {
    this.inAddSession = false;
    this.editingToken = item.token;
    this.editingLabel = item.label;
    this.labelCommitted = false;
    this.openSheet('label');
  }

  private openLabelForToken(token: string, asAddStep: boolean): void {
    this.labelCommitted = false;
    this.editingToken = token;
    this.editingLabel = '';
    if (!asAddStep) {
      for (let index = 0; index < this.appLimits.length; index++) {
        if (this.appLimits[index].token === token) {
          this.editingLabel = this.appLimits[index].label;
          break;
        }
      }
    }
    this.openSheet('label');
  }

  private async confirmLabel(): Promise<void> {
    const name = this.editingLabel.trim();
    if (name.length === 0 || this.editingToken.length === 0) {
      return;
    }
    const token = this.editingToken;
    const continueAdd = this.isAddSession();
    this.labelCommitted = true;
    await this.onSetLabel(token, name);
    if (continueAdd) {
      this.openDurationForToken(token, true);
    } else {
      this.closeSheet();
    }
  }

  private skipLabel(): void {
    const token = this.editingToken;
    this.labelCommitted = true;
    if (this.isAddSession() && token.length > 0) {
      this.openDurationForToken(token, true);
    } else {
      this.closeSheet();
    }
  }

  private openStartPicker(): void {
    const parsed = TimeUtils.parseClock(this.downtimeStart);
    const date = new Date();
    const hour = parsed.length >= 2 ? parsed[0] : 22;
    const minute = parsed.length >= 2 ? parsed[1] : 0;
    date.setHours(hour, minute, 0, 0);
    this.pickerDate = date;
    this.openSheet('start');
  }

  private openEndPicker(): void {
    const parsed = TimeUtils.parseClock(this.downtimeEnd);
    const date = new Date();
    const hour = parsed.length >= 2 ? parsed[0] : 7;
    const minute = parsed.length >= 2 ? parsed[1] : 0;
    date.setHours(hour, minute, 0, 0);
    this.pickerDate = date;
    this.openSheet('end');
  }

  private openDuration(item: AppLimitEntry, asAddStep: boolean): void {
    this.openDurationForToken(item.token, asAddStep);
    if (!asAddStep) {
      this.editingHours = item.minutes > 0 ? Math.floor(item.minutes / 60) : 1;
      this.editingMinutes = item.minutes > 0 ? item.minutes % 60 : 0;
    }
  }

  private openDurationForToken(token: string, asAddStep: boolean): void {
    this.durationCommitted = false;
    this.editingToken = token;
    if (asAddStep) {
      this.editingHours = 1;
      this.editingMinutes = 0;
    }
    this.openSheet('duration');
  }

  private openSheet(kind: string): void {
    this.sheetKind = kind;
    this.showSheet = true;
  }

  private closeSheet(): void {
    this.showSheet = false;
    this.sheetKind = 'none';
  }

  private handleSheetDisappear(): void {
    // If we immediately opened the next sheet, ignore this disappear.
    if (this.showSheet) {
      return;
    }
    const kind = this.sheetKind;
    const token = this.editingToken;
    const durationCommitted = this.durationCommitted;
    const labelCommitted = this.labelCommitted;
    const wasAddDuration = this.isAddSession() && kind === 'duration';
    const wasAddLabel = this.isAddSession() && kind === 'label';
    this.sheetKind = 'none';
    if (wasAddLabel && !labelCommitted && token.length > 0) {
      this.openDurationForToken(token, true);
      return;
    }
    if (wasAddDuration && !durationCommitted && token.length > 0) {
      this.advanceAddSession();
    }
  }
}
