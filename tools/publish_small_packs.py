"""Publish approved small runtime plus species packs, verifying each remote digest."""
import argparse,json,urllib.request
from build_small_packs import ROOT,OUT,TAG,sha
import release_snapshot as api
def publish(commit):
 headers=api.credentials()
 expected=[OUT/'BoksilboksilPet-0.33.0-Windows-Small.zip']+sorted((OUT/'animal-packs').glob('*.pck'))
 if len(expected)!=16:raise RuntimeError('Expected base ZIP and 15 species packs')
 manifest=json.loads((OUT/'animal-packs.json').read_text())
 for spec in manifest['animals'].values():
  p=OUT/'animal-packs'/spec['file']
  if sha(p)!=spec['sha256'] or p.stat().st_size!=spec['size']:raise RuntimeError('Manifest changed')
 sums=OUT/'SHA256SUMS.txt';sums.write_text(''.join(sha(p)+'  '+p.name+'\n' for p in expected),encoding='utf-8')
 expected.append(sums)
 release=next((r for r in api.api('/releases?per_page=100',headers) if r['tag_name']==TAG),None)
 body=(ROOT/'docs/RELEASE-SMALL-2026-10-07.md').read_text(encoding='utf-8')
 if release is None:
  release=api.api('/releases',headers,'POST',{'tag_name':TAG,'target_commitish':commit,'name':'복슬복슬펫 0.33.0 · 183MB 소형판과 동물별 다운로드','body':body,'draft':True,'prerelease':True})
 if not release['draft']:raise RuntimeError('Already public: do not mutate immutable published assets')
 if release['target_commitish']!=commit:raise RuntimeError('Draft commit mismatch')
 for path in expected:
  asset=next((a for a in release['assets'] if a['name']==path.name),None)
  if asset is None:asset=api.upload(release['upload_url'],path,headers)
  if asset['size']!=path.stat().st_size or asset.get('digest')!='sha256:'+sha(path) or asset['state']!='uploaded':raise RuntimeError('Remote verification failed: '+path.name)
  print('REMOTE VERIFIED',path.name,path.stat().st_size,flush=True)
 release=api.api('/releases/'+str(release['id']),headers,'PATCH',{'draft':False,'prerelease':True,'body':body})
 # Fresh API read, not just the publication response.
 public=api.api('/releases/tags/'+TAG,headers)
 ref=api.api('/git/ref/tags/'+TAG,headers)
 if public['draft'] or ref['object']['sha']!=commit:raise RuntimeError('Public tag verification failed')
 for path in expected:
  asset=next(a for a in public['assets'] if a['name']==path.name)
  if asset['size']!=path.stat().st_size or asset.get('digest')!='sha256:'+sha(path):raise RuntimeError('Public digest mismatch')
 result={'release':public['html_url'],'tag':TAG,'commit':commit,'public_verified':True,'assets':[{'name':a['name'],'size':a['size'],'digest':a.get('digest'),'url':a['browser_download_url']} for a in public['assets']]}
 (OUT/'published.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
 print('PUBLIC RELEASE VERIFIED',public['html_url'],commit,flush=True)
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--commit',required=True);args=parser.parse_args();publish(args.commit)
