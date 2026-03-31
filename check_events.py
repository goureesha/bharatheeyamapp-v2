import sys
import re
sys.stdout.reconfigure(encoding='utf-8')

with open(r'd:\bharatheeyamapp sample\lib\core\events.dart', 'r', encoding='utf-8-sig') as f:
    text = f.read()

matches = re.finditer(r"'([^']+)'", text)
matches2 = re.finditer(r'"([^"]+)"', text)
kannada_strings = set(m.group(1) for m in matches if re.search(r'[\u0C80-\u0CFF]', m.group(1)))
kannada_strings.update(set(m.group(1) for m in matches2 if re.search(r'[\u0C80-\u0CFF]', m.group(1))))

print(f"Total Kannada strings in events.dart: {len(kannada_strings)}")
for i, ks in enumerate(list(kannada_strings)[:10]):
    print(ks)
