"""Package the verified current small installation and publish immutable 0.33.1."""
import argparse, hashlib, json, shutil, urllib.request, zipfile
from pathlib import Path
import build_small_packs as packs
import release_snapshot as github

ROOT=Path(__file__).resolve().parents[1]
INSTALL=ROOT.parent/'복슬복슬펫/0.33.0-small-preview'
OUT=ROOT/'builds/release-menu-20261008'
TAG='v0.33.1-preview.20261008'
NAME='BoksilboksilPet-0.33.1-Windows-Small.zip'
BODY=ROOT/'docs/RELEASE-MENU-2026-10-08.md'
RESOURCES=['scripts/decor_art.gd','scripts/desktop_pet.gd','scripts/friend_menu.gd',
           'scripts/furniture_room.gd','scripts/main.gd','scripts/pet_state.gd',
           'scripts/play_catalog.gd','tests/menu_organization_test.gd',
           'assets/decor-cozy-v2/acorn-wobble-v2.png']

def package(commit):
    OUT.mkdir(parents=True,exist_ok=True)
    metadata=json.loads((INSTALL/'LATEST-RUNTIME.json').read_text(encoding='utf-8'))
    assert packs.sha(INSTALL/'DesktopFriends.pck')==metadata['pck_sha256']
    assert packs.sha(INSTALL/'DesktopFriends.exe')==metadata['exe_sha256']
    header,table=packs.read_table(INSTALL/'DesktopFriends.pck')
    resources={}
    with (INSTALL/'DesktopFriends.pck').open('rb') as stream:
        for name,(offset,size,digest) in table.items():
            stream.seek(offset); data=stream.read(size)
            assert hashlib.md5(data).digest()==digest,name
            resources[name]=data
    for name in RESOURCES:
        assert resources[name]==(ROOT/name).read_bytes(),'Outdated installed resource: '+name
    # Compact the patched runtime without rebuilding from historical art.
    packs.write_pack(OUT/'DesktopFriends.pck',resources,header)
    for name in ['DesktopFriends.exe','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json','OPTIMIZATION.json']:
        shutil.copy2(INSTALL/name,OUT/name)
    shutil.copytree(INSTALL/'addons',OUT/'addons',dirs_exist_ok=True)
    included=[OUT/name for name in ['DesktopFriends.exe','DesktopFriends.pck',
             'GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json','OPTIMIZATION.json']]
    included.extend(p for p in (OUT/'addons').rglob('*') if p.is_file())
    report={'version':'0.33.1-preview','commit':commit,'package_sha256':packs.sha(OUT/'DesktopFriends.pck'),
            'resources_match_source':RESOURCES,'resource_count':len(resources),
            'animal_packs':'Unchanged; original 0.33.0 immutable URLs and hashes retained'}
    (OUT/'PACKAGE-VERIFICATION.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    included.append(OUT/'PACKAGE-VERIFICATION.json')
    with zipfile.ZipFile(OUT/NAME,'w',zipfile.ZIP_DEFLATED,compresslevel=1) as archive:
        for path in included: archive.write(path,path.relative_to(OUT).as_posix())
        archive.writestr('README.md',BODY.read_text(encoding='utf-8'))
        archive.writestr('SOURCE_COMMIT.txt',commit+'\n')
        archive.writestr('FILE-SHA256SUMS.txt',''.join(packs.sha(p)+'  '+p.relative_to(OUT).as_posix()+'\n' for p in included))
        archive.write(ROOT/'docs/MENU-ORGANIZATION-HANDOFF-2026-10-08.md','docs/MENU-ORGANIZATION-HANDOFF-2026-10-08.md')
    with zipfile.ZipFile(OUT/NAME) as archive:
        assert archive.testzip() is None
        assert archive.read('SOURCE_COMMIT.txt').decode().strip()==commit
        assert hashlib.sha256(archive.read('DesktopFriends.pck')).hexdigest()==report['package_sha256']
    (OUT/'SHA256SUMS.txt').write_text(packs.sha(OUT/NAME)+'  '+NAME+'\n',encoding='utf-8')
    print('PACKAGE_VERIFIED',NAME,(OUT/NAME).stat().st_size,packs.sha(OUT/NAME),flush=True)

def publish(commit):
    headers=github.credentials()
    releases=github.api('/releases?per_page=100',headers)
    release=next((r for r in releases if r['tag_name']==TAG),None)
    if release is None:
        release=github.api('/releases',headers,'POST',{'tag_name':TAG,'target_commitish':commit,
            'name':'복슬복슬펫 0.33.1 · 함께하기 정리와 도토리 놀이','body':BODY.read_text(encoding='utf-8'),
            'draft':True,'prerelease':True})
    assert release['draft'],'Published release is immutable'
    assert release['target_commitish']==commit,'Draft source commit differs'
    for path in [OUT/NAME,OUT/'SHA256SUMS.txt']:
        asset=next((a for a in release['assets'] if a['name']==path.name),None)
        if asset is None: asset=github.upload(release['upload_url'],path,headers)
        assert asset['size']==path.stat().st_size and asset['state']=='uploaded'
        assert asset.get('digest')=='sha256:'+packs.sha(path)
        print('REMOTE_VERIFIED',path.name,flush=True)
    github.api('/releases/'+str(release['id']),headers,'PATCH',{'draft':False,'prerelease':True})
    public=github.api('/releases/tags/'+TAG,headers)
    ref=github.api('/git/ref/tags/'+TAG,headers)
    assert not public['draft'] and ref['object']['sha']==commit
    zip_asset=next(a for a in public['assets'] if a['name']==NAME)
    assert zip_asset.get('digest')=='sha256:'+packs.sha(OUT/NAME)
    # Read the actual anonymous download endpoint in addition to API metadata.
    request=urllib.request.Request(zip_asset['browser_download_url'],headers={'Range':'bytes=0-31','User-Agent':'Boksil-Release-Check'})
    with urllib.request.urlopen(request,timeout=60) as response:
        assert response.read(4)==b'PK\x03\x04','Public download is not a ZIP'
    result={'release':public['html_url'],'download':zip_asset['browser_download_url'],
            'commit':commit,'sha256':packs.sha(OUT/NAME),'size':zip_asset['size'],'public_verified':True}
    (OUT/'published.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print('PUBLIC_RELEASE_VERIFIED',json.dumps(result,ensure_ascii=False),flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('command',choices=['package','publish'])
    parser.add_argument('--commit',required=True);args=parser.parse_args()
    package(args.commit) if args.command=='package' else publish(args.commit)
