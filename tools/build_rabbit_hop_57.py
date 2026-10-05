"""Pack 19 original cels plus two generated inbetweens for each cyclic interval."""
import argparse,json,math,shutil,subprocess
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'design/rabbit-frame-pilot-v6'
OUT=ROOT/'assets/rabbit-frame-pilot-v6'
parser=argparse.ArgumentParser()
parser.add_argument('--node',default='node')
args=parser.parse_args()
old=json.loads((ROOT/'assets/rabbit-frame-pilot-v5/manifest.json').read_text(encoding='utf8'))
phases=old['stages']['adult']['sequences']['walk']['phases']
assert len(phases)==19
cells,records=[],[]
for i,start in enumerate(phases):
    end=phases[i+1] if i+1<len(phases) else 1.0
    for third in range(3):
        source=WORK/('anchors' if third==0 else 'inbetweens')/(f'{i:02d}.png' if third==0 else f'{i:02d}-{third}.png')
        if not source.exists(): raise SystemExit(f'Missing generated cel: {source}')
        cells.append(Image.open(source).convert('RGB').resize((512,512),Image.Resampling.LANCZOS))
        records.append(dict(index=len(records),source=str(source.relative_to(ROOT)),interval=i,third=third,phase=start+(end-start)*third/3))
assert len(cells)==57
sheet=Image.new('RGB',(8*512,8*512),'cyan')
for i in range(64):sheet.paste(cells[min(i,56)],(i%8*512,i//8*512))
sheet.save(WORK/'selected-source.png')
(WORK/'selected-frames.json').write_text(json.dumps(dict(frames=records,padding_cells=7),indent=2),encoding='utf8')
subprocess.run([args.node,str(ROOT/'tools/pack_rabbit_whole_body.cjs'),str(WORK/'selected-source.png'),'8','8',str(WORK/'packed-selected'),'.5'],check=True)
# Preserve every old anchor byte-for-byte; adding frames must not resize/recolor it.
atlas=Image.new('RGBA',(2048,2048))
for i in range(57):
    dest=WORK/'packed-selected'/f'{i:02d}.png'
    if i%3==0:shutil.copyfile(ROOT/'design/rabbit-frame-pilot-v5/packed-selected'/f'{i//3:02d}.png',dest)
    cel=Image.open(dest).convert('RGBA')
    atlas.paste(cel,(i%8*256,i//8*256))
atlas.save(WORK/'packed-selected/atlas.png')
contact=Image.new('RGB',atlas.size,'#fff8ed');contact.paste(atlas,(0,0),atlas)
contact.save(WORK/'packed-selected/contact.png')
OUT.mkdir(exist_ok=True)
shutil.copyfile(WORK/'packed-selected/atlas.png',OUT/'adult-walk.png')
shutil.copyfile(WORK/'packed-selected/00.png',OUT/'adult-idle.png')
old.update(version=6,method='19 VARCO whole-body anchors plus 38 individually generated whole-body inbetweens, no rig or crossfade')
walk=old['stages']['adult']['sequences']['walk']
walk.update(count=57,phases=[r['phase'] for r in records])
(OUT/'manifest.json').write_text(json.dumps(old,ensure_ascii=False,indent=2),encoding='utf8')
print('57 complete cels, unchanged cycle duration, pending native visual review')
