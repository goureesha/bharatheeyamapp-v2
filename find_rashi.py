import re

path = r'D:\bharatheeyamapp clone\lib\core\viyoni_janma.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find yogas.add blocks where rashi is NOT lagRashi
# These are the ones using planet rashi instead of lagna rashi
for i, line in enumerate(lines):
    if 'rashi:' in line and 'yogas.add' not in line:
        stripped = line.strip()
        # Skip if it's lagRashi
        if 'rashi: lagRashi' in stripped:
            continue
        if 'rashi: y.rashi' in stripped:
            continue
        # Find the yoga name (look backwards)
        name = '?'
        for j in range(i, max(0, i-10), -1):
            m = re.search(r"name:\s*'([^']*)'", lines[j])
            if m:
                name = m.group(1)
                break
        # Get what rashi is set to
        m2 = re.search(r'rashi:\s*(.+?)(?:,|\))', stripped)
        rval = m2.group(1).strip() if m2 else '?'
        print(f"L{i+1}: rashi={rval:30s} | {name[:60]}")
