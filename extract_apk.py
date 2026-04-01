import zipfile
import os
import sys

apk_path = os.path.expanduser(r"~\Downloads\org.srujanjha.amarkosh_2.6.apk")
extract_dir = os.path.join(os.getcwd(), "amarakosh_extracted")

if not os.path.exists(extract_dir):
    os.makedirs(extract_dir)

try:
    with zipfile.ZipFile(apk_path, 'r') as apk:
        # We only care about assets/ or res/raw/ for databases
        db_files = [f for f in apk.namelist() if f.startswith('assets/') or f.startswith('res/raw/')]
        for f in db_files:
            apk.extract(f, extract_dir)
            print(f"Extracted: {f}")
    print("Done extracting assets.")
except Exception as e:
    print(f"Error: {e}")
