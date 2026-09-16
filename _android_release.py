from pathlib import Path
root = Path(r"D:\Tictoc0730")
# search release related in android
hits = []
for p in root.rglob("*.kt"):
    try:
        t = p.read_text(encoding="utf-8")
    except Exception:
        continue
    if "解除" in t or "releaseAll" in t or "ReleaseAll" in t or "clearAll" in t.lower() or "解除全部" in t:
        hits.append(p)
print("files", len(hits))
for p in hits:
    print(p)
