from pathlib import Path
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
t = p.read_text(encoding="utf-8")
i = t.find("struct ProfilePage")
print(repr(t[i-40:i+80]))
