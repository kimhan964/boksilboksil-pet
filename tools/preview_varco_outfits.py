"""Render all species/stages with VARCO garment textures for visual review."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SPECIES = ("rabbit", "otter", "squirrel", "hedgehog", "raccoon", "fox", "bear", "owl",
           "cat", "puppy", "hamster", "panda", "red_panda", "lamb", "koala", "penguin")
STAGES = ("baby", "adult")
STYLES = ("cape", "vest", "sweater")
OUT = ROOT / "design" / "outfits-varco-v1"

for style in STYLES:
    board = Image.new("RGB", (8 * 256, 4 * 284), "#edf4f6")
    draw = ImageDraw.Draw(board)
    for i, species in enumerate(SPECIES):
        for j, stage in enumerate(STAGES):
            frame = Image.open(ROOT / "assets" / "species-v3" / species / f"{stage}-idle.png").convert("RGBA").crop((0, 0, 256, 256))
            outfit = Image.open(ROOT / "assets" / "outfits-varco-v1" / species / f"{stage}-{style}.png").convert("RGBA")
            frame.alpha_composite(outfit)
            tile = Image.new("RGB", (256, 256), "#eaf1f3")
            tile.paste(frame, mask=frame.getchannel("A"))
            x, y = (i % 8) * 256, (i // 8 * 2 + j) * 284
            board.paste(tile, (x, y))
            draw.text((x + 8, y + 260), f"{species} {stage}", fill="#243039")
    board.save(OUT / f"review-{style}.png")
    print(OUT / f"review-{style}.png")
