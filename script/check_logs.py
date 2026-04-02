import urllib.request
import json
import time

REPO = "goureesha/bharatheeyamapp"

def get_runs():
    try:
        ts = int(time.time())
        req = urllib.request.Request(f"https://api.github.com/repos/{REPO}/actions/runs?per_page=5&_={ts}")
        req.add_header('User-Agent', 'Mozilla/5.0')
        req.add_header('Cache-Control', 'no-cache')
        with urllib.request.urlopen(req) as response:
            runs = json.loads(response.read().decode())
            
        with open('latest_log_report.txt', 'w', encoding='utf-8') as f:
            f.write("Recent Runs:\n")
            for run in runs['workflow_runs'][:8]:
                f.write(f"- Run ID: {run['id']} - Name: {run['name']} - Status: {run['status']} - Conclusion: {run['conclusion']} - Commit: {run['head_commit']['message'][:60]}\n")
                if run['conclusion'] == 'failure':
                    req2 = urllib.request.Request(run['jobs_url'])
                    req2.add_header('User-Agent', 'Mozilla/5.0')
                    with urllib.request.urlopen(req2) as res2:
                        jobs = json.loads(res2.read().decode())
                    for job in jobs['jobs']:
                        if job['conclusion'] == 'failure':
                            f.write(f"  -> Job Failed: {job['name']}\n")
                f.write("\n")
                
    except Exception as e:
        with open('latest_log_report.txt', 'w', encoding='utf-8') as f:
            f.write(f"Error: {e}\n")

if __name__ == '__main__':
    get_runs()
