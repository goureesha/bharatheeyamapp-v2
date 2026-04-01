import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import fitz
doc = fitz.open(r'C:\Users\goure\Downloads\Muhurta Chintamani - Kedar Datt Joshi_text.pdf')

out = open(r'd:\bharatheeyamapp sample\mc_lagna_rules.txt', 'w', encoding='utf-8')

# Key pages for each ceremony's lagna rules
sections = {
    'VIVAHA LAGNA': [413, 417, 418, 419, 422, 423, 424, 425, 426, 441, 443, 456, 457, 458, 459, 460, 462, 463, 464, 465, 470, 471, 472, 473, 475, 476, 477],
    'UPANAYANA LAGNA': [315, 319, 329, 332, 333, 337, 343, 345],
    'NAMAKARANA LAGNA': [292, 301],
    'ANNAPRASHANA LAGNA': [301, 302, 303, 304, 305],
    'SEEMANTA LAGNA': [286, 287, 288, 289, 292],
    'CHOWLA/CHUDAKARANA LAGNA': [314, 315, 319, 329],
    'GRIHA PRAVESHA LAGNA': [598, 622, 638, 643, 644, 647],
    'YATRA LAGNA': [47, 48, 49, 100, 137, 160],
    'GENERAL LAGNA SHUDDHI': [31, 32, 33, 34, 35, 39, 42, 43, 46, 47, 48],
}

for section, pages in sections.items():
    out.write(f'\n{"="*80}\n')
    out.write(f'{section}\n')
    out.write(f'{"="*80}\n\n')
    for pg in pages:
        text = doc[pg-1].get_text()
        lines = text.split('\n')
        relevant = []
        for j, line in enumerate(lines):
            if any(kw in line for kw in ['लग्न', 'शुद्ध', 'अष्टम', 'सप्तम', 'राशि', 'केन्द्र', 'त्रिकोण', 'पाप', 'शुभ', 'गुरु', 'मेष', 'वृष', 'मिथुन', 'कर्क', 'सिंह', 'कन्या', 'तुला', 'वृश्चिक', 'धनु', 'मकर', 'कुम्भ', 'मीन']) and len(line.strip()) > 10:
                start = max(0, j-2)
                end = min(len(lines), j+3)
                for k in range(start, end):
                    if lines[k].strip():
                        relevant.append(lines[k])
                relevant.append('')
        if relevant:
            out.write(f'--- Page {pg} ---\n')
            for r in relevant:
                out.write(r + '\n')
            out.write('\n')

out.close()
print('Done! Extracted to mc_lagna_rules.txt')
