import sys, re, os
sys.stdout.reconfigure(encoding='utf-8')
root = r'd:\bharatheeyamapp sample\lib'
for dirpath, dirs, files in os.walk(root):
    for fn in files:
        if not fn.endswith('.dart'): continue
        fpath = os.path.join(dirpath, fn)
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
            for i, line in enumerate(lines, 1):
                # Check for unbalanced parens in Text() widgets
                # Pattern: single-quote string that has ( but no matching ) before the quote ends
                stripped = line.strip()
                # Count open and close parens - look for lines with mismatched parens
                opens = stripped.count('(')
                closes = stripped.count(')')
                if opens != closes and 'Text(' in stripped and opens - closes >= 2:
                    print(f'{os.path.relpath(fpath, root)}:{i}: MISMATCH o={opens} c={closes}')
                    print(f'  {stripped}')
