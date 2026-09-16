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
  @Prop @Watch('onPendingLimitToken') pendingLimitToken: string = '';
  @Prop pendingLimitIndex: number = 0;
  @Prop pendingLimitTotal: number = 0;
  onToggleDowntime: (enabled: boolean) => void = (_enabled: boolean) => {};
  onSetDowntimeClock: (start: string, end: string) => void = (_s: string, _e: string) => {};
  onPickApps: () => void = () => {};
  onOpenAlwaysAllowed: () => void = () => {};
  onRemoveApp: (token: string) => void = (_token: string) => {};
  onSetLimit: (token: string, minutes: number) => void = (_token: string, _minutes: number) => {};
  onPendingLimitClosed: (token: string) => void = (_token: string) => {};

  @State private showStartPicker: boolean = false;
  @State private showEndPicker: boolean = false;
  @State private showDurationPicker: boolean = false;
  @State private durationCommitted: boolean = false;
  @State private editingToken: string = '';
  @State private editingHours: number = 1;
  @State private editingMinutes: number = 0;
  @State private pickerDate: Date = new Date();
  private hourRange: string[] = ControlPage.buildRange(0, 23);
  private minuteRange: string[] = ControlPage.buildRange(0, 59);

  private static buildRange(from: number, to: number): string[] {
    const values: string[] = [];
    for (let value = from; value <= to; value++) {
      values.push(TimeUtils.pad2(value));
    }
    return values;
  }

  onPendingLimitToken(): void {
    if (this.pendingLimitToken.length > 0) {
      this.openPendingDuration(this.pendingLimitToken);
    }
  }

  private downtimeEnabled(): boolean {
    return this.downtime.length > 0;
  }

  build() {
    Column() {
      Text('管控设置')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColor.title)
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 16 }) {
          this.sectionLabel('停用时间 (Downtime)')
          Column() {
            this.switchRow('开启停用时间', this.downtimeEnabled(), (checked: boolean) => {
              this.onToggleDowntime(checked);
            })
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

          this.sectionLabel('应用限额 (App Limits)')
          Column() {
            if (this.appLimits.length === 0) {
              Text('先在系统页搜索并勾选应用，回来后再设每天时长')
                .fontSize(14)
                .fontColor(ThemeColor.subtitle)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(32)
            } else {
              ForEach(this.appLimits, (item: AppLimitEntry, index: number) => {
                Column() {
                  Row() {
                    Column({ space: 4 }) {
                      Text(`第 ${index + 1} 个已选应用`)
                        .fontSize(16)
                        .fontColor(ThemeColor.title)
                      Text(item.minutes > 0 ? '点击可修改每天时长' : '待设置每天时长')
                        .fontSize(12)
                        .fontColor(ThemeColor.subtitle)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .onClick(() => this.openDuration(item))

                    Text(item.minutes > 0 ? `${item.minutes}分钟` : '未设时长')
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(ThemeColor.primary)
                      .onClick(() => this.openDuration(item))
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
              }, (item: AppLimitEntry) => item.token)
            }
            Divider().color(ThemeColor.divider)
            Row({ space: 8 }) {
              Text('+')
                .fontSize(20)
                .fontColor(ThemeColor.primary)
              Text('搜索并选择应用')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(ThemeColor.primary)
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .padding(16)
            .onClick(() => {
              if (!this.busy) {
                this.onPickApps();
              }
            })
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)

          Text('搜索和勾选只能在系统选择页完成，那里有应用名称、图标和搜索。回来后会立刻让你为新选的应用设置每天时长。本页列表只用来改时长或删除，无法显示具体应用名。再点「搜索并选择应用」可在系统页看到已勾选项。')
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
    .bindSheet($$this.showStartPicker, this.startClockSheet(), { height: 360, dragBar: true, showClose: true })
    .bindSheet($$this.showEndPicker, this.endClockSheet(), { height: 360, dragBar: true, showClose: true })
    .bindSheet($$this.showDurationPicker, this.durationSheet(), {
      height: 380,
      dragBar: true,
      showClose: true,
      onDisappear: () => {
        if (!this.durationCommitted && this.pendingLimitToken.length > 0 &&
          this.editingToken === this.pendingLimitToken) {
          this.onPendingLimitClosed(this.editingToken);
        }
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
    .onClick(onClick)
  }

  @Builder
  private startClockSheet() {
    this.clockSheetContent('选择开始时间', true)
  }

  @Builder
  private endClockSheet() {
    this.clockSheetContent('选择结束时间', false)
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
          const next = new Date(this.pickerDate);
          next.setHours(Number(value.hour), Number(value.minute), 0, 0);
          this.pickerDate = next;
        })
      Button('确定')
        .width('100%')
        .onClick(() => {
          const clock = TimeUtils.formatClock(this.pickerDate.getHours(), this.pickerDate.getMinutes());
          if (isStart) {
            this.onSetDowntimeClock(clock, this.downtimeEnd);
            this.showStartPicker = false;
          } else {
            this.onSetDowntimeClock(this.downtimeStart, clock);
            this.showEndPicker = false;
          }
        })
    }
    .padding(24)
    .width('100%')
  }

  @Builder
  private durationSheet() {
    Column({ space: 16 }) {
      Text(this.pendingLimitToken.length > 0 ?
        (this.pendingLimitTotal > 1 ?
          `为刚选的应用设置每天时长（${this.pendingLimitIndex}/${this.pendingLimitTotal}）` :
          '为刚选的应用设置每天时长') :
        '设置每天可用时长')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      Row({ space: 24 }) {
        Column() {
          TextPicker({ range: this.hourRange, selected: this.editingHours })
            .onChange((value: string | string[], index: number | number[]) => {
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
          const minutes = this.editingHours * 60 + this.editingMinutes;
          if (minutes > 0 && this.editingToken.length > 0) {
            this.durationCommitted = true;
            this.onSetLimit(this.editingToken, minutes);
            const closedToken = this.editingToken;
            this.showDurationPicker = false;
            this.onPendingLimitClosed(closedToken);
          }
        })
    }
    .padding(24)
    .width('100%')
  }

  private openStartPicker(): void {
    const parsed = TimeUtils.parseClock(this.downtimeStart);
    const date = new Date();
    date.setHours(parsed[0], parsed[1], 0, 0);
    this.pickerDate = date;
    this.showStartPicker = true;
  }

  private openEndPicker(): void {
    const parsed = TimeUtils.parseClock(this.downtimeEnd);
    const date = new Date();
    date.setHours(parsed[0], parsed[1], 0, 0);
    this.pickerDate = date;
    this.showEndPicker = true;
  }

  private openDuration(item: AppLimitEntry): void {
    this.durationCommitted = false;
    this.editingToken = item.token;
    this.editingHours = item.minutes > 0 ? Math.floor(item.minutes / 60) : 1;
    this.editingMinutes = item.minutes > 0 ? item.minutes % 60 : 0;
    this.showDurationPicker = true;
  }

  private openPendingDuration(token: string): void {
    this.durationCommitted = false;
    this.editingToken = token;
    this.editingHours = 1;
    this.editingMinutes = 0;
    this.showDurationPicker = true;
  }
}
