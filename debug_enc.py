import re
f = open(r'D:\bharatheeyamapp clone\viyoni_good.dart.bak','r',encoding='utf-8-sig').read()
names = re.findall(r"name: '([^']+)'", f)
for n in names[:5]:
    print(repr(n[:40]))
print("---")
# Check if the file actually has the name
print("Contains test:", "name: '" in f)
# Try exact bytes
target = "ಪಕ್ಷಿ ಜನ್ಮ ಯೋಗ"
print(f"Target in file: {target in f}")
print(f"Target repr: {repr(target[:10])}")
# Check first name repr
print(f"First name repr: {repr(names[0][:10])}")
