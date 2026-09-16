from pathlib import Path
root = Path(r"D:\Tictoc0730")
keys = ["解除", "全部限制", "removeAll", "clearLimits", "disableAll", "revoke", "卸载守护", "关闭守护"]
for p in root.rglob("*"):
    if p.suffix.lower() not in {".kt", ".java", ".xml"}:
        continue
    try:
        t = p.read_text(encoding="utf-8")
    except Exception:
        try:
            t = p.read_text(encoding="gbk")
        except Exception:
            continue
    for k in keys:
        if k in t:
            print(f"{p} :: {k}")
            break
