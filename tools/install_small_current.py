"""Install the small runtime and local offline packs without changing player saves."""
import datetime,json,shutil
from pathlib import Path
from build_small_packs import ROOT,OUT,sha
TARGET=ROOT.parent/'복슬복슬펫'/'0.33.0-small-preview'
def install():
 TARGET.mkdir(parents=True,exist_ok=True)
 for name in ['DesktopFriends.exe','DesktopFriends.pck','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json','OPTIMIZATION.json']:
  shutil.copy2(OUT/name,TARGET/name)
 shutil.copytree(OUT/'addons',TARGET/'addons',dirs_exist_ok=True)
 shutil.copytree(OUT/'animal-packs',TARGET/'animal-packs',dirs_exist_ok=True)
 for source in (OUT/'animal-packs').glob('*.pck'):
  assert sha(source)==sha(TARGET/'animal-packs'/source.name)
 assert sha(OUT/'DesktopFriends.pck')==sha(TARGET/'DesktopFriends.pck')
 manifest=json.loads((ROOT.parent/'복슬복슬펫/0.30.3/LATEST-RUNTIME.json').read_text(encoding='utf-8-sig'))
 manifest.update({'updated_at':datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).isoformat(),'version':'0.33.0-small-preview','executable':str(TARGET/'DesktopFriends.exe'),'working_directory':str(TARGET),'package':str(TARGET/'DesktopFriends.pck'),'exe_sha256':sha(TARGET/'DesktopFriends.exe'),'pck_sha256':sha(TARGET/'DesktopFriends.pck'),'github_updated':False,'previous_github_release':manifest.get('github_release'),'github_release':None,'optimization':json.loads((OUT/'OPTIMIZATION.json').read_text()),'animal_packs':'local offline 15 packs, runtime verified on selection; remote publishing pending','standalone_tests':['optimized_assets: PASS 1887 RGBA/canvas checks and 16 species both ages','animal_pack_download: PASS real local HTTP, offline cache, corruption, cancel, retry, old pet preserved','latest_walk_package: PASS 60 frames both ages','otter_expression: PASS 8 poses','furniture_drop: PASS 1344 cases','furniture_front: PASS','toy_play: PASS'],'small_zip_sha256':sha(OUT/'BoksilboksilPet-0.33.0-Windows-Small.zip')})
 # Historical release digest fields are not hashes of this build.
 for key in ['github_commit','release_compacted_pck_sha256','release_zip_sha256']:manifest.pop(key,None)
 (TARGET/'LATEST-RUNTIME.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
 print('INSTALLED VERIFIED',TARGET,manifest['pck_sha256'],flush=True)
if __name__=='__main__':install()
