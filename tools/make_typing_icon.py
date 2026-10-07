"""Package generated Typing Friends artwork without changing the design."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'games/typing-pet/assets/icon'
SIZES = (16, 24, 32, 48, 64, 128, 256)
with Image.open(FOLDER / 'typing-friends-source.png') as source:
    icon = source.convert('RGBA')
    assert icon.getchannel('A').getextrema() == (0, 255)
    icon.resize((256, 256), Image.Resampling.LANCZOS).save(FOLDER / 'pet-icon.png')
    icon.save(FOLDER / 'typing-friends.ico', sizes=[(s, s) for s in SIZES])
with Image.open(FOLDER / 'typing-friends.ico') as icon:
    assert icon.ico.sizes() == {(s, s) for s in SIZES}
    for size in SIZES:
        image = icon.ico.getimage((size, size))
        assert image.size == (size, size)
    print('ICON_VERIFIED:', sorted(icon.ico.sizes()))
