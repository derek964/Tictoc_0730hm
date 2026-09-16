from pathlib import Path
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
# find refreshRuntimeState, requestAuthorization, authorized assignment
for i,l in enumerate(h.splitlines(),1):
    if any(k in l for k in ["refreshRuntimeState","requestAuthorization","this.authorized","openBackground","requestNotify","releaseAll"]):
        if "authorized" in l or "refreshRuntime" in l or "requestAuth" in l or "openBackground" in l or "requestNotify" in l or "releaseAll" in l:
            print(f"{i}|{l[:120]}")
