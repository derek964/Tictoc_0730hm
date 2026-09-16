import { TimeUtils } from '../util/TimeUtils';
import { ThemeColor } from '../ui/Theme';

@Component
export struct DashboardPage {
  @Prop guardStatus: string = '';
  @Prop authorized: boolean = false;
  @Prop managedCount: number = 0;
  @Prop downtimeText: string = '';
  @Prop limitSummary: string = '';
  @Prop strategyCount: number = 0;
  @State private selectedDay: number = TimeUtils.startOfDay(Date.now());

  private minDay(): number {
    return TimeUtils.startOfDay(Date.now()) - 6 * 24 * 60 * 60 * 1000;
  }

  private maxDay(): number {
    return TimeUtils.startOfDay(Date.now());
  }

  build() {
    Column() {
      Column({ space: 4 }) {
        Text('仪表盘')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColor.title)
        Row({ space: 8 }) {
          Text('<')
            .fontSize(18)
            .fontColor(this.selectedDay > this.minDay() ? ThemeColor.primary : '#C5CAD3')
            .onClick(() => {
              if (this.selectedDay > this.minDay()) {
                this.selectedDay -= 24 * 60 * 60 * 1000;
              }
            })
          Text(TimeUtils.formatDateLabel(this.selectedDay))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColor.title)
          Text('>')
            .fontSize(18)
            .fontColor(this.selectedDay < this.maxDay() ? ThemeColor.primary : '#C5CAD3')
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
                .backgroundColor(this.guardStatus === '停用时间中' ? ThemeColor.danger : ThemeColor.primary)
              Text(this.guardStatus)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.guardStatus === '停用时间中' ? ThemeColor.danger : ThemeColor.primary)
              Blank()
              Text('实时守护中')
                .fontSize(12)
                .fontColor(this.guardStatus === '停用时间中' ? '#F97066' : ThemeColor.primary)
            }
            .padding(16)
            .width('100%')
            .backgroundColor(this.guardStatus === '停用时间中' ? '#FEF3F2' : '#E8F3FF')
            .borderRadius(16)
          }

          Column({ space: 8 }) {
            Text('今日守护摘要')
              .fontSize(13)
              .fontColor(ThemeColor.subtitle)
              .width('100%')
            Row({ space: 8 }) {
              this.summaryTile('管控应用', `${this.managedCount} 个`)
              this.summaryTile('系统规则', this.strategyCount < 0 ? '未知' : `${this.strategyCount} 条`)
            }
            .width('100%')
            Row({ space: 8 }) {
              this.summaryTile('停用时间', this.downtimeText.length > 0 ? this.downtimeText : '未开启')
              this.summaryTile('应用限额', this.limitSummary.length > 0 ? this.limitSummary : '未设置')
            }
            .width('100%')
          }
          .padding(16)
          .width('100%')
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)

          Column({ space: 10 }) {
            Text('24小时趋势')
              .fontSize(13)
              .fontColor(ThemeColor.subtitle)
              .width('100%')
            Column() {
              Text(this.authorized ? '当天没有可回读的应用使用明细' : '尚未开启屏幕时间守护授权')
                .fontSize(15)
                .fontColor(ThemeColor.subtitle)
              Text('鸿蒙由系统执行管控。API 22 无法像安卓一样回读各应用名称与时长，授权后请在目标应用中验证拦截效果。')
                .fontSize(12)
                .fontColor('#98A2B3')
                .textAlign(TextAlign.Center)
                .margin({ top: 8 })
            }
            .width('100%')
            .height(160)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .padding({ left: 12, right: 12 })
          }
          .padding(16)
          .width('100%')
          .backgroundColor(ThemeColor.card)
          .borderRadius(16)

          Column({ space: 6 }) {
            Text('累计使用')
              .fontSize(12)
              .fontColor('#D0D5DD')
            Text('由系统守护，本机不展示分钟数')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(ThemeColor.primary)
          .borderRadius(16)
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
