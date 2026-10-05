import argparse,json,hashlib
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
def premult(im):
    a=np.asarray(im.convert('RGBA'),dtype=float)/255
    return np.dstack((a[:,:,:3]*a[:,:,3:4],a[:,:,3]))
def assets():
    rows=[]
    for path in (ROOT/'design/hold-transitions-v1').glob('*/*/bake-review.json'):
        species=path.parent.parent.name;stage=path.parent.name
        for name,spec in json.loads(path.read_text()).items():
            im=Image.open(ROOT/'assets/hold-transitions-v1'/species/stage/f'{name}.png')
            cels=[premult(im.crop((i%8*256,i//8*256,i%8*256+256,i//8*256+256))) for i in range(17)]
            original=float(np.abs(cels[0]-cels[-1]).mean()); peak=max(float(np.abs(cels[i]-cels[i+1]).mean()) for i in range(16))
            rows.append({'species':species,'stage':stage,'bridge':name,'start_exact':spec['first_exact'],'end_exact':spec['last_exact'],'old_single_cut':original,'new_peak_step':peak,'peak_ratio':peak/max(original,1e-9)})
    report={'bridges':len(rows),'frames':len(rows)*17,'max_peak_ratio':max(r['peak_ratio'] for r in rows),'failures':[r for r in rows if not r['start_exact'] or not r['end_exact'] or r['peak_ratio']>=1],'results':rows}
    (ROOT/'design/hold-transitions-v1/asset-audit.json').write_text(json.dumps(report,indent=2))
    print('BRIDGE_ASSETS',report['bridges'],report['frames'],'max peak ratio',report['max_peak_ratio'],'failures',len(report['failures']))
def native(folder):
    report=json.loads((folder/'report.json').read_text());rows=[]
    for case in report['results']:
        blank=[]; clipped=[]; frames=case['frames']
        for f in frames:
            im=Image.open(folder/f['file']).convert('RGBA');b=im.getbbox()
            if not b:blank.append(f['file'])
            elif b[0]<=0 or b[1]<=0 or b[2]>=im.width or b[3]>=im.height:clipped.append(f['file'])
        entries=[f for f in frames if f['bank'] in ['hold-idle_entry','hold-carry_entry']]
        recovery=[f for f in frames if f['bank']=='hold-recover']
        leak=[f['time'] for f in frames if f['phase']=='drop' and not f['hold_visual']]
        checks={'entry':bool(entries) and 3.0<=entries[0]['time']<3.07,'recovery':bool(recovery),'ends_idle':frames[-1]['phase']=='idle','release_continues':not leak,'visible':not blank,'unclipped':not clipped}
        rows.append({'species':case['species'],'stage':case['stage'],'frames':len(frames),'checks':checks,'blank':blank,'clipped':clipped,'first_entry':entries[0]['time'] if entries else None})
    output={'banks':len(rows),'frames':sum(r['frames'] for r in rows),'failures':[r for r in rows if not all(r['checks'].values())],'results':rows}
    (folder/'audit.json').write_text(json.dumps(output,indent=2));print('BRIDGE_NATIVE',output['banks'],output['frames'],'failures',output['failures'])
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--native',type=Path);a=p.parse_args()
    if a.native:native(a.native)
    else:assets()
