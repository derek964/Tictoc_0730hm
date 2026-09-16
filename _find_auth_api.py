from pathlib import Path
roots = [Path(r"D:\TictocBuild-20260911")]
# search for auth APIs in oh_modules / sdk typings if present
patterns = ["requestUserAuth", "getUserAuthStatus", "cancelUserAuth", "revokeUserAuth", "clearUserAuth"]
for root in roots:
    for p in root.rglob("*.d.ts"):
        try:
            t = p.read_text(encoding="utf-8")
        except Exception:
            continue
        if "guardService" in t or "screenTime" in t.lower() or "UserAuth" in t:
            for pat in patterns:
                if pat in t:
                    print(p.name, pat)
            if "Auth" in t and "guard" in t.lower():
                # print auth-related lines
                for line in t.splitlines():
                    if "Auth" in line or "auth" in line:
                        if "function" in line or "Auth" in line:
                            print(f"  {p}: {line.strip()[:140]}")
