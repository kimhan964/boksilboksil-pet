"""Inspect all final raster cels and native-size foot motion; never edit art."""
import argparse,json,hashlib
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--stage',default='adult');p.add_argument('--build',default='balanced-build');a=p.parse_args()
work=ROOT/'design/walk-v13/koala'/a.stage/a.build
report=json.loads((work/'validation.json').read_text('utf8'))
manifest=json.loads((ROOT/'assets/walk-v13/koala/manifest.json').read_text('utf8'))
spec=manifest['stages'][a.stage];atlas=Image.open(ROOT/'assets/walk-v13/koala'/spec['file']).convert('RGBA')
scale=110*.72*(.93 if a.stage=='baby' else 1)/spec['reference_height']
feet=np.asarray(report['sole_tracks']);supports=[];swings=[]
for start,side in [(0,1),(30,0)]:
 xy=feet[start:start+30,side];world=(xy[:,0]+spec['stride']*np.arange(30)/60)*scale
 supports.append(dict(side=side,world_horizontal_range_px=float(np.ptp(world)),vertical_range_px=float(np.ptp(xy[:,1])*scale)))
for start,side in [(0,0),(30,1)]:
 phase=(np.arange(31)+start)%60;xy=feet[phase,side];world=(xy[:,0]+spec['stride']*np.arange(31)/60)*scale;travel=world-world[0]
 swings.append(dict(side=side,total_forward_px=float(travel[-1]),first_half_fraction=float(travel[15]/travel[-1]),max_clearance_px=float(np.max(feet[phase,1-side,1]-xy[:,1])*scale),worst_four_cel_backtrack_px=float(np.min(travel[4:]-travel[:-4]))))
board=Image.new('RGB',(1600,660),'#fff8ed');draw=ImageDraw.Draw(board);head_width=[];head_area=[]
for i in range(60):
 x=i%8*256;y=i//8*256;cel=atlas.crop((x,y,x+256,y+256));mask=np.asarray(cel)[:,:,3]>128
 ys,xs=np.where(mask[:145]);head_width.append(int(xs.max()-xs.min()));head_area.append(int(mask[:145].sum()))
 foot=cel.crop((48,198,208,250));gx=i%10*160;gy=i//10*110;board.paste(foot,(gx,gy+24),foot);draw.text((gx+4,gy+4),str(i),fill='#513d32')
board.save(work/'all-60-feet.png')
summary=dict(stage=a.stage,frames=60,source_keys=report['source_keys'],distinct=report['distinct'],support=supports,swing=swings,head_width_range_atlas=[min(head_width),max(head_width)],head_area_range=[min(head_area),max(head_area)],limitations='Sole-silhouette centroid changes with toe rotation; these are diagnostics, not a naturalness verdict. Inspect native playback and every cel.')
(work/'gait-detail.json').write_text(json.dumps(summary,indent=2),encoding='utf8');print(json.dumps(summary,indent=2))
