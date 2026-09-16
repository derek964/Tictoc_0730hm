from pathlib import Path

cpath = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ControlPage.ets")
c = cpath.read_text(encoding="utf-8")

idx1 = c.find("this.sectionLabel(")
idx2 = c.find("this.sectionLabel(", idx1 + 1)
end_marker = ".margin({ bottom: 24 })"
end = c.find(end_marker, idx2)
# include through the marker
end = end + len(end_marker)

new_block = """this.sectionLabel('应用限额')
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
                      Text(`管控应用 ${index + 1}`)
                        .fontSize(16)
                        .fontColor(ThemeColor.title)
                      Text(item.minutes > 0 ? '点此可修改每天时长' : '尚未设置每天时长')
                        .fontSize(12)
                        .fontColor(ThemeColor.subtitle)
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    .onClick(() => this.openDuration(item, false))

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
              }, (item: AppLimitEntry) => `${item.token}#${item.minutes}`)
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
            .margin({ bottom: 24 })"""

c = c[:idx2] + new_block + c[end:]
cpath.write_text(c, encoding="utf-8")
print("ControlPage patched, length", len(c))
# sanity
t = cpath.read_text(encoding="utf-8")
assert "搜索并添加应用" in t
assert "startAddSession" in t
assert "已选" in t
print("ok")
