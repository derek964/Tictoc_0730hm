from pathlib import Path
p = Path(r"C:\Program Files\Huawei\DevEco Studio\sdk\default\hms\ets\api\@hms.utilityApplication.screenTimeGuard.guardService.d.ts")
t = p.read_text(encoding="utf-8")
for i,l in enumerate(t.splitlines(),1):
    if any(k in l.lower() for k in ["auth", "release", "revoke", "cancel", "clear", "remove", "stop"]):
        print(f"{i}|{l}")
