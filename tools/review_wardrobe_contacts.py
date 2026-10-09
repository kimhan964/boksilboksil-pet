"""Create visual QA grids from the baked full-body cels, never alter runtime art."""
import argparse,json
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('species',nargs='+');args=p.parse_args()
for species in args.species:
    folder=root/f'assets/wardrobe-motion-v3/{species}/adult'
    data=json.loads((folder/'manifest.json').read_text())
    canvas=Image.new('RGB',(1440,1008),'#fff8ed');draw=ImageDraw.Draw(canvas)
    for row,(bank,indices) in enumerate([('walk',[0,7,15,22,30,37,45,52]),('struggle',[0,7,15,22,30,37,45,52]),('hold-idle_entry',[0,2,4,6,8,10,13,16]),('hold-release2',[0,2,4,6,8,10,13,16])]):
        draw.text((8,row*252+2),species+' / '+bank,fill='#304b40')
        for k,style in enumerate(['vest','knit','apron']):
            spec=data['styles'][style][bank];s=spec.get('cell_size',256);im=Image.open(folder/spec['file']).convert('RGBA')
            for j,index in enumerate(indices):
                cell=im.crop((index%8*s,index//8*s,(index%8+1)*s,(index//8+1)*s)).resize((120,120),Image.Resampling.LANCZOS)
                canvas.paste(cell,(k*480+j%4*120,row*252+12+j//4*120),cell)
    out=root/f'builds/wardrobe-v3-native/{species}/motion-review.jpg';out.parent.mkdir(parents=True,exist_ok=True);canvas.save(out,quality=94)
    print(species,'review grid ready')
