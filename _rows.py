from pathlib import Path
import shutil

# Remove unused PermissionManager import from Profile
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
pt = p.read_text(encoding="utf-8")
if "PermissionManager." not in pt and "PermissionManager.load" not in pt:
    pt2 = pt.replace("import { PermissionManager } from '../permission/PermissionManager';\n", "")
    if pt2 != pt:
        p.write_text(pt2, encoding="utf-8")
        print("removed unused import")
        pt = pt2

# Force row rebuild with .key tied to granted flags — find PermissionStatusRow blocks
# Read the permission rows section
lines = pt.splitlines()
for i in range(155, 210):
    print(f"{i+1}|{lines[i]}")
