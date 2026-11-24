extends "res://tests/import_haru.gd"
const ALL_IDS = ["rabbit","otter","squirrel","hedgehog","raccoon","fox","bear","owl","cat","puppy","hamster","panda","red_panda","lamb","koala","penguin"]
const POSES = {"idle":"idle.png","left":"left-c0.png","right":"right-c0.png","action-1":"lie-c0.png","action-2":"cheer-c0.png"}
const TARGET = Rect2i(128,783,768,129)
var report = {"rejected":[],"missing":[],"cleaned":{},"alignment":{},"anchors":{},"suspect":[]}

func green(c: Color) -> bool:
 return c.g-maxf(c.r,c.b)>.06

func load_clean(path: String) -> Image:
 if not FileAccess.file_exists(path):
  report.missing.append(path)
  print("ALL_MISSING: "+path)
  return null
 var image=Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:
  report.rejected.append(path)
  return null
 image.convert(Image.FORMAT_RGBA8)
 var bad=0
 var total=0
 for y in range(0,image.get_height(),4):
  for x in [0,image.get_width()-1]:
   var c=image.get_pixel(x,y)
   total+=1
   if c.a>=.95 and not green(c): bad+=1
 for x in range(0,image.get_width(),4):
  for y in [0,image.get_height()-1]:
   var c=image.get_pixel(x,y)
   total+=1
   if c.a>=.95 and not green(c): bad+=1
 if float(bad)/total>.10:
  report.rejected.append(path)
  print("ALL_REJECT_OPAQUE_BACKGROUND: %s edge_ratio=%.3f"%[path,float(bad)/total])
  return null
 key_and_resize(image)
 var original=image.duplicate()
 var outside=PackedByteArray()
 outside.resize(SIDE*SIDE)
 var queue=PackedInt32Array()
 for i in range(SIDE):
  for p in [i,(SIDE-1)*SIDE+i,i*SIDE,i*SIDE+SIDE-1]:
   var c=image.get_pixel(p%SIDE,p/SIDE)
   if outside[p]==0 and (c.a<.95 or green(c)):
    outside[p]=1
    queue.append(p)
 var cursor=0
 var removed=0
 while cursor<queue.size():
  var p=queue[cursor]
  cursor+=1
  var x=p%SIDE
  var y=int(p/SIDE)
  var c=image.get_pixel(x,y)
  if c.a>.1: removed+=1
  image.set_pixel(x,y,Color.TRANSPARENT)
  for next in [p-1,p+1,p-SIDE,p+SIDE]:
   if next<0 or next>=SIDE*SIDE: continue
   if abs(next%SIDE-x)>1: continue
   if outside[next]!=0: continue
   var nc=image.get_pixel(next%SIDE,next/SIDE)
   if nc.a<.95 or green(nc):
    outside[next]=1
    queue.append(next)
 # Restore only a one-pixel antialias fringe adjacent to retained opaque ink.
 # The distant semitransparent cloud stays zero, opaque brown contours survive.
 var fringe=0
 for p in queue:
  var x=p%SIDE
  var y=int(p/SIDE)
  var c=original.get_pixel(x,y)
  if c.a<.10 or green(c): continue
  var adjacent=false
  for next in [p-1,p+1,p-SIDE,p+SIDE]:
   if next<0 or next>=SIDE*SIDE or abs(next%SIDE-x)>1: continue
   if outside[next]==0 and original.get_pixel(next%SIDE,next/SIDE).a>=.95:
    adjacent=true
    break
  if adjacent:
   c.a=minf(c.a,.65)
   image.set_pixel(x,y,c)
   fringe+=1
 report.cleaned[path]={"removed":removed,"fringe":fringe}
 print("ALL_CLEAN: %s removed=%d fringe=%d"%[path,removed,fringe])
 return image

func measured_eye(image: Image, region: Rect2i, mochi: bool=false) -> Vector2:
 # Isolate dark connected components; reject clipped fur/outline components.
 var seen={}
 var best=Vector2.ZERO
 var score=INF
 for y in range(region.position.y,region.end.y):
  for x in range(region.position.x,region.end.x):
   var start=y*SIDE+x
   if seen.has(start): continue
   seen[start]=true
   if not dark_eye(image.get_pixel(x,y),mochi): continue
   var q: Array[Vector2i]=[Vector2i(x,y)]
   var lo=q[0]
   var hi=lo
   var cursor=0
   while cursor<q.size():
    var p=q[cursor]
    cursor+=1
    lo=lo.min(p)
    hi=hi.max(p)
    for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
     var n: Vector2i=p+d
     if not region.has_point(n) or seen.has(n.y*SIDE+n.x): continue
     seen[n.y*SIDE+n.x]=true
     if dark_eye(image.get_pixelv(n),mochi): q.append(n)
   var dimensions=hi-lo+Vector2i.ONE
   if dimensions.x<12 or dimensions.y<18 or dimensions.x>110 or dimensions.y>130: continue
   if lo.x<=region.position.x or hi.x>=region.end.x-1 or lo.y<=region.position.y or hi.y>=region.end.y-1: continue
   var center=(Vector2(lo+hi)+Vector2.ONE)*.5
   var rank=center.distance_squared_to(Vector2(region.get_center()))
   if rank<score:
    best=center/SIDE
    score=rank
 return best

func dark_eye(c: Color, mochi: bool=false) -> bool:
 return c.a>=.95 and c.r<(.40 if mochi else .24) and c.g<(.25 if mochi else .18) and c.b<(.22 if mochi else .18)

func redesign(sp: String) -> bool:
 for pose in ["idle","left","right"]:
  if not FileAccess.file_exists(SOURCE+"redesign/"+sp+"/"+pose+".png"): return false
 return true

func run() -> void:
 if "--audit-only" in OS.get_cmdline_user_args():
  audit_outputs()
  return
 preload("res://tests/simplify_haru_eyes.gd").restore_rabbit()
 DirAccess.make_dir_recursive_absolute("res://builds/review")
 var sheet=Image.create(800,2560,false,Image.FORMAT_RGBA8)
 var anchors_sheet=Image.create(640,640,false,Image.FORMAT_RGBA8)
 for y in range(2560):
  for x in range(800): sheet.set_pixel(x,y,Color("e0d8ce") if (x/10+y/10)%2==0 else Color("fff7ec"))
 anchors_sheet.fill(Color("efe1cc"))
 for index in range(ALL_IDS.size()):
  var sp=ALL_IDS[index]
  var dir="res://assets/typing-haru-v1/"+sp+"/"
  DirAccess.make_dir_recursive_absolute(dir)
  var idle: Image
  if redesign(sp):
   idle=load_clean(SOURCE+"redesign/"+sp+"/idle.png")
  elif sp=="rabbit":
   idle=Image.load_from_file(dir+"idle.png")
  else:
   idle=load_clean(SOURCE+sp+"/idle.png")
  if idle==null:
   print("ALL_SPECIES_BLOCKED: "+sp)
   continue
  var raw_keyboard=keyboard_bounds(idle)
  if not raw_keyboard.has_area():
   print("ALL_SPECIES_BLOCKED: keyboard not detected "+sp)
   continue
  # Algebraic composition: pose->species idle, then idle->rabbit target.
  var base_scale=768.0/raw_keyboard.size.x
  var values=[]
  var column=0
  for pose in POSES:
   var image: Image
   if redesign(sp):
    image=idle if pose=="idle" or pose.begins_with("action-") else load_clean(SOURCE+"redesign/"+sp+"/"+pose+".png")
   elif sp=="rabbit":
    image=Image.load_from_file(dir+pose+".png")
   elif pose=="idle": image=idle
   else: image=load_clean(SOURCE+sp+"/"+POSES[pose])
   if image==null:
    column+=1
    continue
   var aligned=align_pose(image,TARGET,sp+"/"+pose)
   if aligned.is_empty():
    column+=1
    continue
   var result: Image=aligned.image
   assert(result.save_png(dir+pose+".png")==OK)
   values.append(aligned.scale)
   if pose=="idle":
    assert(result.save_png(dir+"action-0.png")==OK)
    var left=measured_eye(result,Rect2i(280,270,210,360))
    var right=measured_eye(result,Rect2i(535,270,210,360))
    var head=head_bounds(result,TARGET)
    var hat=Vector2(head.get_center().x,head.position.y+5)/SIDE
    var pin=Vector2(head.position.x+head.size.x*.74,head.position.y+head.size.y*.20)/SIDE
    if sp=="rabbit":
     hat=Vector2(.50,.325)
     pin=Vector2(.65,.365)
    report.anchors[sp]={"eyes":[left.x,left.y,right.x,right.y],"hat":[hat.x,hat.y],"pin":[pin.x,pin.y],"head":str(head)}
    if left==Vector2.ZERO or right==Vector2.ZERO: report.suspect.append(sp+"/eye_detection")
    var annotated=result.duplicate()
    for center in [left,right,hat,pin]:
     var pt=Vector2i(center*SIDE)
     for d in range(-12,13):
      if Rect2i(0,0,SIDE,SIDE).has_point(pt+Vector2i(d,0)): annotated.set_pixelv(pt+Vector2i(d,0),Color.RED)
      if Rect2i(0,0,SIDE,SIDE).has_point(pt+Vector2i(0,d)): annotated.set_pixelv(pt+Vector2i(0,d),Color.RED)
    annotated.resize(160,160,Image.INTERPOLATE_LANCZOS)
    anchors_sheet.blend_rect(annotated,Rect2i(0,0,160,160),Vector2i((index%4)*160,(index/4)*160))
   var thumb=result.duplicate()
   thumb.resize(160,160,Image.INTERPOLATE_LANCZOS)
   sheet.blend_rect(thumb,Rect2i(0,0,160,160),Vector2i(column*160,index*160))
   print("ALL_ALIGN: %s/%s base=%.6f scale=%.6f offset=%s keyboard=%s"%[sp,pose,base_scale,aligned.scale,aligned.offset,aligned.keyboard])
   column+=1
  report.alignment[sp]=values
  print("ALL_SPECIES_DONE: "+sp)
 assert(sheet.save_png("res://builds/review/haru-16-poses.png")==OK)
 assert(sheet.get_region(Rect2i(0,0,480,2560)).save_png("res://builds/review/haru-16-mochi.png")==OK)
 assert(anchors_sheet.save_png("res://builds/review/haru-16-anchors.png")==OK)
 var file=FileAccess.open("res://builds/review/haru-all-report.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 file.close()
 audit_outputs(false)
 preload("res://tests/match_haru_colors.gd").process_all()
 preload("res://tests/simplify_haru_eyes.gd").process_all()
 print("ALL_IMPORT_DONE: rejected=%d missing=%d suspect=%s"%[report.rejected.size(),report.missing.size(),report.suspect])
 quit()

func audit_outputs(finish: bool=true) -> void:
 var saved=JSON.parse_string(FileAccess.get_file_as_string("res://builds/review/haru-all-report.json"))
 var preview=Image.create(640,640,false,Image.FORMAT_RGBA8)
 preview.fill(Color("efe1cc"))
 saved.suspect=[]
 var reviewed={"squirrel/left-c0.png":"0ac7343be2971ec2d0b5a9cb3dc9ff0d07b5d60fed803823a3ed5473acf5038d","panda/left-c0.png":"584e54542da5770f6c63f27632798fa8bf772c6492741334db9c4f4ef26ba9f0","red_panda/right-c0.png":"cc5fd1e1c5d259798f791d6d797455f97f873245321fea3f9274e015179bd255","lamb/left-c0.png":"46d8bd2177a4096ba7835754b63c0722e2ab87d58881b144ee6a48b244b2d297"}
 for path in reviewed:
  if FileAccess.get_sha256(SOURCE+path)==reviewed[path]: saved.suspect.append(path)
 saved.audit_note="Visual review: opaque dark fringe/cloud remains on suspect sources; alpha>=0.95 ink deliberately preserved."
 for index in range(ALL_IDS.size()):
  var sp=ALL_IDS[index]
  var im=Image.load_from_file("res://assets/typing-haru-v1/"+sp+"/idle.png")
  if im==null: continue
  var regions=[Rect2i(280,270,210,360),Rect2i(535,270,210,360)]
  if redesign(sp): regions=[Rect2i(280,270,225,430),Rect2i(515,270,230,430)]
  elif sp=="rabbit": regions=[Rect2i(375,485,90,85),Rect2i(555,485,95,85)]
  elif sp=="squirrel": regions=[Rect2i(420,430,120,140),Rect2i(620,430,120,140)]
  elif sp=="fox": regions=[Rect2i(395,450,120,110),Rect2i(570,450,110,110)]
  var left=measured_eye(im,regions[0],redesign(sp))
  var right=measured_eye(im,regions[1],redesign(sp))
  assert(left!=Vector2.ZERO and right!=Vector2.ZERO,"Eye measurement requires review")
  var center=(left+right)*.5*SIDE
  var crown=-1
  # Crown band between ears, centered on measured eyes; avoids tails in silhouette bounds.
  for y in range(80,int(center.y)-60):
   var count=0
   for x in range(int(center.x)-20,int(center.x)+21):
    if im.get_pixel(x,y).a>=.95: count+=1
   if count>=35:
    crown=y
    break
  assert(crown>=0)
  var hat=Vector2(center.x,crown+5)/SIDE
  var pin=Vector2(center.x+(right.x-left.x)*SIDE*.70,crown+(center.y-crown)*.35)/SIDE
  if sp=="rabbit" and not redesign(sp):
   hat=Vector2(.5,.325)
   pin=Vector2(.65,.365)
  saved.anchors[sp]={"eyes":[left.x,left.y,right.x,right.y],"hat":[hat.x,hat.y],"pin":[pin.x,pin.y],"crown_y":crown}
  var annotated=im.duplicate()
  for mark in [[left,Color.RED],[right,Color.RED],[hat,Color.BLUE],[pin,Color.GREEN]]:
   var pt=Vector2i(mark[0]*SIDE)
   for d in range(-12,13):
    annotated.set_pixelv(pt+Vector2i(d,0),mark[1])
    annotated.set_pixelv(pt+Vector2i(0,d),mark[1])
  annotated.resize(160,160,Image.INTERPOLATE_LANCZOS)
  preview.blend_rect(annotated,Rect2i(0,0,160,160),Vector2i((index%4)*160,(index/4)*160))
  print("ALL_ANCHORS: %s eyes=%s,%s crown=%d"%[sp,left,right,crown])
 assert(preview.save_png("res://builds/review/haru-16-anchors.png")==OK)
 var out=FileAccess.open("res://builds/review/haru-all-report.json",FileAccess.WRITE)
 out.store_string(JSON.stringify(saved,"  "))
 out.close()
 report=saved
 print("ALL_AUDIT: opaque-fringe review needed: "+str(saved.suspect))
 if finish: quit()
