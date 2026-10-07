import runpy,re,hashlib,struct,json
from pathlib import Path
from hotpatch_pack import patch,SOURCE
import sys
pack=Path('C:/Users/rlagk/Documents/복슬복슬펫/0.30.3/DesktopFriends.pck')
entries=runpy.run_path(str(SOURCE/'tools/check_walk_pack.py'))['entries']
roots=set()
for script in (SOURCE/'scripts').glob('*.gd'):
 roots.update(re.findall(r'res://assets/([\w-]+)/',script.read_text(encoding='utf-8')))
roots.update(['walk-v14','rabbit-frame-pilot-v9'])
missing=[];sizes={}
for root in sorted(roots):
 for p in (SOURCE/'assets'/root).rglob('*'):
  if not p.is_file() or p.suffix not in ['.png','.json','.res','.tres']: continue
  name=p.relative_to(SOURCE).as_posix()
  if name not in entries or hashlib.md5(p.read_bytes()).digest()!=entries[name][2]:
   missing.append(name);sizes[root]=sizes.get(root,0)+p.stat().st_size
print('Runtime asset differences MB:',{k:round(v/1048576,2) for k,v in sizes.items()},'files',len(missing),'total_MB',round(sum(sizes.values())/1048576,2))
if '--patch' in sys.argv:
 patch(pack,missing,'complete-runtime-assets-20261007')
 print('Runtime assets complete')
