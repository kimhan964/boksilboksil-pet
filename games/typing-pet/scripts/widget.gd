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
var lights: Array[StyleBoxFlat]=[]
var levels: Array[float]=[]
var light_index=-1
var monitor_time=0.0
var screen_rect=Rect2i()
func _init() -> void:
	visible=false
	force_native=true
	borderless=true
	transparent=true
	transparent_bg=true
	always_on_top=true
	unfocusable=true
	unresizable=true
	title="복슬복슬 타자친구"
func _ready() -> void:
	theme=app.skin
	gui_embed_subwindows=false
	root=Node2D.new()
	add_child(root)
	sprite=Sprite2D.new()
	sprite.centered=false
	sprite.position=Vector2(10,80)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var material_=ShaderMaterial.new()
	material_.shader=preload("res://scripts/tone.gdshader")
	sprite.material=material_
	root.add_child(sprite)
	pin=preload("res://scripts/pin.gd").new()
	root.add_child(pin)
	var tray=Panel.new()
	light_tray=tray
	tray.position=Vector2(22,280)
	tray.size=Vector2(176,28)
	tray.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tray.add_theme_stylebox_override("panel",box("faf8f3",9))
	root.add_child(tray)
	for i in range(8):
		var tile=Panel.new()
		tile.position=Vector2(32+i*20,286)
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
	# Header uses its OWN native window, never subject to the pet's WS_EX_TRANSPARENT.
	header=Window.new()
	header.visible=false
	header.force_native=true
	header.borderless=true
	header.transparent=true
	header.transparent_bg=true
	header.always_on_top=true
	header.unresizable=true
	header.title="타자친구 · 설정"
	header.theme=app.skin
	add_child(header)
	header_root=Node2D.new()
	header.add_child(header_root)
	var panel=Panel.new()
	panel.size=Vector2(192,76)
	panel.add_theme_stylebox_override("panel",box("faf8f3",12))
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_root.add_child(panel)
	status=label(Vector2(6,3),Vector2(180,26),18)
	detail=label(Vector2(6,29),Vector2(180,17),10)
	settings_button=Button.new()
	settings_button.text="설정 · 꾸미기"
	settings_button.position=Vector2(8,49)
	settings_button.size=Vector2(126,23)
	settings_button.add_theme_font_size_override("font_size",11)
	for color_ in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		settings_button.add_theme_color_override(color_,Color("59564f"))
	for state_ in ["normal","hover","pressed"]:
		settings_button.add_theme_stylebox_override(state_,box("e5eadd" if state_=="normal" else "cfddc4",7))
	settings_button.focus_mode=Control.FOCUS_ALL
	settings_button.pressed.connect(func(): app.open_settings())
	header_root.add_child(settings_button)
	gift_button=preload("res://scripts/gift_button.gd").new()
	gift_button.position=Vector2(140,45)
	gift_button.size=Vector2(44,30)
	gift_button.add_theme_stylebox_override("normal",box("f4e9e2",8))
	gift_button.add_theme_stylebox_override("hover",box("ead7ce",8))
	gift_button.pressed.connect(func(): app.open_gifts())
	header_root.add_child(gift_button)
	window_input.connect(on_input)
	load_friend()
	place()
	show()
	header.show()
	Native.apply(header,false,true)
	Native.apply(self,false,true)
static func box(color: String,radius: int) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color(color)
	style.set_corner_radius_all(radius)
	return style
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
func apply_cosmetics() -> void:
	pin.kind=app.collection.selected(app.species,"pin")
	sprite.material.set_shader_parameter("shift",app.collection.TINTS.get(app.collection.selected(app.species,"skin"),Vector3.ZERO))
func place() -> void:
	screen_rect=DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen())
	if screen_rect.size.x<=0: screen_rect=Rect2i(0,0,1280,720)
	var zoom_=app.scale_factor if app.scale_factor>0 else [.85,1.0,1.2][app.zoom]
	root.scale=Vector2.ONE*zoom_
	header_root.scale=Vector2.ONE*zoom_
	size=Vector2i(Vector2(220,312)*zoom_)
	position=screen_rect.position+Vector2i(12,12)
	if app.corner in [1,3]: position.x=screen_rect.end.x-size.x-12
	if app.corner in [2,3]: position.y=screen_rect.end.y-size.y-12
	if app.custom_position: position=app.saved_position
	position=position.clamp(screen_rect.position,(screen_rect.end-size).max(screen_rect.position))
	header.size=Vector2i(Vector2(192,76)*zoom_)
	header.position=position+Vector2i(Vector2(14,2)*zoom_)
func on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index==MOUSE_BUTTON_RIGHT: app.open_settings()
		if event.button_index==MOUSE_BUTTON_LEFT and move_enabled:
			if event.pressed:
				moving=true
				grab_offset=DisplayServer.mouse_get_position()-position
			else:
				moving=false
				move_enabled=false
				app.custom_position=true
				app.saved_position=position
				app.save_game()
func advance(delta: float,count: int) -> void:
	if moving:
		position=(DisplayServer.mouse_get_position()-grab_offset).clamp(screen_rect.position,(screen_rect.end-size).max(screen_rect.position))
		header.position=position+Vector2i(Vector2(14,2)*root.scale)
	age+=delta
	if count>0: pending=true
	if pending and age>=.22:
		pending=false
		age=0
		side=1-side
	index=(side+1) if age<.17 else 0
	if frames.size()==3: sprite.texture=frames[index]
	for i in range(8): levels[i]=maxf(0,levels[i]-delta/.32)
	for i in range(mini(count,8)):
		light_index=(light_index+1)%8
		levels[light_index]=1
	for i in range(8):
		lights[i].bg_color=Color("e4e2d8").lerp(Color("b8d58a"),levels[i])
		light_nodes[i].visible=app.show_lights
		lights[i].border_color=Color("d3d5c8").lerp(Color("8eac67"),levels[i])
	refresh_text()
	light_tray.visible=app.show_lights
	var local=sprite.get_global_transform().affine_inverse()*Vector2(DisplayServer.mouse_get_position()-position)
	var hit=frames.size()==3 and sprite.get_rect().has_point(local) and images[index].get_pixelv(Vector2i(local)).a>.1
	Native.apply(self,not hit and not moving)
	monitor_time+=delta
	if monitor_time>1:
		monitor_time=0
		if screen_rect!=DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen()): place()
func refresh_text() -> void:
	status.text="APM —"
	if app.bridge.connected and not app.paused:
		status.text="APM %d"%app.activity.apm
	detail.text="활동 "+app.activity.time_text()
	if app.paused: detail.text="잠시 쉬는 중 · "+app.activity.time_text()
	elif not app.bridge.connected: detail.text="입력 연결 확인 · 설정에서 다시 시작"
	if app.save_error: detail.text="저장 실패 · 폴더 권한을 확인해주세요"
	var gift=app.collection.summary()
	settings_button.text="설정 · 꾸미기"
	if move_enabled: detail.text="동물을 잡아 원하는 곳에 놓아주세요"
	var available=""
	for item in app.collection.ITEMS:
		if app.collection.eligible(item.id) and item.id not in app.collection.claimed: available+=item.id
	if available!=gift_keys:
		if not available.is_empty(): gift_button.arrive()
		gift_keys=available
	gift_button.delivered=not available.is_empty()
	gift_button.effects=app.gift_effects
	gift_button.tooltip_text=gift
	if gift_button.delivered and gift_button.age<5 and not move_enabled: detail.text="작은 선물이 도착했어요!"
	settings_button.tooltip_text=gift
