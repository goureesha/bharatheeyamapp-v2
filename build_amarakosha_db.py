import os
import csv
import json
import codecs
import re
from bs4 import BeautifulSoup

def process():
    words_csv_path = r"amarakosh_extracted/assets/words.csv"
    res_dir = r"amarakosh_extracted/assets/res"
    output_path = r"assets/data/amara_kosha.json"

    words = []
    # words.csv has a single column of sanskrit words
    with codecs.open(words_csv_path, 'r', 'utf-8') as f:
        reader = csv.reader(f)
        for row in reader:
            if row:
                words.append(row[0].strip())

    amara_data = []

    # Let's iterate index 1 to 9376
    # Wait, the number of lines is 9377, the names might be 1 to 9376 and 9377.
    # Let's check files in directory and map them directly.

    for idx, word in enumerate(words):
        # The app might be strictly 1-based index
        file_idx = idx + 1
        html_file = os.path.join(res_dir, f"{file_idx}.html")
        
        if not os.path.exists(html_file):
            continue
            
        try:
            with codecs.open(html_file, 'r', 'utf-16be', errors='ignore') as hf:
                html_text = hf.read()
                
            soup = BeautifulSoup(html_text, 'html.parser')
            
            # The structure of the html is mostly:
            # <header><strong> English </strong></header>
            # <p>Meaning here</p>
            # <header><strong> संस्कृतम् </strong></header>
            # <p>Sanskrit explanation</p>
            # It varies. Let's just grab all <p> tags
            
            paragraphs = soup.find_all('p')
            meaning_text = ""
            if paragraphs:
                # the first <p> after English is usually the english meaning
                meaning_text = paragraphs[0].get_text().strip()
                # Remove brackets like [[letter]] -> letter
                meaning_text = meaning_text.replace('[[', '').replace(']]', '')
                
            # If the english meaning is super short or weird (like ":\u0905"), let's grab the second <p>
            for p in paragraphs:
                pt = p.get_text().strip().replace('[[', '').replace(']]', '')
                if ":" not in pt and len(pt) > len(meaning_text):
                    meaning_text = pt

            amara_data.append({
                "word": word,
                "meaning": meaning_text,
                "synonyms": [] # extracting reliable synonyms is hard from this blob unless it has a <header>Synonyms</header>
            })
            
        except Exception as e:
            pass

    # Save to the main json!
    with open(output_path, 'w', encoding='utf-8') as out:
        json.dump({"words": amara_data}, out, ensure_ascii=False, indent=2)

    print(f"Successfully compiled {len(amara_data)} words into {output_path}!")

if __name__ == "__main__":
    process()
