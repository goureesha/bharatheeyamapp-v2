import sys
sys.stdout.reconfigure(encoding='utf-8')

extra_map = {
    'ಸೂರ್ಯ': 'सूर्य',
    'ಮಂಗಳ': 'मंगल',
    'ಗಂಟೆ': 'घंटे',
    'ನಿಮಿಷ': 'मिनट',
    'ಘಟಿ': 'घटी',
    'ಪ್ರದೋಷ ವ್ರತ': 'प्रदोष व्रत',
    'ಸ್ರೋತ': 'स्रोत',
    'ಆಕರ': 'स्रोत',
    'ಪುರಾಣ': 'पुराण',
    'ಸಿಂಧು': 'सिंधु',
    'ಗಣೇಶ ಪುರಾಣ': 'गणेश पुराण',
    'ಪದ್ಮ ಪುರಾಣ': 'पद्म पुराण',
    'ಸ್ಕಂದ ಪುರಾಣ': 'स्कंद पुराण',
    'ಭವಿಷ್ಯ ಪುರಾಣ': 'भविष्य पुराण',
    'ದತ್ತ ಪುರಾಣ': 'दत्त पुराण',
    'ಧರ್ಮಸಿಂಧು': 'धर्मसिंधु',
    'ನಿರ್ಣಯಸಿಂಧು': 'निर्णयसिंधु',
    'ಚೈತ್ರ ಮಾಸ': 'चैत्र मास',
    'ವೈಶಾಖ ಮಾಸ': 'वैशाख मास',
    'ಜ್ಯೇಷ್ಠ ಮಾಸ': 'ज्येष्ठ मास',
    'ಆಷಾಢ ಮಾಸ': 'आषाढ़ मास',
    'ಉದ್ವೇಗ': 'उद्वेग',
    'ಚಲ': 'चल',
    'ಲಾಭ': 'लाभ',
    'ಅಮೃತ': 'अमृत',
    'ಕಾಲ': 'काल',
    'ಶುಭ': 'शुभ',
    'ರೋಗ': 'रोग',
}

path = r'd:\bharatheeyamapp sample\lib\widgets\common.dart'
try:
    with open(path, 'r', encoding='utf-8-sig') as f:
        text = f.read()
except FileNotFoundError:
    print("common.dart not found")
    sys.exit(0)

lines = text.split('\n')
insert_idx = -1
for i, line in enumerate(lines):
    if 'ಮುಹೂರ್ತ ಸಮಯ' in line:
        insert_idx = i
        break

if insert_idx != -1:
    inserts = []
    for k, v in extra_map.items():
        if f"'{k}': " not in text:
            inserts.append(f"    '{k}': '{v}',")
    
    if inserts:
        lines.insert(insert_idx, '\n'.join(inserts))
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        print(f"Added {len(inserts)} extra mappings to common.dart")
    else:
        print("All extra mappings already in dictionary")
else:
    print("Could not find insert anchor")
