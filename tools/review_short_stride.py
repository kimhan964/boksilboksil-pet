"""Measure existing sprite sole tracks against actual short-distance travel.

This is an evidence report, not a motion fix. Sole silhouettes from the reviewed
whole-image bank are combined with captured world positions. Pixel silhouettes
are not anatomical landmarks. Native contact sheets must also be inspected.
"""
import argparse, hashlib, json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--report', default='walk-native-short-stride-025-report.json')
parser.add_argument('--output', default='design/walk-v12/native-short-stride')
parser.add_argument('--arrival', action='store_true')
parser.add_argument('--capture-root', default=str(ROOT))
parser.add_argument('--live-audit', type=Path, help='Use hash-verified current atlas soles rather than historical build tracks.')
args = parser.parse_args()
CAPTURE_ROOT = Path(args.capture_root)
SOURCE = CAPTURE_ROOT / args.report
OUT = ROOT / args.output
OUT.mkdir(parents=True, exist_ok=True)
capture = json.loads(SOURCE.read_text('utf8'))
live_audit = json.loads(args.live_audit.read_text('utf8')) if args.live_audit else None
results = []
for bank in capture['results']:
    species, stage = bank['species'], bank['stage']
    metadata = json.loads((ROOT/f'assets/walk-v12/{species}/manifest.json').read_text('utf8'))['stages'][stage]
    if live_audit:
        evidence = next(b for b in live_audit['banks'] if (b['species'], b['stage']) == (species, stage))
        track_path = ROOT/evidence['asset']
        assert hashlib.sha256(track_path.read_bytes()).hexdigest() == evidence['sha256'], 'Stale current-atlas audit'
        plan = json.loads((ROOT/evidence['plan']).read_text('utf8'))
        atlas = Image.open(track_path).convert('RGBA')
        factor = metadata['reference_height']/plan['master_height']
        center = plan.get('camera_center_x', 550)
        origin = plan.get('canvas_origin_x', 138)
        runtime_tracks = []
        for index in range(metadata['count']):
            x = index % metadata['columns'] * 256
            y = index // metadata['columns'] * 256
            mask = np.asarray(atlas.crop((x,y,x+256,y+256)))[:,:,3] > 128
            feet = []
            for lo, hi in plan['sole_regions']:
                x0, x1 = round(origin+(lo-center)*factor), round(origin+(hi-center)*factor)
                yy, xx = np.where(mask[205:,x0:x1])
                assert len(yy), (species,stage,index,'Missing sole')
                bottom = int(yy.max()+205)
                yy, xx = np.where(mask[bottom-1:bottom+1,x0:x1])
                feet.append([float(xx.mean()+x0),bottom])
            runtime_tracks.append(feet)
        offset = metadata.get('source_phase_offset', 0)
        tracks = np.asarray([runtime_tracks[(i-offset)%60] for i in range(60)])
    else:
        track_path = ROOT/f'design/walk-v12/{species}/{stage}/{species}-{stage}/validation.json'
        if species == 'otter':
            track_path = ROOT/f'design/walk-v11/otter-{stage}/validation.json'
        source = json.loads(track_path.read_text('utf8'))
        tracks = np.asarray(source['sole_tracks'])
    walking = [f for f in bank['frames'] if f['bank'] == 'walk']
    scale = abs(bank['frames'][0]['scale'][0])
    direction = 1 if bank['frames'][-1]['feet'][0] > bank['frames'][0]['feet'][0] else -1
    groups = [[], []]
    normal_groups = [[], []]
    for frame in walking:
        index = (frame['index'] + metadata.get('source_phase_offset', 0)) % 60
        side = 1 if index < 30 else 0
        # Offsets between sprite and world origin are constant within a stance.
        groups[side].append(frame['feet'][0] + direction*tracks[index, side, 0]*scale)
        normal_groups[side].append((tracks[index, side, 0] + metadata['stride']*(index % 30)/60)*scale)
    drift = [float(np.ptp(g)) if g else None for g in groups]
    normal_drift = [float(np.ptp(g)) if g else None for g in normal_groups]
    actual_distance = abs(bank['frames'][-1]['feet'][0]-bank['frames'][0]['feet'][0])
    blank, clipped = [], []
    scales = set()
    for frame in bank['frames']:
        im = Image.open(CAPTURE_ROOT/frame['file'])
        bbox = im.getbbox()
        if bbox is None: blank.append(frame['file'])
        elif bbox[0]<=0 or bbox[1]<=0 or bbox[2]>=im.width or bbox[3]>=im.height: clipped.append(frame['file'])
        scales.add(tuple(abs(s) for s in frame['scale']))
    item = dict(species=species, stage=stage, native_captures=len(bank['frames']),
                observed_walk_cels=len({f['index'] for f in walking}),
                stride_screen_px=metadata['stride']*scale,
                captured_root_displacement_px=actual_distance,
                planted_sole_drift_px=drift,
                same_cels_full_stride_drift_px=normal_drift,
                track_source=str(track_path.relative_to(ROOT)),
                blank=blank, clipped=clipped, fixed_scale=len(scales)==1)
    results.append(item)
    # The same fixed viewport crop is kept for every native frame. This board
    # does not recenter each character or normalize its size.
    chosen = []
    for index in ([0, 8, 15, 22, 29, 30, 38, 45, 52, 59] if walking else []):
        chosen.append(min(walking, key=lambda f: abs(f['index']-index)))
    idle = [f for f in bank['frames'] if f['bank'] == 'idle']
    if idle: chosen += [idle[0], idle[-1]]
    board = Image.new('RGB', (960, 540), '#fff8ed')
    draw = ImageDraw.Draw(board)
    for n, frame in enumerate(chosen):
        image = Image.open(CAPTURE_ROOT/frame['file']).convert('RGBA')
        # Native viewport is 640 x 224; fixed central crop includes all pets.
        tile = image.crop((230, 44, 470, 204))
        x, y = n % 4 * 240, n // 4 * 180
        board.paste(tile, (x, y+20), tile)
        draw.text((x+4,y+3), f"{frame['bank']} {frame['index']} t={frame['time']:.3f}", fill='#513d32')
    board.save(OUT/f'{species}-{stage}-short-contact.png')

report = dict(requested_stride_fraction=capture['requested_stride_fraction'],
              renderer=capture['renderer'], results=results,
              finding=('Nearest-contact arrival review; inspect measured drift and contact sheets. Final target error is intentionally allowed within half a stride (up to one stride at bounds).' if args.arrival else 'The full 60-cel stride is played while root travel is reduced to 25%. This is a known contact mismatch, not a passed naturalness check.'),
              limits='World drift uses generated sole silhouettes and actual captured root positions; small raster/contact shifts are not anatomical tracking. Captured displacement excludes the first simulation step.')
(OUT/'short-stride-review.json').write_text(json.dumps(report,indent=2),encoding='utf8')
(OUT/SOURCE.name).write_text(SOURCE.read_text('utf8'),encoding='utf8')
print(json.dumps(report,indent=2))
