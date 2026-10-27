import csv
from pathlib import Path

rows = []
for path in ('townscaper_application_methods.tsv', 'townscaper_platform_methods.tsv'):
    with open(Path('outputs') / path, encoding='utf-8') as source:
        rows.extend(csv.DictReader(source, delimiter='\t'))
seen = set()
lines = []
for row in rows:
    if row['rva'] not in seen:
        seen.add(row['rva'])
        lines.append(row['rva'] + '\t' + row['alias'])
Path('work/application_targets.tsv').write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(len(lines))
