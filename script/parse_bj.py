import json
import re

TEXT_FILE = r'd:\bharatheeyamapp sample\script\brihad_jataka.txt'
JSON_FILE = r'd:\bharatheeyamapp sample\assets\data\books.json'

def parse_text(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = [line.strip() for line in f if line.strip()]

    chapters = []
    current_chapter = None
    current_shloka = None

    for line in lines:
        if line.startswith('ಅಧ್ಯಾಯ'):
            # New chapter
            # e.g. "ಅಧ್ಯಾಯ ೧: ರಾಶಿಪ್ರಭೇದಾಧ್ಯಾಯಃ (Chapter 1)"
            parts = line.split(':', 1)
            chap_num_str = parts[0].replace('ಅಧ್ಯಾಯ', '').strip()
            title = parts[1].strip() if len(parts) > 1 else line
            
            # map kannada numerals roughly if needed, or just keep as is
            num_map = {'೧': '1', '೨': '2', '೩': '3', '೪': '4', '೫': '5', '೬': '6', '೭': '7', '೮': '8', '೯': '9', '೦': '0'}
            ch_id_num = ''.join([num_map.get(c, c) for c in chap_num_str])
            try:
                ch_val = int(ch_id_num)
            except:
                ch_val = len(chapters) + 1
            
            current_chapter = {
                "id": f"ch{ch_val}",
                "title": f"ಅಧ್ಯಾಯ {chap_num_str} : {title}",
                "shlokas": []
            }
            chapters.append(current_chapter)
            current_shloka = None
            
        elif line.startswith('ಶ್ಲೋಕ'):
            # New shloka - Sanskrit
            # e.g. "ಶ್ಲೋಕ ೧ मूर्तित्वे ..."
            match = re.match(r'ಶ್ಲೋಕ\s+([0-9೧-೯]+)(.*)', line)
            if match:
                shloka_num_str = match.group(1)
                sanskrit_text = match.group(2).strip()
                
                num_map = {'೧': '1', '೨': '2', '೩': '3', '೪': '4', '೫': '5', '೬': '6', '೭': '7', '೮': '8', '೯': '9', '೦': '0'}
                sh_id_num = ''.join([num_map.get(c, c) for c in shloka_num_str])
                
                if not current_chapter:
                    current_chapter = {
                        "id": "ch1",
                        "title": "ಅಧ್ಯಾಯ ೧",
                        "shlokas": []
                    }
                    chapters.append(current_chapter)
                    
                ch_num = current_chapter['id'].replace('ch', '')
                current_shloka = {
                    "id": f"{ch_num}.{sh_id_num}",
                    "sanskrit": sanskrit_text,
                    "kannada": "",
                    "translation": "",
                    "tags": ["astrology", "brihat_jataka"]
                }
                current_chapter['shlokas'].append(current_shloka)
        else:
            # Kannada text
            if current_shloka:
                if current_shloka["kannada"]:
                    current_shloka["kannada"] += "\n" + line
                else:
                    current_shloka["kannada"] = line

    return chapters

def update_json():
    chapters = parse_text(TEXT_FILE)
    
    with open(JSON_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for book in data.get('books', []):
        if book.get('id') == 'brihat_jataka':
            # Replace the chapters array
            book['chapters'] = chapters
            break
            
    with open(JSON_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully added {len(chapters)} chapters for Brihad Jataka.")
    for ch in chapters:
        print(f" - {ch['title']}: {len(ch['shlokas'])} shlokas")

if __name__ == '__main__':
    update_json()
