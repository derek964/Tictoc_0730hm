from pathlib import Path

g = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets").read_text(encoding="utf-8")
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")

print("=== syncDowntime full ===")
i = g.find("public async syncDowntime")
print(g[i:i+900])

print("\n=== syncControlRules full ===")
i = g.find("public async syncControlRules")
print(g[i:i+600])

print("\n=== restrictedTokens ===")
i = g.find("public restrictedTokens")
print(g[i:i+400])

print("\n=== Home syncRules / toast gates ===")
for name in ["syncRules", "appLimits.length", "先添加", "管控应用", "toggleDowntime"]:
    pass
import re
for m in re.finditer(r"private async syncRules[\s\S]{0,800}", h):
    print(m.group(0)[:800])
# any toast about managed
for i,l in enumerate(h.splitlines(),1):
    if "toast" in l.lower() and ("管控" in l or "应用" in l or "授权" in l or "停用" in l):
        print(f"H{i}|{l}")
for i,l in enumerate(h.splitlines(),1):
    if "syncRules" in l or "if (!this.authorized)" in l:
        print(f"H{i}|{l}")
