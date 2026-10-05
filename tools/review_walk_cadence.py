"""Report measured playback timing and native-surface movement, not art approval."""
import json
from pathlib import Path
from statistics import median

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design/walk-cadence-review'
files = [
    'walk-native-cadence-legacy-report.json',
    'walk-native-koala-cadence-fixed-right-report.json',
    'walk-native-koala-cadence-fixed-left-report.json',
    'walk-native-koala-cadence-gl-report.json',
    'walk-native-cadence-v12-report.json',
]
rows = []
for filename in files:
    path = ROOT / filename
    if not path.exists():
        continue
    report = json.loads(path.read_text('utf8'))
    for bank in report['results']:
        frames = [r for r in bank['frames'] if r['bank'] == 'walk']
        top_speed = max(r['speed'] for r in frames)
        periods = []
        for a, b in zip(frames, frames[1:]):
            dt = b['time'] - a['time']
            dp = (b['cycle_phase'] - a['cycle_phase']) % 1.0
            if 0 < dp < .1 and dt > 0 and min(a['speed'], b['speed']) > top_speed * .995:
                periods.append(dt / dp)
        scales = [abs(r['scale'][0]) for r in frames]
        rows.append(dict(
            report=filename, renderer=report['renderer'], species=bank['species'],
            stage=bank['stage'], captures=len(bank['frames']),
            intended_cycle_seconds=bank['playback_cycle_seconds'],
            measured_steady_cycle_seconds=median(periods) if periods else None,
            native_window_positions=len({tuple(r['window']) for r in frames}),
            sprite_scale_range=[min(scales), max(scales)],
            observed_indices=sorted({r['index'] for r in frames}),
            last_walk_time=frames[-1]['time'],
        ))
result = dict(results=rows, limits=[
    'Steady cycle excludes legacy acceleration/deceleration; a first 2.45s cycle takes about 2.58s including acceleration.',
    'One native position proves no native window move in this recorded stride, not absence of compositor flicker under every desktop condition.',
    'No inference of natural gait from frame coverage, time, fixed scale or absence of blank frames.',
    'Koala retains 16 original cels as flicker mitigation; alternating-foot anatomy and sliding still require replacement art.',
])
(OUT/'measured-cadence.json').write_text(json.dumps(result, indent=2), encoding='utf8')
for r in rows:
    if r['species'] == 'koala' or 'v12-report' in r['report']:
        print(r)
