import sys, re
sys.stdout.reconfigure(encoding='utf-8')

# First, read events.dart
path = r'd:\bharatheeyamapp sample\lib\core\events.dart'
try:
    with open(path, 'r', encoding='utf-8-sig') as f:
        text = f.read()
except FileNotFoundError:
    print("events.dart not found")
    sys.exit(0)

matches = re.finditer(r"name:\s*'([^']+)',\s*description:\s*'([^']+)'", text)

event_strings = []
for m in matches:
    event_strings.append(m.group(1).replace("\n", "\\n"))
    event_strings.append(m.group(2).replace("\n", "\\n"))

# Just unique
event_strings = list(set(event_strings))

print(f"events_list = [")
for s in event_strings:
    print(f"    '{s}',")
print("]")

