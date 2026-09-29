"""Package generated full-body dressed 4x4 animation sheets as 16 game cels.

Each output cel remains a complete animal drawing. No garment or anatomy is
separated and the original undressed sequence's scale and feet root are used
so changing outfits does not change the animal's size or position.
"""

from pathlib import Path
import argparse
import json
from collections import deque

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SIZE = 256


def remove_cyan(cell: Image.Image) -> Image.Image:
    rgb = np.asarray(cell.convert("RGB"), dtype=np.float32)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    spill = np.minimum(g - r, b - r)
    alpha = np.clip(1 - (spill - 10) / 210, 0, 1)
    alpha[alpha < .025] = 0
    safe = np.maximum(alpha, .001)
    output = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    output[:, :, 0] = np.clip(r / safe, 0, 255).astype(np.uint8)
    output[:, :, 1] = np.clip((g - (1 - alpha) * 245) / safe, 0, 255).astype(np.uint8)
    output[:, :, 2] = np.clip((b - (1 - alpha) * 245) / safe, 0, 255).astype(np.uint8)
    output[:, :, 3] = np.rint(alpha * 255).astype(np.uint8)
    output[output[:, :, 3] == 0, :3] = 0
    return Image.fromarray(output, "RGBA")


def keep_whole_character(cell: Image.Image, center: tuple[float, float]) -> Image.Image:
    pixels = np.asarray(cell).copy()
    opaque = pixels[:, :, 3] > 24
    ys, xs = np.nonzero(opaque)
    if not len(xs):
        return cell
    nearest = int(np.argmin((xs - center[0]) ** 2 + (ys - center[1]) ** 2))
    seed = (int(xs[nearest]), int(ys[nearest]))
    visited = np.zeros((SIZE, SIZE), dtype=bool)
    visited[seed[1], seed[0]] = True
    queue = deque([seed])
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < SIZE and 0 <= ny < SIZE and opaque[ny, nx] and not visited[ny, nx]:
                visited[ny, nx] = True
                queue.append((nx, ny))
    pixels[~visited] = 0
    return Image.fromarray(pixels, "RGBA")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("species")
    parser.add_argument("stage", choices=("baby", "adult"))
    parser.add_argument("style", choices=("cape", "vest", "sweater"))
    parser.add_argument("action")
    parser.add_argument("--pilot", action="store_true")
    parser.add_argument("--local", action="store_true", help="Use project image-generation output")
    args = parser.parse_args()
    if args.local and args.pilot:
        parser.error("--local and --pilot are exclusive")
    version = "local-sources" if args.local else ("pilot" if args.pilot else "production-sources")
    source = ROOT / "design/outfits-dressed-v2" / version / args.species / args.stage / args.style / f"{args.action}.png"
    if not source.is_file():
        raise SystemExit(f"Missing generated sheet: {source}")
    sheet = Image.open(source).convert("RGBA")
    if sheet.width != sheet.height or sheet.width < 1024:
        raise SystemExit(f"Expected square 4x4 sprite sheet at least 1024px: {source} {sheet.size}")
    has_alpha = sheet.getextrema()[3][0] < 255
    base = json.loads((ROOT / "assets/species-v3" / args.species / "manifest.json").read_text(encoding="utf-8"))
    original = base["stages"][args.stage]["sequences"][args.action]
    output = Image.new("RGBA", (SIZE * 16, SIZE))
    prepared = []
    for frame in range(16):
        x, y = frame % 4, frame // 4
        cell = sheet.crop((round(x * sheet.width / 4), round(y * sheet.height / 4),
                           round((x + 1) * sheet.width / 4), round((y + 1) * sheet.height / 4)))
        if cell.size != (SIZE, SIZE):
            cell = cell.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
        cel = cell if has_alpha else remove_cyan(cell)
        original_box = original["anchors"][frame]["source_bounds"]
        center = (original_box[0] + original_box[2] / 2, original_box[1] + original_box[3] / 2)
        cel = keep_whole_character(cel, center)
        bbox = cel.getbbox()
        if bbox is None or (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]) < 1000:
            raise SystemExit(f"Missing complete figure: {source} frame {frame}")
        anchor = original["anchors"][frame]
        scale = float(anchor["scale"])
        root = anchor["source_root"]
        width = max(1, round((bbox[2] - bbox[0]) * scale))
        height = max(1, round((bbox[3] - bbox[1]) * scale))
        left = round(128 + (bbox[0] - root[0]) * scale)
        top = round(232 + (bbox[1] - root[1]) * scale)
        rendered = cel.crop(bbox).resize((width, height), Image.Resampling.LANCZOS)
        prepared.append((rendered, left, top, width, height))
    min_x = min(item[1] for item in prepared)
    min_y = min(item[2] for item in prepared)
    max_x = max(item[1] + item[3] for item in prepared)
    max_y = max(item[2] + item[4] for item in prepared)
    shift_x = max(0, 1 - min_x) if min_x < 1 else min(0, SIZE - 1 - max_x)
    shift_y = max(0, 1 - min_y) if min_y < 1 else min(0, SIZE - 1 - max_y)
    if abs(shift_x) > 10 or abs(shift_y) > 10:
        raise SystemExit(f"Generated figure too far outside frame: {source} {(min_x, min_y, max_x, max_y)}")
    cell_bounds = []
    for frame, (rendered, left, top, width, height) in enumerate(prepared):
        left += shift_x
        top += shift_y
        if left < 1 or top < 1 or left + width > SIZE - 1 or top + height > SIZE - 1:
            raise SystemExit(f"Clipped dressed frame: {source} frame {frame}: {(left, top, width, height)}")
        output.alpha_composite(rendered, (frame * SIZE + left, top))
        cell_bounds.append([left, top, width, height])
    folder = ROOT / "assets/outfits-dressed-v2" / args.species / args.stage / args.style
    folder.mkdir(parents=True, exist_ok=True)
    output.save(folder / f"{args.action}.png", optimize=True)
    (folder / f"{args.action}.json").write_text(json.dumps({"source": str(source.relative_to(ROOT)), "bounds": cell_bounds,
                                                      "sheet_shift": [shift_x, shift_y]}, indent=2), encoding="utf-8")
    print(f"DRESSED_CELS {args.species}/{args.stage}/{args.style}/{args.action}=16")


if __name__ == "__main__":
    main()
