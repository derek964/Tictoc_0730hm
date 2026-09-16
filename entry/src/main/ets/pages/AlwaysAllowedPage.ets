import { ThemeColor } from '../ui/Theme';

@Component
export struct AlwaysAllowedPage {
  @Prop extraCount: number = 0;
  onBack: () => void = () => {};
  onPickApps: () => void = () => {};

  private coreApps: string[] = ['电话', '短信', '联系人', '相机'];

  build() {
    Column() {
      Row() {
        Text('返回')
          .fontSize(16)
          .fontColor(ThemeColor.primary)
          .onClick(() => this.onBack())
        Text('始终允许应用')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColor.title)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column({ space: 12 }) {
          Text('选中的应用在停用期间和达到限额后仍可使用。电话、信息等核心应用已默认始终允许。')
            .fontSize(13)
            .fontColor(ThemeColor.title)
            .padding(16)
            .backgroundColor('#E8F3FF')
            .borderRadius(12)
            .width('100%')

          Text('核心通讯应用')
            .fontSize(13)
            .fontColor(ThemeColor.primary)
            .margin({ left: 4, top: 8 })
            .width('100%')

          Column() {
            ForEach(this.coreApps, (label: string) => {
              Row() {
                Column({ space: 2 }) {
                  Text(label)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  Text('系统默认允许')
                    .fontSize(12)
                    .fontColor(ThemeColor.subtitle)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Text('已允许')
                  .fontSize(13)
                  .fontColor(ThemeColor.subtitle)
              }
              .padding(12)
              .width('100%')
            }, (label: string) => label)
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(12)

          Text('其他应用')
            .fontSize(13)
            .fontColor(ThemeColor.primary)
            .margin({ left: 4, top: 8 })
            .width('100%')

          Column() {
            Row() {
              Column({ space: 4 }) {
                Text('额外始终允许')
                  .fontSize(16)
                  .fontColor(ThemeColor.title)
                Text(`已通过系统选择器选择 ${this.extraCount} 个`)
                  .fontSize(12)
                  .fontColor(ThemeColor.subtitle)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Text('去选择')
                .fontSize(14)
                .fontColor(ThemeColor.primary)
                .fontWeight(FontWeight.Bold)
            }
            .padding(16)
            .width('100%')
            .onClick(() => this.onPickApps())
          }
          .backgroundColor(ThemeColor.card)
          .borderRadius(12)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColor.pageBg)
  }
}
