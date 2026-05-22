import re

path = r'D:\bharatheeyamapp clone\lib\core\viyoni_janma.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Yoga names to remove
remove_names = [
    'ಪಕ್ಷಿ ಜನ್ಮ ಯೋಗ',
    'ವೃಕ್ಷ ಜನ್ಮ ಯೋಗ',
    'ವೃಕ್ಷ ಪ್ರಕಾರ ಯೋಗ',
    'ನವಾಂಶ ವೃಕ್ಷ ಸಂಖ್ಯೆ',
    'ಋತುದರ್ಶನ ಯೋಗ',
    'ಮಿಲನ ಯೋಗ',
    'ಮಿಲನ ಸ್ವರೂಪ ಯೋಗ',
    'ಪಿತೃ-ಮಾತೃ ಕಾರಕ ಯೋಗ',
    'ಪುತ್ರ ಜನನ ಯೋಗ (೧೨,೧೩)',
    'ಪುತ್ರಿ ಜನನ ಯೋಗ (೧೨)',
    'ಗರ್ಭ ಮಾಸಾಧಿಪತಿ ಫಲ (೧೬)',
    'ಜನನ ಕಾಲ ನಿರ್ಣಯ (೨೧)',
    'ಅನ್ಯಜಾತ ಯೋಗ (ಜಕ ೫)',
    'ಹೆರಿಗೆ ಮನೆ ಲಕ್ಷಣ (ಜಕ ೧೮)',
    'ಹೆರಿಗೆ ಮನೆ ಸ್ವರೂಪ (ಜಕ ೧೯)',
    'ಹೆರಿಗೆ ಕೋಣೆ ದಿಕ್ಕು (ಜಕ ೨೦)',
    'ಹಾಸಿಗೆ ಪಾದ ಯೋಗ (ಜಕ ೨೧)',
    'ಉಪಸೂತಿಕಾ ಯೋಗ (ಜಕ ೨೨)',
    'ಶಿಶು ಶರೀರ/ಬಣ್ಣ (ಜಕ ೨೩)',
    'ದೇಹಾಂಗ ರಾಶಿ ಮ್ಯಾಪ್ (ಜಕ ೨೪)',
]

# Find block markers (═══ comments that start each yoga block)
# Each yoga block starts with a comment like "// ═══ ... ═══" and ends just before the next one
block_starts = []
for i, line in enumerate(lines):
    if '═══' in line and ('Shloka' in line or 'JK' in line or 'jk' in line.lower()):
        block_starts.append(i)
    # Also catch blocks that start with just an if/final after a blank line
    
# For each yoga name to remove, find which line has that name
remove_ranges = []
for rn in remove_names:
    for i, line in enumerate(lines):
        if f"name: '{rn}'" in line:
            # Find the block start (go backwards to find ═══ or blank+comment)
            start = i
            for j in range(i-1, max(0, i-30), -1):
                stripped = lines[j].strip()
                if '═══' in stripped:
                    start = j
                    break
                if stripped == '' and j < i-1:
                    # Check if next non-blank is the start of this block's variables
                    start = j + 1
                    # But prefer ═══ marker
                    for k in range(j, max(0, j-3), -1):
                        if '═══' in lines[k]:
                            start = k
                            break
                    break
            
            # Find the block end (go forward to find next ═══ or next yoga block or Chapter marker)
            end = i
            brace_depth = 0
            for j in range(i, min(len(lines), i+80)):
                stripped = lines[j].strip()
                brace_depth += stripped.count('{') - stripped.count('}')
                # Block ends when we hit the next ═══ marker or Chapter marker
                if j > i and ('═══' in stripped or 'Chapter' in stripped):
                    end = j - 1
                    # Trim trailing blank lines
                    while end > start and lines[end].strip() == '':
                        end -= 1
                    end += 1  # include the blank line
                    break
                # Or when brace depth returns to 0 after a yoga.add closing
                if j > i + 2 and brace_depth <= 0 and (stripped == '' or stripped == '}'):
                    # Look ahead - if next non-blank is a new block, this is the end
                    for k in range(j+1, min(len(lines), j+5)):
                        if lines[k].strip() != '':
                            if '═══' in lines[k] or 'Chapter' in lines[k] or 'final jk' in lines[k] or 'return yogas' in lines[k]:
                                end = j + 1
                                break
                            break
                    if end > i:
                        break
            
            if end <= i:
                end = i + 1  # at minimum remove the name line
            
            remove_ranges.append((start, end, rn))
            print(f"REMOVE L{start+1}-L{end}: {rn}")
            break
    else:
        print(f"NOT FOUND: {rn}")

# Sort by start line descending (remove from bottom first)
remove_ranges.sort(key=lambda x: x[0], reverse=True)

# Remove the blocks
for start, end, name in remove_ranges:
    del lines[start:end]

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print(f"\nRemoved {len(remove_ranges)} blocks. New file has {len(lines)} lines.")
