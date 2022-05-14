from csv_diff import load_csv, compare
import json
from mako.template import Template

template = Template(filename='release.mako')

added,removed,changed = [],[],[]

def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

for i in ['E', 'F', '9', '0', '1', '2', '3', '4']:
    diff = compare(
        load_csv(open("/tmp/IN%s.csv" % i), key="ISIN"),
        load_csv(open("IN%s.csv" % i), key="ISIN"),
        True
    )
    # print(diff)
    added += diff['added']
    changed += diff['changed']
    removed += diff['removed']

print(template.render(added=added, changed=changed, removed=removed))