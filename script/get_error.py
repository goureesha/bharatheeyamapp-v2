import urllib.request
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

REPO = "goureesha/bharatheeyamapp"
RUN_ID = "23859829893"

def get_error():
    # Get jobs for the run
    req = urllib.request.Request(f"https://api.github.com/repos/{REPO}/actions/runs/{RUN_ID}/jobs")
    req.add_header('User-Agent', 'Mozilla/5.0')
    with urllib.request.urlopen(req) as response:
        jobs = json.loads(response.read().decode())
    
    for job in jobs['jobs']:
        print(f"Job: {job['name']} - Conclusion: {job['conclusion']}")
        for step in job['steps']:
            if step['conclusion'] == 'failure':
                print(f"  FAILED Step: {step['name']}")
                print(f"  Number: {step['number']}")
        print()

if __name__ == '__main__':
    get_error()
