"""Package the approved generated artwork as PNG and Windows ICO (Pillow)."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
folder = root / 'assets/icon'
with Image.open(folder / 'puppy-source.png') as source:
    image = source.convert('RGBA')
    assert image.getchannel('A').getextrema() == (0, 255), 'Transparent source required'
    image.resize((256, 256), Image.Resampling.LANCZOS).save(folder / 'pet-icon.png')
    image.save(folder / 'pet-icon.ico', sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])
with Image.open(folder / 'pet-icon.ico') as icon:
    assert len(icon.ico.sizes()) == 7
    print('ICON_SIZES:', sorted(icon.ico.sizes()))
