from pathlib import Path
import re

home = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets")
ctrl = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ControlPage.ets")
guard = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets")

h = home.read_text(encoding="utf-8")
c = ctrl.read_text(encoding="utf-8")
g = guard.read_text(encoding="utf-8")

print("=== toggleDowntime ===")
i = h.find("toggleDowntime")
print(h[i:i+900] if i>=0 else "NOT FOUND")

print("\n=== Control downtime switch / gates ===")
for i,l in enumerate(c.splitlines(),1):
    if any(k in l for k in ["downtime", "Downtime", "停用", "appLimits", "authorized", "toggle", "whitelist"]):
        if "onToggle" in l or "downtime" in l.lower() or "停用" in l or "appLimits.length" in l or "authorized" in l:
            print(f"{i}|{l}")

print("\n=== Guard downtime / ALLOWLIST / sync ===")
for i,l in enumerate(g.splitlines(),1):
    if any(k in l for k in ["downtime", "Downtime", "ALLOWLIST", "BLOCKLIST", "whitelist", "DAILY", "syncControl", "STRATEGY"]):
        print(f"{i}|{l[:140]}")
