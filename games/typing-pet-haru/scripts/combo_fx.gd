extends Node2D
const WORDS=[[],["몸 풀렸다!","슬슬 시작?","손가락 예열 완료"],["손이 안 보여!","타닥타닥 모드","오늘 좀 치는데?"],["타자 장인 등장","키보드 뜨끈뜨끈","멈출 수 없어!"],["키보드 살려…","전설의 손가락","퇴근 각!"]]
const AMBIENT_LIMIT=4
const HOP_DURATION=.4
var silhouette=Rect2(10,26,200,174)
var particles=[]
var text_scale=1.0
var last_tier=0
var hop_remaining=0.0
var origin=Vector2(110,60)
var face_transform=Transform2D.IDENTITY
var eye_centers=Vector4(.4,.5,.6,.5)
var since_input=1.0
var activity=0.0
var blush=0.0
var clocks={"note":0.0,"sweat":0.0,"steam":0.0,"sparkle":0.0,"tap":0.0}
var next_side=-1
var bob_clock=0.0
var bob=0.0
var rest_tier=0
var rest_emitted=false
var rest_count=0
var bubble_time=0.0
var bubble_text=""
var bubble_side=1
var last_phrase=""
func set_silhouette(images: Array) -> void:
 silhouette=Rect2()
 for image in images:
  var used=image.get_used_rect()
  var bounds=Rect2(Vector2(10,0)+Vector2(used.position)*200/image.get_width(),Vector2(used.size)*200/image.get_width())
  silhouette=bounds if silhouette.size==Vector2.ZERO else silhouette.merge(bounds)
func particle_center(p) -> Vector2:
 var t=clampf(p.age/p.life,0,1)
 var ease=1-pow(1-t,2)
 if p.kind=="tap":
  return Vector2(silhouette.position.x-24 if p.side<0 else silhouette.end.x+24,155-5*ease)
 if p.kind=="steam":
  return Vector2(silhouette.position.x-13 if p.side<0 else silhouette.end.x+13,maxf(25,silhouette.position.y-14)-4*ease)
 if p.kind=="heart":
  var slot=absf(p.offset)/12
  return Vector2(110+p.side*(83+slot*26+ease*(8+slot*3)),maxf(23,origin.y+24-slot*22-12*ease))
 return Vector2(110+p.side*72,maxf(22,origin.y+p.offset-12*ease))
func particle_alpha(p) -> float:
 # Hold the original RGB; fade only the final portion of the lifetime.
 return clampf((p.life-p.age)/.3,0,1)*activity
func reset(tier: int=0) -> void:
 last_tier=tier
 particles.clear()
 hop_remaining=0
 since_input=1
 activity=0
 blush=0
 bob=0
 bubble_time=0
 rest_tier=0
 rest_emitted=false
 for key in clocks: clocks[key]=0
func ambient_count() -> int:
 return particles.filter(func(p): return p.kind!="heart").size()
func emit_particle(kind: String,life: float,side: int,offset: float=0) -> void:
 particles.append({"kind":kind,"life":life,"age":0.0,"side":side,"offset":offset})
func show_bubble(text: String,duration: float) -> void:
 bubble_text=text
 bubble_time=duration
 bubble_side=-bubble_side
func bubble_lines() -> Array[String]:
 var lines: Array[String]=[]
 var line=""
 var font=preload("res://scripts/cozy_ui.gd").heading_font()
 for c in bubble_text:
  if font.get_string_size(line+c,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x>64:
   lines.append(line.strip_edges())
   line=""
  line+=c
 lines.append(line.strip_edges())
 return lines
func bubble_rect() -> Rect2:
 return Rect2(Vector2(-62 if bubble_side<0 else 202,maxf(34,origin.y-10)),Vector2(80,16+bubble_lines().size()*17))
func advance(dt: float,tier: int,pressed: bool,enabled: bool) -> void:
 var rising=tier>last_tier and tier>0
 last_tier=tier
 bubble_time=maxf(0,bubble_time-dt)
 since_input=0 if pressed else since_input+dt
 if pressed:
  rest_tier=tier
  rest_emitted=false
 activity=clampf(1-since_input/.9,0,1) if enabled and tier>0 else 0.0
 hop_remaining=maxf(0,hop_remaining-dt)
 bob_clock=fmod(bob_clock+dt,.6)
 bob=1.5*(.5-.5*cos(TAU*bob_clock/.6))*activity if tier==4 else 0.0
 for p in particles: p.age+=dt
 particles=particles.filter(func(p): return p.age<p.life)
 if not enabled:
  reset(tier)
 elif activity==0:
  particles.clear()
  hop_remaining=0
  for key in clocks: clocks[key]=0
  if rest_tier>=2 and since_input>=3 and not rest_emitted:
   show_bubble("휴…",1)
   rest_emitted=true
   rest_count+=1
 else:
  for key in clocks: clocks[key]+=dt
  if rising and pressed:
   hop_remaining=HOP_DURATION
   particles.clear()
   for i in range([0,3,3,4,5][tier]): emit_particle("heart",.9,-1 if i%2==0 else 1,-(i/2)*12)
   var choices=WORDS[tier].filter(func(word): return word!=last_phrase)
   last_phrase=choices.pick_random()
   show_bubble(last_phrase,1.4)
  if not particles.any(func(p): return p.kind=="heart"):
   var intervals={"note":4.0,"sweat":7.0,"steam":5.0,"sparkle":6.0,"tap":3.0}
   var tiers={"note":1,"sweat":2,"steam":3,"sparkle":3,"tap":4}
   for kind in intervals:
    var amount=2 if kind=="steam" else 1
    if tier>=tiers[kind] and clocks[kind]>=intervals[kind] and particles.size()+amount<=AMBIENT_LIMIT:
     for i in range(amount):
      emit_particle(kind,.8 if kind in ["sweat","tap"] else 1.2,next_side,-i*8)
      next_side=-next_side
     clocks[kind]=0
 var target=.22*activity if tier>=2 and enabled else 0.0
 blush=move_toward(blush,target,dt*.7)
 if not enabled or activity==0: blush=0
 visible=not particles.is_empty() or blush>0 or bubble_time>0
 queue_redraw()
func polygon(points: PackedVector2Array,color: Color,alpha: float,width: float=1.0) -> void:
 draw_colored_polygon(points,Color(color,alpha))
 var edge=points.duplicate()
 edge.append(edge[0])
 draw_polyline(edge,Color(Color("6b4a35"),alpha),width,true)
func _draw():
 if blush>0:
  draw_circle(face_transform*Vector2(10+eye_centers.x*200-14,eye_centers.y*200+10),7.5,Color(Color("f4a7b0"),blush),true,-1,true)
  draw_circle(face_transform*Vector2(10+eye_centers.z*200+14,eye_centers.w*200+10),7.5,Color(Color("f4a7b0"),blush),true,-1,true)
 for p in particles:
  var t=clampf(p.age/p.life,0,1)
  var ease=1-pow(1-t,2)
  var center=particle_center(p)
  var alpha=particle_alpha(p)
  var points=PackedVector2Array()
  if p.kind=="heart":
   for i in range(48):
    var a=TAU*i/48
    points.append(center+Vector2(16*pow(sin(a),3),-(13*cos(a)-5*cos(2*a)-2*cos(3*a)-cos(4*a)))*.5)
   polygon(points,Color("f49aab"),alpha,1.5)
   draw_circle(center+Vector2(-3,-3),1.2,Color(1,1,1,alpha),true,-1,true)
  elif p.kind=="sparkle":
   for i in range(8):
    var a=-PI/2+i*PI/4
    points.append(center+Vector2(cos(a),sin(a))*(6 if i%2==0 else 1.8))
   polygon(points,Color("f6d98b"),alpha)
  elif p.kind=="sweat":
   center=origin+Vector2(p.side*65,4*ease)
   points=PackedVector2Array([center+Vector2(0,-6),center+Vector2(4,0),center+Vector2(3,4),center+Vector2(0,6),center+Vector2(-3,4),center+Vector2(-4,0)])
   polygon(points,Color("9fd3f0"),alpha)
  elif p.kind=="steam":
   center=particle_center(p)
   for i in range(32):
    var a=TAU*i/32
    var radius=1.3*(6+.6*cos(3*a))
    points.append(center+Vector2(cos(a),sin(a)) * radius)
   polygon(points,Color("fff7ec"),.95*alpha)
  elif p.kind=="tap":
   center=particle_center(p)
   draw_set_transform(center,deg_to_rad(p.side*8))
   var font=preload("res://scripts/cozy_ui.gd").heading_font()
   draw_string_outline(font,Vector2(-12,0),"타닥!",HORIZONTAL_ALIGNMENT_LEFT,-1,12,2,Color(Color("fffdf8"),alpha))
   draw_string(font,Vector2(-12,0),"타닥!",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(Color("6b4a35"),alpha))
   draw_set_transform(Vector2.ZERO)
  else:
   # 16px musical note, native vector silhouette and 1px warm outline.
   points=PackedVector2Array([Vector2(0,4),Vector2(0,-7),Vector2(2,-7),Vector2(6,-4),Vector2(6,-1),Vector2(2,-4),Vector2(2,4)])
   for i in range(points.size()): points[i]=points[i]*1.14+center
   polygon(points,Color("f49aab"),alpha)
   points=PackedVector2Array()
   for i in range(24):
    var a=TAU*i/24
    points.append(center+Vector2(-1+3*cos(a),4+2*sin(a))*1.14)
   polygon(points,Color("f49aab"),alpha)

 if bubble_time>0:
  var rect=bubble_rect()
  var alpha=clampf(bubble_time/.15,0,1)
  var style=StyleBoxFlat.new()
  style.bg_color=Color(Color("fffdf8"),alpha)
  style.border_color=Color(Color("6b4a35"),alpha)
  style.set_border_width_all(2)
  style.set_corner_radius_all(10)
  draw_style_box(style,rect)
  var x=rect.end.x-1 if bubble_side<0 else rect.position.x+1
  var y=rect.position.y+rect.size.y*.65
  var tail=PackedVector2Array([Vector2(x,y-5),Vector2(x-bubble_side*7,y+2),Vector2(x,y+5)])
  draw_colored_polygon(tail,Color(Color("fffdf8"),alpha))
  draw_polyline(tail,Color(Color("6b4a35"),alpha),2,true)
  var font=preload("res://scripts/cozy_ui.gd").heading_font()
  var i=0
  for line in bubble_lines():
   var width=font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
   draw_string(font,Vector2(rect.position.x+(80-width)/2,rect.position.y+20+i*17),line,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(Color("5b4636"),alpha))
   i+=1
