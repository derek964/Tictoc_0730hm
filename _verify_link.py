from pathlib import Path
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
t = p.read_text(encoding="utf-8")
print(t.splitlines()[0:8])
print("PermissionManager" in t)
# Home tab change
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
i = h.find(".onChange((index: number)")
print(h[i:i+280])
i = h.find("refreshProfilePermissions")
print("refreshProfilePermissions def", i>=0)
print(h[i:i+220])
