"""Report captured gait timing and source evidence without approving naturalness."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
out = a.output.resolve()
audit = json.loads((out / 'live-swing-timing.json').read_text('utf8'))
results = []
for side in ('right', 'left'):
    raw = json.loads((ROOT / f'walk-native-detailed-current-{side}-report.json').read_text('utf8'))
    validations = json.loads((out / side / 'validation.json').read_text('utf8'))
    heads = json.loads((out / side / 'head-motion-review.json').read_text('utf8'))
    for bank, validation, head in zip(raw['results'], validations['results'], heads):
        key = (bank['species'], bank['stage'])
        assert key == (validation['species'], validation['stage']) == (head['species'], head['stage'])
        live = next(b for b in audit['banks'] if (b['species'], b['stage']) == key)
        assert hashlib.sha256((ROOT / live['asset']).read_bytes()).hexdigest() == live['sha256']
        manifest = json.loads((ROOT / 'assets/walk-v12' / key[0] / 'manifest.json').read_text('utf8'))
        metadata = manifest['stages'][key[1]]
        # New captures record effective playback cadence separately from the
        # authored manifest. Historical captures keep their original duration.
        playback_cycle = bank.get('playback_cycle_seconds', metadata['cycle_seconds'])
        plan = json.loads((ROOT / live['plan']).read_text('utf8'))
        walk = [f for f in bank['frames'] if f['bank'] == 'walk']
        gaps = np.diff([f['time'] for f in walk]) * 1000
        holds = []
        current = 1
        for first, second in zip(walk, walk[1:]):
            if second['index'] == first['index']:
                current += 1
            else:
                holds.append(current)
                current = 1
        holds.append(current)
        # Boundary runs can be partial; discard them for the cadence histogram.
        histogram = dict(sorted(Counter(holds[1:-1]).items()))
        jumps = [int((b['index'] - f['index']) % metadata['count']) for f, b in zip(walk, walk[1:])]
        results.append(dict(species=key[0], stage=key[1], direction=side,
            validation=validation, source_key_count=len(plan['keys']),
            cycle_seconds=playback_cycle, authored_cycle_seconds=metadata['cycle_seconds'], cels_per_second=metadata['count']/playback_cycle,
            capture_gap_ms=dict(min=float(gaps.min()), median=float(np.median(gaps)), max=float(gaps.max())),
            captured_samples_per_cel=histogram, skipped_cel_transitions=sum(j > 1 for j in jumps),
            head={k:v for k,v in head.items() if k != 'samples'},
            support=live['supports'], swing=live['swings']))
summary = dict(scope='Current v12 ten walking banks; left/right start, three cycles, stop.',
    naturalness_approved=False,
    evidence_limit='Native viewport captures and static full-cel/sole boards. Continuous normal-speed visual observation is not complete. Capture time is game time, not a wall-clock GPU profiler.',
    captures=sum(r['validation']['captures'] for r in results), results=results)
(out / 'detailed-summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf8')

# Diagnostic crops only. Never write these enlarged crops into game assets.
board = Image.new('RGB', (1500, 820), '#fff8ed')
draw = ImageDraw.Draw(board)
font = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 23)
small = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 17)
rows = [
    ('너구리 현재: 발바닥이 정면으로 돌아옴', ROOT/'assets/walk-v12/raccoon/adult.png', [37,40,43,46,49,52]),
    ('너구리 후보: 발바닥 각도 개선 / 몸통 반응 보완 필요', ROOT/'design/walk-v12/raccoon/adult/sole-palette-assets/adult.png', [37,40,43,46,49,52]),
    ('다람쥐 새끼: 발 이동이 앞 구간에 몰림', ROOT/'assets/walk-v12/squirrel/baby.png', [30,36,42,48,54,59]),
    ('수달 성체: 착지 중 발끝 폭·형태 변화', ROOT/'assets/walk-v12/otter/adult.png', [18,20,22,24,26,28]),
]
for row, (label, path, indices) in enumerate(rows):
    y = row * 205
    draw.text((18,y+10), label, font=font, fill='#513d32')
    atlas = Image.open(path).convert('RGBA')
    for col, index in enumerate(indices):
        x0=index%8*256; y0=index//8*256
        cel=atlas.crop((x0+48,y0+198,x0+208,y0+250)).resize((240,78),Image.Resampling.NEAREST)
        board.paste(cel,(col*250+5,y+74),cel)
        draw.text((col*250+12,y+165),f'{index}번',font=small,fill='#513d32')
board.save(out/'motion-issues.png')
print(json.dumps(dict(captures=summary['captures'], banks=len(results), failures=sum(not r['validation']['pass'] for r in results)), indent=2))
for r in results:
    if r['direction']!='right': continue
    h=r['head'];v=h['vertical_review']
    print(r['species'],r['stage'],'headXY',round(h['head_offset_range_px'],3),round(v['head_offset_range_px'],3),
        'speed',round(h['root_speed'],3),'keys',r['source_key_count'],'cadence',r['captured_samples_per_cel'],
        'height',v['body_bbox_height_range_px'],'swing',[round(s['first_half_fraction']*100,1) for s in r['swing']])
