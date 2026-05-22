import re
f = open(r'D:\bharatheeyamapp clone\lib\core\viyoni_janma.dart','r',encoding='utf-8').read()
matches = re.findall(r"name:\s*'([^']*)'", f)
# Chapter markers
lines = f.split('\n')
ch4_start = ch4_end = ch5_start = ch5_end = 0
for i, line in enumerate(lines):
    if 'Shloka 1: Basic Viyoni' in line: ch4_start = i
    if 'Chapter 5' in line and 'Birth-time' in line: ch4_end = i; ch5_start = i
    if 'Chapter 6' in line or 'Chapter 7' in line or ('Chapter' in line and i > ch5_start + 10):
        if ch5_end == 0 and ch5_start > 0: ch5_end = i

# Get yogas by line range
ch4_yogas = []
ch5_yogas = []
for i, line in enumerate(lines):
    m = re.search(r"name:\s*'([^']*)'", line)
    if m:
        name = m.group(1)
        if ch4_start <= i < ch4_end:
            ch4_yogas.append((i+1, name))
        elif ch5_start <= i < (ch5_end if ch5_end > 0 else len(lines)):
            if any(tag in name for tag in ['ಜಕ','JK','ವಿಯೋ','ಆಶ್ರಯ']):
                ch5_yogas.append((i+1, name))
            elif ch5_start <= i < ch5_start + 2000:
                ch5_yogas.append((i+1, name))

print("=== CHAPTER 4: ವಿಯೋನಿಜನ್ಮಾಧ್ಯಾಯ ===")
for ln, n in ch4_yogas:
    print(f"  L{ln}: {n}")
print(f"\n  Total: {len(ch4_yogas)}")
print("\n=== CHAPTER 5: ಜನ್ಮಕಾಲಲಕ್ಷಣಾಧ್ಯಾಯ ===")
for ln, n in ch5_yogas:
    print(f"  L{ln}: {n}")
print(f"\n  Total: {len(ch5_yogas)}")
