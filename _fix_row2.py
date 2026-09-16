from pathlib import Path
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
pt = p.read_text(encoding="utf-8")

# Replace the whole PermissionStatusRow struct cleanly
start = pt.find("struct PermissionStatusRow")
end = pt.find("struct ProfilePage")
if start < 0 or end < 0:
    raise SystemExit(f"markers missing {start} {end}")

# Keep the comment block before struct if any — start at struct
new_struct = r'''struct PermissionStatusRow {
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
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })

      if (!this.isLast) {
        Divider()
          .color(ThemeColor.divider)
          .margin({ left: 16 })
      }
    }
    .width('100%')
    .onClick(() => {
      this.onTap();
    })
  }
}

'''

# Find comment before struct to preserve header comment
comment_start = pt.rfind("/**", 0, start)
if comment_start >= 0 and "Permission row" in pt[comment_start:start]:
    # replace from comment through end of old struct
    header = """/**
 * Permission row mirrors Android PermissionItem:
 * trailing and subtitle both bind to the same granted @Prop (no local copy).
 */
"""
    pt = pt[:comment_start] + header + new_struct + pt[end:]
else:
    pt = pt[:start] + new_struct + pt[end:]

# Add .key() after each PermissionStatusRow call block to force remount when flag flips
# After auth row closing `})` before `}` of Column - use unique markers
replacements = [
    (
"""            PermissionStatusRow({
              title: '屏幕时间守护授权',
              granted: this.authorized,
              offSubtitle: '授权后系统才能执行管控：管理应用选择、限时、时段。「管控设置」里完成。',
              isLast: true,
              onTap: () => {
                this.handleAuthTap();
              }
            })""",
"""            PermissionStatusRow({
              title: '屏幕时间守护授权',
              granted: this.authorized,
              offSubtitle: '授权后系统才能执行管控：管理应用选择、限时、时段。「管控设置」里完成。',
              isLast: true,
              onTap: () => {
                this.handleAuthTap();
              }
            })
              .key(`stg-${this.authorized}`)"""
    ),
]
# Don't rely on exact Chinese offSubtitle - do structural key inserts with regex
import re

def add_key_after_row(text: str, title: str, key_expr: str) -> str:
    # Find PermissionStatusRow({ ... title: '...' ... }) and insert .key after closing })
    pattern = re.compile(
        r"(PermissionStatusRow\(\{\s*title:\s*'" + re.escape(title) + r"'[\s\S]*?\n\s*\}\))",
        re.M
    )
    m = pattern.search(text)
    if not m:
        print("WARN: row not found for", title)
        return text
    block = m.group(1)
    if ".key(" in text[m.end():m.end()+40]:
        print("key already present for", title)
        return text
    return text[:m.end()] + f"\n              .key({key_expr})" + text[m.end()]

# Extract titles from file by reading granted lines context
# Use titles as they appear in file
for m in re.finditer(r"PermissionStatusRow\(\{\s*title:\s*'([^']+)'", pt):
    print("found title:", m.group(1))

titles_keys = []
# map by order: authorized, background, notify
rows = list(re.finditer(r"PermissionStatusRow\(\{[\s\S]*?\n\s*\}\)", pt))
print("row count", len(rows))
for i, m in enumerate(rows):
    block = m.group(0)
    if "this.authorized" in block:
        key = "`stg-${this.authorized}`"
    elif "this.backgroundGranted" in block:
        key = "`bg-${this.backgroundGranted}`"
    elif "this.notifyEnabled" in block:
        key = "`nt-${this.notifyEnabled}`"
    else:
        continue
    if ".key(" in pt[m.end():m.end()+60]:
        continue
    pt = pt[:m.end()] + f"\n              .key({key})" + pt[m.end():]
    # re-find because offsets shifted - simpler: rebuild from scratch after collecting
print("done first pass approach bad - redo")
