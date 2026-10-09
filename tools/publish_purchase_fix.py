import argparse,zipfile
import release_menu_update as release
from build_small_packs import sha
release.OUT=release.ROOT/'builds/purchase-small-20261009'
release.TAG='v0.33.3-purchase.20261009'
release.NAME='BoksilboksilPet-0.33.3-Windows-Purchase.zip'
release.BODY=release.ROOT/'docs/RELEASE-PURCHASE-2026-10-09.md'
release.TITLE='복슬복슬펫 0.33.3 · 계정 창과 구매 동물 다운로드 수정'
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--commit',required=True);args=parser.parse_args()
    path=release.OUT/release.NAME
    with zipfile.ZipFile(path,'a',zipfile.ZIP_DEFLATED) as archive:
        if 'SOURCE_COMMIT.txt' not in archive.namelist(): archive.writestr('SOURCE_COMMIT.txt',args.commit+'\n')
        assert archive.read('SOURCE_COMMIT.txt').decode().strip()==args.commit
        assert archive.testzip() is None
    (release.OUT/'SHA256SUMS.txt').write_text(sha(path)+'  '+path.name+'\n',encoding='utf-8')
    release.publish(args.commit)
