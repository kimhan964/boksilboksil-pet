"""Inspect complete cels and captured native pet windows; no art synthesis."""
import hashlib, json, sys, math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
CAPTURE_ROOT=Path(next((x.split('=',1)[1] for x in sys.argv if x.startswith('--capture-root=')),str(ROOT)))
VERSION=next((x.split('=',1)[1] for x in sys.argv if x.startswith('--version=')), '2')
BANK=ROOT / f'assets/rabbit-frame-pilot-v{VERSION}'
OUT = ROOT / f'design/rabbit-frame-pilot-v{VERSION}'
manifest = json.loads((BANK / 'manifest.json').read_text(encoding='utf8'))
STAGES=list(manifest['stages'])
report = {'method': manifest['method'], 'stages': {}, 'failures': []}
for stage in STAGES:
    spec = manifest['stages'][stage]['sequences']['walk']
    atlas = Image.open(BANK / spec['file']).convert('RGBA')
    cells = [atlas.crop((i % 8 * 256, i // 8 * 256, i % 8 * 256 + 256, i // 8 * 256 + 256)) for i in range(spec['count'])]
    bounds = [cel.getbbox() for cel in cells]
    clipped = [i for i, b in enumerate(bounds) if not b or min(b[:2]) < 3 or max(b[2:]) > 253]
    unique = len({hashlib.sha256(c.tobytes()).hexdigest() for c in cells})
    if clipped: report['failures'].append(f'{stage}: empty or clipped cels {clipped}')
    if unique != spec['count']: report['failures'].append(f'{stage}: only {unique} distinct complete cels')
    report['stages'][stage] = {'walk_cels': len(cells), 'distinct_images': unique, 'clipped_cels': clipped, 'source_bounds': bounds}
    frames = []
    stage_spec=manifest['stages'][stage]
    phases=spec.get('phases',[i/len(cells) for i in range(len(cells))])
    for i,cel in enumerate(cells):
        canvas = Image.new('RGB', (320,300), '#fff8ed')
        lift=0
        if stage_spec.get('locomotion')=='short_hop':
            t=max(0,min(1,(phases[i]-stage_spec['launch_phase'])/(stage_spec['land_phase']-stage_spec['launch_phase'])))
            lift=math.sin(t*math.pi)*stage_spec['lift_canvas']
        canvas.paste(cel, (32,20-round(lift)), cel)
        frames.append(canvas)
    durations=[max(10,round((end-start)*stage_spec['cycle_seconds']*100)*10) for start,end in zip(phases,phases[1:]+[1.0])]
    frames[0].save(OUT / f'{stage}-frame-loop.gif', save_all=True, append_images=frames[1:], duration=durations, loop=0)

play_path = CAPTURE_ROOT / 'rabbit-frame-playback-report.json'
if play_path.exists():
    play = json.loads(play_path.read_text(encoding='utf8'))
    if int(VERSION)>=5 and play.get('asset_version')!=manifest['version']:
        raise SystemExit('Capture version mismatch. Record the current game before reviewing.')
    groups = {stage: [c for c in play['captures'] if c['stage'] == stage] for stage in STAGES}
    report['native_game_windows'] = play['native_game_windows']
    report['native_capture_count'] = len(play['captures'])
    for stage, cases in groups.items():
        scales = [abs(c['scale'][0]) for c in cases]
        blank, clipped, heights = [], [], []
        for i,c in enumerate(cases):
            im = Image.open(CAPTURE_ROOT / c['file']).convert('RGBA'); b = im.getbbox()
            if not b: blank.append(i)
            elif min(b[:2]) < 2 or b[2] > im.width-2 or b[3] > im.height-2: clipped.append(i)
            if b: heights.append(b[3]-b[1])
        span = max(scales)-min(scales)
        if span > 1e-6: report['failures'].append(f'{stage}: native scale varies {span}')
        if blank or clipped: report['failures'].append(f'{stage}: native empty/clipped captures')
        seen=sorted({int(c['index']) for c in cases if c['bank']=='walk'})
        missing=sorted(set(range(int(manifest['stages'][stage]['sequences']['walk']['count'])))-set(seen))
        if int(VERSION)>=6 and missing: report['failures'].append(f'{stage}: uncaptured walk cels {missing}')
        report['stages'][stage]['native'] = {'captures':len(cases), 'captured_walk_cels':len(seen), 'uncaptured_walk_cels':missing, 'scale_range':span, 'peak_speed':max(c['speed'] for c in cases), 'blank_captures':blank, 'clipped_captures':clipped, 'visible_height_range':[min(heights),max(heights)], 'banks':sorted({c['bank'] for c in cases}), 'native_window_positions':len({tuple(c.get('window_origin',[])) for c in cases})}
    font = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',16)
    frames = []
    for n in range(min(len(v) for v in groups.values())):
        canvas=Image.new('RGB',(560,195+165*(len(STAGES)-1)),'#fff8ed'); d=ImageDraw.Draw(canvas)
        d.text((18,10),'실제 게임 창 기록 · 전신 프레임 걷기',font=font,fill='#523727')
        for row,stage in enumerate(STAGES):
            cases=groups[stage];c=cases[n];origin=min(s['feet'][0] for s in cases)
            x=95+c['feet'][0]-origin; ground=174+row*165
            d.line((28,ground,532,ground),fill='#d8cdbd')
            d.text((18,43+row*165),'성체' if stage=='adult' else '새끼',font=font,fill='#523727')
            native=Image.open(CAPTURE_ROOT/c['file']).convert('RGBA');local=c.get('local_root',[128,190]);canvas.paste(native,(round(x-local[0]),round(ground-local[1])),native)
            d.text((400,45+row*165),'걷기' if c['bank']=='walk' else '쉬기',font=font,fill='#746044')
            d.text((400,70+row*165),f"{c['speed']:.1f} px/초",font=font,fill='#746044')
        frames.append(canvas)
    cases=groups['adult'];durations=[max(10,round(cases[i+1]['time']*100)*10-round(cases[i]['time']*100)*10) if i+1<len(frames) else 20 for i in range(len(frames))]
    frames[0].save(OUT/'native-gameplay-review.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0)
    frames[min(12,len(frames)-1)].save(OUT/'native-gameplay-review.png')
    # Actual rendered game frames across one complete cycle, including the seam.
    strip=Image.new('RGB',(1120,195*4),'#fff8ed')
    chosen=[min(range(len(cases)),key=lambda j:abs(cases[j]['time']-t)) for t in [.15,.35,.55,.75,.95,1.15,1.35,1.55]]
    for slot,n in enumerate(chosen):
        strip.paste(frames[n],(slot%2*560,slot//2*195))
        ImageDraw.Draw(strip).text((slot%2*560+350,slot//2*195+110),f"{cases[n]['time']:.2f}s / cel {cases[n]['index']}",font=font,fill='#523727')
    strip.save(OUT/'native-cycle-contact.png')
report['visual_review_required'] = ['face and palette consistency', 'grounded paw position and flight timing', 'last-to-first seam', 'naturalness of actual moving game window']
(OUT/'frame-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({**report,'stages':{s:{k:v for k,v in r.items() if k!='source_bounds'} for s,r in report['stages'].items()}},ensure_ascii=False,indent=2))
raise SystemExit(bool(report['failures']))
