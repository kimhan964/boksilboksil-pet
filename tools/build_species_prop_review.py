"""Build a local art candidate from the verified purchase runtime; no publishing."""
from pathlib import Path
import sys,shutil,json
from build_small_packs import read_table,write_pack,sha
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'builds/purchase-small-20261009'
OUT=ROOT/'builds/species-props-20261009'
def build():
    h,t=read_table(SOURCE/'DesktopFriends.pck');resources={}
    with (SOURCE/'DesktopFriends.pck').open('rb') as f:
        for name,(offset,size,digest) in t.items():f.seek(offset);resources[name]=f.read(size)
    paths=['scripts/friend_menu.gd','scripts/home_unlocks.gd','scripts/play_catalog.gd','tests/home_unlock_rules_test.gd','scripts/decor_art.gd','scripts/main.gd','scripts/pet_state.gd','scripts/furniture_room.gd','scripts/furniture_arrivals.gd',
           'tests/species_prop_art_review.gd','tests/species_prop_native_review.gd','tests/automatic_delivery_limit_test.gd','tests/auto_delivery_menu_review.gd','assets/species-props-v2/manifest.json']
    paths.extend(p.relative_to(ROOT).as_posix() for p in (ROOT/'assets/species-props-v2').glob('*.png') if not p.name.endswith('-atlas.png'))
    for name in paths:resources[name]=(ROOT/name).read_bytes()
    OUT.mkdir(parents=True,exist_ok=True)
    write_pack(OUT/'DesktopFriends.pck',resources,h)
    for name in ['DesktopFriends.exe','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json']:shutil.copy2(SOURCE/name,OUT/name)
    shutil.copytree(SOURCE/'addons',OUT/'addons',dirs_exist_ok=True)
    (OUT/'ART-UPDATE.json').write_text(json.dumps({'source_pck_sha256':sha(SOURCE/'DesktopFriends.pck'),'pck_sha256':sha(OUT/'DesktopFriends.pck'),'resources':paths,'published':False,'commerce_preserved':True},indent=2),encoding='utf-8')
    print('SPECIES_PROP_CANDIDATE_VERIFIED',sha(OUT/'DesktopFriends.pck'))
if __name__=='__main__':build()
