import json, sys
sys.stdout.reconfigure(encoding='utf-8')

data = json.load(open(r'd:\bharatheeyamapp sample\assets\data\books.json', 'r', encoding='utf-8'))
bj = [b for b in data['books'] if b['id'] == 'brihat_jataka'][0]

ch4 = [ch for ch in bj['chapters'] if ch['id'] == 'ch4'][0]
print(f"=== {ch4['title']} === ({len(ch4['shlokas'])} shlokas)\n")

for s in ch4['shlokas']:
    print(f"--- Shloka {s['id']} ---")
    print(f"Sanskrit: {s.get('sanskrit', 'N/A')}")
    print(f"Kannada:  {s.get('kannada', 'N/A')}")
    print()
