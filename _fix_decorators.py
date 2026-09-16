from pathlib import Path
p = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ProfilePage.ets")
pt = p.read_text(encoding="utf-8")
print(pt[:700])
print("--- around ProfilePage ---")
idx = pt.find("struct ProfilePage")
print(pt[idx-80:idx+200])
# remove .key lines
import re
pt2 = re.sub(r"\n\s*\.key\(`[^`]+`\)", "", pt)
# fix decorators
pt2 = pt2.replace("struct PermissionStatusRow", "@Component\nstruct PermissionStatusRow", 1)
pt2 = pt2.replace("struct ProfilePage", "@Component\nexport struct ProfilePage", 1)
# avoid double @Component if already present
while "@Component\n@Component\n" in pt2:
    pt2 = pt2.replace("@Component\n@Component\n", "@Component\n")
while "export export " in pt2:
    pt2 = pt2.replace("export export ", "export ")
p.write_text(pt2, encoding="utf-8")
print("--- after fix head ---")
print(p.read_text(encoding="utf-8")[:750])
print("key leftover", ".key(" in p.read_text(encoding="utf-8"))
