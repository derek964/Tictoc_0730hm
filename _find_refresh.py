from pathlib import Path
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
lines = h.splitlines()
# find method and call sites
for i,l in enumerate(lines,1):
    if "refreshProfilePermissions" in l or "refreshPermissions" in l and "private" in l:
        print(f"{i}: {l}")
print("--- around 600-630 ---")
for i in range(590, min(650, len(lines))):
    print(f"{i+1}: {lines[i]}")
print("--- class structure: struct/export ---")
for i,l in enumerate(lines,1):
    if "struct HomePage" in l or "export struct" in l or l.strip().startswith("private async refresh") or l.strip().startswith("private refresh"):
        print(f"{i}: {l}")
