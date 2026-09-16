from pathlib import Path
import re

gpath = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\guard\TictocGuardManager.ets")
g = gpath.read_text(encoding="utf-8")

old_sync = """  public async syncControlRules(managed: AppLimitEntry[], whitelist: string[],
    downtime: string): Promise<GuardActionResult> {
    const tokens = this.restrictedTokens(managed, whitelist);
    const downtimeResult = await this.syncDowntime(tokens, downtime);
"""
new_sync = """  public async syncControlRules(managed: AppLimitEntry[], whitelist: string[],
    downtime: string): Promise<GuardActionResult> {
    // Downtime = allowlist: whitelist apps stay usable; empty whitelist still restricts all others.
    const downtimeResult = await this.syncDowntime(whitelist, downtime);
"""
if old_sync not in g:
    raise SystemExit("syncControlRules block not found")
g = g.replace(old_sync, new_sync, 1)

old_dt = """  public async syncDowntime(tokens: string[], downtime: string): Promise<GuardActionResult> {
    if (downtime.length === 0) {
      return await this.removeNamedStrategy(TictocGuardManager.DOWNTIME_STRATEGY, '已关闭停用时段');
    }
    const parts = downtime.split('-');
    if (parts.length !== 2 || !TimeUtils.isValidClock(parts[0]) || !TimeUtils.isValidClock(parts[1]) ||
      parts[0] === parts[1]) {
      return { success: false, message: '请设置有效且不同的开始和结束时间，例如 22:00 至 07:00' };
    }
    if (tokens.length === 0) {
      return { success: false, message: '请先添加管控应用后再开启停用时段' };
    }
    const strategy: guardService.GuardStrategy = {
      name: TictocGuardManager.DOWNTIME_STRATEGY,
      timeStrategy: {
        type: guardService.TimeStrategyType.START_END_TIME_TYPE,
        startTime: parts[0],
        endTime: parts[1],
        repeat: [1, 2, 3, 4, 5, 6, 7]
      },
      appInfo: { appTokens: tokens },
      appRestrictionType: guardService.RestrictionType.BLOCKLIST_TYPE
    };
    return await this.replaceAndStart(strategy, '每日停用时段已生效');
  }
"""

# Match with flexible Chinese via regex
pat = re.compile(
    r"  public async syncDowntime\(tokens: string\[\], downtime: string\): Promise<GuardActionResult> \{[\s\S]*?"
    r"return await this\.replaceAndStart\(strategy, '[^']*'\);\n  \}",
    re.M
)
m = pat.search(g)
if not m:
    raise SystemExit("syncDowntime not matched")

new_dt = """  public async syncDowntime(whitelistTokens: string[], downtime: string): Promise<GuardActionResult> {
    if (downtime.length === 0) {
      return await this.removeNamedStrategy(TictocGuardManager.DOWNTIME_STRATEGY, '已关闭停用时段');
    }
    const parts = downtime.split('-');
    if (parts.length !== 2 || !TimeUtils.isValidClock(parts[0]) || !TimeUtils.isValidClock(parts[1]) ||
      parts[0] === parts[1]) {
      return { success: false, message: '请设置有效且不同的开始和结束时间，例如 22:00 至 07:00' };
    }
    // ALLOWLIST: tokens are apps still allowed in downtime; empty list = all non-exempt apps blocked.
    const strategy: guardService.GuardStrategy = {
      name: TictocGuardManager.DOWNTIME_STRATEGY,
      timeStrategy: {
        type: guardService.TimeStrategyType.START_END_TIME_TYPE,
        startTime: parts[0],
        endTime: parts[1],
        repeat: [1, 2, 3, 4, 5, 6, 7]
      },
      appInfo: { appTokens: whitelistTokens },
      appRestrictionType: guardService.RestrictionType.ALLOWLIST_TYPE
    };
    return await this.replaceAndStart(strategy, '每日停用时段已生效（除白名单外默认受控）');
  }"""

g = g[:m.start()] + new_dt + g[m.end():]
gpath.write_text(g, encoding="utf-8")
print("guard OK")

# ControlPage: add short hint under downtime switch
cpath = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ControlPage.ets")
c = cpath.read_text(encoding="utf-8")
needle = """            this.switchRow('开启停用时段', this.downtimeEnabled(), (checked: boolean) => {
              this.onToggleDowntime(checked);
            })
"""
# flexible match Chinese title
pat2 = re.compile(
    r"            this\.switchRow\('[^']*', this\.downtimeEnabled\(\), \(checked: boolean\) => \{\n"
    r"              this\.onToggleDowntime\(checked\);\n"
    r"            \}\)\n"
)
m2 = pat2.search(c)
if not m2:
    raise SystemExit("switchRow downtime not found")
insert = m2.group(0) + """            Text('时段内除「始终允许」白名单外，其他应用默认受控；不必先添加管控应用。')
              .fontSize(12)
              .fontColor(ThemeColor.subtitle)
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 10 })
"""
if "不必先添加管控应用" not in c:
    c = c[:m2.start()] + insert + c[m2.end():]
    cpath.write_text(c, encoding="utf-8")
    print("control hint OK")
else:
    print("hint already present")

# verify no other syncDowntime callers with wrong semantics
root = Path(r"D:\TictocBuild-20260911\entry\src\main\ets")
for p in root.rglob("*.ets"):
    t = p.read_text(encoding="utf-8")
    if "syncDowntime" in t:
        print("caller", p)
