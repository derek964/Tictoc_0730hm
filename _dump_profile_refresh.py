from pathlib import Path
home = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets").read_text(encoding="utf-8")
profile = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets").read_text(encoding="utf-8")
# requestAuthorization / requestNotify / openBackground
for name in ["requestAuthorization", "requestNotify", "openBackground", "refreshPermissions"]:
    i = home.find(f"private async {name}" if name != "refreshPermissions" else "private async refreshPermissions")
    if i < 0:
        i = home.find(f"private {name}")
    print(f"\n=== {name} ===")
    print(home[i:i+550] if i>=0 else "missing")
print("\n=== Profile permissionItem/rowItem ===")
lines = profile.splitlines()
for n,l in enumerate(lines,1):
    if any(x in l for x in ["permissionItem", "rowItem", "authorized", "backgroundGranted", "notifyEnabled", "去开启", "已开启", "@Builder"]):
        print(f"{n}|{l}")
