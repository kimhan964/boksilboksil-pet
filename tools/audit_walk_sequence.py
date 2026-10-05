"""Diagnostic boards of installed whole-image cels; does not modify game art."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design/walk-v12/detailed-bidirectional'
OUT.mkdir(parents=True, exist_ok=True)
results = []
for manifest_path in sorted((ROOT / 'assets/walk-v12').glob('*/manifest.json')):
    manifest = json.loads(manifest_path.read_text('utf8'))
    for stage, spec in manifest['stages'].items():
        name = manifest['species'] + '-' + stage
        atlas = Image.open(manifest_path.parent / spec['file']).convert('RGBA')
        cels = [atlas.crop((i % spec['columns'] * 256, i // spec['columns'] * 256,
                            i % spec['columns'] * 256 + 256, i // spec['columns'] * 256 + 256))
                for i in range(spec['count'])]
        full = Image.new('RGB', (1440, 1056), '#fff8ed')
        feet = Image.new('RGB', (1600, 660), '#fff8ed')
        full_draw, feet_draw = ImageDraw.Draw(full), ImageDraw.Draw(feet)
        for i, cel in enumerate(cels):
            x, y = i % 10 * 144, i // 10 * 176
            small = cel.resize((144, 144), Image.Resampling.LANCZOS)
            full.paste(small, (x, y + 24), small)
            full_draw.text((x + 5, y + 5), f'{name} {i}', fill='#513d32')
            # Common fixed crop includes both entire soles and preserves their relative positions.
            lower = cel.crop((32, 184, 224, 256)).resize((160, 60), Image.Resampling.LANCZOS)
            x, y = i % 10 * 160, i // 10 * 110
            feet.paste(lower, (x, y + 28), lower)
            feet_draw.text((x + 5, y + 5), f'{name} {i}', fill='#513d32')
        full.save(OUT / (name + '-all-cels.png'))
        feet.save(OUT / (name + '-all-feet.png'))
        idle = Image.open(manifest_path.parent / spec['idle_file']).convert('RGBA')
        results.append(dict(name=name, count=len(cels), unique=len(set(c.tobytes() for c in cels)),
                            idle_equals_first=idle.tobytes() == cels[0].tobytes(),
                            cycle_seconds=spec['cycle_seconds']))
(OUT / 'asset-summary.json').write_text(json.dumps(results, indent=2), encoding='utf8')
print(json.dumps(results, indent=2))
