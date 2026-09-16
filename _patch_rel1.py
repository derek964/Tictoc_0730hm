from pathlib import Path
import re

gpath = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets")
g = gpath.read_text(encoding="utf-8")
print("reachable, revoke present:", "revokeUserAuth" in g)
start = g.find("async releaseAll(")
m = re.search(r"\n  (?:async |private async |public async |private )[a-zA-Z]", g[start+20:])
end = start+20+m.start() if m else len(g)
method = g[start:end]
print(method[-900:])
