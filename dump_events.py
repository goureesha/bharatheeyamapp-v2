import sys, re
sys.stdout.reconfigure(encoding='utf-8')

with open(r'd:\bharatheeyamapp sample\lib\core\events.dart', 'r', encoding='utf-8-sig') as f:
    text = f.read()

matches = re.finditer(r"name:\s*'([^']+)',\s*description:\s*'([^']+)'", text)

extracted = []
for m in matches:
    extracted.append((m.group(1), m.group(2)))

with open('events_dump.txt', 'w', encoding='utf-8') as f:
    for n, d in extracted:
        f.write(f"'{n}': '',\n")
        f.write(f"'{d}': '',\n")
        
print("Dumped 126 keys to events_dump.txt")
