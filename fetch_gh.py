import urllib.request
import json
import sys

url = 'https://api.github.com/repos/goureesha/bharatheeyamapp/actions/runs?per_page=1'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as res:
        data = json.loads(res.read())
        run = data['workflow_runs'][0]
        with open('github_status.txt', 'w', encoding='utf-8') as f:
            f.write(f"Run ID: {run['id']}, Status: {run['status']}, Conclusion: {run['conclusion']}\n")
        
        jobs_url = run['jobs_url']
        req2 = urllib.request.Request(jobs_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req2) as res2:
            jobs_data = json.loads(res2.read())
            with open('github_status.txt', 'a', encoding='utf-8') as f:
                for job in jobs_data['jobs']:
                    f.write(f"Job: {job['name']}, Conclusion: {job['conclusion']}, URL: {job['html_url']}\n")
except Exception as e:
    with open('github_status.txt', 'w', encoding='utf-8') as f:
        f.write(str(e))
