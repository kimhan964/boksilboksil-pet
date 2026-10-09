"""Verify complete cels, alpha margins, timing counts and calibrated bridge ends."""
import hashlib,json
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
rows=[]
for path in sorted((root/'assets/wardrobe-motion-v3').glob('*/adult/manifest.json')):
    data=json.loads(path.read_text());count=0
    assert set(data['styles'])=={'vest','knit','apron'},path
    for style,banks in data['styles'].items():
        for bank,spec in banks.items():
            with Image.open(path.parent/spec['file']) as im:
                im=im.convert('RGBA');side=spec.get('cell_size',256);cols=spec['columns'];n=spec['count']
                assert im.size==(side*cols,side*((n+cols-1)//cols)),(path,bank,'layout')
                assert hashlib.sha256(im.tobytes()).hexdigest()==spec['sha256'],(path,bank,'hash')
                if bank in ['walk','struggle']:assert n==60,(path,bank,'frame count')
                if bank.startswith('hold-'):assert n==17 and spec['first_exact'] and spec['last_exact'],(path,bank,'bridge')
                for i in range(n):
                    cel=im.crop((i%cols*side,i//cols*side,(i%cols+1)*side,(i//cols+1)*side));box=cel.getbbox()
                    assert box and min(box[:2])>1 and max(box[2:])<side-1,(path,bank,i,'clipping')
                    assert cel.getextrema()[3]==(0,255),(path,bank,i,'alpha')
                count+=n
    rows.append({'species':data['species'],'styles':len(data['styles']),'cels':count})
report={'scope':'structural assets; visual anatomy needs separate review','species':rows,'total_cels':sum(r['cels'] for r in rows)}
out=root/'builds/wardrobe-v3-native/asset-check.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,indent=2))
print(json.dumps(report))
