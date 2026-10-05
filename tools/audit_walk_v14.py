"""Review contact sheets and discontinuity metrics; not a naturalness verdict."""
from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,hashlib
root=Path(__file__).resolve().parents[1]/'design/walk-v14'
results=[]
for species in sorted((root/'candidates').iterdir()):
    manifest=json.loads((species/'manifest.json').read_text())
    gallery=Image.new('RGB',(8*180,2*205),'#fff8ed');draw=ImageDraw.Draw(gallery)
    for row,(age,spec) in enumerate(sorted(manifest['stages'].items())):
        atlas=Image.open(species/spec['file'])
        frames=[atlas.crop((i%8*256,i//8*256,i%8*256+256,i//8*256+256)) for i in range(60)]
        areas=np.array([(np.array(f)[:,:,3]>128).sum() for f in frames])
        delta=np.abs(np.roll(areas,-1)-areas)/areas
        assert areas.min()>0
        clipped=[i for i,f in enumerate(frames) if min(f.getbbox()[:2])<=0 or max(f.getbbox()[2:])>=256]
        assert not clipped
        distinct=len({hashlib.sha256(f.tobytes()).hexdigest() for f in frames})
        assert distinct==60
        results.append(dict(species=species.name,stage=age,frames=60,distinct=distinct,source_keys=spec['source_key_count'],max_area_step_percent=round(float(delta.max()*100),3),max_area_step_at=int(delta.argmax()),stride=spec['stride'],cycle=spec['cycle_seconds'],clipped=clipped))
        for col,i in enumerate([0,7,15,22,30,37,45,52]):
            f=frames[i].resize((180,180));gallery.paste(f,(col*180,row*205+20),f)
            draw.text((col*180+5,row*205+5),f'{age} {i}',fill='black')
    gallery.save(root/species.name/'final-review.jpg')
(root/'atlas-audit.json').write_text(json.dumps(results,indent=2))
print(json.dumps(dict(banks=len(results),cels=sum(r['frames'] for r in results),max_area_step_percent=max(r['max_area_step_percent'] for r in results)),indent=2))
