from pathlib import Path
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
i = h.find("private async refreshRuntimeState")
print(h[i:i+700])
print("--- getState / loadRuntime ---")
g = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets").read_text(encoding="utf-8")
for name in ["async getState", "loadState", "queryState", "readState", "fetchState", "async snapshot", "getRuntime"]:
    if name in g:
        print("found", name)
# list methods
import re
for m in re.finditer(r"(async )?[a-zA-Z]+\([^)]*\)\s*(:\s*[^{]+)?\s*\{", g):
    line = m.group(0)[:100]
    if "private" in g[max(0,m.start()-30):m.start()] or "public" in g[max(0,m.start()-30):m.start()] or g[max(0,m.start()-10):m.start()].strip()=="":
        pass
for m in re.finditer(r"^\s+(async )?[a-zA-Z]+\(", g, re.M):
    print(m.group(0).strip()[:80])
# Home how it gets state
i = h.find("refreshRuntimeState")
# find guard. call
for m in re.finditer(r"this\.guard\.\w+", h):
    print("guard call", m.group(0))
