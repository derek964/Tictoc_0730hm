from pathlib import Path
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
i = h.find("private async pickManagedApps")
print(h[i:i+1100])
print("--- mergeLimits ---")
i = h.find("mergeLimits")
print(h[i:i+500])
# AlwaysAllowed
print("--- AlwaysAllowed ---")
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages")
for f in p.glob("*.ets"):
    if "Always" in f.name or "Whitelist" in f.name:
        print(f)
