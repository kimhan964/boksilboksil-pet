extends Window
signal moved
signal removed
signal activated(action: String)
signal layer_changed
const Catalog=preload("res://scripts/furniture_catalog.gd")
var item_id="sofa"
var sprite: Sprite2D
var menu: PopupMenu
var dragging=false
var press_cursor=Vector2.ZERO
var press_position=Vector2.ZERO
var hit_polygon=PackedVector2Array()
var food_sprite: Sprite2D
var active=false
var drop_hover=false
var mirrored=false
var floor_locked=false
var floor_top=0
func _init() -> void:
	visible=false
	force_native=true
	borderless=true
	transparent=true
	transparent_bg=true
	always_on_top=true
	unfocusable=true
	unresizable=true
	transient=false
	exclusive=false
func _ready() -> void:
	title=Catalog.ITEMS[item_id].name+" · 드래그로 배치 / 우클릭으로 치우기"
	var tex=Catalog.texture(item_id)
	if tex==null: return
	var limit: Vector2=Catalog.ITEMS[item_id].size
	var factor=minf(limit.x/tex.get_width(),limit.y/tex.get_height())
	var dimensions=tex.get_size()*factor
	size=Vector2i(dimensions.ceil())+Vector2i(12,12)
	sprite=Sprite2D.new()
	sprite.texture=tex
	sprite.centered=false
	sprite.position=Vector2(6,6)
	sprite.scale=Vector2.ONE*factor
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	refresh_hit_region()
	food_sprite=Sprite2D.new()
	add_child(food_sprite)
	menu=PopupMenu.new()
	menu.force_native=true
	menu.add_item(Catalog.use_label(item_id),1)
	if item_id=="table": menu.add_item("물 마시기",2)
	if item_id=="table": menu.add_item("여기서 식사하기",3)
	menu.add_separator()
	menu.add_item("← 왼쪽으로 이동",10)
	menu.add_item("오른쪽으로 이동 →",11)
	menu.add_check_item("좌우 반전",12)
	menu.add_separator()
	menu.add_item("가구 치우기",0)
	menu.id_pressed.connect(menu_action)
	add_child(menu)
	window_input.connect(handle_input)
	show()
	update_input()
func menu_action(id: int) -> void:
	match id:
		0: removed.emit()
		10: nudge(-24)
		11: nudge(24)
		12: set_mirrored(not mirrored,true)
		_: activated.emit("drink" if id==2 else ("eat" if id==3 else "default"))
func refresh_hit_region() -> void:
	var tex=sprite.texture
	var points=preload("res://scripts/animation_outline.gd").local_hull(tex)
	if mirrored:
		for i in range(points.size()): points[i].x=tex.get_width()-points[i].x
	hit_polygon=sprite.transform*points
	# This picture never animates. Install one generously padded input region;
	# clicking must also work when the cursor enters and presses in one frame.
	var padded=PackedVector2Array()
	for point in hit_polygon:
		for offset in [Vector2(-2,-2),Vector2(2,-2),Vector2(-2,2),Vector2(2,2)]: padded.append(point+offset)
	mouse_passthrough_polygon=Geometry2D.convex_hull(padded)
func set_mirrored(value: bool,persist: bool=false) -> void:
	mirrored=value
	if is_instance_valid(sprite):
		sprite.flip_h=value
		refresh_hit_region()
	if is_instance_valid(menu) and menu.get_item_index(12)>=0: menu.set_item_checked(menu.get_item_index(12),value)
	if persist:
		moved.emit()
		layer_changed.emit()
func nudge(amount: int) -> void:
	position=clamp_position(Vector2(position)+Vector2(amount,0))
	if floor_locked: position.y=floor_top
	moved.emit()
	layer_changed.emit()
func clamp_position(point: Vector2) -> Vector2i:
	if DisplayServer.get_name()=="headless": return Vector2i(point.clamp(Vector2.ZERO,Vector2(1920,1080)-Vector2(size)))
	var monitor=DisplayServer.get_screen_from_rect(Rect2i(Vector2i(point+Vector2(size)*.5),Vector2i.ONE))
	if monitor<0: monitor=DisplayServer.SCREEN_PRIMARY
	var usable=DisplayServer.screen_get_usable_rect(monitor)
	return Vector2i(point.clamp(Vector2(usable.position),Vector2((usable.end-size).max(usable.position))))
func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging:
		move_dragged_to(Vector2(DisplayServer.mouse_get_position()))
		return
	if not event is InputEventMouseButton: return
	if event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
		dragging=false
		menu.position=DisplayServer.mouse_get_position()
		menu.popup()
	elif event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging=true
			# Use the position carried by the press event: the OS cursor can
			# already be at the release point during a very quick drag.
			press_cursor=Vector2(position)+event.position
			press_position=Vector2(position)
		elif dragging:
			move_dragged_to(Vector2(DisplayServer.mouse_get_position()))
			dragging=false
			finish_drag()
func update_input() -> void:
	mouse_passthrough=false
func finish_drag() -> void:
	if Vector2(position).distance_to(press_position)<4: activated.emit("default")
	else: moved.emit()
	layer_changed.emit()
func art_point(fraction: Vector2) -> Vector2:
	if mirrored: fraction.x=1.0-fraction.x
	return Vector2(position)+sprite.position+sprite.texture.get_size()*sprite.scale*fraction
func set_food(texture: Texture2D,amount: float=1.0) -> void:
	if item_id!="table": return
	food_sprite.texture=texture
	food_sprite.visible=texture!=null and amount>.01
	if not food_sprite.visible: return
	food_sprite.position=art_point(Vector2(.68,.35))-Vector2(position)
	food_sprite.flip_h=mirrored
	food_sprite.scale=Vector2.ONE*minf(21.0/texture.get_width(),18.0/texture.get_height())*lerpf(.7,1.0,amount)
	food_sprite.modulate.a=amount
func set_active(value: bool) -> void:
	active=value
	refresh_tint()
func set_drop_hover(value: bool) -> void:
	if drop_hover==value: return
	drop_hover=value
	refresh_tint()
func refresh_tint() -> void:
	if not is_instance_valid(sprite): return
	# Tint existing pixels so the shaped native window cannot clip a new halo.
	sprite.modulate=Color(1.0,.88,.63) if drop_hover else (Color(1.0,.94,.81) if item_id=="lamp" and active else Color.WHITE)
func move_dragged_to(cursor: Vector2) -> void:
	position=clamp_position(press_position+cursor-press_cursor)
	if floor_locked: position.y=floor_top
func _process(_delta: float) -> void:
	if dragging:
		move_dragged_to(Vector2(DisplayServer.mouse_get_position()))
		if not (DisplayServer.mouse_get_button_state() & MOUSE_BUTTON_MASK_LEFT):
			dragging=false
			finish_drag()
	update_input()
