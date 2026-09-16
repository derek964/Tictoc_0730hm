from pathlib import Path
cpath = Path(r"D:\TictocBuild-20260911\entry\src\main\ets\pages\ControlPage.ets")
c = cpath.read_text(encoding="utf-8")

# Locate the app-limits block from sectionLabel after downtime card to the footer Text
# Find second sectionLabel (app limits)
idx1 = c.find("this.sectionLabel(")
idx2 = c.find("this.sectionLabel(", idx1+1)
if idx2 < 0:
    raise SystemExit("second sectionLabel not found")
# footer starts at Text('...') after the card - look for the long help text after the card close
# The add button onClick startAddSession is unique
start = idx2
# end of footer Text that mentions 系统页 - find next .margin({ bottom: 24 })
end_marker = ".margin({ bottom: 24 })"
end = c.find(end_marker, start)
if end < 0:
    raise SystemExit("footer end not found")
# include the Text(...) block ending at that margin plus newline after
# find start of that Text by going back to last "          Text(" before end
text_start = c.rfind("          Text(", start, end)
print("block start line", c[:start].count("\n")+1)
print("text_start line", c[:text_start].count("\n")+1)
print("end line", c[:end].count("\n")+1)
print("--- CURRENT BLOCK ---")
print(c[start:end+len(end_marker)+1])
