from pathlib import Path
h = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets")
text = h.read_text(encoding="utf-8")
# Insert method after refreshPermissions
old = """  private async refreshPermissions(): Promise<void> {
    const snapshot = await PermissionManager.load(this.authorized, this.appLimits.length);
    this.notifyEnabled = snapshot.notificationEnabled;
    this.backgroundGranted = snapshot.backgroundGranted;
  }
"""
new = """  private async refreshPermissions(): Promise<void> {
    const snapshot = await PermissionManager.load(this.authorized, this.appLimits.length);
    this.notifyEnabled = snapshot.notificationEnabled;
    this.backgroundGranted = snapshot.backgroundGranted;
  }

  /** Same idea as Android ON_RESUME: re-read auth + notify + background for Profile. */
  private async refreshProfilePermissions(): Promise<void> {
    await this.refreshRuntimeState(false);
    await this.refreshPermissions();
  }
"""
if old not in text:
    raise SystemExit("refreshPermissions block not found")
text = text.replace(old, new, 1)
# Fix callback type inference
text = text.replace(
    "onRefreshPermissions: () => this.refreshProfilePermissions(),",
    "onRefreshPermissions: async (): Promise<void> => await this.refreshProfilePermissions(),",
    1
)
h.write_text(text, encoding="utf-8")
print("HomePage patched OK")

# Remove unused PermissionManager from Profile if unused
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
pt = p.read_text(encoding="utf-8")
# check if PermissionManager is used beyond import
body = pt.split("import", 2)[-1] if False else pt
uses = pt.count("PermissionManager")
print("PermissionManager mentions:", uses)
if uses == 1 and "import { PermissionManager }" in pt:
    pt = pt.replace("import { PermissionManager } from '../permission/PermissionManager';\n", "")
    p.write_text(pt, encoding="utf-8")
    print("removed unused PermissionManager import")

# Also ensure requestNotify/openBackground refresh permissions after
for name in ["requestNotify", "openBackground"]:
    i = text.find(f"private async {name}")
    print("---", name, "---")
    print(text[i:i+450])
