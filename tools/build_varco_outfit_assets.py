"""Turn approved VARCO dressed masters into clothes-only game textures.

The original character art remains the source of animation. This script only
extracts the newly drawn garment, then aligns it to each complete frame's
visible bounds. No face or body part is cut out or reassembled.
"""

from pathlib import Path
import argparse
import colorsys
import json

import numpy as np
from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
STYLES = ("cape", "vest", "sweater")
STAGES = ("baby", "adult")
SIZE = 256
COLORS = ("88a879", "dc9078", "79a9c5", "a790c2", "c96f7b", "d8bd88")
BASE = {"cape": (153, 174, 105), "vest": (226, 130, 69), "sweater": (115, 159, 189)}


def subject_box(image: Image.Image) -> tuple[int, int, int, int]:
    rgb = np.asarray(image.convert("RGB"), dtype=np.int16)
    bg = np.median(np.concatenate((rgb[:40].reshape(-1, 3), rgb[-40:].reshape(-1, 3))), axis=0)
    mask = np.max(np.abs(rgb - bg), axis=2) > 35
    ys, xs = np.nonzero(mask)
    return int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)


def garment_mask(master: Image.Image, dressed: Image.Image, style: str) -> Image.Image:
    original = np.asarray(master.convert("RGB"), dtype=np.int16)
    edited = np.asarray(dressed.convert("RGB"), dtype=np.int16)
    r, g, b = (edited[:, :, i].astype(np.float32) for i in range(3))
    if style == "cape":
        seed = (r > 60) & (r < 210) & (g > 85) & (g > b * 1.15) & (r > b * 1.12)
        seed |= (r > 170) & (g > 95) & (b < 110)  # small gold clasp
    elif style == "vest":
        seed = (r > 130) & (r > g * 1.20) & (g > b * 1.20) & (g > 55)
    else:
        seed = (b > 85) & (b > r * 1.07) & (b > g * .95) & (r < 200)
    x0, y0, x1, y1 = subject_box(master)
    height = y1 - y0
    roi = np.zeros(seed.shape, dtype=bool)
    upper = {"cape": .645, "vest": .635, "sweater": .635}[style]
    lower = {"cape": .81, "vest": .88, "sweater": .88}[style]
    roi[int(y0 + height * upper):int(y0 + height * lower), x0:x1] = True
    seed &= roi
    near = Image.fromarray((seed * 255).astype("uint8"), "L").filter(ImageFilter.MaxFilter(23))
    changed = np.max(np.abs(edited - original), axis=2) > 18
    cyan = (r < 65) & (g > 150) & (b > 150)
    ivory = (r > 215) & (g > 205) & (b > 175)
    near_trim = np.asarray(Image.fromarray((seed * 255).astype("uint8"), "L").filter(ImageFilter.MaxFilter(9))) > 0
    keep_trim = near_trim if style != "cape" else np.zeros_like(near_trim)
    mask = ((np.asarray(near) > 0) & changed & roi & ~cyan & (~ivory | keep_trim)).astype("uint8") * 255
    return Image.fromarray(mask, "L").filter(ImageFilter.GaussianBlur(.45))


def recolor_fabric(canvas: Image.Image, style: str, hex_color: str) -> Image.Image:
    rgba = np.asarray(canvas).copy()
    rgb = rgba[:, :, :3].astype(np.float32)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    if style == "cape":
        fabric = (r > 60) & (r < 210) & (g > 85) & (g > b * 1.15) & (r > b * 1.12)
    elif style == "vest":
        fabric = (r > 130) & (r > g * 1.20) & (g > b * 1.20) & (g > 55)
    else:
        fabric = (b > 85) & (b > r * 1.07) & (b > g * .95) & (r < 200)
    fabric &= rgba[:, :, 3] > 40
    if not np.any(fabric):
        return canvas.copy()
    target = tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))
    base_h, base_s, base_v = colorsys.rgb_to_hsv(*(x / 255 for x in BASE[style]))
    target_h, target_s, target_v = colorsys.rgb_to_hsv(*(x / 255 for x in target))
    selected = rgb[fabric] / 255
    maximum, minimum = selected.max(axis=1), selected.min(axis=1)
    saturation = np.where(maximum > 0, (maximum - minimum) / np.maximum(maximum, 1e-6), 0)
    value = maximum
    saturation = np.clip(saturation * target_s / max(base_s, .05), 0, .9)
    value = np.clip(value * target_v / max(base_v, .05), 0, 1)
    h = target_h * 6
    c = value * saturation
    x = c * (1 - abs(h % 2 - 1))
    m = value - c
    if h < 1: new = np.stack((c, x, np.zeros_like(c)), axis=1)
    elif h < 2: new = np.stack((x, c, np.zeros_like(c)), axis=1)
    elif h < 3: new = np.stack((np.zeros_like(c), c, x), axis=1)
    elif h < 4: new = np.stack((np.zeros_like(c), x, c), axis=1)
    elif h < 5: new = np.stack((x, np.zeros_like(c), c), axis=1)
    else: new = np.stack((c, np.zeros_like(c), x), axis=1)
    rgba[fabric, :3] = np.clip((new + m[:, None]) * 255, 0, 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--species", default="rabbit")
    args = parser.parse_args()
    species = args.species
    source = ROOT / "design" / "outfits-varco-v1" / species
    out = ROOT / "assets" / "outfits-varco-v1" / species
    out.mkdir(parents=True, exist_ok=True)
    report = {}
    for stage in STAGES:
        master = Image.open(ROOT / "design" / "all-species-v3" / "masters" / species / f"{stage}.png").convert("RGBA")
        source_box = subject_box(master)
        frame_sheet = Image.open(ROOT / "assets" / "species-v3" / species / f"{stage}-idle.png").convert("RGBA")
        target_box = frame_sheet.crop((0, 0, SIZE, SIZE)).getbbox()
        assert target_box is not None
        sx = (target_box[2] - target_box[0]) / (source_box[2] - source_box[0])
        sy = (target_box[3] - target_box[1]) / (source_box[3] - source_box[1])
        for style in STYLES:
            dressed = Image.open(source / f"{stage}-{style}-source.png").convert("RGBA")
            assert dressed.size == master.size
            mask = garment_mask(master, dressed, style)
            dressed.putalpha(mask)
            bbox = mask.getbbox()
            assert bbox is not None and bbox[2] - bbox[0] > 30 and bbox[3] - bbox[1] > 15, (species, stage, style, bbox)
            garment = dressed.crop(bbox)
            canvas = Image.new("RGBA", (SIZE, SIZE))
            position = (round(target_box[0] + (bbox[0] - source_box[0]) * sx),
                        round(target_box[1] + (bbox[1] - source_box[1]) * sy))
            size = (max(1, round(garment.width * sx)), max(1, round(garment.height * sy)))
            canvas.alpha_composite(garment.resize(size, Image.Resampling.LANCZOS), position)
            canvas.save(out / f"{stage}-{style}.png")
            for color, hex_color in enumerate(COLORS):
                recolor_fabric(canvas, style, hex_color).save(out / f"{stage}-{style}-{color}.png")
            report[f"{stage}-{style}"] = {"source_box": source_box, "target_box": target_box,
                                           "garment_box": bbox, "position": position, "size": size}
    (out / "manifest.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"built {len(report)} VARCO garments for {species}")


if __name__ == "__main__":
    main()
