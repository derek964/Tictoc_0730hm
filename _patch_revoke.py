from pathlib import Path

# --- Guard: revoke auth after clearing strategies ---
gpath = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets")
g = gpath.read_text(encoding="utf-8")
old = """      if (!quotaCleanup.success && quotaCleanup.message.indexOf('1019000005') < 0) {
        return quotaCleanup;
      }
      return {
        success: true,
        message: changed ? '已解除 Tictoc 创建的全部限制' : '当前没有 Tictoc 管控规则'
      };
"""
# File may have different Chinese - match structurally without relying on exact message chars
import re
pat = re.compile(
    r"      if \(!quotaCleanup\.success && quotaCleanup\.message\.indexOf\('1019000005'\) < 0\) \{\n"
    r"        return quotaCleanup;\n"
    r"      \}\n"
    r"      return \{\n"
    r"        success: true,\n"
    r"        message: changed \? '[^']*' : '[^']*'\n"
    r"      \};",
    re.M
)
m = pat.search(g)
if not m:
    raise SystemExit("releaseAll success block not found")
new = """      if (!quotaCleanup.success && quotaCleanup.message.indexOf('1019000005') < 0) {
        return quotaCleanup;
      }
      // Mirror Android-style full release: clear rules then revoke Screen Time Guard auth
      // so Profile 守护状态 / 「已开启」 flip to 未开启 after refresh.
      try {
        await guardService.revokeUserAuth();
        changed = true;
      } catch (error) {
        this.logError('revokeUserAuth', error as BusinessError);
        return this.toFailure('管控规则已清理，但撤销屏幕时间守护授权失败', error as BusinessError);
      }
      return {
        success: true,
        message: '已解除全部限制，并关闭屏幕时间守护授权'
      };
"""
g = g[:m.start()] + new + g[m.end():]
gpath.write_text(g, encoding="utf-8")
print("guard patched")

# --- Profile: await onReleaseAll ---
ppath = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
p = ppath.read_text(encoding="utf-8")
p = p.replace(
    "onReleaseAll: () => void = () => {};",
    "onReleaseAll: () => Promise<void> = async () => {};",
    1
)
old_confirm = """  private async confirmReleaseAll(): Promise<void> {
    if (!await PinSecurity.verify(this.releasePin, this.pinSalt, this.pinHash)) {
      this.onToast('密码错误');
      return;
    }
    this.closeSheet();
    this.releasePin = '';
    this.onReleaseAll();
    await this.reloadPermissions();
  }
"""
# match toast message flexibly
pat2 = re.compile(
    r"  private async confirmReleaseAll\(\): Promise<void> \{\n"
    r"    if \(!await PinSecurity\.verify\(this\.releasePin, this\.pinSalt, this\.pinHash\)\) \{\n"
    r"      this\.onToast\('[^']*'\);\n"
    r"      return;\n"
    r"    \}\n"
    r"    this\.closeSheet\(\);\n"
    r"    this\.releasePin = '';\n"
    r"    this\.onReleaseAll\(\);\n"
    r"    await this\.reloadPermissions\(\);\n"
    r"  \}",
    re.M
)
m2 = pat2.search(p)
if not m2:
    raise SystemExit("confirmReleaseAll not found")
# keep the same toast string from original
toast_line = re.search(r"this\.onToast\('([^']*)'\)", m2.group(0)).group(1)
new_confirm = f"""  private async confirmReleaseAll(): Promise<void> {{
    if (!await PinSecurity.verify(this.releasePin, this.pinSalt, this.pinHash)) {{
      this.onToast('{toast_line}');
      return;
    }}
    this.closeSheet();
    this.releasePin = '';
    await this.onReleaseAll();
    await this.reloadPermissions();
  }}"""
p = p[:m2.start()] + new_confirm + p[m2.end():]
ppath.write_text(p, encoding="utf-8")
print("profile patched")

# --- Home: wire async onReleaseAll ---
hpath = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\HomePage.ets")
h = hpath.read_text(encoding="utf-8")
h2 = h.replace(
    "onReleaseAll: () => this.releaseAll(),",
    "onReleaseAll: async (): Promise<void> => await this.releaseAll(),",
    1
)
if h2 == h:
    raise SystemExit("Home onReleaseAll wiring not found")
hpath.write_text(h2, encoding="utf-8")
print("home patched")
