extends Node2D
const GENERATED=["ribbon","jester","crown","beret","wizard","sprout","clover","daisy","star","headphones","sleepcap","friedegg","teacup","mushroom"]
static var textures: Dictionary={}
var worn=false
func _init() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
static func is_hat(id: String) -> bool:
	return id in ["jester","crown","beret","wizard","sprout","headphones","sleepcap","teacup","mushroom"]
static func texture_for(id: String) -> Texture2D:
	if id not in GENERATED: return null
	if not textures.has(id):
		var image=Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/accessories-varco-v2/"+id+".png"))!=OK: return null
		if image.get_width()>192:
			image.resize(192,maxi(1,roundi(image.get_height()*192.0/image.get_width())),Image.INTERPOLATE_LANCZOS)
		image.generate_mipmaps()
		textures[id]=ImageTexture.create_from_image(image)
	return textures[id]
func asset_rect() -> Rect2:
	var tex=texture_for(kind)
	if tex==null: return Rect2(-10,-10,20,20)
	var width=50.0 if is_hat(kind) else 30.0
	if kind=="sprout": width=30.0
	var dimensions=tex.get_size()*(width/tex.get_width())
	# Keep tall floppy hats inside the shortest pet's canvas at every window size.
	if is_hat(kind) and dimensions.y>42.0: dimensions*=42.0/dimensions.y
	return Rect2(Vector2(-dimensions.x/2,-dimensions.y+4) if worn and is_hat(kind) else -dimensions/2,dimensions)
var kind="":
	set(value):
		kind=value
		queue_redraw()
const LINE=Color("756659")
func polygon(points: PackedVector2Array,color: Color) -> void:
	draw_colored_polygon(points,color)
	var outline=points.duplicate()
	outline.append(points[0])
	draw_polyline(outline,LINE,1.0,true)
func _draw() -> void:
	var texture_=texture_for(kind)
	if texture_!=null:
		draw_texture_rect(texture_,asset_rect(),false)
		return
	if kind=="ribbon":
		polygon(PackedVector2Array([Vector2(-2,0),Vector2(-9,-5),Vector2(-10,4),Vector2(-3,3)]),Color("c99eaa"))
		polygon(PackedVector2Array([Vector2(2,0),Vector2(9,-5),Vector2(10,4),Vector2(3,3)]),Color("d6adb6"))
		polygon(PackedVector2Array([Vector2(-2,1),Vector2(-6,10),Vector2(-1,8),Vector2(1,2)]),Color("c99eaa"))
		polygon(PackedVector2Array([Vector2(2,1),Vector2(6,10),Vector2(1,8),Vector2(-1,2)]),Color("d6adb6"))
		draw_circle(Vector2.ZERO,2.7,LINE,true,-1,true)
		draw_circle(Vector2.ZERO,1.8,Color("edd7d8"),true,-1,true)
	elif kind=="clover":
		draw_line(Vector2(0,2),Vector2(3,10),LINE,1.5,true)
		for p in [Vector2(-3,-3),Vector2(3,-3),Vector2(-3,3),Vector2(3,3)]:
			draw_circle(p,4.5,LINE,true,-1,true)
			draw_circle(p,3.7,Color("9ab88a"),true,-1,true)
		draw_circle(Vector2.ZERO,2,Color("dce6c3"),true,-1,true)
	elif kind=="daisy":
		for i in range(7):
			var p=Vector2.from_angle(i*TAU/7)*5
			draw_circle(p,3.9,LINE,true,-1,true)
			draw_circle(p,3.2,Color("fff6df"),true,-1,true)
		draw_circle(Vector2.ZERO,3.4,Color("d8b46c"),true,-1,true)
	elif kind=="star":
		var points=PackedVector2Array()
		for i in range(10): points.append(Vector2.from_angle(-PI/2+i*PI/5)*(9 if i%2==0 else 4.6))
		polygon(points,Color("e6ca87"))
		draw_line(Vector2(-2,-3),Vector2(1,-4),Color("fff3ce"),1.5,true)
