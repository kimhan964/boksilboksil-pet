"""Pack existing whole cels as image-edit references; never reconstruct limbs."""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design/wardrobe-v3/motion/rabbit/adult'
OUT.mkdir(parents=True, exist_ok=True)
records = []
sheet = Image.new('RGBA', (2048, 2048), (255, 0, 255, 255))
for bank, path, indices in [
    ('walk', 'assets/rabbit-frame-pilot-v9/adult-walk.png', [0, 8, 16, 23, 30, 38, 45, 53]),
    ('struggle', 'assets/struggle-v1/rabbit/adult.png', [0, 15, 30, 45]),
    ('idle', 'assets/rabbit-frame-pilot-v9/adult-idle.png', [0, 39, 49, 59]),
]:
    atlas = Image.open(ROOT / path).convert('RGBA')
    for frame in indices:
        cel = atlas.crop((frame % 8 * 256, frame // 8 * 256, frame % 8 * 256 + 256, frame // 8 * 256 + 256))
        i = len(records)
        sheet.alpha_composite(cel.resize((512, 512), Image.Resampling.NEAREST), (i % 4 * 512, i // 4 * 512))
        records.append(dict(cell=i, bank=bank, index=frame, source=path))
sheet.convert('RGB').save(OUT / 'source-poses.png')
(OUT / 'source-poses.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
print(OUT / 'source-poses.png')
