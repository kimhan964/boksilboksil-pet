"""Compare adjacent whole-cel continuity at identical 60-cel/1.5s timing."""
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design/rabbit-frame-pilot-v8'

def bank(version):
    folder=ROOT/f'design/rabbit-frame-pilot-v{version}'
    manifest=json.loads((folder/'manifest.json').read_text(encoding='utf8'))
    spec=manifest['stages']['adult']; atlas=Image.open(folder/'adult-walk.png').convert('RGBA')
    cells=[]; centroids=[]; top=[]; rendered=[]
    for i in range(60):
        im=atlas.crop((i%8*256,i//8*256,i%8*256+256,i//8*256+256));cells.append(im)
        phase=i/60;t=np.clip((phase-spec['launch_phase'])/(spec['land_phase']-spec['launch_phase']),0,1)
        lift=np.sin(t*np.pi)*spec['lift_canvas']
        a=np.array(im)[:,:,3]/255.; yy,xx=np.indices(a.shape)
        centroids.append([(xx*a).sum()/a.sum(),(yy*a).sum()/a.sum()-lift])
        top.append(im.getbbox()[1]-lift)
        canvas=Image.new('RGBA',(320,320));canvas.alpha_composite(im,(32,40-round(lift)));rendered.append(canvas)
    c=np.array(centroids);acc=np.roll(c,-1,axis=0)-2*c+np.roll(c,1,axis=0)
    tops=np.array(top); top_steps=np.abs(np.roll(tops,-1)-tops)
    # Silhouette displacement + deformation, not a perceptual quality score.
    mask=np.array([np.asarray(im.resize((80,80),Image.Resampling.LANCZOS))[:,:,3]/255. for im in rendered])
    changes=np.mean(np.abs(np.roll(mask,-1,axis=0)-mask),axis=(1,2))
    return dict(max_top_step_atlas_px=float(top_steps.max()),max_centroid_step_atlas_px=float(np.linalg.norm(np.roll(c,-1,axis=0)-c,axis=1).max()),centroid_acceleration_rms=float(np.sqrt(np.mean(acc**2))),silhouette_change_mean=float(changes.mean()),silhouette_change_max=float(changes.max()),worst_top_transition=[int(top_steps.argmax()),int((top_steps.argmax()+1)%60)]),rendered

before,old=bank(7);after,new=bank(8)
report=dict(before=before,after=after,limitations='Measures position/outline discontinuities; does not prove anatomy, identity or subjective naturalness.')
(OUT/'jitter-comparison.json').write_text(json.dumps(report,indent=2),encoding='utf8')
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',18);frames=[]
for i in range(60):
    canvas=Image.new('RGB',(640,365),'#fff8ed');d=ImageDraw.Draw(canvas)
    d.text((24,12),'수정 전 · 독립 생성 60장',font=font,fill='#523727');d.text((344,12),'수정 후 · 전신 보간 60장',font=font,fill='#523727')
    for x,im in [(0,old[i]),(320,new[i])]:canvas.paste(im,(x,35),im)
    d.line((25,307,295,307),fill='#cabca6');d.line((345,307,615,307),fill='#cabca6')
    frames.append(canvas)
durations=[round((i+1)*2.5)*10-round(i*2.5)*10 for i in range(60)]
frames[0].save(OUT/'before-after.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0)
print(json.dumps(report,indent=2))
