import runpy, hashlib, sys
from pathlib import Path
from hotpatch_pack import patch, SOURCE

pack = Path('C:/Users/rlagk/Documents/복슬복슬펫/0.30.3/DesktopFriends.pck')
entries = runpy.run_path(str(SOURCE/'tools/check_walk_pack.py'))['entries']
files = []
for root in ['scripts', 'scenes']:
    for p in (SOURCE/root).rglob('*'):
        if p.is_file() and p.suffix in ['.gd', '.gdshader', '.gdshaderinc', '.tscn', '.tres']:
            name = p.relative_to(SOURCE).as_posix()
            if name not in entries or hashlib.md5(p.read_bytes()).digest() != entries[name][2]:
                files.append(name)
print('Runtime code differences:', files)
if '--patch' in sys.argv and files:
    patch(pack, files, 'complete-runtime-code-20261007')
