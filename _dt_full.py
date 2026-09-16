from pathlib import Path
g = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets").read_text(encoding="utf-8")
i = g.find("public async syncDowntime")
print(g[i:i+1200])
# Control page downtime section labels / help text
c = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ControlPage.ets").read_text(encoding="utf-8")
print("\n=== Control downtime section ===")
print(c[c.find("sectionLabel"):c.find("sectionLabel")+50])
# print lines 55-100
lines = c.splitlines()
for i in range(55, 100):
    print(f"{i+1}|{lines[i]}")
