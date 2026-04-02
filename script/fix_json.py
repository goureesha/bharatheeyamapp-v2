import json

JSON_FILE = r'd:\bharatheeyamapp sample\assets\data\books.json'

def fix_json():
    with open(JSON_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for book in data.get('books', []):
        if book.get('id') == 'brihat_jataka':
            ch_idx = 1
            for ch in book.get('chapters', []):
                sh_idx = 1
                for sh in ch.get('shlokas', []):
                    # fix ID numbering sequentially to avoid numeral mapping issues
                    sh['id'] = f"{ch_idx}.{sh_idx}"
                    
                    # Also clean up the sanskrit text if the numeral was left behind
                    # e.g., "० गोऽजा..."
                    # We can leave the sanskrit text mostly intact to avoid destroying meaning,
                    # but strip leading stray devanagari numerals
                    # Actually standardizing the ID is the primary issue.
                    
                    sh_idx += 1
                ch_idx += 1
            break
            
    with open(JSON_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
    print("Fixed JSON IDs successfully.")

if __name__ == '__main__':
    fix_json()
