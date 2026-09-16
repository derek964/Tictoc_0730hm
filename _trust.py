from pathlib import Path
gpath = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets")
g = gpath.read_text(encoding="utf-8")
g2 = g.replace("ALLOWLIST_TYPE", "TRUSTLIST_TYPE")
if g2 == g:
    raise SystemExit("no ALLOWLIST to replace")
gpath.write_text(g2, encoding="utf-8")
print("replaced to TRUSTLIST_TYPE, count", g2.count("TRUSTLIST_TYPE"))
