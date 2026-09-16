from pathlib import Path
p = Path(r"D:\Tictoc0730\app\src\main\java\com\derek\tictoc\ui\profile\ProfileScreen.kt")
t = p.read_text(encoding="utf-8")
# print lines with chinese related to release
for i,l in enumerate(t.splitlines(),1):
    if any(x in l for x in ["解除", "限制", "卸载", "守护", "DeviceAdmin", "removeActive", "clear", "Release", "全部"]):
        print(f"{i}|{l}")
