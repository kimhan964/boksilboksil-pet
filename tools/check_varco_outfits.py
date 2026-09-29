"""Check generated outfit coverage, bounds, and baby/adult fabric hue."""
from pathlib import Path
import colorsys
import json

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPECIES = ("rabbit", "otter", "squirrel", "hedgehog", "raccoon", "fox", "bear", "owl",
           "cat", "puppy", "hamster", "panda", "red_panda", "lamb", "koala", "penguin")
STYLES = ("cape", "vest", "sweater")
PALETTE = ("88a879", "dc9078", "79a9c5", "a790c2", "c96f7b", "d8bd88")
sources = json.loads((ROOT / "design/outfits-varco-v1/varco-sources.json").read_text(encoding="utf-8"))
failures = []
count = 0

for species in SPECIES:
    for style in STYLES:
        for color, target in enumerate(PALETTE):
            stage_hues = []
            target_rgb = [int(target[i:i + 2], 16) for i in (0, 2, 4)]
            target_hue = colorsys.rgb_to_hsv(*(v / 255 for v in target_rgb))[0]
            for stage in ("baby", "adult"):
                path = ROOT / "assets/outfits-varco-v1" / species / f"{stage}-{style}-{color}.png"
                if not path.is_file() or stage not in sources["species"][species][style]:
                    failures.append(f"missing {species}/{stage}-{style}-{color}")
                    continue
                image = Image.open(path).convert("RGBA")
                if image.size != (256, 256) or image.getbbox() is None:
                    failures.append(f"invalid image {path}")
                    continue
                count += 1
                rgba = np.asarray(image)
                rgb = rgba[:, :, :3].astype(float) / 255
                maximum = rgb.max(axis=2)
                minimum = rgb.min(axis=2)
                saturation = np.where(maximum > 0, (maximum - minimum) / np.maximum(maximum, 1e-6), 0)
                visible = (rgba[:, :, 3] > 160) & (saturation > .18) & (maximum > .3)
                if not np.any(visible):
                    failures.append(f"no visible colored fabric {path}")
                    continue
                pixels = rgb[visible]
                hues = np.array([colorsys.rgb_to_hsv(*pixel)[0] for pixel in pixels])
                distance = np.minimum(abs(hues - target_hue), 1 - abs(hues - target_hue))
                matching = hues[distance < .018]
                if matching.size < 12:
                    failures.append(f"fabric color absent {path}")
                else:
                    stage_hues.append(float(np.median(matching)))
            if len(stage_hues) == 2:
                delta = min(abs(stage_hues[0] - stage_hues[1]), 1 - abs(stage_hues[0] - stage_hues[1]))
                if delta > .025:
                    failures.append(f"stage color mismatch {species}/{style}-{color}: {delta:.3f}")

print(f"VARCO_OUTFIT_CHECK images={count} expected=576 failures={len(failures)}")
for failure in failures[:30]:
    print(failure)
raise SystemExit(1 if failures else 0)
