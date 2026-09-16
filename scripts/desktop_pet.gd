extends Window

signal returned
signal companion_selected(species: int)
signal activity_requested(id: int)
signal dropped_on_desktop(point: Vector2)
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const View=preload("res://scripts/desktop_pet_view.gd")
const Catalog=preload("res://scripts/animal_catalog.gd")
const Food=preload("res://scripts/food_catalog.gd")
const Profiles=preload("res://scripts/companion_profiles.gd")
const Outline=preload("res://scripts/animation_outline.gd")
var species=0
var state
var motion=Motion.new()
var view
var ball_window: Window
var ball_view
var menu
var press_screen=Vector2.ZERO
var press_feet=Vector2.ZERO
var dragging=false
var monitor_timer=0.0
var mask_key=""
var masks: Dictionary={}
var decorating=false
var feeding=false
var ball_dragging=false
var ball_grab_offset=Vector2.ZERO
var ball_samples: Array=[]
var hint="클릭: 쓰다듬기 · 드래그: 이동"

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
	gui_embed_subwindows=false
	size=Vector2i(204,190)
	name="DesktopPet"

func _ready() -> void:
	title=Catalog.NAMES[species]+" · 바탕화면 친구"
	motion.species=species
	motion.growth_scale=state.growth_scale(species) if state else 1.0
	motion.growth_stage=state.growth_stage(species) if state else 2
	var screen=desktop_bounds()
	motion.configure(screen,screen.position+Vector2(screen.size.x*.5,screen.size.y*.78))
	view=View.new()
	view.motion=motion
	add_child(view)
	ball_window=Window.new()
	ball_window.visible=false
	ball_window.force_native=true
	ball_window.borderless=true
	ball_window.transparent=true
	ball_window.transparent_bg=true
	ball_window.always_on_top=true
	ball_window.unfocusable=true
	ball_window.unresizable=true
	ball_window.mouse_passthrough=false
	ball_window.size=Vector2i(32,32)
	ball_window.title="바탕화면 친구 · 공"
	add_child(ball_window)
	ball_window.window_input.connect(handle_ball_input)
	ball_view=View.new()
	ball_view.ball_only=true
	ball_window.add_child(ball_view)
	menu=preload("res://scripts/friend_menu.gd").new()
	menu.force_native=true
	menu.add_item("쓰다듬기",0)
	menu.add_item("공 꺼내기 · 잡아서 던지기",1)
	menu.add_check_item("여기서 쉬기",2)
	menu.add_item("간식 찾기",4)
	menu.add_check_item("꾸미기 모드",5)
	menu.add_item("소품 색상 바꾸기",6)
	menu.add_item("소품 모두 보이기 / 숨기기",7)
	menu.add_item("소품 위치 정리",8)
	menu.add_item("발견한 취향",9)
	menu.add_item("성격 행동 · "+motion.Personality.TYPES[species]+" · "+motion.Personality.NAMES[species],16)
	menu.add_item("사용법",10)
	menu.add_item("친밀도와 선물",14)
	menu.add_item("전용 소품 안내",19)
	menu.add_item("킁킁 · 폴짝 놀이",22)
	menu.add_item(Profiles.TOYS[species]+"에서 놀기",20)
	menu.add_item(Profiles.COMFORTS[species]+"에서 쉬기",21)
	menu.add_item("성장 기록 · 새끼 → 중간 → 성체",18)
	menu.add_item(Profiles.BEDS[species]+"에서 쉬기",11)
	menu.add_item(Profiles.RETREATS[species]+"로 가기",12)
	menu.add_item("잠자리에서 토닥여주기",13)
	var foods=PopupMenu.new()
	foods.name="Foods"
	foods.force_native=true
	for s in range(8):
		var group=PopupMenu.new()
		group.name="Species%d"%s
		group.force_native=true
		for p in range(4):
			var id=s*4+p
			group.add_item(Food.title(id)+( " ★" if id==Profiles.FAVORITE_FOOD[species] and state.favorite_foods.get(str(species),false) else ""),100+id)
		group.id_pressed.connect(func(id): activity_requested.emit(id))
		foods.add_child(group)
		foods.add_submenu_item(Catalog.NAMES[s],group.name)
	menu.add_child(foods)
	menu.add_submenu_item("식당 음식 차려주기","Foods",15)
	var friends=PopupMenu.new()
	friends.name="Friends"
	friends.force_native=true
	for i in range(Catalog.NAMES.size()):
		friends.add_radio_check_item(Catalog.NAMES[i],i)
		friends.set_item_checked(i,i==species)
	friends.id_pressed.connect(func(id): companion_selected.emit(id))
	menu.add_child(friends)
	menu.add_submenu_item("친구 바꾸기","Friends",17)
	menu.add_separator()
	menu.add_item("종료",3)
	menu.id_pressed.connect(menu_action)
	menu.popup_hide.connect(func(): motion.held=false)
	add_child(menu)
	refresh_unlock_menu()
	motion.bonded.connect(func():
		if state: state.reward_activity(species,"pet"))
	motion.activity_bonded.connect(func(action):
		if state: state.reward_activity(species,action))
	window_input.connect(handle_input)
	close_requested.connect(close_companion)
	_process(0)
	show()

func desktop_bounds() -> Rect2:
	if DisplayServer.get_name()=="headless": return Rect2(0,0,1280,720)
	var screen=DisplayServer.get_screen_from_rect(Rect2i(position,size)) if visible else DisplayServer.SCREEN_OF_MAIN_WINDOW
	return Rect2(DisplayServer.screen_get_usable_rect(screen))

func handle_input(event: InputEvent) -> void:
	if feeding: return
	if motion.phase=="prop_use" and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and view.accepts_prop_grab(event.position):
			motion.begin_prop_drag(Vector2(position)+event.position)
			return
		elif not event.pressed and motion.prop_dragging:
			motion.release_prop_drag()
			return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
			open_menu()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				begin_pointer(Vector2(DisplayServer.mouse_get_position()))
			else: release_pointer()
	# Queued local mouse events describe the OLD native window position.
	# Only the per-frame desktop cursor sample is allowed to move this window.

func begin_pointer(screen_point: Vector2) -> void:
	motion.cancel_play()
	motion.held=true
	dragging=false
	press_screen=screen_point
	press_feet=motion.feet

func move_pointer(screen_point: Vector2) -> void:
	var displacement=screen_point-press_screen
	if displacement.length()>6 and not dragging:
		dragging=true
		motion.carried=true
		motion.carry_elapsed=0
	if dragging:
		# Allow a dragged pet to move to another monitor, then keep it visible there.
		if DisplayServer.get_name()!="headless":
			var screen=DisplayServer.get_screen_from_rect(Rect2i(Vector2i(screen_point),Vector2i.ONE))
			if screen>=0:
				var rect=Rect2(DisplayServer.screen_get_usable_rect(screen))
				motion.bounds=Rect2(rect.position+Vector2(102,160),(rect.size-Vector2(204,190)).max(Vector2.ONE))
		motion.feet=(press_feet+displacement).clamp(motion.bounds.position,motion.bounds.end)
		motion.target=motion.feet

func sync_position() -> void:
	var next_position=Vector2i(motion.feet-View.FEET)
	if position!=next_position: position=next_position

func release_pointer() -> void:
	if not motion.held or menu.visible: return
	motion.held=false
	if not dragging: motion.pet()
	else:
		motion.carried=false
		motion.landing_left=.24
		motion.rest_left=4
		dropped_on_desktop.emit(motion.feet)
	dragging=false

func open_menu() -> void:
	refresh_unlock_menu()
	motion.cancel_play()
	motion.held=true
	dragging=false
	menu.set_item_checked(menu.get_item_index(2),motion.resting)
	menu.set_item_checked(menu.get_item_index(5),decorating)
	var foods=menu.get_node("Foods")
	for s in range(8):
		var group=foods.get_node("Species%d"%s)
		for p in range(4):
			var id=s*4+p
			group.set_item_text(p,Food.title(id)+( " ★" if id==Profiles.FAVORITE_FOOD[species] and state.favorite_foods.get(str(species),false) else ""))
	menu.set_item_text(menu.get_item_index(0),"쓰다듬기 · 교감 %d"%int(state.play_affection.get(str(species),0)))
	menu.set_item_text(menu.get_item_index(18),"성장 기록 · %s · 경험치 %d"%[state.GROWTH_NAMES[state.growth_stage(species)],int(state.growth.get(str(species),0))])
	menu.position=position+Vector2i(0,32)
	menu.popup()

func menu_action(id: int) -> void:
	motion.held=false
	if not state.can_action(species,id): return
	match id:
		0: motion.pet()
		1:
			activity_requested.emit(1)
		2:
			motion.resting=not motion.resting
			motion.cancel_play()
		3: close_companion()
		_: activity_requested.emit(id)

func close_companion() -> void:
	returned.emit()
	hide()
	queue_free()

func handle_ball_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or motion.phase!="ball_ready": return
	if event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
		ball_dragging=false
		motion.held=false
		motion.cancel_play()
	elif event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		ball_dragging=true
		motion.held=true
		ball_grab_offset=motion.ball_position-Vector2(DisplayServer.mouse_get_position())
		ball_samples=[{"point":motion.ball_position,"time":Time.get_ticks_msec()/1000.0}]

func update_ball_drag() -> void:
	var point=Vector2(DisplayServer.mouse_get_position())+ball_grab_offset
	var now=Time.get_ticks_msec()/1000.0
	motion.ball_position=point.clamp(motion.bounds.position,motion.bounds.end)
	ball_samples.append({"point":motion.ball_position,"time":now})
	while ball_samples.size()>2 and now-ball_samples[0].time>.12:
		ball_samples.pop_front()
	if not (DisplayServer.mouse_get_button_state() & MOUSE_BUTTON_MASK_LEFT):
		var first: Dictionary=ball_samples[0]
		var velocity=(motion.ball_position-first.point)/maxf(.016,now-first.time)
		ball_dragging=false
		motion.release_ball(motion.ball_position,velocity)
		ball_samples.clear()

func refresh_unlock_menu() -> void:
	if menu==null: return
	for id in [1,4,5,6,7,8,11,12,13,15]:
		var index=menu.get_item_index(id)
		if index>=0:
			menu.set_item_disabled(index,not state.can_action(species,id))
	menu.set_item_text(menu.get_item_index(14),state.next_gift(species))

func _process(delta: float) -> void:
	if view==null: return
	if motion.prop_dragging and DisplayServer.get_name()!="headless":
		if DisplayServer.mouse_get_button_state() & MOUSE_BUTTON_MASK_LEFT:
			motion.drag_prop(Vector2(DisplayServer.mouse_get_position()))
		else: motion.release_prop_drag()
	if ball_dragging:
		if not motion.ball_visible:
			ball_dragging=false
			motion.held=false
		else:
			update_ball_drag()
	# NO_FOCUS preserves the user's typing focus; poll only while dragging so a
	# release outside the shaped window cannot leave the pet stuck to the cursor.
	if motion.held and not ball_dragging and not feeding and not menu.visible and DisplayServer.get_name()!="headless":
		if DisplayServer.mouse_get_button_state() & MOUSE_BUTTON_MASK_LEFT:
			move_pointer(Vector2(DisplayServer.mouse_get_position()))
		else: release_pointer()
	monitor_timer+=delta
	if monitor_timer>=2 and not motion.held:
		monitor_timer=0
		var screen=desktop_bounds()
		var new_bounds=Rect2(screen.position+Vector2(102,160),(screen.size-Vector2(204,190)).max(Vector2.ONE))
		if new_bounds!=motion.bounds:
			motion.bounds=new_bounds
			motion.move_to(motion.feet)
	motion.advance(delta)
	view.refresh()
	Outline.fit(view.sprite,View.FEET,Vector2(size))
	sync_position()
	update_mouse_region()
	if motion.ball_visible:
		ball_window.position=Vector2i(motion.ball_position-Vector2(16,16+motion.ball_height))
		ball_window.mouse_passthrough=motion.phase!="ball_ready"
		if not ball_window.visible: ball_window.show()
		ball_view.queue_redraw()
	elif ball_window.visible: ball_window.hide()

func update_mouse_region() -> void:
	# Never change the Win32 drawing region during animation. SetWindowRgn
	# invalidates the moving OpenGL surface and can expose a white erase frame.
	# Keep alpha rendering intact and independently decide whether to accept input.
	if DisplayServer.get_name()=="headless": return
	var accept_input=motion.held or motion.prop_dragging or dragging or menu.visible
	if not accept_input:
		var cursor=Vector2(DisplayServer.mouse_get_position())-Vector2(position)
		var points=Outline.blended_points(view.sprite)
		if points.size()>=3:
			accept_input=Geometry2D.is_point_in_polygon(cursor,Geometry2D.convex_hull(points))
	var pass_through=not accept_input
	if mouse_passthrough!=pass_through: mouse_passthrough=pass_through
