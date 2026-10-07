extends Window
const Catalog=preload("res://scripts/catalog.gd")
const Native=preload("res://scripts/native_mouse.gd")
var app
var root: Node2D
var sprite: Sprite2D
var pin
var frames: Array[Texture2D]=[]
var images: Array[Image]=[]
var index=0
var age=1.0
var pending=false
var side=0
var header: Window
var header_root: Node2D
var status: Label
var detail: Label
var settings_button: Button
var gift_button
var gift_keys=""
var light_tray: Panel
var light_nodes: Array[Panel]=[]
var move_enabled=false
var moving=false
var grab_offset=Vector2i.ZERO
var anchor_position=Vector2i.ZERO
var lights: Array[StyleBoxFlat]=[]
var levels: Array[float]=[]
var light_index=-1
var monitor_time=0.0
var screen_rect=Rect2i()
var base_input_points=PackedVector2Array()
var header_panel: Panel
var header_rule: ColorRect
var header_action_pending=false
var header_action_gifts=false
var text_refresh_time=0.0
func header_width() -> float:
	return 180+maxf(0,app.text_scale-1)*160
func _init() -> void:
	visible=false
	force_native=true
	borderless=true
	transparent=true
	transparent_bg=true
	always_on_top=true
	unfocusable=false
	unresizable=true
	title="복슬복슬메이트"
func _ready() -> void:
	theme=app.skin
	gui_embed_subwindows=false
	root=Node2D.new()
	add_child(root)
	sprite=Sprite2D.new()
	sprite.centered=false
	sprite.position=Vector2(10,0)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var material_=ShaderMaterial.new()
	material_.shader=preload("res://scripts/tone.gdshader")
	sprite.material=material_
	root.add_child(sprite)
	pin=preload("res://scripts/pin.gd").new()
	pin.worn=true
	root.add_child(pin)
	var tray=Panel.new()
	light_tray=tray
	tray.position=Vector2(20,196)
	tray.size=Vector2(180,28)
	tray.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tray.add_theme_stylebox_override("panel",box("faf8f3",9))
	root.add_child(tray)
	for i in range(8):
		var tile=Panel.new()
		tile.position=Vector2(32+i*20,202)
		tile.size=Vector2(16,16)
		tile.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var style=box("e4e2d8",3)
		style.set_border_width_all(1)
		style.border_color=Color("d3d5c8")
		tile.add_theme_stylebox_override("panel",style)
		root.add_child(tile)
		light_nodes.append(tile)
		lights.append(style)
		levels.append(0)
	# Controls live in the PRIMARY OS window. No transparent/passive root ancestor.
	header=get_tree().root
	header.borderless=true
	# Opaque native header: Windows must not alpha-hit-test the controls.
	header.transparent=false
	header.transparent_bg=false
	header.always_on_top=true
	header.unresizable=true
	header.unfocusable=false
	header.transient=false
	header.exclusive=false
	header.title="복슬복슬메이트 · 설정"
	header.theme=app.skin
	header.mouse_passthrough=false
	header_root=Node2D.new()
	header.add_child(header_root)
	var panel=Panel.new()
	header_panel=panel
	panel.size=Vector2(180,88)
	var panel_style=box("fff9ef",12)
	panel_style.border_color=Color("dbcbb7")
	panel_style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel",panel_style)
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_root.add_child(panel)
	var rule=ColorRect.new()
	header_rule=rule
	rule.position=Vector2(12,38)
	rule.size=Vector2(156,1)
	rule.color=Color("e5d8c7")
	rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_root.add_child(rule)
	status=label(Vector2(6,7),Vector2(86,28),18)
	status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	status.add_theme_font_override("font",preload("res://scripts/cozy_ui.gd").heading_font())
	detail=label(Vector2(94,7),Vector2(80,28),12)
	detail.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	settings_button=Button.new()
	settings_button.text="설정"
	settings_button.icon=preload("res://scripts/cozy_ui.gd").icon("settings",18)
	settings_button.position=Vector2(8,46)
	settings_button.size=Vector2(78,34)
	settings_button.add_theme_font_size_override("font_size",12)
	for color_ in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		settings_button.add_theme_color_override(color_,Color("59564f"))
	style_header_button(settings_button,"e5eadd","dce5d2","cfddc4","98a68f")
	settings_button.focus_mode=Control.FOCUS_ALL
	settings_button.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
	settings_button.pressed.connect(func(): request_header_action(false))
	header_root.add_child(settings_button)
	gift_button=preload("res://scripts/gift_button.gd").new()
	gift_button.position=Vector2(94,46)
	gift_button.size=Vector2(78,34)
	gift_button.compact=true
	gift_button.alignment=HORIZONTAL_ALIGNMENT_RIGHT
	gift_button.add_theme_font_size_override("font_size",11)
	for color_ in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		gift_button.add_theme_color_override(color_,Color("744c48"))
	gift_button.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
	style_header_button(gift_button,"f4e9e2","f0e0d8","ead7ce","bb8a83")
	gift_button.pressed.connect(func(): request_header_action(true))
	header_root.add_child(gift_button)
	header.window_input.connect(on_header_input)
	header.focus_exited.connect(finish_drag)
	focus_exited.connect(finish_drag)
	window_input.connect(on_input)
	load_friend()
	apply_text_size()
	place()
	show()
	header.show()
	Native.apply(header,false,true)
	Native.apply(self,false,true)
func request_header_action(gifts: bool) -> void:
	finish_drag()
	header_action_gifts=gifts
	if header_action_pending: return
	header_action_pending=true
	commit_header_action.call_deferred()
func commit_header_action() -> void:
	header_action_pending=false
	if header_action_gifts: app.open_gifts()
	else: app.open_settings()
func on_header_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	if event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		finish_drag()
		return
	var point=header_root.get_global_transform().affine_inverse()*event.position
	if event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if Rect2(settings_button.position,settings_button.size).has_point(point):
			request_header_action(false)
			return
		if Rect2(gift_button.position,gift_button.size).has_point(point):
			request_header_action(true)
			return
	if point.y<45: on_input(event)
func finish_drag() -> void:
	if not moving: return
	moving=false
	move_enabled=false
	app.custom_position=true
	app.saved_position=anchor_position
	app.save_game()
static func box(color: String,radius: int) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(color)
	style.set_corner_radius_all(radius)
	return style
static func style_header_button(button: Button,normal: String,hover: String,pressed: String,outline: String) -> void:
	# Explicit states also work across the Node2D parent, without default dark styles.
	for state_ in ["normal","hover","pressed","hover_pressed","disabled"]:
		var color_=normal
		if state_=="hover": color_=hover
		if state_ in ["pressed","hover_pressed"]: color_=pressed
		button.add_theme_stylebox_override(state_,box(color_,8))
	var focus=box("00000000",8)
	focus.border_color=Color(outline)
	focus.set_border_width_all(1)
	button.add_theme_stylebox_override("focus",focus)
func label(pos: Vector2,dimensions: Vector2,font_size: int) -> Label:
	var value=Label.new()
	value.position=pos
	value.size=dimensions
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	value.mouse_filter=Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_size_override("font_size",font_size)
	value.add_theme_color_override("font_color",Color("59564f"))
	header_root.add_child(value)
	return value
func load_friend() -> void:
	frames=Catalog.frames(app.species)
	images.clear()
	for frame in frames: images.append(frame.get_image())
	base_input_points.clear()
	if frames.size()!=3:
		push_error("타자친구 이미지 3장이 필요합니다")
		return
	index=0
	age=1
	pending=false
	sprite.texture=frames[0]
	sprite.scale=Vector2.ONE*(200.0/frames[0].get_width())
	pin.position=sprite.position+Catalog.PINS[app.species]*200
	apply_cosmetics()
	update_input_region()
func apply_cosmetics() -> void:
	sprite.material.set_shader_parameter("balance",Catalog.TONES[app.species])
	pin.kind=app.collection.selected(app.species,"pin")
	pin.position=sprite.position+Catalog.accessory_anchor(app.species,pin.kind)*200
	sprite.material.set_shader_parameter("shift",app.collection.TINTS.get(app.collection.selected(app.species,"skin"),Vector3.ZERO))
	update_input_region()
func place() -> void:
	screen_rect=DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen())
	if screen_rect.size.x<=0: screen_rect=Rect2i(0,0,1280,720)
	var zoom_=app.scale_factor if app.scale_factor>0 else [.85,1.0,1.2][app.zoom]
	root.scale=Vector2.ONE*zoom_
	header_root.scale=Vector2.ONE*maxf(1.0,zoom_)
	size=Vector2i(Vector2(220,232)*zoom_)
	var footprint=footprint_for(zoom_)
	anchor_position=screen_rect.position+Vector2i(12,12)
	if app.corner in [1,3]: anchor_position.x=screen_rect.end.x-footprint.x-12
	if app.corner in [2,3]: anchor_position.y=screen_rect.end.y-footprint.y-12
	if app.custom_position: anchor_position=app.saved_position
	anchor_position=anchor_position.clamp(screen_rect.position,(screen_rect.end-footprint).max(screen_rect.position))
	header.size=Vector2i(Vector2(header_width(),88)*header_root.scale)
	header.mouse_passthrough_polygon=PackedVector2Array()
	sync_positions()
	update_input_region()
func sync_positions() -> void:
	position=anchor_position+Vector2i((footprint_for(root.scale.x).x-size.x)/2,roundi(90*header_root.scale.y))
	var width=footprint_for(root.scale.x).x
	header.position=anchor_position+Vector2i((width-header.size.x)/2,0)
func update_input_region() -> void:
	if frames.is_empty(): return
	# Fixed Windows region, encompassing all cels. Never flip WS_EX_TRANSPARENT while clicking.
	var points=PackedVector2Array()
	if base_input_points.is_empty():
		for image_ in images:
			var bitmap=BitMap.new()
			bitmap.create_from_image_alpha(image_,.1)
			for polygon in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image_.get_size()),8):
				for point in polygon: base_input_points.append(sprite.position+point*sprite.scale)
		base_input_points=Geometry2D.convex_hull(base_input_points)
	for point in base_input_points: points.append(point*root.scale)
	for point in [Vector2(20,196),Vector2(200,196),Vector2(200,224),Vector2(20,224)]: points.append(point*root.scale)
	if not pin.kind.is_empty():
		var rect=pin.asset_rect()
		for point in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]: points.append((pin.position+point)*root.scale)
	mouse_passthrough_polygon=Geometry2D.convex_hull(points)
	Native.apply(self,false,true)
func on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index==MOUSE_BUTTON_RIGHT: app.open_settings()
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				moving=true
				grab_offset=DisplayServer.mouse_get_position()-anchor_position
			else:
				finish_drag()
func advance(delta: float,count: int) -> void:
	if moving:
		var footprint=footprint_for(root.scale.x)
		anchor_position=(DisplayServer.mouse_get_position()-grab_offset).clamp(screen_rect.position,(screen_rect.end-footprint).max(screen_rect.position))
		sync_positions()
	age+=delta
	if count>0: pending=true
	if pending and age>=.22:
		pending=false
		age=0
		side=1-side
	index=(side+1) if age<.17 else 0
	if frames.size()==3 and sprite.texture!=frames[index]: sprite.texture=frames[index]
	for i in range(8): levels[i]=maxf(0,levels[i]-delta/.32)
	for i in range(mini(count,8)):
		light_index=(light_index+1)%8
		levels[light_index]=1
	for i in range(8):
		var fill=Color("e4e2d8").lerp(app.collection.light_color(),levels[i])
		if lights[i].bg_color!=fill: lights[i].bg_color=fill
		light_nodes[i].visible=app.show_lights
		var border=Color("d3d5c8").lerp(Color("8eac67"),levels[i])
		if lights[i].border_color!=border: lights[i].border_color=border
	text_refresh_time+=delta
	if text_refresh_time>=.1:
		text_refresh_time=0.0
		refresh_text()
	light_tray.visible=app.show_lights
	monitor_time+=delta
	if monitor_time>1:
		monitor_time=0
		if screen_rect!=DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen()): place()
func refresh_text() -> void:
	var apm_text="APM —"
	if app.bridge.connected and not app.paused:
		apm_text="APM %d"%app.activity.apm
	status.text=apm_text
	detail.text="활동 "+app.activity.time_text()
	if app.paused: detail.text="잠시 쉬는 중 · "+app.activity.time_text()
	elif not app.bridge.connected: detail.text="입력 연결 확인 · 설정에서 다시 시작"
	if app.save_error: detail.text="저장 실패 · 폴더 권한을 확인해주세요"
	var gift=app.collection.summary()
	settings_button.text="설정"
	if move_enabled: detail.text="동물을 잡아 원하는 곳에 놓아주세요"
	var available=""
	var gift_count=0
	for item in app.collection.ITEMS:
		if app.collection.eligible(item.id) and item.id not in app.collection.claimed:
			available+=item.id
			gift_count+=1
	var ready_orders=app.collection.ready_orders()
	if ready_orders>0:
		available+="orders:"+app.collection.day+":"+str(ready_orders)
		gift_count+=ready_orders
	if available!=gift_keys:
		if not available.is_empty(): gift_button.arrive()
		gift_keys=available
	gift_button.delivered=not available.is_empty()
	gift_button.count=gift_count
	gift_button.text="선물 "
	gift_button.modulate=Color.WHITE
	gift_button.effects=app.gift_effects
	gift_button.tooltip_text=gift
	detail.tooltip_text=detail.text
	if gift_button.delivered: gift_button.tooltip_text="받을 수 있는 선물 %d개 · 눌러서 확인"%gift_count
	settings_button.tooltip_text=gift
func apply_text_size() -> void:
	status.add_theme_font_size_override("font_size",maxi(12,roundi(18*app.text_scale)))
	detail.add_theme_font_size_override("font_size",maxi(12,maxi(12,roundi(12*app.text_scale))))
	settings_button.add_theme_font_size_override("font_size",maxi(12,roundi(12*app.text_scale)))
	gift_button.add_theme_font_size_override("font_size",maxi(12,roundi(12*app.text_scale)))
	var width=header_width()
	header_panel.size=Vector2(width,88)
	header_rule.size.x=width-24
	var column=(width-24)/2
	status.size.x=column+8
	detail.position.x=width/2+4
	detail.size.x=column+2
	settings_button.size=Vector2(column,34)
	gift_button.position.x=width/2+4
	gift_button.size=Vector2(column,34)
	if visible: place()

func footprint_for(zoom_: float) -> Vector2i:
	return Vector2i(ceil(maxf(220*zoom_,header_width()*maxf(1,zoom_))),ceil(232*zoom_+90*maxf(1,zoom_)))
func resize_pivot_offset(zoom_: float) -> Vector2:
	var bounds=Vector2(footprint_for(zoom_))
	return Vector2(bounds.x/2,bounds.y)
