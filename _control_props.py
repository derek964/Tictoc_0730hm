from pathlib import Path
c = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ControlPage.ets").read_text(encoding="utf-8")
# props at top
print(c[:1200])
print("--- Home ControlPage wiring ---")
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
i = h.find("ControlPage({")
print(h[i:i+700])
print("--- Dashboard wiring ---")
i = h.find("DashboardPage({")
print(h[i:i+500])
