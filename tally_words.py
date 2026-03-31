import sys, re
from collections import Counter
sys.stdout.reconfigure(encoding='utf-8')

with open(r'd:\bharatheeyamapp sample\events_dump.txt', 'r', encoding='utf-8') as f:
    text = f.read()

words = re.findall(r'[\u0C80-\u0CFF]+', text)
counts = Counter(words)

try:
    with open(r'd:\bharatheeyamapp sample\lib\widgets\common.dart', 'r', encoding='utf-8-sig') as f:
        common_text = f.read()
    existing_keys = set(re.findall(r"'([\u0C80-\u0CFF]+)'\s*:\s*'", common_text))
except Exception:
    existing_keys = set()

missing = [w for w, c in counts.most_common() if w not in existing_keys]
print("Top 50 missing words:")
for w in missing[:50]:
    print(w)
