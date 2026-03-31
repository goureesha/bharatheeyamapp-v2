import os, re
import sys
sys.stdout.reconfigure(encoding='utf-8')

lib_dir = r"d:\bharatheeyamapp sample\lib"
kannada_pattern = re.compile(r'[\u0C80-\u0CFF]')

print("Scanning for untranslated strings...", flush=True)

untranslated = {}

for root, _, files in os.walk(lib_dir):
    for filename in files:
        if filename.endswith(".dart"):
            path = os.path.join(root, filename)
            with open(path, "r", encoding="utf-8-sig") as f:
                content = f.read()
                
            # Quick check if Kannada string literal
            strs = re.findall(r"'([^']+)'", content) + re.findall(r'"([^"]+)"', content)
            kannada_strs = [s for s in set(strs) if kannada_pattern.search(s)]
            
            # Check for strings not in tr()
            missing = []
            for s in kannada_strs:
                if f"tr('{s}')" not in content and f'tr("{s}")' not in content:
                    # Ignore dictionary and constants
                    if "_knToHi" not in content and "planetNames =" not in content and "static const _" not in content:
                        missing.append(s)
            
            if missing:
                untranslated[filename] = missing

for file, items in untranslated.items():
    print(f"\n--- {file} ---")
    for m in items:
        print(f"'{m}'")
print("\nDone.")
