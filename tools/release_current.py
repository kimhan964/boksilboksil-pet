"""Compact the verified installed PCK without changing a single resource byte."""
import argparse,hashlib,json,struct,shutil,os,zipfile
from pathlib import Path
SOURCE=Path(__file__).resolve().parents[1]
INSTALL=SOURCE.parent/'복슬복슬펫'/'0.30.3'
OUTPUT=SOURCE/'builds'/'release-20261007'
TAG='v0.32.0-preview.20261007'
NAME='BoksilboksilPet-0.32.0-Windows.zip'
def digest(path):
 with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def compact():
 OUTPUT.mkdir(parents=True,exist_ok=True)
 origin=INSTALL/'DesktopFriends.pck';target=OUTPUT/'DesktopFriends.pck'
 if target.exists():raise RuntimeError('Output already exists; inspect before overwriting')
 manifest=json.loads((INSTALL/'LATEST-RUNTIME.json').read_text(encoding='utf-8-sig'))
 if digest(origin).upper()!=manifest['pck_sha256'].upper():raise RuntimeError('Installed manifest mismatch')
 with origin.open('rb') as src,target.open('xb') as out:
  header=bytearray(src.read(128))
  if struct.unpack_from('<6I',header)!=(0x43504447,4,4,7,2,2):raise RuntimeError('Unsupported PCK')
  base,directory=struct.unpack_from('<QQ',header,24);src.seek(directory)
  count=struct.unpack('<I',src.read(4))[0];entries=[]
  for _ in range(count):
   length=struct.unpack('<I',src.read(4))[0];name=src.read(length).rstrip(b'\0').decode()
   offset,size,md5,flags=struct.unpack('<QQ16sI',src.read(36))
   if flags or base+offset+size>directory:raise RuntimeError('Invalid PCK entry')
   entries.append((name,offset,size,md5))
  out.write(header);unique={};packed=[];duplicates=0;duplicate_bytes=0
  for name,offset,size,expected in entries:
   src.seek(base+offset);md5=hashlib.md5();sha=hashlib.sha256();left=size
   while left:
    block=src.read(min(left,1024*1024))
    if not block:raise RuntimeError('Truncated PCK')
    md5.update(block);sha.update(block);left-=len(block)
   if md5.digest()!=expected:raise RuntimeError('Resource digest mismatch: '+name)
   key=(size,sha.digest())
   if key in unique:
    new_offset=unique[key];duplicates+=1;duplicate_bytes+=size
   else:
    out.write(b'\0'*((-out.tell())%32));new_offset=out.tell()-base;unique[key]=new_offset
    src.seek(base+offset);left=size
    while left:
     block=src.read(min(left,1024*1024));out.write(block);left-=len(block)
   packed.append((name,new_offset,size,expected))
  out.write(b'\0'*((-out.tell())%32));new_directory=out.tell();out.write(struct.pack('<I',len(packed)))
  for name,offset,size,md5 in sorted(packed):
   encoded=name.encode();encoded+=b'\0'*((-len(encoded))%4)
   out.write(struct.pack('<I',len(encoded))+encoded+struct.pack('<QQ16sI',offset,size,md5,0))
  struct.pack_into('<Q',header,32,new_directory);out.seek(0);out.write(header);out.flush();os.fsync(out.fileno())
 # Independently verify every resulting resource against its recorded MD5.
 with target.open('rb') as stream:
  for name,offset,size,expected in packed:
   stream.seek(base+offset);md5=hashlib.md5();left=size
   while left:
    block=stream.read(min(left,1024*1024));md5.update(block);left-=len(block)
   if md5.digest()!=expected:raise RuntimeError('Compacted resource changed: '+name)
 for name in ['DesktopFriends.exe','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json']:
  shutil.copy2(INSTALL/name,OUTPUT/name)
 for file in (INSTALL/'addons/windows_mouse_passthrough').rglob('*'):
  if file.is_file():
   dest=OUTPUT/file.relative_to(INSTALL);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,dest)
 report={'original_bytes':origin.stat().st_size,'compacted_bytes':target.stat().st_size,'resources':count,'identical_resource_duplicates':duplicates,'duplicate_bytes_removed':duplicate_bytes,'changed_resource_bytes':0,'original_sha256':digest(origin),'compacted_sha256':digest(target)}
 (OUTPUT/'OPTIMIZATION.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report),flush=True)
def package(commit):
 archive=OUTPUT/NAME
 entries=[(OUTPUT/name,name) for name in ['DesktopFriends.exe','DesktopFriends.pck','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json','OPTIMIZATION.json']]
 entries += [(p,p.relative_to(OUTPUT).as_posix()) for p in (OUTPUT/'addons').rglob('*') if p.is_file()]
 entries += [(SOURCE/'docs/RELEASE-2026-10-07.md','README.md')]
 sums=[digest(p)+'  '+name for p,name in entries]
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6,allowZip64=True) as z:
  for file,name in entries:z.write(file,name)
  z.writestr('SOURCE_COMMIT.txt',commit+'\n');z.writestr('FILE-SHA256SUMS.txt','\n'.join(sums)+'\n')
 with zipfile.ZipFile(archive) as z:
  if z.testzip():raise RuntimeError('ZIP CRC failure')
  assert z.namelist().count('DesktopFriends.pck')==1
 (OUTPUT/'SHA256SUMS.txt').write_text(digest(archive)+'  '+archive.name+'\n',encoding='utf-8')
 print('ZIP VERIFIED',archive.name,archive.stat().st_size,digest(archive),flush=True)
def publish(commit):
 import release_snapshot as api
 headers=api.credentials();releases=api.api('/releases?per_page=100',headers)
 release=next((r for r in releases if r['tag_name']==TAG),None)
 if release is None:
  release=api.api('/releases',headers,'POST',{'tag_name':TAG,'target_commitish':commit,'name':'복슬복슬펫 0.32.0 · 새 수달 표정과 집 꾸미기','body':(SOURCE/'docs/RELEASE-2026-10-07.md').read_text(encoding='utf-8'),'draft':True,'prerelease':True})
 for path in [OUTPUT/NAME,OUTPUT/'SHA256SUMS.txt']:
  asset=next((a for a in release['assets'] if a['name']==path.name),None)
  if asset is None:asset=api.upload(release['upload_url'],path,headers)
  if asset.get('digest')!='sha256:'+digest(path) or asset['size']!=path.stat().st_size or asset['state']!='uploaded':raise RuntimeError('Remote verification failed')
  print('REMOTE VERIFIED',path.name,flush=True)
 release=api.api('/releases/'+str(release['id']),headers,'PATCH',{'draft':False,'prerelease':True})
 result={'release':release['html_url'],'commit':commit,'assets':[{'name':a['name'],'url':a['browser_download_url'],'size':a['size'],'digest':a.get('digest')} for a in release['assets']]}
 (OUTPUT/'published.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result),flush=True)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('command',choices=['compact','package','publish']);p.add_argument('--commit');a=p.parse_args()
 if a.command!='compact' and not a.commit:p.error('--commit required')
 compact() if a.command=='compact' else (package(a.commit) if a.command=='package' else publish(a.commit))
