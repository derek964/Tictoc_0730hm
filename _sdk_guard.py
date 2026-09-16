from pathlib import Path
sdk = Path(r"C:\Program Files\Huawei\DevEco Studio\sdk")
hits = 0
for p in sdk.rglob("*guard*"):
    if p.suffix in {".d.ts", ".ets", ".ts", ".js", ".json"}:
        print("file", p)
        hits += 1
        if hits > 30: break
print("total listed", hits)
