from pathlib import Path
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
pt = p.read_text(encoding="utf-8")
# show PermissionStatusRow struct fully
start = pt.find("struct PermissionStatusRow")
print(pt[start:start+900])
print("--- top card ---")
# find guard status / 守护
for i,l in enumerate(pt.splitlines(),1):
    if "authorized" in l or "守护" in l or "guard" in l.lower() or "coreReady" in l or "statusTitle" in l:
        if i < 160:
            print(f"{i}|{l}")
