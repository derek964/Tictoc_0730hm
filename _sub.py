from pathlib import Path
# Update Profile row subtitle for 解除全部限制 to mention auth revoke
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
t = p.read_text(encoding="utf-8")
# find rowItem for release - look for openSheet('release')
idx = t.find("openSheet('release')")
print(t[idx-250:idx+80])
