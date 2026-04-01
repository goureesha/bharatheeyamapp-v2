import sys, re
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'd:\bharatheeyamapp sample\mc_lagna_rules.txt', 'r', encoding='utf-8') as f:
    text = f.read()

out = open(r'd:\bharatheeyamapp sample\all_events_rules.md', 'w', encoding='utf-8')

out.write("# Detailed Rule Analysis for All Muhurta Events\n\n")

sections = re.split(r'={80}\n', text)

keywords = {
    '1st house (Lagna)': ['लग्ने', 'प्रथम', 'तनु', 'उदय'],
    '7th house (Saptama)': ['सप्तम', 'जामित्र', 'अस्ते', 'dyuta'],
    '8th house (Ashtama)': ['अष्टम', 'मृतौ', 'रन्ध्र', 'निधन', 'मृत्यु'],
    '10th house (Dashama)': ['दशम', 'कर्म', 'व्यापार'],
    'Kendra (1,4,7,10)': ['केन्द्र'],
    'Trikona (5,9)': ['त्रिकोण'],
    'Malefics (Papa)': ['पाप', 'क्रूर', 'सूर्य', 'कुज', 'मन्द', 'शनि', 'राहु', 'केतु'],
    'Benefics (Shubha)': ['शुभ', 'सौम्य', 'गुरु', 'बुध', 'शुक्र', 'चन्द्र'],
    'Exceptions/Cancellation': ['परिहार', 'अपवाद', 'भङ्ग', 'मित्र', 'स्वोच्च', 'वर्गोत्तम'],
    'Gandanta': ['गण्डान्त', 'सन्धि']
}

for i in range(1, len(sections), 2):
    title = sections[i].strip()
    if 'VIVAHA' in title: continue # Already did Vivaha deeply
    if not title: continue
    
    content = sections[i+1]
    
    out.write(f"## {title}\n")
    
    # Check what keywords exist
    found_concepts = {}
    for conc, kws in keywords.items():
        if any(kw in content for kw in kws):
            found_concepts[conc] = True
            
    if '1st house (Lagna)' in found_concepts: out.write("- **Lagna (1st) Rules:** Mentioned.\n")
    if '7th house (Saptama)' in found_concepts: out.write("- **Saptama (7th) Rules:** Mentioned.\n")
    if '8th house (Ashtama)' in found_concepts: out.write("- **Ashtama (8th) Rules:** Mentioned.\n")
    if '10th house (Dashama)' in found_concepts: out.write("- **Dashama (10th) Rules:** Mentioned.\n")
    if 'Kendra (1,4,7,10)' in found_concepts: out.write("- **Kendra Rules:** Mentioned.\n")
    if 'Malefics (Papa)' in found_concepts: out.write("- **Malefic Rules:** Mentioned.\n")
    if 'Benefics (Shubha)' in found_concepts: out.write("- **Benefic Rules:** Mentioned.\n")
    if 'Exceptions/Cancellation' in found_concepts: out.write("- **Exceptions/Cancellations:** Mentioned.\n")

    # Extract all lines that might contain rules (containing shubha, papa, kendra, trikona, or house names)
    lines = content.split('\n')
    important = set()
    for j, l in enumerate(lines):
        if len(l.strip()) < 10: continue
        if any(kw in l for kw in ['लग्ने', 'सप्तम', 'अष्टम', 'दशम', 'केन्द्र', 'त्रिकोण', 'पाप', 'शुभ', 'वर्ज्य', 'परिहार']):
            important.add(l.strip())
            
    out.write("\n### Key Source Text Snippets:\n")
    for imp in list(important)[:15]: # Take first 15 unique rule lines
        out.write(f"> {imp}\n")
    out.write("\n---\n\n")

out.close()
print("Done writing to all_events_rules.md")
