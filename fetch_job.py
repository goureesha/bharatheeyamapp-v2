import urllib.request
import json
import io
import sys

# Windows console encoding fix
sys.stdout.reconfigure(encoding='utf-8')

run_id = '23907249120'
url = f'https://api.github.com/repos/goureesha/bharatheeyamapp/actions/runs/{run_id}/jobs'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as res:
        data = json.loads(res.read())
        for job in data['jobs']:
            print(job['name'], job['conclusion'])
            if job['conclusion'] == 'failure':
                # We can't download logs without auth, so we just mention the URL
                print(f"Failed job: {job['html_url']}")
                job_id = job['id']
                log_url = f"https://api.github.com/repos/goureesha/bharatheeyamapp/actions/jobs/{job_id}/logs"
                print(f"Fetch logs manually from: {log_url} with GITHUB_TOKEN if needed")
except Exception as e:
    print(e)
