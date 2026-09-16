from pathlib import Path
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets").read_text(encoding="utf-8")
# print confirmReleaseAll and surrounding + securityCard/coreGranted/top status
i = p.find("private async confirmReleaseAll")
print(p[i:i+600])
print("--- coreGranted / securityCard ---")
i = p.find("private coreGranted")
print(p[i:i+400])
i = p.find("securityCard")
# find builder
i = p.find("private securityCard()")
print(p[i:i+700])
print("--- guard.releaseAll ---")
g = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets").read_text(encoding="utf-8")
i = g.find("releaseAll")
print(g[i:i+800])
print("--- TimeUtils.guardStatus ---")
# find TimeUtils
for path in Path(r"D:\TictocBuild-20260911\entry\src\main\ets").rglob("*.ets"):
    t = path.read_text(encoding="utf-8")
    if "guardStatus" in t:
        print(path)
        idx = t.find("guardStatus")
        print(t[idx:idx+400])
