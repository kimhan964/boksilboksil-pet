"""Validate real native game captures, not a standalone sprite viewer."""
import argparse,json
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('capture_root');p.add_argument('--expected-banks',type=int,default=30);p.add_argument('--output',default='design/walk-v5/native');p.add_argument('--report',default='walk-native-report.json');a=p.parse_args()
source=Path(a.capture_root);work=ROOT/a.output;work.mkdir(parents=True,exist_ok=True)
report=json.loads((source/a.report).read_text('utf8'))
results=[];gallery=Image.new('RGB',(1200,max(1,(len(report['results'])+1)//2)*150),'#fff8ed');gd=ImageDraw.Draw(gallery)
for row,bank in enumerate(report['results']):
    expected=bank.get('expected_walk_frames',60)
    expected_indices=bank.get('expected_indices',list(range(expected)))
    captures=bank['frames'];seen=set();scales=set();blank=[];clipped=[];frames=[]
    for c in captures:
        im=Image.open(source/c['file']).convert('RGBA');b=im.getbbox()
        if b is None:blank.append(c['file'])
        elif b[0]<=0 or b[1]<=0 or b[2]>=im.width or b[3]>=im.height:clipped.append(c['file'])
        if c['bank']=='walk':seen.add(c['index']);scales.add(tuple(abs(v) for v in c['scale']))
        bg=Image.new('RGBA',im.size,'#fff8ed');bg.alpha_composite(im)
        frames.append(bg.convert('RGB'))
    # Fixed viewport crop preserves actual travel and scale rather than tracking the sprite.
    contact=Image.new('RGB',(1280,4*180),'#fff8ed');draw=ImageDraw.Draw(contact)
    for j,target in enumerate([expected_indices[int(expected*i/8)] for i in range(8)]):
        idx=next((i for i,c in enumerate(captures) if c['index']==target and c['bank']=='walk'),0)
        im=frames[idx].crop((0,44,640,224));contact.paste(im,(j%2*640,j//2*180));draw.text((j%2*640+8,j//2*180+4),f"{bank['species']} {bank['stage']} cel {captures[idx]['index']}",fill='#513d32')
    name=bank['species']+'-'+bank['stage'];contact.save(work/(name+'-contact.png'))
    gif=[im.crop((100,44,570,224)) for im in frames[::2]]
    times=[max(10,round((captures[min(i+2,len(captures)-1)]['time']-captures[i]['time'])*1000)) for i in range(0,len(captures),2)]
    gif[0].save(work/(name+'.gif'),save_all=True,append_images=gif[1:],duration=times,loop=0)
    gx=row%2*600;gy=row//2*150
    gd.text((gx+8,gy+8),name,fill='#513d32')
    for j,target in enumerate([expected_indices[int(expected*i/4)] for i in range(4)]):
        idx=next((i for i,c in enumerate(captures) if c['index']==target),0)
        b=Image.open(source/captures[idx]['file']).getbbox()
        if b:
            center=(b[0]+b[2])//2
            gallery.paste(frames[idx].crop((center-90,44,center+90,224)).resize((120,120)),(gx+10+j*145,gy+25))
    result=dict(species=bank['species'],stage=bank['stage'],captures=len(captures),seen_frames=len(seen),expected_walk_frames=expected,playback_cycle_seconds=bank.get('playback_cycle_seconds'),missing=sorted(set(expected_indices)-seen),unexpected=sorted(seen-set(expected_indices)),blank=blank,clipped=clipped,scales=[list(s) for s in scales])
    result['pass']=not result['missing'] and not result['unexpected'] and not blank and not clipped and len(scales)==1
    results.append(result)
gallery.save(work/'all-species-contact.png')
summary=dict(renderer=report['renderer'],banks=len(results),captures=sum(r['captures'] for r in results),failures=[r for r in results if not r['pass']],results=results)
(work/'validation.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in summary.items() if k!='results'},indent=2))
assert len(results)==a.expected_banks and not summary['failures']
