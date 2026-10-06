extends Node2D
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
