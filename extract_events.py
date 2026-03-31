import sys, re
sys.stdout.reconfigure(encoding='utf-8')

with open(r'd:\bharatheeyamapp sample\lib\core\events.dart', 'r', encoding='utf-8-sig') as f:
    text = f.read()

# Extract AstroEvent calls. Format: AstroEvent(name: 'xyz', description: 'abc', source: '...')
matches = re.finditer(r"name:\s*'([^']+)',\s*description:\s*'([^']+)'", text)

extracted = []
for m in matches:
    name, desc = m.group(1), m.group(2)
    extracted.append((name, desc))

for n, d in extracted[:5]:
    print(f"{n} | {d}")
    
print(f"Total extracted events: {len(extracted)}")
