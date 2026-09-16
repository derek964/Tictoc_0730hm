from pathlib import Path
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
pt = p.read_text(encoding="utf-8")

old_row = """struct PermissionStatusRow {
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
"""

# Read exact content from file for the struct start
start = pt.find("struct PermissionStatusRow")
end = pt.find("export struct ProfilePage")
if end < 0:
    end = pt.find("struct ProfilePage")
print("struct range", start, end)
print(repr(pt[start:start+800]))
