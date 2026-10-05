"""Measure existing walking drawings and current presentation corrections.
These metrics detect visual jumps; they do not certify anatomical correctness.
"""
from pathlib import Path
from PIL import Image, ImageChops
import json, statistics

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design/motion-reanalysis-2026-10-02'
OUT.mkdir(parents=True,exist_ok=True)
rows=[]
def cels(file,count):
    sheet=Image.open(file).convert('RGBA')
    return [sheet.crop((i*256,0,(i+1)*256,256)) for i in range(count)]
def bounds(cel): return cel.getchannel('A').getbbox()
def normalized(cel,reference,sx=None,anchor_x=128):
    b=bounds(cel);scale=reference/(b[3]-b[1]);sx=scale if sx is None else sx
    patch=cel.crop(b).resize((round((b[2]-b[0])*sx),round(reference)),Image.Resampling.BICUBIC)
    canvas=Image.new('RGBA',(320,256))
    canvas.alpha_composite(patch,(round(160+(b[0]-anchor_x)*sx),round(232-reference)))
    return canvas
def difference(a,b):
    a=a.getchannel('A').point(lambda p:255 if p>90 else 0)
    b=b.getchannel('A').point(lambda p:255 if p>90 else 0)
    union=ImageChops.lighter(a,b).histogram()[255]
    intersection=ImageChops.darker(a,b).histogram()[255]
    return 1-intersection/max(1,union)
def jumps(cels): return [difference(cels[i],cels[(i+1)%len(cels)]) for i in range(len(cels))]
for directory in sorted((ROOT/'assets/species-v3').iterdir()):
    if not directory.is_dir(): continue
    for stage in ['baby','adult']:
        idle=cels(directory/f'{stage}-idle.png',16)
        reference=sorted(bounds(c)[3]-bounds(c)[1] for c in idle)[8]
        original=cels(directory/f'{stage}-walk.png',16)
        raw=cels(ROOT/'assets/walk-v4'/directory.name/f'{stage}.png',32)
        corrected=[];ratios=[]
        for i,cel in enumerate(raw):
            b=bounds(cel);sy=reference/(b[3]-b[1]);sx=sy;anchor=128
            if i%2:
                a=bounds(original[i//2]);n=bounds(original[(i//2+1)%16])
                sa=reference/(a[3]-a[1]);sn=reference/(n[3]-n[1])
                width=((a[2]-a[0])*sa+(n[2]-n[0])*sn)/2
                center=(((a[0]+a[2])/2-128)*sa+((n[0]+n[2])/2-128)*sn)/2
                sx=width/(b[2]-b[0]);anchor=(b[0]+b[2])/2-center/sx
                ratios.append(sx/sy)
            corrected.append(normalized(cel,reference,sx,anchor))
        old_jumps=jumps([normalized(c,reference) for c in original])
        new_jumps=jumps(corrected)
        row={'species':directory.name,'stage':stage,'odd_frame_aspect_min':min(ratios),'odd_frame_aspect_max':max(ratios),'median_silhouette_jump_16':statistics.median(old_jumps),'median_silhouette_jump_32':statistics.median(new_jumps),'max_silhouette_jump_32':max(new_jumps)}
        rows.append(row)
        if directory.name=='rabbit':
            # Diagnostic playback only: it is not replacement game artwork.
            backgrounds=[]
            for cel in corrected:
                bg=Image.new('RGBA',cel.size,'#faf5e9');bg.alpha_composite(cel);backgrounds.append(bg.convert('RGB'))
            backgrounds[0].save(OUT/f'rabbit-{stage}-current.gif',save_all=True,append_images=backgrounds[1:],duration=round(1050/32),loop=0,disposal=2)
report={'method':'alpha silhouette overlap after current whole-cel normalization; no gait rotation; diagnostic only','rows':rows}
(OUT/'walk-consistency.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
for row in rows:
    if row['species']=='rabbit': print(json.dumps(row))
print('STAGE_BANKS=',len(rows),'BANKS_WITH_32_JUMP_WORSE=',sum(r['median_silhouette_jump_32']>r['median_silhouette_jump_16'] for r in rows))
print('ASPECT_RATIO_RANGE=',min(r['odd_frame_aspect_min'] for r in rows),max(r['odd_frame_aspect_max'] for r in rows))
