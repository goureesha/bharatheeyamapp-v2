import sys
import os
sys.stdout.reconfigure(encoding='utf-8')

try:
    import fitz  # PyMuPDF
except ImportError:
    print("PyMuPDF not installed")
    sys.exit(1)

pdf_path = os.path.join(os.environ['USERPROFILE'], 'Downloads', 'Copy of Mantra sangraha.pdf')
out_path = os.path.join(os.environ['USERPROFILE'], 'Downloads', 'Mantra_sangraha_text.txt')

doc = fitz.open(pdf_path)
print(f"Pages: {len(doc)}")

with open(out_path, 'w', encoding='utf-8') as f:
    for i, page in enumerate(doc):
        text = page.get_text()
        if text.strip():
            f.write(f"--- Page {i+1} ---\n")
            f.write(text)
            f.write("\n\n")

doc.close()
print(f"Done! Text saved to: {out_path}")
