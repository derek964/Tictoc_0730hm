from pathlib import Path
g = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets").read_text(encoding="utf-8")
i = g.find("async releaseAll")
if i < 0:
    i = g.find("releaseAll(")
print(g[i:i+1800])
print("--- queryState ---")
i = g.find("async queryState")
print(g[i:i+900])
# Profile confirmReleaseAll and Home onReleaseAll typing
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets").read_text(encoding="utf-8")
print("--- profile callbacks ---")
for i,l in enumerate(p.splitlines(),1):
    if l.strip().startswith("on") and ("=" in l or ":" in l) and i < 90:
        print(f"{i}|{l}")
print(p[p.find("confirmReleaseAll"):p.find("confirmReleaseAll")+350])
