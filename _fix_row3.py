from pathlib import Path
import re

p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
pt = p.read_text(encoding="utf-8")

# Locate from first /** about Permission row OR struct PermissionStatusRow to struct ProfilePage
idx_struct = pt.find("struct PermissionStatusRow")
idx_profile = pt.find("struct ProfilePage")
if idx_struct < 0 or idx_profile < 0:
    raise SystemExit(f"bad markers {idx_struct} {idx_profile}")

# Prefer replacing including the comment block immediately above
idx_comment = pt.rfind("/**", 0, idx_struct)
if idx_comment < 0 or "Permission" not in pt[idx_comment:idx_struct]:
    idx_comment = idx_struct

new_block = """/**
 * Permission row mirrors Android PermissionItem:
 * trailing and subtitle both bind to the same granted @Prop (no local copy).
 */
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

"""

pt = pt[:idx_comment] + new_block + pt[idx_profile:]

# Insert .key after each PermissionStatusRow({...}) that uses the three flags
def inject_keys(src: str) -> str:
    out = []
    i = 0
    while True:
        j = src.find("PermissionStatusRow({", i)
        if j < 0:
            out.append(src[i:])
            break
        out.append(src[i:j])
        # find matching closing })
        depth = 0
        k = j + len("PermissionStatusRow(")
        # src[k] should be '{'
        while k < len(src):
            ch = src[k]
            if ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    k += 1
                    break
            k += 1
        # expect )
        if k < len(src) and src[k] == ')':
            k += 1
        block = src[j:k]
        out.append(block)
        # already has key?
        rest = src[k:k+80]
        if ".key(" not in rest:
            if "this.authorized" in block:
                out.append("\n              .key(`stg-${this.authorized}`)")
            elif "this.backgroundGranted" in block:
                out.append("\n              .key(`bg-${this.backgroundGranted}`)")
            elif "this.notifyEnabled" in block:
                out.append("\n              .key(`nt-${this.notifyEnabled}`)")
        out.append("")  # placeholder no
        # fix: don't append empty - just continue
        # actually I appended "" wrongly - remove
        i = k
    return "".join(out).replace("\n              .key", "\n              .key")  # noop

# cleaner inject
def inject_keys2(src: str) -> str:
    result = []
    i = 0
    while True:
        j = src.find("PermissionStatusRow({", i)
        if j < 0:
            result.append(src[i:])
            break
        result.append(src[i:j])
        depth = 0
        k = j + len("PermissionStatusRow(")
        while k < len(src):
            if src[k] == '{':
                depth += 1
            elif src[k] == '}':
                depth -= 1
                if depth == 0:
                    k += 1
                    break
            k += 1
        if k < len(src) and src[k] == ')':
            k += 1
        block = src[j:k]
        result.append(block)
        if ".key(" not in src[k:k+100]:
            if "granted: this.authorized" in block:
                result.append("\n              .key(`stg-${this.authorized}`)")
            elif "granted: this.backgroundGranted" in block:
                result.append("\n              .key(`bg-${this.backgroundGranted}`)")
            elif "granted: this.notifyEnabled" in block:
                result.append("\n              .key(`nt-${this.notifyEnabled}`)")
        i = k
    return "".join(result)

pt = inject_keys2(pt)
p.write_text(pt, encoding="utf-8")

# verify
v = p.read_text(encoding="utf-8")
assert "isOn" not in v.split("struct ProfilePage")[0]
assert "this.granted ?" in v
assert ".key(`stg-" in v
assert ".key(`bg-" in v
assert ".key(`nt-" in v
print("ProfilePage OK")
print("Home has refreshProfilePermissions:", "refreshProfilePermissions" in Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8"))
