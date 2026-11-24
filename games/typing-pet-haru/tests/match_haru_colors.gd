extends SceneTree
const IDS=preload("res://scripts/catalog.gd").IDS
const BASE="res://assets/typing-haru-v1/"
static func rgb(c: Color) -> Vector3: return Vector3(c.r,c.g,c.b)
static func linear(v: float) -> float: return v/12.92 if v<=.04045 else pow((v+.055)/1.055,2.4)
static func f(v: float) -> float: return pow(v,1.0/3) if v>.008856 else 7.787*v+16.0/116
static func lab(c: Color) -> Vector3:
 var r=linear(c.r); var g=linear(c.g); var b=linear(c.b)
 var x=f((.4124564*r+.3575761*g+.1804375*b)/.95047)
 var y=f(.2126729*r+.7151522*g+.072175*b)
 var z=f((.0193339*r+.119192*g+.9503041*b)/1.08883)
 return Vector3(116*y-16,500*(x-y),200*(y-z))
static func invf(v: float) -> float: return v*v*v if v>6.0/29 else (v-16.0/116)/7.787
static func srgb(v: float) -> float: return 12.92*v if v<=.0031308 else 1.055*pow(v,1.0/2.4)-.055
static func from_lab(v: Vector3, alpha: float) -> Color:
 var y=(v.x+16)/116
 var x=.95047*invf(y+v.y/500)
 var z=1.08883*invf(y-v.z/200)
 y=invf(y)
 return Color(clampf(srgb(3.2404542*x-1.5371385*y-.4985314*z),0,1),clampf(srgb(-.969266*x+1.8760108*y+.041556*z),0,1),clampf(srgb(.0556434*x-.2040259*y+1.0572252*z),0,1),alpha)
static func weight(c: Color) -> float:
 if c.a<.95: return 0
 # Preserve brown/black outline, eyes and pink cheeks/key lighting.
 if c.r>c.g*1.13 and c.b>c.g*1.04: return 0
 return smoothstep(.28,.45,.299*c.r+.587*c.g+.114*c.b)
static func stats(im: Image) -> Dictionary:
 var total=0; var count=0
 var weight_sum=0.0
 var sum=Vector3.ZERO; var square=Vector3.ZERO
 var all_rgb=Vector3.ZERO; var all_lab=Vector3.ZERO
 for y in range(0,748,2):
  for x in range(0,1024,2):
   var c=im.get_pixel(x,y)
   if c.a<.95: continue
   total+=1; all_rgb+=rgb(c); all_lab+=lab(c); weight_sum+=weight(c)
   if weight(c)<.99: continue
   count+=1; sum+=rgb(c); square+=rgb(c)*rgb(c)
 var mu=sum/maxi(1,count)
 var variance=square/maxi(1,count)-mu*mu
 return {"mean":mu,"std":Vector3(sqrt(maxf(.0001,variance.x)),sqrt(maxf(.0001,variance.y)),sqrt(maxf(.0001,variance.z))),"rgb":all_rgb/maxi(1,total),"lab":all_lab/maxi(1,total),"samples":total,"weight":weight_sum/maxi(1,total)}
static func values(v: Vector3) -> Array: return [v.x,v.y,v.z]
static func process_all() -> void:
 var report={"metric":"CIE76 distance between mean per-pixel Lab (D65 sRGB); alpha>=0.95, y<0.73; sampling stride 2","species":{},"highest_head_y":1024}
 for sp in IDS:
  var idle=Image.new()
  idle.load_png_from_buffer(FileAccess.get_file_as_bytes(BASE+sp+"/idle.png"))
  var ref=stats(idle)
  var entry={"idle_rgb":values(ref.rgb),"idle_lab":values(ref.lab),"poses":{}}
  for pose in ["idle","left","right"]:
   var im=Image.new()
   im.load_png_from_buffer(FileAccess.get_file_as_bytes(BASE+sp+"/"+pose+".png"))
   # Global highest silhouette is stable across species and typing frames.
   for y in range(748):
    var found=false
    for x in range(1024):
     if im.get_pixel(x,y).a>=.95: found=true; break
    if found:
     report.highest_head_y=mini(report.highest_head_y,y)
     break
   if pose=="idle": continue
   var original=im.duplicate()
   var before=stats(im)
   var gain: Vector3=ref.std/before.std
   gain=gain.clamp(Vector3.ONE*.8,Vector3.ONE*1.25)
   for y in range(748):
    for x in range(1024):
     var c=im.get_pixel(x,y)
     var w=weight(c)
     if w==0: continue
     var matched: Vector3=(rgb(c)-before.mean)*gain+ref.mean
     var delta=(matched-rgb(c)).clamp(Vector3.ONE*(-.12),Vector3.ONE*.12)
     var out=rgb(c)+delta*w
     im.set_pixel(x,y,Color(clampf(out.x,0,1),clampf(out.y,0,1),clampf(out.z,0,1),c.a))
   var after=stats(im)
   # Bounded Lab mean correction compensates pose area proportions; never accept worse Delta E.
   for iteration in range(2):
    if after.lab.distance_to(ref.lab)<.08: break
    var delta: Vector3=(ref.lab-after.lab)/maxf(.1,after.weight)
    delta=delta.clamp(Vector3(-5,-4,-4),Vector3(5,4,4))
    for y in range(748):
     for x in range(1024):
      var c=im.get_pixel(x,y)
      var w=weight(c)
      if w>0: im.set_pixel(x,y,from_lab(lab(c)+delta*w,c.a))
    after=stats(im)
   var accepted=after.lab.distance_to(ref.lab)<=before.lab.distance_to(ref.lab)
   if not accepted:
    im=original
    after=before
   entry.poses[pose]={"before_rgb":values(before.rgb),"after_rgb":values(after.rgb),"before_lab":values(before.lab),"after_lab":values(after.lab),"delta_e_before":before.lab.distance_to(ref.lab),"delta_e_after":after.lab.distance_to(ref.lab),"gain":values(gain),"accepted":accepted}
   assert(im.save_png(BASE+sp+"/"+pose+".png")==OK)
  report.species[sp]=entry
 var out=FileAccess.open("res://builds/review/haru-color-match.json",FileAccess.WRITE)
 out.store_string(JSON.stringify(report,"  ")); out.close()
 print("COLOR_MATCH_DONE: 32 frames; highest_head_y=",report.highest_head_y)
func _initialize():
 process_all()
 quit()
