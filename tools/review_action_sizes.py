"""Compare existing rendered sprite footprints; never modifies game artwork."""
import json, sys
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np

folder=Path(sys.argv[1])
rows=json.loads((folder/'report.json').read_text())
actions=['idle','wander','carry','struggle','happy','angry','eat','drink','doze','relax','groom','stretch','dizzy']
stats=[]
for r in rows:
    im=Image.open(folder/r['file']).convert('RGBA')
    r['area']=float(np.asarray(im)[:,:,3].sum()/255)*r['scale']**2
for r in rows:
    base=next(x for x in rows if x['species']==r['species'] and x['stage']==r['stage'] and x['action']=='idle')
    r['linear_mass_ratio']=(r['area']/base['area'])**.5
    stats.append({k:r[k] for k in ['species','stage','action','linear_mass_ratio']})
for group in range(4):
    canvas=Image.new('RGB',(len(actions)*150,8*185),'#f4f0e9')
    draw=ImageDraw.Draw(canvas)
    for j,(species,stage) in enumerate(( (s,a) for s in range(group*4,group*4+4) for a in [0,2])):
        for i,action in enumerate(actions):
            r=next(x for x in rows if x['species']==species and x['stage']==stage and x['action']==action)
            im=Image.open(folder/r['file']).convert('RGBA')
            # Same camera and feet, 1.45x magnification for review only.
            scale=r['scale']*1.45
            im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
            px=i*150+75+round((r['position'][0]-128)*1.45)
            py=j*185+155+round((r['position'][1]-190)*1.45)
            canvas.paste(im,(px,py),im)
            draw.text((i*150+5,j*185+3),f'{species}/{stage} {action}',fill='#242424')
            draw.text((i*150+5,j*185+17),f"mass-size {r['linear_mass_ratio']:.2f}",fill='#464646')
            draw.line((i*150+5,j*185+155,i*150+145,j*185+155),fill='#c0b6a7')
    canvas.save(folder/f'comparison-{group}.jpg',quality=91)
(folder/'measurements.json').write_text(json.dumps(stats,indent=2))
print('Largest size mismatches:', sorted(stats,key=lambda r:abs(r['linear_mass_ratio']-1),reverse=True)[:12])
