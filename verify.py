import os
import re

files_to_check = []
for root, _, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            files_to_check.append(os.path.join(root, f))

# Look for patterns like (EnglishWord), \nEnglishWord inside string literals
found = False
for path in files_to_check:
    with open(path, 'r', encoding='utf-8') as file:
        lines = file.readlines()
        for i, line in enumerate(lines):
            line = line.strip()
            # Only care about UI strings (containing Kannada)
            if "'" in line or '"' in line:
                if re.search(r'[ಅ-ಹ]', line) and re.search(r'[a-zA-Z]', line):
                    # Exclude console logs, exceptions, map keys, etc.
                    if 'import' not in line and 'Color' not in line and 'print' not in line and 'Exception' not in line:
                        print(f'{path}:{i+1}: {line}')
                        found = True

if not found:
    print('No mixed Kannada-English UI strings found!')
