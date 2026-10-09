"""Build commerce-only small candidate from the current verified release snapshot."""
import hashlib,json,shutil,zipfile
from pathlib import Path
from build_small_packs import read_table,write_pack,sha
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'builds/purchase-small-20261008'
OUT=ROOT/'builds/purchase-small-20261009'
def build():
    header,table=read_table(SOURCE/'DesktopFriends.pck');resources={}
    with (SOURCE/'DesktopFriends.pck').open('rb') as stream:
        for name,(offset,size,digest) in table.items():
            stream.seek(offset);data=stream.read(size)
            assert hashlib.md5(data).digest()==digest,name
            resources[name]=data
    for name in ['scripts/main.gd','scripts/animal_pack_manager.gd','scripts/commerce_access.gd',
                 'tests/purchase_pack_access_test.gd','tests/commerce_access_test.gd','tests/account_window_review.gd']:
        resources[name]=(ROOT/name).read_bytes()
    config=resources['project.godot'].decode('utf-8')
    assert 'enabled=true' in config and 'site_url="https://boksilboksil.kr"' in config
    config=config.replace('[application]\n','[application]\nconfig/version="0.33.3"\n')
    resources['project.godot']=config.encode()
    OUT.mkdir(parents=True,exist_ok=True)
    write_pack(OUT/'DesktopFriends.pck',resources,header)
    for name in ['DesktopFriends.exe','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json']:
        shutil.copy2(SOURCE/name,OUT/name)
    shutil.copytree(SOURCE/'addons',OUT/'addons',dirs_exist_ok=True)
    report={'version':'0.33.3','purchase_only':True,'site_url':'https://boksilboksil.kr',
            'source_snapshot_sha256':sha(SOURCE/'DesktopFriends.pck'),
            'pck_sha256':sha(OUT/'DesktopFriends.pck'),'changed_resources':[
                'project.godot','scripts/main.gd','scripts/animal_pack_manager.gd','scripts/commerce_access.gd',
                'tests/purchase_pack_access_test.gd','tests/commerce_access_test.gd','tests/account_window_review.gd'],
            'public_downloads_replaced':False}
    (OUT/'PURCHASE-BUILD.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    files=[OUT/n for n in ['DesktopFriends.exe','DesktopFriends.pck','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json','PURCHASE-BUILD.json']]
    files.extend(p for p in (OUT/'addons').rglob('*') if p.is_file())
    target=OUT/'BoksilboksilPet-0.33.3-Windows-Purchase.zip'
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=1) as archive:
        for path in files:archive.write(path,path.relative_to(OUT).as_posix())
        archive.writestr('README.txt','Windows purchase-only build. Extract all files, run DesktopFriends.exe and connect the account holding your animal entitlement. Only server-approved animals may be selected/downloaded/used. Internet is required to verify access. Existing pet progress is retained. No animal entitlement is granted by downloading this program.\n')
        archive.writestr('FILE-SHA256SUMS.txt',''.join(sha(p)+'  '+p.relative_to(OUT).as_posix()+'\n' for p in files))
    with zipfile.ZipFile(target) as archive:assert archive.testzip() is None
    print('PURCHASE_ZIP_VERIFIED',target,sha(target),flush=True)
if __name__=='__main__':build()
