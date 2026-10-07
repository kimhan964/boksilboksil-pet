import json, statistics
from pathlib import Path
for path in sorted(Path('builds/general-walk-profile').glob('*.json')):
 data=json.loads(path.read_text())
 samples=data['samples'][60:]
 deltas=sorted(s['dt'] for s in samples)
 current=longest=0
 for s in samples:
  if abs(s['dx'])<.001: current+=s['dt']
  else: longest=max(longest,current);current=0
 print(path.stem,'species',data['species'],'fps',round(1/statistics.median(deltas),1),'p95_ms',round(deltas[int(len(deltas)*.95)]*1000,2),'stationary_fraction',round(sum(abs(s['dx'])<.001 for s in samples)/len(samples),3),'longest_stop',round(longest,3))
