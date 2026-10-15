from pathlib import Path
import hashlib, importlib.util, json, os, re, subprocess, sys, zipfile

ROOT=Path('C:/Users/rlagk/Documents/바탕화면 친구')
INSTALL=ROOT.parent/'복슬복슬펫'
OUT=ROOT/'builds/purchase-life-20261016'
STAGE=OUT/'source'
BASE=ROOT/'builds/purchase-small-20261009/BoksilboksilPet-0.33.3-Windows-Purchase.zip'
TAG='v0.33.4-purchase.20261016'
NAME='BoksilboksilPet-0.33.4-Windows-Purchase.zip'
sys.path.insert(0,str(ROOT/'tools'))
import build_small_packs as packs
import release_snapshot as github
import release_menu_update as release

def git(*args,input=None,env=None):
    return subprocess.check_output(['git',*args],cwd=ROOT,input=input,env=env)
def put(name,data):
    p=STAGE/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
def normalized(data): return data.decode('utf-8-sig').replace('\r\n','\n')
def patch_menu(raw):
    s=normalized(raw)
    assert 'func open_v1_action_album' not in s
    reference=normalized((INSTALL/'output/v1-action-album/patch/scripts/friend_menu.gd').read_bytes())
    funcs=reference[reference.index('func open_v1_action_album'):reference.index('func open_source')]
    s=s.replace('func open_source',funcs+'func open_source',1)
    s=s.replace('\tabout_to_popup.connect(prepare)','\tabout_to_popup.connect(prepare)\n\tif OS.get_cmdline_user_args().has("--v1-action-album"): open_v1_action_album.call_deferred()',1)
    block=reference[reference.index('\tif section in [0,3]:'):reference.index('\tvar caption=Label.new()')]
    assert '\tvar caption=Label.new()' in s
    return s.replace('\tvar caption=Label.new()',block+'\tvar caption=Label.new()',1).encode()
def patch_main(raw):
    s=normalized(raw);assert 'get_node_or_null("V1ActionAlbum")' not in s
    n='\tif download_visible: ordered_windows.append(animal_packs.panel)';assert n in s
    return s.replace(n,'\tvar album=get_node_or_null("V1ActionAlbum")\n\tif is_instance_valid(album) and album.visible: ordered_windows.append(album)\n'+n,1).encode()

def prepare():
    OUT.mkdir(parents=True,exist_ok=True)
    assert packs.sha(BASE)=='720c12b8c048b3b8aebd889b24daf707c254b222882fb886e102f1fd21d5a446'
    with zipfile.ZipFile(BASE) as z:
        assert z.testzip() is None
        for name in z.namelist():
            if name in ['DesktopFriends.exe','DesktopFriends.pck','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json'] or name.startswith('addons/'):
                path=OUT/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(z.read(name))
    header,table=packs.read_table(OUT/'DesktopFriends.pck');resources={}
    with (OUT/'DesktopFriends.pck').open('rb') as f:
        for n,(offset,size,digest) in table.items():
            f.seek(offset);b=f.read(size);assert hashlib.md5(b).digest()==digest;resources[n]=b
    base_digests={n:hashlib.sha256(b).hexdigest() for n,b in resources.items()}
    parent=git('rev-parse','HEAD').decode().strip();(OUT/'parent.txt').write_text(parent)
    for name,fn in [('scripts/main.gd',patch_main),('scripts/friend_menu.gd',patch_menu)]:
        resources[name]=fn(resources[name]);put(name,fn(git('show',parent+':'+name)))
    for name in ['scripts/v1_action_album.gd','scripts/v1_action_album_data.gd','scripts/home_animation.gd']:
        resources[name]=(ROOT/name).read_bytes();put(name,resources[name])
    config=resources['project.godot'].decode();assert '[commerce]' in config and 'enabled=true' in config
    assert 'site_url="https://boksilboksil.kr"' in config
    resources['project.godot']=re.sub(r'config/version="[^"]+"','config/version="0.33.4"',config).encode()
    changed=[n for n,b in resources.items() if base_digests.get(n)!=hashlib.sha256(b).hexdigest()]
    assert set(changed)<=set(['project.godot','scripts/main.gd','scripts/friend_menu.gd','scripts/home_animation.gd','scripts/v1_action_album.gd','scripts/v1_action_album_data.gd'])
    packs.write_pack(OUT/'DesktopFriends.pck',resources,header)
    verification={'base':'v0.33.3-purchase.20261009','purchase_only':True,'changed_resources':changed,'pck_sha256':packs.sha(OUT/'DesktopFriends.pck'),'new_animation_frames':False}
    (OUT/'PACKAGE-VERIFICATION.json').write_text(json.dumps(verification,indent=2))
    put('docs/V1-ACTION-ALBUM-HANDOFF-2026-10-16.md',(INSTALL/'v1-행동도감-인수인계-2026-10-14.md').read_bytes())
    check=(INSTALL/'output/v1-life-20s/check.gd').read_text(encoding='utf-8-sig')
    check=check.replace('C:/Users/rlagk/Documents/복슬복슬펫/0.33.0-small-preview/animal-packs','res://animal-packs')
    put('tests/v1_life_duration_test.gd',check.encode())
    body='''# 복슬복슬펫 v1 · 0.33.4

ZIP을 새 폴더에 모두 풀고 **DesktopFriends.exe**를 실행하세요. 계정을 연결하면 구매·수령한 동물만 이용할 수 있습니다. 기존 성장·가구 저장은 유지됩니다.

## 변경 사항
- 동물 우클릭 → 함께하기 또는 생활 기록 → **행동 도감**에서 16가지 행동과 발생 방법을 확인할 수 있습니다.
- 현재 동물의 새끼·성체 미리보기, 일시 정지, 방향 전환, 가구 해금 조건 및 배치 바로가기를 제공합니다.
- 생활 행동을 20초대로 조정했습니다. 독서 25.2초, 낮잠·차·음악 21.6초, 휴식 24초, 몸단장 20.4초, 놀이 25.6초입니다. 기존 재생 속도와 완전한 반복 주기를 유지합니다.
- 숨김 실행 시 행동 도감의 첫 표시가 누락되던 문제를 수정했습니다.

기존 16종 v1 업데이트입니다. 기존 원본 애니메이션을 연결한 도감이며 새 프레임 생성이나 목욕 추가는 포함하지 않습니다.

구매 동물 권한 확인과 다운로드 제한은 0.33.3의 동작을 유지합니다. 인터넷 연결이 필요하며, ZIP 다운로드 자체로 동물 이용권이 생기지는 않습니다.

검증: 16종·새끼/성체의 224개 생활 행동 진입·유지·종료 검사, 도감 자산/조건 검사, 구매 권한 회귀 검사. 실제 결제는 수행하지 않았습니다.
'''
    put('docs/RELEASE-V1-2026-10-16.md',body.encode())
    put('tools/publish_v1_life_snapshot.py',Path(__file__).read_bytes())
    print('PREPARED',changed,flush=True)

def commit():
    parent=(OUT/'parent.txt').read_text().strip()
    env=os.environ.copy();env['GIT_INDEX_FILE']=str(OUT/'release.index')
    git('read-tree',parent,env=env)
    for p in STAGE.rglob('*'):
        if not p.is_file():continue
        name=p.relative_to(STAGE).as_posix();blob=git('hash-object','-w','--stdin',input=p.read_bytes()).decode().strip()
        git('update-index','--add','--cacheinfo','100644',blob,name,env=env)
    tree=git('write-tree',env=env).decode().strip()
    sha=git('commit-tree',tree,'-p',parent,input=b'Add v1 action album and 20-second home activities\n').decode().strip()
    branch='release/v1-life-0.33.4';git('update-ref','refs/heads/'+branch,sha,'0'*40)
    (OUT/'commit.txt').write_text(sha);print('COMMIT_READY',sha,branch,flush=True)

def package():
    sha=(OUT/'commit.txt').read_text().strip()
    files=[OUT/n for n in ['DesktopFriends.exe','DesktopFriends.pck','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json','PACKAGE-VERIFICATION.json']]
    files.extend(p for p in (OUT/'addons').rglob('*') if p.is_file())
    with zipfile.ZipFile(OUT/NAME,'w',zipfile.ZIP_DEFLATED,compresslevel=1) as z:
        for p in files:z.write(p,p.relative_to(OUT).as_posix())
        z.writestr('SOURCE_COMMIT.txt',sha+'\n')
        z.writestr('README.md',(STAGE/'docs/RELEASE-V1-2026-10-16.md').read_bytes())
        z.writestr('FILE-SHA256SUMS.txt',''.join(packs.sha(p)+'  '+p.relative_to(OUT).as_posix()+'\n' for p in files))
    with zipfile.ZipFile(OUT/NAME) as z:
        assert z.testzip() is None
        assert hashlib.sha256(z.read('DesktopFriends.pck')).hexdigest()==packs.sha(OUT/'DesktopFriends.pck')
    (OUT/'SHA256SUMS.txt').write_text(packs.sha(OUT/NAME)+'  '+NAME+'\n')
    print('ZIP_VERIFIED',NAME,(OUT/NAME).stat().st_size,flush=True)

def publish():
    sha=(OUT/'commit.txt').read_text().strip()
    git('push','origin','refs/heads/release/v1-life-0.33.4')
    release.OUT=OUT;release.TAG=TAG;release.NAME=NAME
    release.BODY=STAGE/'docs/RELEASE-V1-2026-10-16.md'
    release.TITLE='복슬복슬펫 v1 · 0.33.4 — 행동 도감과 생활 동작 개선'
    release.publish(sha)

if __name__=='__main__':
    {'prepare':prepare,'commit':commit,'package':package,'publish':publish}[sys.argv[1]]()
