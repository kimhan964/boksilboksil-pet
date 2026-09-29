"""Compare baby/adult head-fur color in available dressed idle sheets."""

from pathlib import Path
import argparse
import json
import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]


def head_color(file: Path) -> list[int]:
    image = Image.open(file).convert("RGBA")
    samples = []
    for frame in range(16):
        cell = np.asarray(image.crop((frame * 256, 0, (frame + 1) * 256, 256)))
        ys, xs = np.nonzero(cell[:, :, 3] > 200)
        if not len(xs):
            continue
        left, right, top, bottom = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        width, height = right - left, bottom - top
        x0, x1 = round(left + width * .38), round(left + width * .62)
        y0, y1 = round(top + height * .12), round(top + height * .25)
        crop = cell[y0:y1, x0:x1]
        pixels = crop[crop[:, :, 3] > 200, :3]
        pixels = pixels[(pixels.max(axis=1) > 70) & (pixels.min(axis=1) < 250)]
        if len(pixels):
            samples.append(np.median(pixels, axis=0))
    if not samples:
        raise ValueError(f"No head fur sample: {file}")
    return np.rint(np.median(samples, axis=0)).astype(int).tolist()


def fabric_color(file: Path, style: str) -> list[int] | None:
    image = Image.open(file).convert("RGBA")
    samples = []
    for frame in range(16):
        cel = image.crop((frame * 256, 0, (frame + 1) * 256, 256))
        rgba = np.asarray(cel)
        ys, xs = np.nonzero(rgba[:, :, 3] > 200)
        if not len(xs):
            continue
        left, right, top, bottom = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        x0, x1 = round(left + (right-left)*.25), round(left + (right-left)*.82)
        y0, y1 = round(top + (bottom-top)*.40), round(top + (bottom-top)*.83)
        rgb = rgba[y0:y1, x0:x1, :3]
        alpha = rgba[y0:y1, x0:x1, 3]
        hsv = np.asarray(cel.convert("HSV"))[y0:y1, x0:x1]
        h, s, v = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]
        if style == "cape":
            mask = (h >= 35) & (h <= 105) & (s > 50) & (v > 50)
        elif style == "vest":
            mask = (h <= 30) & (s > 105) & (v > 80)
        else:
            mask = (h >= 120) & (h <= 190) & (s > 40) & (v > 60)
        values = rgb[mask & (alpha > 200)]
        if len(values) > 20:
            samples.append(np.median(values, axis=0))
    return np.rint(np.median(samples, axis=0)).astype(int).tolist() if samples else None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("species")
    args = parser.parse_args()
    base = ROOT / "assets/outfits-dressed-v2" / args.species
    results = []
    for style in ("cape", "vest", "sweater"):
        baby, adult = (base / stage / style / "idle.png" for stage in ("baby", "adult"))
        if not baby.is_file() or not adult.is_file():
            continue
        b, a = head_color(baby), head_color(adult)
        difference = float(np.linalg.norm((np.asarray(b) - a) / 255))
        fabric_b, fabric_a = fabric_color(baby, style), fabric_color(adult, style)
        fabric_difference = (float(np.linalg.norm((np.asarray(fabric_b) - fabric_a) / 255))
                             if fabric_b is not None and fabric_a is not None else None)
        results.append({"style": style, "baby_rgb": b, "adult_rgb": a, "normalized_rgb_distance": round(difference, 3),
                        "fabric_baby_rgb": fabric_b, "fabric_adult_rgb": fabric_a,
                        "fabric_rgb_distance": round(fabric_difference, 3) if fabric_difference is not None else None})
    print(json.dumps({"species": args.species, "head_fur": results}))


if __name__ == "__main__":
    main()
