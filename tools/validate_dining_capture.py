"""Validate recorded native frames without changing the artwork."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parents[1]
report = json.loads((root / 'dining-native-owl-v13-report.json').read_text(encoding='utf-8'))
case = next(c for c in report['results'] if c['stage'] == 'adult' and c['prop'] == 'water')
frames = case['frames']
active = [f for f in frames if f['action'] == 'drink']
blank, clipped = [], []
for f in frames:
    alpha = np.asarray(Image.open(root / f['file']).convert('RGBA'))[:, :, 3]
    ys, xs = np.where(alpha > 16)
    if not len(xs):
        blank.append(f['file'])
    elif xs.min() == 0 or ys.min() == 0 or xs.max() == alpha.shape[1]-1 or ys.max() == alpha.shape[0]-1:
        clipped.append(f['file'])
validation = {
    'source': 'dining-native-owl-v13-report.json',
    'captures': len(frames), 'drink_captures': len(active),
    'observed_indices': sorted({f['index'] for f in active}),
    'scales': sorted({tuple(f['scale']) for f in active}),
    'rotations': sorted({f['rotation'] for f in active}),
    'root_range_px': np.ptp(np.array([f['feet'] for f in active]), axis=0).tolist(),
    'blank': blank, 'clipped': clipped,
    'visual_review': 'Full contact sheet reviewed: beak reaches pond; bow, sip and upright recovery visible.',
    'limitations': ['Root stability does not prove sole stability. Source soles still vary up to 1.25 screen pixels.',
                   '120 timeline slots contain 63 distinct images; 3.2-second cycle, not 120 unique poses or 60fps.',
                   'Native viewport captures/composites do not alone verify operating-system window stacking.',
                   'Age-paired palette, remaining species and general-game integration pending.'],
}
assert len(validation['observed_indices']) == 120
assert len(validation['scales']) == 1 and validation['rotations'] == [0.0]
assert validation['root_range_px'] == [0.0, 0.0] and not blank and not clipped
out = root / 'design/dining-v13/owl/native-review/validation.json'
out.write_text(json.dumps(validation, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k: validation[k] for k in ['captures','drink_captures','root_range_px','blank','clipped']}))
