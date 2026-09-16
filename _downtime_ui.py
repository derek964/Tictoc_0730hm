from pathlib import Path
c = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ControlPage.ets").read_text(encoding="utf-8")
# downtime UI
for i,l in enumerate(c.splitlines(),1):
    if "downtime" in l.lower() or "停用" in l or "Toggle" in l:
        print(f"{i}|{l}")
