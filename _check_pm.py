from pathlib import Path
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets").read_text(encoding="utf-8")
for i,l in enumerate(p.splitlines(),1):
    if "PermissionManager" in l:
        print(f"{i}|{l}")
# show PermissionStatusRow usage with key
for i,l in enumerate(p.splitlines(),1):
    if "PermissionStatusRow" in l or "granted:" in l:
        print(f"{i}|{l}")
