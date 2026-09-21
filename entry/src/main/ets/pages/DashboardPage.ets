import { TimeUtils } from '../util/TimeUtils';
import { ThemeColor } from '../ui/Theme';
import { LimitUsageRow } from '../guard/TictocGuardManager';

@Component
export struct DashboardPage {
  @Prop guardStatus: string = '';
  @Prop authorized: boolean = false;
  @Prop managedCount: number = 0;
  @Prop downtimeText: string = '';
  @Prop limitSummary: string = '';
  @Prop strategyCount: number = 0;
  @Prop usageSupported: boolean = false;
  @Prop usageRows: LimitUsageRow[] = [];
  @State private selectedDay: number = TimeUtils.startOfDay(Date.now());

  private minDay(): number {
    return TimeUtils.startOfDay(Date.now()) - 6 * 24 * 60 * 60 * 1000;
  }

  private maxDay(): number {
    return TimeUtils.startOfDay(Date.now());
  }

  private isDowntimeActive(): boolean {
    return this.guardStatus === '停用时间中';
  }

  private formatMinutes(value: number): string {
    if (value <= 0) {
      return '0 分钟';
    }
    if (value < 60) {
      return `${value} 分钟`;
    }
    const hours = Math.floor(value / 60);
    const minutes = value % 60;
    if (minutes === 0) {
      return `${hours} 小时`;
    }
    return `${hours} 小时 ${minutes} 分钟`;
  }

  private usageHint(): string {
    if (!this.authorized) {
      return '请先开启屏幕时间守护授权';
    }
    if (!this.usageSupported) {
      return '当前系统版本暂不支持读取应用已用时长（需要 API 26+）。已管控规则仍会生效，下方继续显示限额摘要。';
    }
    if (this.usageRows.length === 0) {
      return '还没有设置每日限额的管控应用。去「管控」添加后，这里会显示已用/限额。';
    }
    return '';
  }

  build() {
    Column() {
      Column({ space: 4 }) {
        Text('仪表盘')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColor.title)
        Row({ space: 8 }) {
          Text('‹')
            .fontSize(18)
            .fontColor(this.selectedDay > this.minDay() ? ThemeColor.primary : '#C0C4CC')
            .onClick(() => {
              if (this.selectedDay > this.minDay()) {
                this.selectedDay -= 24 * 60 * 60 * 1000;
              }
            })
          Text(TimeUtils.formatDateLabel(this.selectedDay))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColor.title)
          Text('›')
            .fontSize(18)
            .fontColor(this.selectedDay < this.maxDay() ? ThemeColor.primary : '#C0C4CC')
            .onClick(() => {
              if (this.selectedDay < this.maxDay()) {
                this.selectedDay += 24 * 60 * 60 * 1000;
              }
            })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 12 }) {
          if (this.guardStatus.length > 0) {
            Row({ space: 12 }) {
              Column()
                .width(8)
                .height(8)
                .borderRadius(4)
                .backgroundColor(this.isDowntimeActive() ? ThemeColor.danger : ThemeColor.primary)
              Text(this.guardStatus)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isDowntimeActive() ? ThemeColor.danger : ThemeColor.primary)
              Blank()
              Text(this.isDowntimeActive() ? '停用时段中' : '实时守护中')
                .fontSize(12)
                .fontColor(this.isDowntimeActive() ? ThemeColor.danger : ThemeColor.primary)
            }
            .padding(16)
            .width('100%')
            .backgroundColor(this.isDowntimeActive() ? '#FEF3F2' : '#E8F3FF')
            .borderRadius(16)
          }

          Column({ space: 8 }) {
            Text('今日守护摘要')
              .fontSize(13)
              .fontColor(ThemeColor.subtitle)
              .width('100%')
            Row({ space: 8 }) {
              this.summaryTile('管控应用', `${this.managedCount}`)
              this.summaryTile('系统策略', this.strategyCount < 0 ? '未知' : `${this.strategyCount}`)
            }
            .width('100%')
            Row({ space: 8 }) {
              this.summaryTile('停用时段', this.downtimeText.length > 0 ? this.downtimeText : '未设置')
              this.summaryTile('应用限额', this.limitSummary.length > 0 ? this.limitSummary : '未设置')
            }
            .width('100%')
          }
          .padding(16)
          .width('100%')
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)

          Column({ space: 10 }) {
            Row() {
              Text(this.usageSupported ? '管控应用时长' : '应用使用时长')
                .fontSize(13)
                .fontColor(ThemeColor.subtitle)
                .layoutWeight(1)
              if (this.usageSupported) {
                Text('实时策略用量')
                  .fontSize(11)
                  .fontColor(ThemeColor.primary)
              } else {
                Text('当前系统受限')
                  .fontSize(11)
                  .fontColor('#B54708')
              }
            }
            .width('100%')

            if (this.usageHint().length > 0) {
              Column() {
                Text(this.usageHint())
                  .fontSize(14)
                  .fontColor(ThemeColor.subtitle)
                  .textAlign(TextAlign.Start)
                  .width('100%')
                if (!this.usageSupported && this.authorized && this.managedCount > 0) {
                  Text('更高系统（API 26+）上同一安装包会自动显示各管控应用的已用/限额。')
                    .fontSize(12)
                    .fontColor('#B54708')
                    .margin({ top: 8 })
                    .width('100%')
                }
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }

            if (this.usageSupported && this.usageRows.length > 0) {
              ForEach(this.usageRows, (row: LimitUsageRow) => {
                Column({ space: 6 }) {
                  Row() {
                    Text(row.label)
                      .fontSize(16)
                      .fontColor(ThemeColor.title)
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(row.available ?
                      `${this.formatMinutes(row.usedMinutes)} / ${this.formatMinutes(row.limitMinutes)}` :
                      `限额 ${this.formatMinutes(row.limitMinutes)}`)
                      .fontSize(13)
                      .fontColor(row.available && row.usedMinutes >= row.limitMinutes ?
                        ThemeColor.danger : ThemeColor.primary)
                  }
                  .width('100%')
                  if (row.available) {
                    Progress({
                      value: Math.min(row.usedMinutes, row.limitMinutes),
                      total: Math.max(row.limitMinutes, 1),
                      type: ProgressType.Linear
                    })
                      .width('100%')
                      .height(6)
                      .color(row.usedMinutes >= row.limitMinutes ? ThemeColor.danger : ThemeColor.primary)
                      .backgroundColor(ThemeColor.divider)
                  } else {
                    Text('该管控应用暂无法查询策略已用时长')
                      .fontSize(12)
                      .fontColor('#98A2B3')
                      .width('100%')
                  }
                }
                .width('100%')
                .padding({ top: 8, bottom: 8 })
              }, (row: LimitUsageRow) => `${row.token}#${row.usedMinutes}#${row.limitMinutes}#${row.label}`)
            } else if (!this.usageSupported && this.authorized && this.managedCount > 0) {
              Text(this.limitSummary.length > 0 ?
                `按时长规则工作：${this.limitSummary}` :
                '已有管控应用，但本机无法查询策略已用时长。')
                .fontSize(13)
                .fontColor(ThemeColor.subtitle)
                .width('100%')
            }
          }
          .padding(16)
          .width('100%')
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)

          Column({ space: 6 }) {
            Text('说明')
              .fontSize(12)
              .fontColor('#98A2B3')
            Text(this.usageSupported ?
              '已用时长来自屏幕时间守护策略，对策略内有效应用累计；名称是家长备注。' :
              '低版本系统仍可安装与管控，已用时长查询在支持的系统上会自动启用。')
              .fontSize(12)
              .fontColor('#98A2B3')
          }
          .width('100%')
          .padding({ left: 4, right: 4, bottom: 8 })
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColor.pageBg)
  }

  @Builder
  private summaryTile(label: string, value: string) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(12)
        .fontColor(ThemeColor.subtitle)
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColor.title)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding(12)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(ThemeColor.pageBg)
    .borderRadius(12)
  }
}
