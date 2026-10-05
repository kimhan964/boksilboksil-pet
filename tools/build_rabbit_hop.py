"""Pack reviewed, complete VARCO cels in authored chronology. No pose synthesis."""
import argparse,json,math,shutil,subprocess
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'design/rabbit-frame-pilot-v5'
OUT=ROOT/'assets/rabbit-frame-pilot-v5'
parser=argparse.ArgumentParser()
parser.add_argument('--node',default='node')
parser.add_argument('--mids',default='1,2,3,6')
args=parser.parse_args()
accepted={int(v) for v in args.mids.split(',') if v}
cells,records=[],[]
for i in range(1,16):
    cells.append(Image.open(WORK/'keys'/f'{i:02d}.png').convert('RGB'))
    records.append(dict(kind='key',source=i,phase=(i-1)/15))
    if i in accepted:
        cells.append(Image.open(WORK/'mids'/f'{i:02d}.png').convert('RGB').resize((512,512),Image.Resampling.LANCZOS))
        records.append(dict(kind='mid',source=i,phase=(i-.5)/15))
columns,rows=5,math.ceil(len(cells)/5)
sheet=Image.new('RGB',(columns*512,rows*512),'cyan')
for i in range(columns*rows):sheet.paste(cells[min(i,len(cells)-1)],(i%columns*512,i//columns*512))
sheet.save(WORK/'selected-source.png')
(WORK/'selected-frames.json').write_text(json.dumps(dict(frames=records,excluded_keys=[0],rejected_midpoints=sorted(set(range(1,16))-accepted)),indent=2))
subprocess.run([args.node,str(ROOT/'tools/pack_rabbit_whole_body.cjs'),str(WORK/'selected-source.png'),str(columns),str(rows),str(WORK/'packed-selected')],check=True)
OUT.mkdir(exist_ok=True)
shutil.copyfile(WORK/'packed-selected/atlas.png',OUT/'adult-walk.png')
shutil.copyfile(WORK/'packed-selected/00.png',OUT/'adult-idle.png')
manifest=dict(version=5,method='complete VARCO whole-body cels, reviewed chronological keys and midpoints, no rig or anatomical parts',canvas=[256,256],root=[128,232],stages=dict(adult=dict(reference_height=216,stride=24,cycle_seconds=1.5,locomotion='short_hop',launch_phase=.2,land_phase=.6,lift_canvas=12,sequences=dict(walk=dict(file='adult-walk.png',count=len(cells),columns=8,phases=[r['phase'] for r in records]),idle=dict(file='adult-idle.png',count=1,columns=1)))))
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
print(f'{len(cells)} complete cels, pending native visual review')
