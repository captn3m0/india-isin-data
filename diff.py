from csv_diff import load_csv, compare
import json
from mako.template import Template

template = Template(filename='release.mako')

added,removed,changed = [],[],[]

def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

diff = compare(
    load_csv(open("/tmp/ISIN.csv" % i), key="ISIN"),
    load_csv(open("ISIN.csv" % i), key="ISIN"),
    True
)

print(template.render(added=diff['added'], changed=diff['changed'], removed=diff['removed']))