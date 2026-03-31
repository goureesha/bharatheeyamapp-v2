import re, sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\bharatheeyamapp sample\lib\screens\panchanga_screen.dart'
with open(path, 'r', encoding='utf-8-sig') as f:
    text = f.read()

strings = re.findall(r"'([^']+)'", text)
strings += re.findall(r'"([^"]+)"', text)

kannada_strings = set()
for s in strings:
    if re.search(r'[\u0C80-\u0CFF]', s):
        kannada_strings.add(s)

for s in kannada_strings:
    if f"tr('{s}')" not in text and f'tr("{s}")' not in text:
        print(f"MISSING TR(): '{s}'")
