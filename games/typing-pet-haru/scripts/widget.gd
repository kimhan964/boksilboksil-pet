extends Window
const COMBO_REACTIONS := true
const HEAD_TOP_PX := 132.0 # Regenerated asset silhouette minimum; updated with color audit.
const HEAD_GAP := 12.0
const WIDGET_WIDTH := 360.0
var pet_root: Node2D
const TYPING_CYCLE := .24
const Catalog=preload("res://scripts/catalog.gd")
const Native=preload("res://scripts/native_mouse.gd")
var app
var root: Node2D
var sprite: Sprite2D
var action_sprite: Sprite2D
var action_frames: Array[Texture2D]=[]
var action_time=0.0
var action_duration=0.0
var action_cooldown=0.0
var action_index=0
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
var footer: Window
var footer_root: Node2D
var footer_panel: Panel
var combo_bar
var combo_number
var apm_label: Label
var combo_fx
var detail: Label
var settings_button: Button
var gift_button
var gift_keys=""
var gift_window: Window
var gift_root: Node2D
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
var body_offset=Vector2.ZERO
var expression=Vector2.ZERO
func header_width() -> float:
	return 200+maxf(0,app.text_scale-1)*160
func footer_row_height() -> float:
	if app.text_scale<=1.0: return 17.0
	var height=17.0
	for text_label in [apm_label,detail]:
		var font=text_label.get_theme_font("font")
		var pixels=text_label.get_theme_font_size("font_size")
		height=maxf(height,ceil(font.get_height(pixels))+2*text_label.get_theme_constant("outline_size"))
	return height
func footer_height() -> float:
	return footer_row_height()*2
static func usable_screens() -> Array[Rect2i]:
	var screens: Array[Rect2i]=[]
	for screen in range(DisplayServer.get_screen_count()):
		screens.append(DisplayServer.screen_get_usable_rect(screen))
	return screens
static func screen_for_bounds(bounds: Rect2i,screens: Array,primary: int=0) -> Rect2i:
	var chosen=Rect2i(0,0,1280,720)
	if primary>=0 and primary<screens.size() and screens[primary].has_area(): chosen=screens[primary]
	else:
		for screen in screens:
			if screen.has_area():
				chosen=screen
				break
	var largest=0
	for screen in screens:
		var overlap=bounds.intersection(screen)
		var area=overlap.size.x*overlap.size.y
		if area>largest:
			largest=area
			chosen=screen
	return chosen
static func screen_for_point(point: Vector2i,screens: Array,primary: int=0) -> Rect2i:
	var chosen=screen_for_bounds(Rect2i(),screens,primary)
	var nearest=INF
	for screen in screens:
		if not screen.has_area(): continue
		if screen.has_point(point): return screen
		# Usable areas exclude taskbars; keep dragging on the nearest screen there.
		var distance=Vector2(point-point.clamp(screen.position,screen.end)).length_squared()
		if distance<nearest:
			nearest=distance
			chosen=screen
	return chosen
func _init() -> void:
	visible=false
	force_native=true
	borderless=true
	transparent=true
	transparent_bg=true
	always_on_top=true
	unfocusable=false
	unresizable=true
	title="단짝 타자친구"
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
	action_sprite=Sprite2D.new()
	action_sprite.centered=false
	action_sprite.position=sprite.position
	action_sprite.visible=false
	action_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	action_sprite.material=material_.duplicate()
	root.add_child(action_sprite)
	pin=preload("res://scripts/pin.gd").new()
	pin.worn=true
	root.add_child(pin)
	pet_root=Node2D.new()
	root.add_child(pet_root)
	sprite.reparent(pet_root)
	action_sprite.reparent(pet_root)
	pin.reparent(pet_root)
	combo_fx=preload("res://scripts/combo_fx.gd").new()
	root.add_child(combo_fx)
	var tray=Panel.new()
	light_tray=tray
	tray.position=Vector2(20,196)
	tray.size=Vector2(180,28)
	tray.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tray.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	root.add_child(tray)
	for i in range(8):
		var tile=Panel.new()
		tile.position=Vector2(43.5+i*17,201)
		tile.size=Vector2(14,12)
		tile.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var style=box("fff7ec",3)
		style.shadow_color=Color("efe1cc")
		style.shadow_size=1
		style.shadow_offset=Vector2(0,2)
		style.set_border_width_all(2)
		style.border_color=Color("6b4a35")
		tile.add_theme_stylebox_override("panel",style)
		root.add_child(tile)
		light_nodes.append(tile)
		lights.append(style)
		levels.append(0)
	# Controls remain in the primary native window with opaque button hit surfaces.
	header=get_tree().root
	header.borderless=true
	# Transparent surroundings; button fills remain opaque for Windows hit testing.
	header.transparent=true
	header.transparent_bg=true
	header.always_on_top=true
	header.unresizable=true
	header.unfocusable=false
	header.transient=false
	header.exclusive=false
	header.title="단짝 타자친구 · 설정"
	header.theme=app.skin
	header.mouse_passthrough=false
	header_root=Node2D.new()
	header.add_child(header_root)
	var panel=Panel.new()
	header_panel=panel
	panel.size=Vector2(200,74)
	panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_root.add_child(panel)
	var rule=ColorRect.new()
	header_rule=rule
	rule.visible=false
	rule.position=Vector2(12,117)
	rule.size=Vector2(156,1)
	rule.color=Color("efe1cc")
	rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_root.add_child(rule)
	status=label(Vector2(6,4),Vector2(168,28),18)
	status.visible=false
	combo_number=preload("res://scripts/combo_number.gd").new()
	combo_number.position=Vector2(6,0)
	combo_number.size=Vector2(188,70)
	combo_number.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_root.add_child(combo_number)
	status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	status.add_theme_font_override("font",preload("res://scripts/cozy_ui.gd").heading_font())
	apm_label=label(Vector2(6,33),Vector2(168,24),12)
	detail=label(Vector2(6,57),Vector2(168,22),12)
	detail.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	combo_bar=preload("res://scripts/combo_timer.gd").new()
	combo_bar.position=Vector2(30,66)
	combo_bar.size=Vector2(140,4)
	combo_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_root.add_child(combo_bar)
	footer=Window.new()
	footer.visible=false
	footer.force_native=true
	footer.borderless=true
	footer.transparent=true
	footer.transparent_bg=true
	footer.always_on_top=true
	footer.unresizable=true
	footer.title="단짝 타자친구 · 활동"
	footer.theme=app.skin
	add_child(footer)
	footer_root=Node2D.new()
	footer.add_child(footer_root)
	footer_panel=Panel.new()
	footer_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	footer_root.add_child(footer_panel)
	apm_label.reparent(footer_root)
	detail.reparent(footer_root)
	apm_label.position=Vector2(0,0)
	detail.position=Vector2(80,0)
	footer.window_input.connect(on_input)
	footer.focus_exited.connect(finish_drag)
	visibility_changed.connect(func(): footer.visible=visible)
	settings_button=Button.new()
	settings_button.text="설정"
	settings_button.visible=false
	settings_button.icon=preload("res://scripts/cozy_ui.gd").icon("settings",18)
	settings_button.position=Vector2(8,84)
	settings_button.size=Vector2(88,30)
	settings_button.add_theme_font_size_override("font_size",12)
	for color_ in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		settings_button.add_theme_color_override(color_,Color("5b4636"))
	style_header_button(settings_button,"f7c6c7","fbe0dc","f3c2be","6b4a35")
	settings_button.focus_mode=Control.FOCUS_ALL
	settings_button.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
	settings_button.pressed.connect(func(): request_header_action(false))
	header_root.add_child(settings_button)
	gift_button=preload("res://scripts/gift_button.gd").new()
	gift_button.position=Vector2(104,84)
	gift_button.size=Vector2(88,30)
	gift_button.compact=true
	gift_button.alignment=HORIZONTAL_ALIGNMENT_RIGHT
	gift_button.add_theme_font_size_override("font_size",12)
	for color_ in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		gift_button.add_theme_color_override(color_,Color("5b4636"))
	gift_button.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
	style_header_button(gift_button,"f7c6c7","fbe0dc","f3c2be","6b4a35")
	gift_button.pressed.connect(func(): request_header_action(true))
	header_root.add_child(gift_button)
	gift_window=Window.new()
	gift_window.visible=false
	gift_window.force_native=true
	gift_window.borderless=true
	gift_window.transparent=true
	gift_window.transparent_bg=true
	gift_window.always_on_top=true
	gift_window.unresizable=true
	gift_window.theme=app.skin
	gift_window.title="단짝 타자친구 · 선물"
	add_child(gift_window)
	gift_root=Node2D.new()
	gift_window.add_child(gift_root)
	gift_button.reparent(gift_root)
	gift_window.window_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			if event.button_index==MOUSE_BUTTON_LEFT: request_header_action(true)
			elif event.button_index==MOUSE_BUTTON_RIGHT: request_header_action(false))
	visibility_changed.connect(func(): gift_window.visible=visible)
	header.window_input.connect(on_header_input)
	header.focus_exited.connect(finish_drag)
	focus_exited.connect(finish_drag)
	window_input.connect(on_input)
	load_friend()
	apply_text_size()
	place()
	show()
	header.show()
	footer.show()
	gift_window.show()
	Native.apply(gift_window,false,true)
	Native.apply(footer,false,true)
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
		if settings_button.visible and Rect2(settings_button.position,settings_button.size).has_point(point):
			request_header_action(false)
			return
		if gift_button.get_parent()==header_root and Rect2(gift_button.position,gift_button.size).has_point(point):
			request_header_action(true)
			return
	on_input(event)
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
	style.set_corner_radius_all(clampi(radius,14,18) if radius>=8 else radius)
	style.border_color=Color("6b4a35")
	style.set_border_width_all(2)
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
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus",focus)
func label(pos: Vector2,dimensions: Vector2,font_size: int) -> Label:
	var value=Label.new()
	value.position=pos
	value.size=dimensions
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	value.mouse_filter=Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_size_override("font_size",font_size)
	value.add_theme_color_override("font_color",Color("5b4636"))
	value.add_theme_color_override("font_outline_color",Color("fff7ec"))
	value.add_theme_constant_override("outline_size",4)
	header_root.add_child(value)
	return value
func load_friend() -> void:
	frames=Catalog.frames(app.species)
	action_frames=[]
	action_time=0
	action_cooldown=0
	sprite.modulate.a=1
	action_sprite.hide()
	images.clear()
	for frame in frames: images.append(frame.get_image())
	combo_fx.set_silhouette(images)
	base_input_points.clear()
	if frames.size()!=3:
		push_error("타자친구 이미지 3장이 필요합니다")
		return
	combo_fx.reset(app.report.tier)
	pet_root.position=Vector2.ZERO
	pet_root.scale=Vector2.ONE
	index=0
	age=1
	pending=false
	sprite.texture=frames[0]
	sprite.scale=Vector2.ONE*(200.0/frames[0].get_width())
	pin.position=sprite.position+Catalog.PINS[app.species]*200
	sprite.material.set_shader_parameter("eye_centers",Catalog.EYES[app.species])
	expression=Vector2.ZERO
	sprite.material.set_shader_parameter("eye_expression",expression)
	apply_cosmetics()
	update_input_region()
func apply_cosmetics() -> void:
	sprite.material.set_shader_parameter("balance",Catalog.TONES[app.species])
	action_sprite.material.set_shader_parameter("balance",Catalog.TONES[app.species])
	pin.kind=app.collection.selected(app.species,"pin")
	pin.position=sprite.position+Catalog.accessory_anchor(app.species,pin.kind)*200
	sprite.material.set_shader_parameter("shift",app.collection.TINTS.get(app.collection.selected(app.species,"skin"),Vector3.ZERO))
	action_sprite.material.set_shader_parameter("shift",app.collection.TINTS.get(app.collection.selected(app.species,"skin"),Vector3.ZERO))
	update_input_region()
func place() -> void:
	var zoom_=app.scale_factor if app.scale_factor>0 else [.85,1.0,1.2][app.zoom]
	root.scale=Vector2.ONE*zoom_
	root.position=Vector2((WIDGET_WIDTH-220)/2,animal_root_y())*zoom_
	header_root.scale=Vector2.ONE*maxf(1.0,zoom_)
	size=Vector2i(Vector2(WIDGET_WIDTH,232+animal_root_y())*zoom_)
	var footprint=footprint_for(zoom_)
	var saved_bounds=Rect2i(app.saved_position,footprint) if app.custom_position else Rect2i()
	screen_rect=screen_for_bounds(saved_bounds,usable_screens(),DisplayServer.get_primary_screen())
	anchor_position=screen_rect.position+Vector2i(12,12)
	if app.corner in [1,3]: anchor_position.x=screen_rect.end.x-footprint.x-12
	if app.corner in [2,3]: anchor_position.y=screen_rect.end.y-footprint.y-12
	if app.custom_position: anchor_position=app.saved_position
	anchor_position=anchor_position.clamp(screen_rect.position,(screen_rect.end-footprint).max(screen_rect.position))
	header.size=Vector2i(Vector2(header_width(),74)*header_root.scale)
	gift_root.scale=header_root.scale
	gift_window.size=Vector2i(Vector2(40,38)*header_root.scale)
	footer_root.scale=header_root.scale
	footer.size=Vector2i(Vector2(header_width(),footer_height())*footer_root.scale)
	footer_panel.size=Vector2(header_width(),footer_height())
	header.mouse_passthrough_polygon=PackedVector2Array()
	sync_positions()
	update_input_region()
func sync_positions() -> void:
	position=anchor_position+Vector2i((footprint_for(root.scale.x).x-size.x)/2,roundi(72*header_root.scale.y))
	var width=footprint_for(root.scale.x).x
	header.position=anchor_position+Vector2i((width-header.size.x)/2,0)
	footer.position=Vector2i(header.position.x,position.y+size.y-roundi(16*root.scale.y))
	align_footer()
func update_input_region() -> void:
	if frames.is_empty(): return
	# A silhouette region also clips native drawing. Animated fur, pins and FX
	# need the complete padded canvas; transparent pixels remain transparent.
	mouse_passthrough_polygon=PackedVector2Array()
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
		var pointer=DisplayServer.mouse_get_position()
		screen_rect=screen_for_point(pointer,usable_screens(),DisplayServer.get_primary_screen())
		anchor_position=(pointer-grab_offset).clamp(screen_rect.position,(screen_rect.end-footprint).max(screen_rect.position))
		sync_positions()
	body_offset=Vector2.ZERO
	expression=Vector2.ZERO
	sprite.material.set_shader_parameter("body_motion",Vector2.ZERO)
	sprite.material.set_shader_parameter("eye_expression",Vector2.ZERO)
	var accessory_anchor=Catalog.accessory_anchor(app.species,pin.kind)
	pin.position=sprite.position+accessory_anchor*200+body_offset*(1-smoothstep(.56,.73,accessory_anchor.y))
	status.position.y=4
	status.add_theme_font_size_override("font_size",maxi(12,roundi(12*app.text_scale)))
	combo_number.advance(delta,app.report.combo,0,app.bridge.key_delta>0 and count>0,app.text_scale,app.combo_effects and not app.paused)
	combo_bar.value=app.report.remaining
	combo_bar.tooltip_text="%.1f초 남음 · 키를 누르면 5초로 충전"%(app.report.remaining*5)
	combo_fx.eye_centers=Catalog.EYES[app.species]
	combo_fx.advance(delta,app.report.tier,app.bridge.key_delta>0 and count>0,COMBO_REACTIONS and app.combo_effects and not app.paused and app.bridge.connected)
	combo_bar.advance_shimmer(delta,app.report.tier,combo_fx.activity)
	combo_fx.origin=Vector2(110,maxf(HEAD_TOP_PX*200/1024+22,Catalog.HATS[app.species].y*200+20))
	var t=1-combo_fx.hop_remaining/.4
	var lift=10*sin(t*PI) if combo_fx.hop_remaining>0 else 0.0
	var squash=.05*sin(PI*clampf(t/.25,0,1)) if combo_fx.hop_remaining>0 else 0.0
	pet_root.scale=Vector2(1+squash,1-squash)
	var pivot=Vector2(110,190)
	pet_root.position=pivot-pivot*pet_root.scale+Vector2(0,-lift-combo_fx.bob)
	combo_fx.face_transform=pet_root.transform
	age+=delta
	if count>0: pending=true
	var cycle=TYPING_CYCLE
	if pending and age>=cycle:
		pending=false
		age=0
		side=1-side
	index=(side+1) if age<cycle*.75 else 0
	if frames.size()==3 and sprite.texture!=frames[index]: sprite.texture=frames[index]
	advance_action(delta,0,false)
	for i in range(8): levels[i]=maxf(0,levels[i]-delta/.32)
	for i in range(mini(app.bridge.key_delta if count>0 else 0,8)):
		light_index=(light_index+1)%8
		levels[light_index]=1
	for i in range(8):
		var fill=Color("fff7ec").lerp((Color("f7c6c7") if app.collection.light_style.is_empty() else app.collection.light_color()),levels[i])
		light_nodes[i].position.y=201+2*levels[i]
		lights[i].shadow_offset=Vector2(0,2*(1-levels[i]))
		if lights[i].bg_color!=fill: lights[i].bg_color=fill
		light_nodes[i].visible=app.show_lights
		var border=Color("6b4a35").lerp(Color("6b4a35"),levels[i])
		if lights[i].border_color!=border: lights[i].border_color=border
	text_refresh_time+=delta
	if text_refresh_time>=.1:
		text_refresh_time=0.0
		refresh_text()
	light_tray.visible=app.show_lights
	monitor_time+=delta
	if monitor_time>1:
		monitor_time=0
		if not moving:
			var bounds=Rect2i(anchor_position,footprint_for(root.scale.x)) if app.custom_position else Rect2i()
			if screen_rect!=screen_for_bounds(bounds,usable_screens(),DisplayServer.get_primary_screen()): place()
func refresh_text() -> void:
	var apm_text="APM —"
	if app.bridge.connected and not app.paused:
		apm_text="APM %d"%app.activity.apm
	apm_label.text=apm_text
	status.text="COMBO %d"%app.report.combo
	status.tooltip_text="최근 60초 키 입력 수 · 5초 동안 타자가 없으면 초기화"
	detail.text="활동 "+app.activity.time_text()
	if app.paused: detail.text="잠시 쉬는 중 · "+app.activity.time_text()
	elif not app.bridge.connected: detail.text="입력 연결 확인 · 설정에서 다시 시작"
	if app.save_error: detail.text="저장 실패 · 폴더 권한을 확인해주세요"
	var gift=app.collection.summary()
	settings_button.text="설정"
	settings_button.visible=false
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
	gift_button.text=""
	gift_button.modulate=Color.WHITE
	gift_button.effects=app.gift_effects
	gift_button.tooltip_text=gift
	detail.tooltip_text=detail.text
	if gift_button.delivered: gift_button.tooltip_text="받을 수 있는 선물 %d개 · 눌러서 확인"%gift_count
	settings_button.tooltip_text="우클릭으로 설정 열기"
	align_footer()
func apply_text_size() -> void:
	status.add_theme_font_size_override("font_size",maxi(12,roundi(18*app.text_scale)))
	detail.add_theme_font_size_override("font_size",maxi(12,maxi(12,roundi(12*app.text_scale))))
	settings_button.add_theme_font_size_override("font_size",maxi(12,roundi(12*app.text_scale)))
	gift_button.add_theme_font_size_override("font_size",maxi(12,roundi(12*app.text_scale)))
	combo_fx.text_scale=app.text_scale
	gift_button.text_scale=app.text_scale
	var width=header_width()
	header_panel.size=Vector2(width,74)
	header_rule.size.x=width-24
	combo_bar.size.x=width-60
	combo_number.size.x=width-12
	var column=(width-24)/2
	status.size.x=width-12
	apm_label.add_theme_font_size_override("font_size",maxi(12,roundi(12*app.text_scale)))
	var row_height=footer_row_height()
	apm_label.size=Vector2(width,row_height)
	detail.position=Vector2(0,row_height)
	detail.size=Vector2(width,row_height)
	settings_button.size=Vector2(column,30)
	gift_button.position=Vector2(2,4)
	gift_button.size=Vector2(36,30)
	if visible: place()

func animal_root_y() -> float:
	return HEAD_GAP-HEAD_TOP_PX*200.0/1024.0
func footprint_for(zoom_: float) -> Vector2i:
	return Vector2i(ceil(maxf(WIDGET_WIDTH*zoom_,header_width()*maxf(1,zoom_))),ceil((216+animal_root_y())*zoom_+(72+footer_height())*maxf(1,zoom_)))
func resize_pivot_offset(zoom_: float) -> Vector2:
	var bounds=Vector2(footprint_for(zoom_))
	return Vector2(bounds.x/2,bounds.y)


func advance_action(_delta: float,_tier: int,_pressed: bool) -> void:
	action_time=0
	action_sprite.hide()
	sprite.modulate.a=1
	pin.modulate.a=1

func align_footer() -> void:
	if not is_instance_valid(gift_window): return
	var text_width=84.0
	for text_label in [apm_label,detail]:
		text_width=maxf(text_width,text_label.get_theme_font("font").get_string_size(text_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_label.get_theme_font_size("font_size")).x+8)
	text_width=minf(text_width,header_width()-48)
	var start=(header_width()-(36+8+text_width))/2
	var row_height=footer_row_height()
	apm_label.position=Vector2(start+44,0)
	detail.position=Vector2(start+44,row_height)
	apm_label.size=Vector2(text_width,row_height)
	detail.size=Vector2(text_width,row_height)
	gift_window.position=footer.position+Vector2i(roundi((start-2)*footer_root.scale.x),roundi((footer_height()-38)*.5*footer_root.scale.y))
