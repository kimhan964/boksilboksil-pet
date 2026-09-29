"""Check complete dressed animation cels and write a contact sheet for review."""

from pathlib import Path
import argparse
import json

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
STAGES = ("baby", "adult")
STYLES = ("cape", "vest", "sweater")
ACTIONS = ("idle", "walk", "pet", "eat", "drink", "sleep", "carry", "jump", "look", "sniff", "wave", "groom", "stretch", "rub", "toy", "rest")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("species")
    parser.add_argument("--complete", action="store_true")
    args = parser.parse_args()
    folder = ROOT / "assets/outfits-dressed-v2" / args.species
    failures = []
    present = 0
    contact = Image.new("RGB", (16 * 140, 6 * 166), "#edf2f4")
    draw = ImageDraw.Draw(contact)
    for row, (style, stage) in enumerate((style, stage) for style in STYLES for stage in STAGES):
        for col, action in enumerate(ACTIONS):
            file = folder / stage / style / f"{action}.png"
            if not file.exists():
                if args.complete:
                    failures.append(f"missing {stage}/{style}/{action}")
                continue
            present += 1
            image = Image.open(file).convert("RGBA")
            if image.size != (4096, 256):
                failures.append(f"size {stage}/{style}/{action}: {image.size}")
                continue
            for frame in range(16):
                cell = image.crop((frame * 256, 0, (frame + 1) * 256, 256))
                box = cell.getbbox()
                if box is None:
                    failures.append(f"blank {stage}/{style}/{action}/{frame}")
                    continue
                if box[0] <= 0 or box[1] <= 0 or box[2] >= 256 or box[3] >= 256:
                    failures.append(f"edge {stage}/{style}/{action}/{frame}: {box}")
                if np.count_nonzero(np.asarray(cell)[:, :, 3] > 32) < 1000:
                    failures.append(f"tiny {stage}/{style}/{action}/{frame}")
            preview = image.crop((0, 0, 256, 256)).resize((122, 122), Image.Resampling.LANCZOS)
            contact.paste(preview, (col * 140 + 9, row * 166 + 5), preview)
            draw.text((col * 140 + 8, row * 166 + 131), f"{stage[0]}/{style[0]} {action}", fill="#25322a")
    review = ROOT / "design/runtime-review" / f"dressed-{args.species}-contact.png"
    review.parent.mkdir(parents=True, exist_ok=True)
    contact.save(review)
    print(json.dumps({"species": args.species, "sheets": present, "frames": present * 16,
                      "failures": failures[:30], "failure_count": len(failures), "review": str(review)}))
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
