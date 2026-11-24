extends SceneTree
const Catalog=preload("res://scripts/catalog.gd")
const BASE="res://assets/typing-haru-v1/"
const EYE_SCALE=.85
const HIGHLIGHT_SCALE=.60
const REVIEW="res://builds/review/"
func _initialize():
 process_all()
 quit()
static func ink(c: Color) -> bool:
 return c.a>.95 and c.r<.25 and c.g<.21 and c.b<.20
static func component(im: Image, anchor: Vector2) -> Dictionary:
 var roi=Rect2i(Vector2i(anchor)-Vector2i(85,85),Vector2i(170,170)).intersection(Rect2i(0,0,1024,1024))
 var seen={}
 var best={}
 var distance=INF
 for y in range(roi.position.y,roi.end.y):
  for x in range(roi.position.x,roi.end.x):
   var start=Vector2i(x,y)
   if seen.has(start): continue
   seen[start]=true
   if not ink(im.get_pixelv(start)): continue
   var q=[start]
   var lo=start
   var hi=start
   var cursor=0
   while cursor<q.size():
    var p: Vector2i=q[cursor]
    cursor+=1
    lo=lo.min(p)
    hi=hi.max(p)
    for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
     var n: Vector2i=p+d
     if not roi.has_point(n) or seen.has(n): continue
     seen[n]=true
     if ink(im.get_pixelv(n)): q.append(n)
   var size=hi-lo+Vector2i.ONE
   if size.x<20 or size.y<24 or size.x>75 or size.y>85: continue
   if float(size.y)/size.x<.85 or float(q.size())/(size.x*size.y)<.60: continue
   var center=(Vector2(lo+hi)+Vector2.ONE)*.5
   var dist=center.distance_to(anchor)
   if dist<distance and dist<65:
    best={"box":Rect2i(lo,size),"points":q,"center":center}
    distance=dist
 return best
static func paint_eye(im: Image, data: Dictionary) -> void:
 var original=im.duplicate()
 var box: Rect2i=data.box
 var red=[]
 var green=[]
 var blue=[]
 # Ring median preserves the local fur or dark panda/raccoon patch.
 for y in range(box.position.y-7,box.end.y+7):
  for x in range(box.position.x-7,box.end.x+7):
   if box.grow(2).has_point(Vector2i(x,y)): continue
   var c=im.get_pixel(x,y)
   if c.a>.95:
    red.append(c.r); green.append(c.g); blue.append(c.b)
 red.sort(); green.sort(); blue.sort()
 var mid=int(red.size()/2)
 var face=Color(red[mid],green[mid],blue[mid],1)
 # Fill each ink row, including enclosed white highlight holes; preserve surrounding patch.
 var rows={}
 for p in data.points:
  if not rows.has(p.y): rows[p.y]=Vector2i(p.x,p.x)
  rows[p.y]=Vector2i(mini(rows[p.y].x,p.x),maxi(rows[p.y].y,p.x))
 for y in rows:
  for yy in range(y-2,y+3):
   for x in range(rows[y].x-2,rows[y].y+3): im.set_pixel(x,yy,face)
 # Preserve the original silhouette and black ink, including its irregular outline.
 var inks=[[],[],[]]
 for p in data.points:
  var c=original.get_pixelv(p)
  inks[0].append(c.r); inks[1].append(c.g); inks[2].append(c.b)
 for channel in inks: channel.sort()
 var median=int(inks[0].size()/2)
 var eye_color=Color(inks[0][median],inks[1][median],inks[2][median],1)
 var layer=Image.create(box.size.x,box.size.y,false,Image.FORMAT_RGBA8)
 layer.fill(Color.TRANSPARENT)
 var whites={}
 for y in rows:
  for x in range(rows[y].x,rows[y].y+1):
   var c=original.get_pixel(x,y)
   layer.set_pixel(x-box.position.x,y-box.position.y,c if ink(c) else eye_color)
   if minf(c.r,minf(c.g,c.b))>.65: whites[Vector2i(x,y)]=true
 # Connected highlight components: retain only the largest, at its original location.
 var largest=[]
 while not whites.is_empty():
  var q=[whites.keys()[0]]
  whites.erase(q[0])
  var cursor=0
  while cursor<q.size():
   var p: Vector2i=q[cursor]
   cursor+=1
   for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var n=p+d
    if whites.has(n):
     whites.erase(n)
     q.append(n)
  if q.size()>largest.size(): largest=q
 layer.resize(maxi(1,roundi(box.size.x*EYE_SCALE)),maxi(1,roundi(box.size.y*EYE_SCALE)),Image.INTERPOLATE_LANCZOS)
 im.blend_rect(layer,Rect2i(Vector2i.ZERO,layer.get_size()),Vector2i(Vector2(data.center)-Vector2(layer.get_size())*.5))
 if not largest.is_empty():
  var lo: Vector2i=largest[0]
  var hi=lo
  for p in largest:
   lo=lo.min(p); hi=hi.max(p)
  var shine=Image.create(hi.x-lo.x+1,hi.y-lo.y+1,false,Image.FORMAT_RGBA8)
  shine.fill(Color.TRANSPARENT)
  for p in largest: shine.set_pixelv(p-lo,original.get_pixelv(p))
  shine.resize(maxi(1,roundi(shine.get_width()*HIGHLIGHT_SCALE)),maxi(1,roundi(shine.get_height()*HIGHLIGHT_SCALE)),Image.INTERPOLATE_LANCZOS)
  var center=(Vector2(lo+hi)+Vector2.ONE)*.5
  im.blend_rect(shine,Rect2i(Vector2i.ZERO,shine.get_size()),Vector2i(center-Vector2(shine.get_size())*.5))
static func process_all() -> void:
 DirAccess.make_dir_recursive_absolute(REVIEW+"eyes-original")
 var manifest={}
 var manifest_path=REVIEW+"haru-eyes-report.json"
 if FileAccess.file_exists(manifest_path): manifest=JSON.parse_string(FileAccess.get_file_as_string(manifest_path)).get("hashes",{})
 var results={"success":[],"skipped":[],"closed_or_unmatched":[],"hashes":manifest,"centers":{}}
 var has_dot=true
 for sp in Catalog.IDS:
  if not FileAccess.file_exists(REVIEW+"eyes-dot/"+sp+"-idle.png"): has_dot=false
 var sheet=Image.create((3 if has_dot else 2)*256,16*200,false,Image.FORMAT_RGBA8)
 sheet.fill(Color("fff7ec"))
 for index in range(16):
  var sp=Catalog.IDS[index]
  var anchors=Catalog.EYES[index]
  for pose in ["idle","left","right","action-0","action-1","action-2"]:
   var key=sp+"/"+pose+".png"
   var path=BASE+key
   var backup=REVIEW+"eyes-original/"+sp+"-"+pose+".png"
   var im=Image.new()
   var current_hash=FileAccess.get_sha256(path)
   var from_backup=manifest.get(key,"")==current_hash and FileAccess.file_exists(backup)
   assert(im.load_png_from_buffer(FileAccess.get_file_as_bytes(backup if from_backup else path))==OK)
   var before=im.duplicate()
   var eyes=[component(im,Vector2(anchors.x,anchors.y)*1024),component(im,Vector2(anchors.z,anchors.w)*1024)]
   var normal=pose in ["idle","left","right","action-0"]
   # Closed/sleeping poses only change when both open-eye components are unambiguous.
   if FileAccess.file_exists(BASE+"source/redesign/"+sp+"/idle.png") or sp=="puppy" or not normal or eyes[0].is_empty() or eyes[1].is_empty():
    if from_backup:
     assert(before.save_png(path)==OK)
     manifest.erase(key)
    if normal: results.skipped.append(key)
    else: results.closed_or_unmatched.append(key)
   else:
    if not from_backup: assert(before.save_png(backup)==OK)
    for eye in eyes: paint_eye(im,eye)
    assert(im.save_png(path)==OK)
    manifest[key]=FileAccess.get_sha256(path)
    results.success.append(key)
    if pose=="idle": results.centers[sp]=[eyes[0].center.x/1024,eyes[0].center.y/1024,eyes[1].center.x/1024,eyes[1].center.y/1024]
   if pose=="idle":
    var center=Vector2((anchors.x+anchors.z)*.5,(anchors.y+anchors.w)*.5)*1024
    var rect=Rect2i(Vector2i(center)-Vector2i(200,156),Vector2i(400,312))
    var col=0
    var comparisons=[before]
    if has_dot:
     var dot=Image.new()
     assert(dot.load_png_from_buffer(FileAccess.get_file_as_bytes(REVIEW+"eyes-dot/"+sp+"-idle.png"))==OK)
     comparisons.append(dot)
    comparisons.append(im)
    for source in comparisons:
     var crop=source.get_region(rect)
     crop.resize(256,200,Image.INTERPOLATE_LANCZOS)
     sheet.blend_rect(crop,Rect2i(0,0,256,200),Vector2i(col*256,index*200))
     col+=1
 assert(sheet.save_png(REVIEW+"haru-eyes-before-after.png")==OK)
 var poses_sheet=Image.create(800,2560,false,Image.FORMAT_RGBA8)
 for y in range(2560):
  for x in range(800): poses_sheet.set_pixel(x,y,Color("e0d8ce") if (x/10+y/10)%2==0 else Color("fff7ec"))
 for index in range(16):
  var column=0
  for pose in ["idle","left","right","action-1","action-2"]:
   var thumb=Image.new()
   thumb.load_png_from_buffer(FileAccess.get_file_as_bytes(BASE+Catalog.IDS[index]+"/"+pose+".png"))
   thumb.resize(160,160,Image.INTERPOLATE_LANCZOS)
   poses_sheet.blend_rect(thumb,Rect2i(0,0,160,160),Vector2i(column*160,index*160))
   column+=1
 assert(poses_sheet.save_png(REVIEW+"haru-16-poses.png")==OK)
 assert(poses_sheet.get_region(Rect2i(0,0,480,2560)).save_png(REVIEW+"haru-16-mochi.png")==OK)
 var out=FileAccess.open(manifest_path,FileAccess.WRITE)
 out.store_string(JSON.stringify(results,"  "))
 out.close()
 print("EYES_RESULT: success=%d skipped=%s closed_or_unmatched=%d"%[results.success.size(),results.skipped,results.closed_or_unmatched.size()])

static func restore_rabbit() -> void:
 var file=REVIEW+"haru-eyes-report.json"
 if not FileAccess.file_exists(file): return
 var hashes=JSON.parse_string(FileAccess.get_file_as_string(file)).get("hashes",{})
 for pose in ["idle","left","right","action-0","action-1","action-2"]:
  var path=BASE+"rabbit/"+pose+".png"
  var backup=REVIEW+"eyes-original/rabbit-"+pose+".png"
  if hashes.get("rabbit/"+pose+".png","")==FileAccess.get_sha256(path) and FileAccess.file_exists(backup):
   var image=Image.new()
   image.load_png_from_buffer(FileAccess.get_file_as_bytes(backup))
   image.save_png(path)
