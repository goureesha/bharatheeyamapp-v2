import urllib.request
import json
url = 'https://api.github.com/repos/goureesha/bharatheeyamapp/actions/runs?per_page=5'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as res:
        data = json.loads(res.read())
        for r in data['workflow_runs']:
            print(f"ID: {r['id']}, Name: {r['name']}, Conclusion: {r['conclusion']}")
except Exception as e:
    print(e)
