"""Review grids and measurable atlas/native playback checks for held gestures."""
import argparse,hashlib,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
IDS='rabbit otter squirrel hedgehog raccoon fox bear owl cat puppy hamster panda red_panda lamb koala penguin'.split()
def atlases():
    rows=[]; failures=[]
    for species in IDS:
        folder=ROOT/'assets/struggle-v1'/species
        meta=json.loads((folder/'manifest.json').read_text())
        for stage in ['adult','baby']:
            atlas=Image.open(folder/f'{stage}.png').convert('RGBA')
            cels=[atlas.crop((i%8*256,i//8*256,i%8*256+256,i//8*256+256)) for i in range(60)]
            distinct=len({hashlib.sha256(im.tobytes()).hexdigest() for im in cels})
            diffs=[float(np.abs(np.array(cels[i],dtype=float)-np.array(cels[(i+1)%60],dtype=float)).mean()) for i in range(60)]
            bad=[i for i,im in enumerate(cels) if not im.getbbox() or min(im.getbbox()[:2])<=2 or max(im.getbbox()[2:])>=254]
            if distinct!=60 or bad: failures.append([species,stage,distinct,bad])
            rows.append({'species':species,'stage':stage,'frames':60,'distinct':distinct,'clipped':bad,'loop_pixel_delta':diffs[-1],'max_adjacent_pixel_delta':max(diffs),'cycle_seconds':meta['stages'][stage]['cycle_seconds']})
    for page in range(4):
        canvas=Image.new('RGB',(1152,8*148),'#fff8ed'); draw=ImageDraw.Draw(canvas)
        for line in range(8):
            species=IDS[page*4+line//2]; stage=['adult','baby'][line%2]
            atlas=Image.open(ROOT/'assets/struggle-v1'/species/f'{stage}.png').convert('RGBA')
            for col,i in enumerate([0,7,15,22,30,37,45,52,59]):
                im=atlas.crop((i%8*256,i//8*256,i%8*256+256,i//8*256+256)).resize((128,128))
                canvas.paste(im,(col*128,line*148+20),im)
                draw.text((col*128+3,line*148+3),f'{species} {stage} {i}',fill='#302820')
        canvas.save(ROOT/f'design/struggle-v1/review-{page+1}.png')
    report={'banks':len(rows),'frames':sum(r['frames'] for r in rows),'failures':failures,'results':rows}
    (ROOT/'design/struggle-v1/atlas-audit.json').write_text(json.dumps(report,indent=2))
    print('ATLAS',report['banks'],report['frames'],'failures',failures)
def native(folder):
    report=json.loads((folder/'report.json').read_text()); failures=[]; rows=[]
    for case in report['results']:
        frames=case['frames']; active=[f for f in frames if f['struggling']]
        first=min((f['time'] for f in active),default=0)
        blank=[];clipped=[]
        for f in frames:
            im=Image.open(folder/f['file']).convert('RGBA'); box=im.getbbox()
            if not box: blank.append(f['file'])
            elif box[0]<=0 or box[1]<=0 or box[2]>=im.width or box[3]>=im.height: clipped.append(f['file'])
        scales={tuple(round(abs(v),6) for v in f['scale']) for f in active}
        bad=(not 3.0<=first<=3.07 or len(scales)!=1 or blank or clipped or any(f['struggling'] for f in frames if f['time']>6.01) or any(f['bank']!='struggle-v1' for f in active))
        row={'species':case['species'],'stage':case['stage'],'input':case['input'],'first_protest':first,'frames':len(frames),'unique_protest_scales':len(scales),'blank':blank,'clipped':clipped}
        rows.append(row)
        if bad: failures.append(row)
    (folder/'audit.json').write_text(json.dumps({'cases':len(rows),'frames':sum(r['frames'] for r in rows),'failures':failures,'results':rows},indent=2))
    print('NATIVE cases',len(rows),'failures',failures)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--native',type=Path);a=p.parse_args()
    if a.native:native(a.native)
    else:atlases()
