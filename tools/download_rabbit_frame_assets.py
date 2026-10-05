"""Download the scoped VARCO outputs recorded for the whole-cel pilot."""
import concurrent.futures, hashlib, json, urllib.request
from pathlib import Path
from urllib.parse import urlparse
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'design/rabbit-frame-pilot-v2'
jobs=json.loads((WORK/'varco-walk-downloads-v2.json').read_text(encoding='utf8'))
expected={(stage,index) for stage in ['adult','baby'] for index in range(32)}
if len(jobs)!=64 or {(j['stage'],j['index']) for j in jobs}!=expected:
    raise ValueError('Expected exactly 32 unique frame slots per stage')

def download(j):
    url=urlparse(j['url'])
    if url.scheme!='https' or url.netloc!='3d.varco.ai' or not url.path.startswith('/api/objects/'):
        raise ValueError('Unexpected asset origin')
    target=WORK/'frames-walk-v2'/j['stage']/f"{j['index']:02d}.png"
    target.parent.mkdir(parents=True,exist_ok=True)
    with urllib.request.urlopen(j['url'],timeout=90) as response:
        raw=response.read()
    target.write_bytes(raw)
    with Image.open(target) as im:
        if im.format!='PNG' or im.width!=im.height: raise ValueError('Invalid square image')
        size=list(im.size); im.verify()
    return {'stage':j['stage'],'index':j['index'],'file':str(target.relative_to(ROOT)).replace('\\','/'),'size':size,'sha256':hashlib.sha256(raw).hexdigest(),'nodeId':j['imageNode'],'url':j['url']}

with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    records=list(pool.map(download,jobs))
records.sort(key=lambda r:(r['stage'],r['index']))
(WORK/'source-frame-records.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print(json.dumps({'downloaded':len(records),'stages':{s:sum(r['stage']==s for r in records) for s in ['adult','baby']}}))
