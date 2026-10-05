"""Review every sole cel and estimate planted-foot drift in screen pixels.

Measurements are silhouette evidence, not a naturalness approval. Source tracks
retain pre-rotation key order; the contact atlas uses the manifest phase offset.
"""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--species',required=True);p.add_argument('--version',type=int,default=12);p.add_argument('--height',type=float,required=True);p.add_argument('--stage',choices=['baby','adult'])
p.add_argument('--asset-dir',type=Path,help='Inspect an uninstalled candidate bank')
p.add_argument('--work-dir',type=Path,help='Candidate build directory; requires --stage')
p.add_argument('--output',type=Path,help='Separate support report for a candidate')
a=p.parse_args()
if a.work_dir and not a.stage:p.error('--work-dir requires --stage')
folder=ROOT/f'design/walk-v{a.version}/{a.species}'
asset=a.asset_dir.resolve() if a.asset_dir else ROOT/f'assets/walk-v{a.version}/{a.species}'
manifest=json.loads((asset/'manifest.json').read_text('utf8'));results={}
for stage,spec in manifest['stages'].items():
    if a.stage and stage!=a.stage: continue
    work=a.work_dir.resolve() if a.work_dir else folder/stage/f'{a.species}-{stage}'
    report=json.loads((work/'validation.json').read_text('utf8'))
    scale=110*a.height*(.93 if stage=='baby' else 1)/spec['reference_height']
    tracks=np.array(report['sole_tracks']);supports=[]
    for start,side in [(0,1),(30,0)]:
        xy=tracks[start:start+30,side];world=xy[:,0]+spec['stride']*np.arange(30)/60
        supports.append(dict(foot=side,horizontal_drift_screen_px=float(np.ptp(world))*scale,vertical_drift_screen_px=float(np.ptp(xy[:,1]))*scale))
    swings=[]
    for start,side in [(0,0),(30,1)]:
        # Include the next contact, including the wrap from source59 to0.
        # A planted-foot fit can look good while the airborne foot stalls.
        xy=tracks[(np.arange(31)+start)%60,side]
        world=(xy[:,0]+spec['stride']*np.arange(31)/60)*scale
        travel=world-world[0];total=float(travel[-1])
        fraction=float(travel[15]/total) if total>0 else None
        warnings=[]
        if fraction is None or not .2<=fraction<=.8:
            warnings.append('Airborne-foot travel is strongly concentrated in one half. Inspect the full cels and actual game; this is a timing diagnostic, not an automatic aesthetic rejection.')
        swings.append(dict(foot=side,runtime_start=(start+spec.get('source_phase_offset',30))%60,
            total_forward_screen_px=total,first_half_travel_fraction=fraction,
            forward_progress_screen_px=travel.tolist(),
            minimum_four_cel_forward_screen_px=float(np.min(world[4:]-world[:-4])),
            warnings=warnings))
    atlas=Image.open(asset/spec['file']).convert('RGBA')
    # One fixed crop for the entire bank, wide enough for both feet in every
    # cel. A hardcoded x=75 used to trim a penguin's outer toe in the QA board.
    foot_bounds=[]
    for i in range(spec['count']):
        x=i%spec['columns']*256;y=i//spec['columns']*256
        b=atlas.crop((x,y+202,x+256,y+246)).getchannel('A').getbbox()
        if b: foot_bounds.append(b)
    left=max(0,min(b[0] for b in foot_bounds)-4);right=min(256,max(b[2] for b in foot_bounds)+4)
    cell_width=right-left
    board=Image.new('RGB',(cell_width*10,480),'#fff8ed');d=ImageDraw.Draw(board)
    for i in range(spec['count']):
        x=i%spec['columns']*256;y=i//spec['columns']*256
        # Keep a fixed crop and size across the entire bank, never track a foot.
        im=atlas.crop((x+left,y+202,x+right,y+246))
        gx=i%10*cell_width;gy=i//10*80;board.paste(im,(gx,gy+22),im);d.text((gx+5,gy+4),str(i),fill='#513d32')
    board.save(work/'all-feet-review.png')
    full=Image.new('RGB',(1536,1080),'#fff8ed');fd=ImageDraw.Draw(full)
    for i in range(spec['count']):
        x=i%spec['columns']*256;y=i//spec['columns']*256
        cel=atlas.crop((x,y,x+256,y+256)).resize((150,150),Image.Resampling.LANCZOS)
        gx=i%10*153;gy=i//10*180
        full.paste(cel,(gx,gy+24),cel);fd.text((gx+6,gy+4),str(i),fill='#513d32')
    full.save(work/'all-cels-review.png')
    results[stage]=dict(screen_scale=scale,stride_screen_px=spec['stride']*scale,supports=supports,swings=swings,limits='Silhouette positions; does not validate foot identity or aesthetic quality. Inspect the whole-image and every-sole boards and native runtime. Swing time diagnostics assume the four-pose biped support schedule used by these banks, not arbitrary gaits.')
report_path=a.output.resolve() if a.output else folder/'support-review.json'
report_path.write_text(json.dumps(results,indent=2),encoding='utf8')
print(json.dumps(results,indent=2))
