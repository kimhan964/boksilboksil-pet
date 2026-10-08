"""Build storage-optimized packs from the last verified runtime, preserving source art.

Only shipped runtime families are retained. PNG originals stay in the repository.
Lossless WebP + alpha-bounds cropping round-trips every visible RGBA pixel.
"""
import argparse, concurrent.futures, hashlib, io, json, shutil, struct, time, zipfile
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'builds'/'small-20261007'
IDS='rabbit otter squirrel hedgehog raccoon fox bear owl cat puppy hamster panda red_panda lamb koala penguin'.split()
ANIMAL=set('species-v3 hold-transitions-v1 slapstick-varco-v1 outfits-dressed-v2 struggle-v1 walk-v14 home-v2 outfits-varco-v1 emotions-v1 emotions-v2 dizzy-v1 dining-v13'.split())
COMMON=set('decor decor-cozy-v2 food furniture-v1 furniture-v2 furniture-v3 furniture-v4 furniture-v5 furniture-v6 icon ui-cozy-v1'.split())
TAG='v0.33.0-preview.20261007'
URL=f'https://github.com/kimhan964/boksilboksil-pet/releases/download/{TAG}/'

def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def read_table(p):
 with p.open('rb') as f:
  h=f.read(128);base,d=struct.unpack_from('<QQ',h,24);f.seek(d);n=struct.unpack('<I',f.read(4))[0];table={}
  for _ in range(n):
   l=struct.unpack('<I',f.read(4))[0];name=f.read(l).rstrip(b'\0').decode();off,size,md5,flags=struct.unpack('<QQ16sI',f.read(36))
   assert flags==0;table[name]=(base+off,size,md5)
 return h,table
def write_pack(target,resources,header):
 header=bytearray(header);struct.pack_into('<Q',header,24,128)
 entries=[]
 with target.open('wb') as f:
  f.write(header)
  for name,data in sorted(resources.items()):
   if isinstance(data,Path):data=data.read_bytes()
   f.write(b'\0'*(-f.tell()%32));off=f.tell()-128;f.write(data)
   entries.append((name,off,len(data),hashlib.md5(data).digest()))
  f.write(b'\0'*(-f.tell()%32));directory=f.tell();f.write(struct.pack('<I',len(entries)))
  for name,off,size,digest in entries:
   encoded=name.encode();encoded+=b'\0'*(-len(encoded)%4)
   f.write(struct.pack('<I',len(encoded))+encoded+struct.pack('<QQ16sI',off,size,digest,0))
  struct.pack_into('<Q',header,32,directory);f.seek(0);f.write(header)
 # Independent digest verification after writing.
 _,table=read_table(target)
 with target.open('rb') as f:
  for name,(off,size,digest) in table.items():
   f.seek(off);assert hashlib.md5(f.read(size)).digest()==digest,name

def owner(name):
 parts=name.split('/')
 if not name.startswith('assets/'):return 'common'
 if len(parts)<3:return 'common' if name in ['assets/animation-regions.json','assets/hold-camera-v2.json'] else None
 family=parts[1]
 if name=='assets/icon/pet-icon.ico':return 'common' # Windows native icon uses this exact binary path.
 if name.endswith(('.import','.md','.ico')) or '-generated' in name:return None
 if family=='rabbit-frame-pilot-v9':return 'rabbit'
 if family in COMMON:return 'common'
 if family in ANIMAL and parts[2] in IDS:
  if family=='emotions-v1' and parts[2]=='otter':return None
  return parts[2]
 return None

def convert(job):
 source,name,entry=job
 cache=OUT/'converted'/Path(name).with_suffix('.webp')
 metadata=cache.with_suffix('.json')
 if metadata.exists():
  meta=json.loads(metadata.read_text());cached=OUT/'converted'/meta['file'][6:]
  if cached.exists():
   meta['cropped_rgba_sha256']=hashlib.sha256(Image.open(cached).convert('RGBA').tobytes()).hexdigest()
   return name,cached,meta,entry[1]
 with source.open('rb') as f:
  f.seek(entry[0]);raw=f.read(entry[1]);assert hashlib.md5(raw).digest()==entry[2]
 original=Image.open(io.BytesIO(raw)).convert('RGBA')
 box=original.getchannel('A').getbbox() or (0,0,1,1)
 cropped=original.crop(box)
 b=io.BytesIO();cropped.save(b,format='WEBP',lossless=True,quality=100,method=4,exact=True)
 encoded=b.getvalue();decoded=Image.open(io.BytesIO(encoded)).convert('RGBA')
 assert decoded.tobytes()==cropped.tobytes(),name
 # If lossless WebP is larger than a cropped PNG, ship the smaller lossless file.
 png=io.BytesIO();cropped.save(png,format='PNG',compress_level=9)
 if len(png.getvalue())<len(encoded):cache=cache.with_suffix('.png');encoded=png.getvalue()
 cache.parent.mkdir(parents=True,exist_ok=True);cache.write_bytes(encoded)
 result={'file':'res://'+cache.relative_to(OUT/'converted').as_posix(),'size':list(original.size),'offset':[box[0],box[1]],'crop_size':list(cropped.size),'visible_rgba_exact':True,'cropped_rgba_sha256':hashlib.sha256(cropped.tobytes()).hexdigest()}
 metadata.write_text(json.dumps(result),encoding='utf-8')
 return name,cache,result,entry[1]

def build():
 source=ROOT/'builds/release-20261007/DesktopFriends.pck'
 if sha(source)!='5ebb0fd7d9190fe4546a978256f9995b904455a39272e712ee70a6a74a34e1e7':
  raise RuntimeError('Input is not the verified 0.32.0 runtime snapshot')
 header,table=read_table(source);OUT.mkdir(parents=True,exist_ok=True)
 groups={id:{} for id in ['common']+IDS};index={};removed=[];jobs=[];before=0
 with source.open('rb') as f:
  for name,entry in table.items():
   group=owner(name)
   if group is None:removed.append({'path':name,'bytes':entry[1]});continue
   before+=entry[1]
   if name.endswith('.png'):jobs.append((source,name,entry));continue
   f.seek(entry[0]);groups[group][name]=f.read(entry[1])
 # Runtime edits are overlaid explicitly; project.godot remains installed GL config.
 for p in (ROOT/'scripts').glob('*'):
  if p.suffix in ['.gd','.gdshader','.gdshaderinc']:groups['common'][p.relative_to(ROOT).as_posix()]=p.read_bytes()
 for p in (ROOT/'tests').glob('*.gd'):groups['common'][p.relative_to(ROOT).as_posix()]=p.read_bytes()
 groups['common']['tools/check_package.gd']=(ROOT/'tools/check_package.gd').read_bytes()
 groups['common']['assets/hold-camera-v2.json']=(ROOT/'assets/hold-camera-v2.json').read_bytes()
 # New generated common art is outside the old runtime snapshot.
 groups['common']['assets/decor-cozy-v2/acorn-wobble-v2.png']=(ROOT/'assets/decor-cozy-v2/acorn-wobble-v2.png').read_bytes()
 original_png=0;encoded_png=0;pixels=0;cropped_pixels=0;start=time.monotonic()
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
  for i,(name,path,meta,size) in enumerate(pool.map(convert,jobs),1):
   group=owner(name);groups[group][meta['file'][6:]]=path;index['res://'+name]=meta
   original_png+=size;encoded_png+=path.stat().st_size;pixels+=meta['size'][0]*meta['size'][1];cropped_pixels+=meta['crop_size'][0]*meta['crop_size'][1]
   if i%40==0:print('CONVERTED',i,'/',len(jobs),'seconds',round(time.monotonic()-start),'MB',round(encoded_png/1e6,1),flush=True)
 groups['common']['assets/image-storage.json']=json.dumps(index,separators=(',',':')).encode()
 pack_manifest={'version':'storage-20261007-v1','default':'rabbit','animals':{}}
 pack_dir=OUT/'animal-packs';pack_dir.mkdir(exist_ok=True)
 for id in IDS:
  if id=='rabbit':groups['common'].update(groups[id]);continue
  path=pack_dir/f'pet-{id}.pck';write_pack(path,groups[id],header)
  pack_manifest['animals'][id]={'file':path.name,'size':path.stat().st_size,'sha256':sha(path),'url':URL+path.name,'required_paths':['res://assets/species-v3/'+id+'/manifest.json','res://assets/walk-v14/'+id+'/manifest.json']}
 (OUT/'animal-packs.json').write_text(json.dumps(pack_manifest,indent=2),encoding='utf-8')
 groups['common']['assets/animal-packs.json']=json.dumps(pack_manifest,separators=(',',':')).encode()
 write_pack(OUT/'DesktopFriends.pck',groups['common'],header)
 install=ROOT.parent/'복슬복슬펫/0.30.3'
 for name in ['DesktopFriends.exe','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json']:shutil.copy2(install/name,OUT/name)
 shutil.copytree(install/'addons',OUT/'addons',dirs_exist_ok=True)
 report={'previous_pck_bytes':source.stat().st_size,'removed_bytes':sum(x['bytes'] for x in removed),'removed_resources':len(removed),'retained_before_conversion_bytes':before,'png_before_bytes':original_png,'encoded_images_bytes':encoded_png,'image_count':len(index),'original_pixels':pixels,'stored_pixels':cropped_pixels,'base_pck_bytes':(OUT/'DesktopFriends.pck').stat().st_size,'animal_packs_bytes':sum(x['size'] for x in pack_manifest['animals'].values()),'visible_rgba_verified_images':len(index),'default_animal':'rabbit'}
 (OUT/'OPTIMIZATION.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 (OUT/'REMOVED-RESOURCES.json').write_text(json.dumps(removed,indent=2),encoding='utf-8')
 print('BUILD VERIFIED',json.dumps(report),flush=True)

def package(commit=None):
 entries=[OUT/n for n in ['DesktopFriends.exe','DesktopFriends.pck','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json','OPTIMIZATION.json']]
 entries += [p for p in (OUT/'addons').rglob('*') if p.is_file()]
 for name,files in [('BoksilboksilPet-0.33.0-Windows-Small.zip',entries),('BoksilboksilPet-0.33.0-AnimalPacks-Offline.zip',list((OUT/'animal-packs').glob('*.pck')))]:
  with zipfile.ZipFile(OUT/name,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
   for p in files:z.write(p,p.relative_to(OUT).as_posix())
   z.writestr('README.md',(ROOT/'docs/SMALL-PACK-HANDOFF-2026-10-07.md').read_text(encoding='utf-8'))
   z.writestr('FILE-SHA256SUMS.txt','\n'.join(sha(p)+'  '+p.relative_to(OUT).as_posix() for p in files)+'\n')
   if commit:z.writestr('SOURCE_COMMIT.txt',commit+'\n')
  with zipfile.ZipFile(OUT/name) as z:assert z.testzip() is None
  print('ZIP VERIFIED',name,(OUT/name).stat().st_size,sha(OUT/name),flush=True)
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('command',choices=['build','package']);parser.add_argument('--commit');args=parser.parse_args()
 build() if args.command=='build' else package(args.commit)
