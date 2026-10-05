"""Review the installed game's captures; composites retain native window positions."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'design/rabbit-actions-v9'
results={}
for action in ['drink','eat','idle']:
    folder=WORK/'native'/action
    data=json.loads((folder/'rabbit-frame-playback-report.json').read_text('utf8'))
    assert data['asset_version']==9 and data['action']==action
    captures=data['captures']; frames=[]; blank=[]; clipped=[]; seen=set(); scales=set()
    for c in captures:
        im=Image.open(folder/c['file']).convert('RGBA'); b=im.getbbox()
        if not b: blank.append(c['file'])
        elif b[0]<=0 or b[1]<=0 or b[2]>=im.width or b[3]>=im.height: clipped.append(c['file'])
        if c['bank']==action: seen.add(c['index']);scales.add(tuple(c['scale']))
        canvas=Image.new('RGBA',im.size,'#fff8ed')
        if action=='drink':
            pond=Image.open(folder/'rabbit-frame-playback/pond.png').convert('RGBA')
            offset=tuple(round(c['pond_origin'][i]-c['window_origin'][i]) for i in range(2))
            canvas.alpha_composite(pond,offset)
        canvas.alpha_composite(im)
        # Exact same viewport crop for all captured moments.
        frames.append(canvas.crop((290,62,530,218)).convert('RGB'))
    sample_indices=[min(range(len(captures)),key=lambda i:abs(captures[i]['time']-t)) for t in [0.15,.85,1.6,2.5,3.3,4.35,5.2,5.7]]
    contact=Image.new('RGB',(4*240,2*182),'#fff8ed'); draw=ImageDraw.Draw(contact)
    for j,i in enumerate(sample_indices):
        x=j%4*240;y=j//4*182
        contact.paste(frames[i],(x,y));draw.text((x+8,y+158),f"{captures[i]['time']:.2f}s  {captures[i]['bank']} {captures[i]['index']}",fill='#513d32')
    contact.save(WORK/f'{action}-native-contact.png')
    gif=[frames[i] for i in range(0,len(frames),2)]
    durations=[max(10,round((captures[min(i+2,len(captures)-1)]['time']-captures[i]['time'])*1000)) for i in range(0,len(frames),2)]
    gif[0].save(WORK/f'{action}-native.gif',save_all=True,append_images=gif[1:],duration=durations,loop=0)
    results[action]=dict(captures=len(captures),seen_frames=len(seen),uncaptured_frames=sorted(set(range(60))-seen),blank=blank,clipped=clipped,scales=list(scales),returned_idle=captures[-1]['bank']=='idle',errors=(folder/'run-errors.log').read_text('utf8').strip())
    assert not blank and not clipped and len(scales)==1 and results[action]['returned_idle'] and not results[action]['errors']
(WORK/'native-validation.json').write_text(json.dumps(results,indent=2),encoding='utf8')
print(json.dumps(results,indent=2))
