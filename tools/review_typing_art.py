"""Read-only asset QA and contact sheets from Godot window captures."""
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'builds/typing-review/all-art'
IDS=['rabbit','otter','squirrel','hedgehog','raccoon','fox','bear','owl','cat','puppy','hamster','panda','red_panda','lamb','koala','penguin']
rows=[]
for i,name in enumerate(IDS):
    directory=ROOT/'assets'/('typing-rabbit-v1' if i==0 else 'typing-animals-v1/'+name)
    frames=[Image.open(directory/(pose+'.png')).convert('RGBA') for pose in ['idle','left','right']]
    assert len({frame.size for frame in frames})==1
    assert all(frame.getchannel('A').getextrema()==(0,255) for frame in frames)
    bboxes=[]
    small=[]
    for frame in frames:
        bboxes.append(frame.getchannel('A').point(lambda a:255 if a>128 else 0).getbbox())
        bg=Image.new('RGBA',frame.size,'#f7f4ee')
        bg.alpha_composite(frame)
        small.append(np.asarray(bg.convert('RGB').resize((200,200),Image.Resampling.LANCZOS)).astype(float))
    # Upper half excludes hands; catches resizing/reframing in facial features.
    errors=[float(np.abs(small[0][:100]-a[:100]).mean()) for a in small[1:]]
    drift=max(abs(bboxes[0][j]-b[j]) for b in bboxes[1:] for j in range(4))
    rows.append(dict(species=name,size=frames[0].size,opaque_bounds=bboxes,bounds_drift_source_px=drift,upper_half_rgb_mae_at_200px=errors))
for page in range(2):
    sheet=Image.new('RGB',(1320,980),'#f7f4ee')
    draw=ImageDraw.Draw(sheet)
    for j in range(8):
        species=page*8+j
        x=(j%2)*660
        y=(j//2)*245
        draw.text((x+12,y+8),IDS[species]+'    idle / left / right',fill='#4e4238')
        for pose in range(3):
            capture=Image.open(OUT/f'{species:02d}-{pose}.png').convert('RGBA')
            sheet.paste(capture,(x+pose*220,y+26),capture)
    sheet.save(OUT/f'poses-{page+1}.jpg',quality=94)

cover=Image.new('RGB',(960,1024),'#f7f4ee')
draw=ImageDraw.Draw(cover)
for i,name in enumerate(IDS):
    x=(i%4)*240
    y=(i//4)*256
    capture=Image.open(OUT/f'{i:02d}-0.png').convert('RGBA')
    cover.paste(capture,(x+10,y+12),capture)
    draw.text((x+16,y+235),name,fill='#4e4238')
cover.save(OUT/'all-16.jpg',quality=94)
(OUT/'asset-qa.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(json.dumps(rows,indent=2))
