from pathlib import Path

c = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ControlPage.ets").read_text(encoding="utf-8")
print("=== ControlPage full ===")
print(c)
print("\n\n===== HOME pick/add =====")
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
import re
for name in ["pickManagedApps", "startAddSession", "onPickApps"]:
    i = h.find(name)
    print("---", name, "---")
    if i>=0:
        print(h[max(0,i-200):i+700])
