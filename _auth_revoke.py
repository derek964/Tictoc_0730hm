from pathlib import Path
g = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets").read_text(encoding="utf-8")
for k in ["revoke", "cancelAuth", "Auth", "requestAuthorization", "getUserAuth"]:
    if k.lower() in g.lower():
        pass
import re
for m in re.finditer(r".{0,40}(Auth|auth|revoke|cancel).{0,60}", g):
    s = m.group(0).replace("\n"," ")
    if "Auth" in s or "auth" in s or "revoke" in s:
        print(s[:120])
# also check Control ForEach key and empty state
c = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ControlPage.ets").read_text(encoding="utf-8")
for i,l in enumerate(c.splitlines(),1):
    if "ForEach" in l or "appLimits" in l and ("length" in l or "Text" in l) or "暂无" in l or "还没有" in l:
        print(f"C{i}|{l}")
