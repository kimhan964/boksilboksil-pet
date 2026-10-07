from pathlib import Path
from hotpatch_pack import patch,SOURCE
files=[]
for directory in ['assets/walk-v14','assets/rabbit-frame-pilot-v9']:
 files.extend(p.relative_to(SOURCE).as_posix() for p in (SOURCE/directory).rglob('*') if p.is_file() and p.suffix in ['.json','.png'])
files+=['scripts/rabbit_hop_motion.gd','scripts/toy_play.gd','tests/general_walk_profile.gd','tests/toy_play_test.gd']
patch(Path('C:/Users/rlagk/Documents/복슬복슬펫/0.30.3/DesktopFriends.pck'),files,'latest-walk-assets-20261007')
