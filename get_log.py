import urllib.request
import json
import zipfile
import io

# Get latest failed run
req = urllib.request.Request(
    'https://api.github.com/repos/goureesha/bharatheeyamapp/actions/runs?per_page=1&status=failure',
    headers={'User-Agent': 'Mozilla/5.0'}
)
res = urllib.request.urlopen(req).read()
data = json.loads(res)
run_id = data['workflow_runs'][0]['id']

# Get logs URL
req2 = urllib.request.Request(
    f'https://api.github.com/repos/goureesha/bharatheeyamapp/actions/runs/{run_id}/logs',
    headers={'User-Agent': 'Mozilla/5.0'}
)
logs_res = urllib.request.urlopen(req2).read()

# The logs endpoint returns a ZIP file
with zipfile.ZipFile(io.BytesIO(logs_res)) as z:
    for name in z.namelist():
        if "Build" in name and ".txt" in name:
            with open("failed_build_log.txt", "wb") as f:
                f.write(z.read(name))
            print(f"Extracted {name} to failed_build_log.txt")
            break
