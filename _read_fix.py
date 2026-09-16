from pathlib import Path
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
lines = h.splitlines()
# print refreshPermissions and nearby methods
for i in range(100, 160):
    print(f"{i+1}|{lines[i]}")
print("--- ProfilePage key parts ---")
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets").read_text(encoding="utf-8")
pl = p.splitlines()
for i,l in enumerate(pl,1):
    if any(k in l for k in ["@Link","@Prop","reloadPermissions","onRefreshPermissions","PermissionStatusRow","granted","aboutToAppear","isOn","onGranted"]):
        print(f"{i}|{l}")
