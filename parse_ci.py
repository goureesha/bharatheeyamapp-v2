import json
f = open(r'C:\Users\goure\.gemini\antigravity\brain\b1effb56-c83f-461a-8e01-cfee753e70f2\.system_generated\steps\3644\content.md','r',encoding='utf-8').read()
idx = f.find('{')
data = json.loads(f[idx:].strip())
for job in data.get('jobs',[]):
    name = job["name"]
    conc = job["conclusion"]
    print(f"Job: {name} status={conc}")
    for step in job.get('steps',[]):
        if step.get('conclusion') == 'failure':
            sname = step["name"]
            print(f"  FAILED step: {sname}")
