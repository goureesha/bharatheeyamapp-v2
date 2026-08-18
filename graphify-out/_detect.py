import json
from graphify.detect import detect
from pathlib import Path

result = detect(Path('.'))
Path('graphify-out/.graphify_detect.json').write_text(
    json.dumps(result, ensure_ascii=False), encoding='utf-8'
)
total = result.get('total_files', 0)
words = result.get('total_words', 0)
files = result.get('files', {})
print(f"Corpus: {total} files ~ {words} words")
for ftype, flist in files.items():
    if flist:
        print(f"  {ftype}: {len(flist)} files")
