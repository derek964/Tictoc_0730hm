from pathlib import Path
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
# aboutToAppear / onPageShow / load settings
for name in ["aboutToAppear", "onPageShow", "loadAll", "settings.load", "readSettings", "bootstrap", "init"]:
    idx = 0
    while True:
        i = h.find(name, idx)
        if i < 0: break
        line = h[:i].count("\n")+1
        print(f"{line}| ... {h[i:i+80].splitlines()[0]}")
        idx = i+1
print("--- startup ---")
print(h[h.find("aboutToAppear"):h.find("aboutToAppear")+800] if "aboutToAppear" in h else "none")
print("--- onPageShow ---")
print(h[h.find("onPageShow"):h.find("onPageShow")+500] if "onPageShow" in h else "none")
