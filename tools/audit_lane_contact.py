"""Track the visible near sole through a complete image sequence, including wrap."""
import json,argparse
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
parser=argparse.ArgumentParser();parser.add_argument('--version',type=int,default=8);args=parser.parse_args()
ROOT=Path(__file__).resolve().parents[1];WORK=ROOT/f'design/walk-v{args.version}/otter-adult'
def sole(im):
    arr=np.asarray(im);mask=arr[:,:,3]>128;ys,xs=np.where(mask)
    bottom=int(ys.max());band=mask[max(0,bottom-3):bottom+1]
    yy,xx=np.where(band)
    return float(xx.mean()),bottom
atlas=Image.open(ROOT/f'assets/walk-v{args.version}/otter/adult.png').convert('RGBA')
points=[sole(atlas.crop((i%8*256,i//8*256,i%8*256+256,i//8*256+256))) for i in range(60)]
spec=json.loads((ROOT/f'assets/walk-v{args.version}/otter/manifest.json').read_text('utf8'))['stages']['adult']
offset=spec.get('source_phase_offset',0)
points=points[-offset:]+points[:-offset] if offset else points
stance=np.arange(0,35);x=np.array([p[0] for p in points]);y=np.array([p[1] for p in points])
fit=np.polyfit(stance/60,x[stance],1);stride=-float(fit[0]);residual=x[stance]+stride*stance/60
scale=110*.64/200
report=dict(near_sole_points=points,estimated_stride=stride,configured_stride=spec['stride'],stance_world_drift_px=float(np.ptp(residual))*scale,stance_vertical_drift_px=float(np.ptp(y[stance]))*scale,max_adjacent_sole_step_px=float(np.max(np.abs(np.roll(x,-1)-x)))*scale,near_foot_reversals_during_stance=[int(i) for i in range(34) if x[i+1]-x[i]>.75],limitations='Near visible sole measurement only. Not a far-foot anatomy or naturalness approval.')
(WORK/'contact-audit.json').write_text(json.dumps(report,indent=2),encoding='utf8')
sheet=Image.new('RGB',(1200,5*100),'#fff8ed');draw=ImageDraw.Draw(sheet)
for i in range(60):
    im=atlas.crop((i%8*256+80,i//8*256+196,i%8*256+190,i//8*256+240)).resize((100,60))
    dx=i%12*100;dy=i//12*100;sheet.paste(im,(dx,dy+20),im);draw.text((dx+4,dy+4),str(i),fill='#513d32')
sheet.save(WORK/'all-feet-review.png')
print(json.dumps({k:v for k,v in report.items() if k!='near_sole_points'},indent=2))
