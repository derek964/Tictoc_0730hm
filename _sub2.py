from pathlib import Path
import re
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
t = p.read_text(encoding="utf-8")
# Replace subtitle near openSheet('release') - the rowItem second arg
pat = re.compile(
    r"(this\.rowItem\('解除全部限制',\s*')([^']*)(',\s*true,\s*\(\)\s*=>\s*\{\s*\n\s*this\.releasePin = '';\s*\n\s*this\.openSheet\('release'\);)",
    re.M
)
m = pat.search(t)
if not m:
    # try find by openSheet only and replace previous string literal in rowItem
    idx = t.find("openSheet('release')")
    # walk back to rowItem
    start = t.rfind("this.rowItem(", 0, idx)
    chunk = t[start:idx]
    print("chunk:", repr(chunk[:200]))
    # replace second string arg
    m2 = re.match(r"this\.rowItem\('([^']*)',\s*'([^']*)'", chunk)
    if m2:
        old_sub = m2.group(2)
        new_sub = '需验证家长密码；清除全部管控规则，并关闭屏幕时间守护授权'
        t = t[:start] + chunk.replace(old_sub, new_sub, 1) + t[idx:]
        p.write_text(t, encoding="utf-8")
        print("subtitle updated from:", old_sub)
    else:
        print("no match")
else:
    t = pat.sub(r"\1需验证家长密码；清除全部管控规则，并关闭屏幕时间守护授权\3", t, 1)
    p.write_text(t, encoding="utf-8")
    print("subtitle updated via pat")
