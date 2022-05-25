from csv_diff import load_csv, compare
import json
from mako.template import Template

template = Template(filename='src/release.mako')

added,removed,changed = [],[],[]

def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

diff = compare(
    load_csv(open("/tmp/ISIN.csv"), key="ISIN"),
    load_csv(open("ISIN.csv"), key="ISIN"),
    True
)

contents = template.render(added=diff['added'], changed=diff['changed'], removed=diff['removed'])

# GitHub supports a maximum limit of 125000 for release notes.
# 124800 = 124000 - 200 for buffer and the warning line
# To get around this, we add a warning if we hit the limit
# and attach a release.md file with the complete notes
if len(contents) >= 125000:
    notes = """This file is truncated due to GitHub limitations.
please see the attached `release.md` file for complete notes""" + contents[:124800]
else:
    notes = contents

"""
notes are the viewable notes on the release page on GitHub
while release.md is the attached notes. This is the complete text.
"""
with open('notes.md', 'w') as f:
    f.write(notes)

with open('release.md', 'w') as f:
    f.write(contents)