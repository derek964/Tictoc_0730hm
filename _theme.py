from pathlib import Path
t = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\ui\Theme.ets").read_text(encoding="utf-8")
print(t)
# check old divider in profile git or other files
import re
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets").read_text(encoding="utf-8")
print("--- divider/theme refs ---")
for m in re.finditer(r"ThemeColor\.\w+", p):
    pass
print(sorted(set(re.findall(r"ThemeColor\.(\w+)", p))))
