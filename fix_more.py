import sys, re
sys.stdout.reconfigure(encoding='utf-8')

with open(r'd:\bharatheeyamapp sample\lib\core\events.dart', 'r', encoding='utf-8-sig') as f:
    text = f.read()

sources = re.findall(r"source:\s*'([^']+)'", text)
sources = list(set(sources))

# Manual additions that were missed
missing_dict = {
    'ಸೂರ್ಯ': 'सूर्य',
    'ಮಂಗಳ': 'मंगल',
    'ಗಂಟೆ': 'घंटे',
    'ನಿಮಿಷ': 'मिनट',
    'ಘಟಿ': 'घटी',
    'ಸ್ರೋತ': 'स्रोत',
}

# Assume sources are Kannada if they contain kannada char
k_pat = re.compile(r'[\u0C80-\u0CFF]')
for s in sources:
    if k_pat.search(s):
        # We need to translate these sources. I will just hardcode the known ones since there aren't many
        if 'ಸ್ಕಂದ ಪುರಾಣ' in s: missing_dict[s] = 'स्कंद पुराण'
        elif 'ಧರ್ಮ ಸಿಂಧು' in s: missing_dict[s] = 'धर्म सिंधु'
        elif 'ನಿರ್ಣಯ ಸಿಂಧು' in s: missing_dict[s] = 'निर्णय सिंधु'
        elif 'ಪುರಾಣ' in s: missing_dict[s] = s.replace('ಪುರಾಣ', 'पुराण')
        elif 'ಆಗಮ' in s: missing_dict[s] = s.replace('ಆಗಮ', 'आगम')
        elif 'ಶಾಸ್ತ್ರ' in s: missing_dict[s] = s.replace('ಶಾಸ್ತ್ರ', 'शास्त्र')
        else: missing_dict[s] = s # fallback if unknown

# We'll see what prints
print("Missing dictionary entries:")
for k, v in missing_dict.items():
    print(f"    '{k}': '{v}',")
