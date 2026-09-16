from pathlib import Path

def show(path, needles):
    t = Path(path).read_text(encoding="utf-8")
    lines = t.splitlines()
    print("====", path)
    for i,l in enumerate(lines,1):
        if any(n in l for n in needles):
            print(f"{i}|{l}")

home = r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets"
prof = r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets"
guard = r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets"
show(home, ["releaseAll", "release", "authorized", "refreshRuntime", "refreshPermission", "refreshProfile"])
print("--- releaseAll body ---")
h = Path(home).read_text(encoding="utf-8")
i = h.find("private async releaseAll")
print(h[i:i+900])
print("--- Profile release ---")
p = Path(prof).read_text(encoding="utf-8")
for needle in ["release", "解除", "reloadPermissions", "handleAuth", "openSheet"]:
    pass
i = p.find("release")
# print methods related
import re
for m in re.finditer(r"(private async |private |aboutToAppear|confirmRelease|doRelease|handleRelease)[^\n]*", p):
    print(m.group(0))
# find release sheet confirm
idx = p.find("sheetKind")
print(p[p.find("release"):p.find("release")+200] if "release" in p else "no")
# better: find confirm for release pin
for i,l in enumerate(p.splitlines(),1):
    if "release" in l.lower() or "解除" in l or "Release" in l:
        print(f"{i}|{l}")
