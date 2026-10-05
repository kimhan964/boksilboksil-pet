"""Read live v12 atlas pixels to inspect biped swing timing, not frame counts.

These banks use alternating half-cycle support. Do not apply this schedule to
quadruped walks or rabbit hops. No artwork is edited, and no naturalness pass
is inferred from the diagnostic thresholds.
"""
import argparse, hashlib, json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--output',type=Path,required=True)
a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
heights={'otter':.64,'squirrel':.69,'fox':.93,'raccoon':.76,'bear':1.04,'owl':.64,'penguin':.66}
results=[]
for manifest_file in sorted((ROOT/'assets/walk-v12').glob('*/manifest.json')):
    species=manifest_file.parent.name
    if species not in heights:continue
    manifest=json.loads(manifest_file.read_text('utf8'))
    for stage,spec in manifest['stages'].items():
        work=ROOT/f'design/walk-v12/{species}/{stage}'
        plan_name='accepted-keys.json';build=work/f'{species}-{stage}'
        if species=='squirrel':
            plan_name='contact-rebuild-plan.json';build=work/'contact-rebuild-build'
            if stage=='baby':
                plan_name='swing-tone-0-plan.json';build=work/'swing-tone-0-build'
        elif species=='otter' and stage=='adult':
            plan_name='toe-repair-tta-keys.json';build=work/'toe-repair-tta-build'
        elif species=='owl' and stage=='adult':
            plan_name='swing-palette-plan.json';build=work/'swing-palette-build'
        elif species=='bear' and stage=='adult':
            plan_name='low-between-plan.json';build=work/'low-between-build'
        elif species=='fox' and stage=='baby':
            plan_name='exact-palette-plan.json';build=work/'exact-palette-build'
        plan=json.loads((work/plan_name).read_text('utf8'))
        record=json.loads((build/'validation.json').read_text('utf8'))
        assert spec['count']==60 and abs(record['stride']-spec['stride'])<1e-8,(species,stage,'stale build')
        factor=spec['reference_height']/plan['master_height']
        center=plan.get('camera_center_x',550);origin=plan.get('canvas_origin_x',138)
        path=manifest_file.parent/spec['file'];atlas=Image.open(path).convert('RGBA')
        tracks=[]
        for i in range(60):
            x=i%spec['columns']*256;y=i//spec['columns']*256
            mask=np.asarray(atlas.crop((x,y,x+256,y+256)))[:,:,3]>128
            feet=[]
            for lo,hi in plan['sole_regions']:
                x0=round(origin+(lo-center)*factor);x1=round(origin+(hi-center)*factor)
                yy,xx=np.where(mask[205:,x0:x1]);assert len(yy),(species,stage,i,'missing sole')
                bottom=int(yy.max()+205)
                yy,xx=np.where(mask[bottom-1:bottom+1,x0:x1])
                feet.append([float(xx.mean()+x0),bottom])
            tracks.append(feet)
        # Rotate live playback back into the source phase order used by the baker.
        offset=spec.get('source_phase_offset',30)
        source=np.array([tracks[(i-offset)%60] for i in range(60)])
        error=float(np.max(np.abs(source-np.asarray(record['sole_tracks']))))
        assert error<1e-7,(species,stage,'live pixels differ from build tracking',error)
        scale=110*heights[species]*(.93 if stage=='baby' else 1)/spec['reference_height']
        # Fixed camera and crop for every cel: never resize each character to
        # its own bounds, which would conceal unwanted size changes.
        full=Image.new('RGB',(1536,1080),'#fff8ed');fd=ImageDraw.Draw(full)
        feet_board=Image.new('RGB',(1600,660),'#fff8ed');dd=ImageDraw.Draw(feet_board)
        for i in range(60):
            x=i%spec['columns']*256;y=i//spec['columns']*256
            cel=atlas.crop((x,y,x+256,y+256))
            thumb=cel.resize((150,150),Image.Resampling.LANCZOS)
            gx=i%10*153;gy=i//10*180
            full.paste(thumb,(gx,gy+24),thumb);fd.text((gx+4,gy+4),str(i),fill='#513d32')
            foot=cel.crop((48,198,208,250))
            gx=i%10*160;gy=i//10*110
            feet_board.paste(foot,(gx,gy+24),foot);dd.text((gx+4,gy+4),str(i),fill='#513d32')
        full.save(out/f'{species}-{stage}-all-cels.png')
        feet_board.save(out/f'{species}-{stage}-all-feet.png')
        supports=[]
        for start,side in [(0,1),(30,0)]:
            xy=source[start:start+30,side]
            world=(xy[:,0]+spec['stride']*np.arange(30)/60)*scale
            supports.append(dict(foot=side,horizontal_drift_px=float(np.ptp(world)),
                vertical_drift_px=float(np.ptp(xy[:,1]))*scale))
        swings=[]
        for start,side in [(0,0),(30,1)]:
            xy=source[(np.arange(31)+start)%60,side]
            world=(xy[:,0]+spec['stride']*np.arange(31)/60)*scale
            travel=world-world[0];total=float(travel[-1]);fraction=float(travel[15]/total) if total>0 else None
            min_step=float(np.min(world[4:]-world[:-4]))
            min_at=int(np.argmin(world[4:]-world[:-4]))
            phase=(np.arange(31)+start)%60
            clearance=(source[phase,1-side,1]-xy[:,1])*scale
            warnings=[]
            if fraction is None or not .2<=fraction<=.8:warnings.append('travel concentrated in one half')
            if min_step<-.25:warnings.append('four-cel backward movement exceeds0.25screenpx')
            swings.append(dict(foot=side,runtime_start=(start-offset)%60,
                total_forward_screen_px=total,first_half_fraction=fraction,
                minimum_four_cel_progress_px=min_step,
                minimum_four_cel_runtime_frames=[(start-offset+min_at)%60,(start-offset+min_at+4)%60],
                maximum_clearance_px=float(clearance.max()),
                progress_px=travel.tolist(),warnings=warnings))
        results.append(dict(species=species,stage=stage,asset=str(path.relative_to(ROOT)),
            sha256=hashlib.sha256(path.read_bytes()).hexdigest(),plan=str((work/plan_name).relative_to(ROOT)),
            live_tracking_matches_build=error,supports=supports,swings=swings))
summary=dict(scope='Current ten v12 biped banks only; rabbit and unbuilt/legacy species are not covered.',
    limitations='Bottom-silhouette centroid can change when a toe rotates; inspect complete cels and native playback. Assumes half-cycle alternating biped support. Not a naturalness approval.',banks=results)
(out/'live-swing-timing.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
lines=['# 현재 걷기 자산의 들린 발 타이밍 검사','',summary['scope'],'',summary['limitations'],'',
       '| 동물 | 나이 | 왼쪽/오른쪽 발 전반 이동 비율 | 경고 |','|---|---|---|---|']
for r in results:
    fractions='/'.join(f"{s['first_half_fraction']:.1%}" if s['first_half_fraction'] is not None else '?' for s in r['swings'])
    warnings='; '.join(f"발{s['foot']}: {', '.join(s['warnings'])}" for s in r['swings'] if s['warnings']) or '수치 경고 없음; 시각 승인 아님'
    lines.append(f"| {r['species']} | {r['stage']} | {fractions} | {warnings} |")
(out/'README.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print('\n'.join(lines))
