import struct,hashlib
from pathlib import Path
p=Path('C:/Users/rlagk/Documents/복슬복슬펫/0.30.3/DesktopFriends.pck')
with p.open('rb') as f:
 h=f.read(128);base,directory=struct.unpack_from('<QQ',h,24)
 f.seek(directory);count=struct.unpack('<I',f.read(4))[0];entries={}
 for _ in range(count):
  n=struct.unpack('<I',f.read(4))[0];name=f.read(n).rstrip(b'\0').decode()
  entries[name]=struct.unpack('<QQ16sI',f.read(36))
 for name in ['scripts/smooth_species_art.gd','scripts/rabbit_pilot_art.gd','scripts/rabbit_hop_motion.gd','scripts/smooth_species_motion.gd','project.godot']:
  offset,size,*_=entries[name];f.seek(base+offset);data=f.read(size)
  source=Path(name).read_bytes()
  print(name,'matches_source',hashlib.sha256(data).digest()==hashlib.sha256(source).digest())
  if name.endswith('_art.gd') or name=='project.godot':
   print('\n'.join(line for line in data.decode().splitlines() if 'version=' in line or 'static var path' in line or 'rendering' in line))
 print('walk_v14_manifests',len([x for x in entries if x.startswith('assets/walk-v14/') and x.endswith('manifest.json')]))
 print('rabbit_v9_manifest','assets/rabbit-frame-pilot-v9/manifest.json' in entries)
