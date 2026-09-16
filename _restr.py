from pathlib import Path
p = Path(r"C:\Program Files\Huawei\DevEco Studio\sdk\default\hms\ets\api\@hms.utilityApplication.screenTimeGuard.guardService.d.ts")
t = p.read_text(encoding="utf-8")
# find RestrictionType enum
i = t.find("RestrictionType")
print(t[i:i+800])
print("--- all enum members near Restriction ---")
import re
for m in re.finditer(r"enum RestrictionType[\s\S]*?\}", t):
    print(m.group(0))
# also WHITELIST ALLOW
for i,l in enumerate(t.splitlines(),1):
    if "ALLOW" in l or "WHITE" in l or "BLOCK" in l or "Restriction" in l:
        if "TYPE" in l or "enum" in l or "RestrictionType" in l:
            print(f"{i}|{l}")
