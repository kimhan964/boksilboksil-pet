extends Node

const Pet=preload("res://scripts/desktop_pet.gd")
const Prop=preload("res://scripts/desktop_prop.gd")
const State=preload("res://scripts/pet_state.gd")
const Profiles=preload("res://scripts/companion_profiles.gd")
const Food=preload("res://scripts/food_catalog.gd")
const HeldFood=preload("res://scripts/held_food.gd")
const Catalog=preload("res://scripts/animal_catalog.gd")
const CommerceAccess=preload("res://scripts/commerce_access.gd")
var commerce_access
var world_started=false
var held_food
var held_food_id=-1
const FAVORITES=["cushion","water","basket","plant","cushion","plant","cushion","lamp","shelter","basket","bowl","plant","shelter","cushion","cushion","water"]
var state=State.new()
var pet
var props: Dictionary={}
var hunt: Array=[]
var hidden_snack=0
var hunt_resolved=false
var hunt_previous_resting=false
var decorating=false
var expanded_props=false
var focus_prop=""
var preferred_rest=""
var preferred_toy=""
var info: AcceptDialog
var app_theme: Theme
var gift_notice: Window
var falling_gifts: Dictionary={}
var pending_gift_visits: Array[String]=[]
var layers_dirty=true

func request_layer_order() -> void:
	layers_dirty=true

func objects_are_dragging() -> bool:
	if is_instance_valid(held_food): return true
	for prop in props.values()+hunt:
		if is_instance_valid(prop) and prop.dragging: return true
	return false

func restore_layer_order() -> void:
	if not layers_dirty or not is_instance_valid(pet) or not pet.visible: return
	# Defer native style changes until dragging ends; they can erase the
	# transparent OpenGL surface while Windows is moving it.
	if pet.motion.held or pet.motion.prop_dragging or pet.dragging or objects_are_dragging(): return
	if pet.menu.visible or (is_instance_valid(info) and info.visible): return
	if DisplayServer.get_name()=="headless": return
	layers_dirty=false
	# Reapply the borderless style: unlike the TOPMOST-only setter, this also
	# restores native visibility with SW_SHOWNOACTIVATE after the style update.
	# Order from back to front: props (unchanged), animal, ball, held food, notice.
	for window in [pet,pet.ball_window,held_food,gift_notice]:
		if is_instance_valid(window) and window.visible:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true,window.get_window_id())

func _ready() -> void:
	if OS.get_cmdline_user_args().has("--check-package"):
		add_child(load("res://tools/check_package.gd").new())
		return
	# Load the raw packaged PNG so the window icon also works without editor imports.
	if DisplayServer.get_name()!="headless":
		var icon=Image.new()
		if icon.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/icon/pet-icon.png"))==OK: DisplayServer.set_icon(icon)
	Engine.max_fps=60
	get_tree().auto_accept_quit=false
	get_window().transparent_bg=true
	# Godot cannot hide its primary window; keep this transparent host passive.
	get_window().mouse_passthrough=true
	get_window().unfocusable=true
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Malgun Gothic","sans-serif"])
	app_theme=Theme.new()
	app_theme.default_font=font
	app_theme.default_font_size=16
	state.load_game()
	if state.test_unlocks(): state.hidden.clear()
	if bool(ProjectSettings.get_setting("commerce/enabled",false)):
		commerce_access=CommerceAccess.new()
		add_child(commerce_access)
		commerce_access.allowed_changed.connect(_commerce_changed)
		commerce_access.begin()
		return
	_start_world()

func _start_world() -> void:
	if world_started: return
	world_started=true
	state.affection_changed.connect(on_affection_changed)
	state.food_unlocked.connect(func(species,foods):
		if is_instance_valid(pet) and species==state.selected:
			pet.motion.say("새 먹이 %d종!"%foods.size()))
	state.growth_changed.connect(on_growth_changed)
	build_props()
	choose_friend(state.selected)
	var timer=Timer.new()
	timer.wait_time=3
	timer.autostart=true
	timer.timeout.connect(refresh_destinations)
	add_child(timer)

func _commerce_changed(ids: PackedStringArray) -> void:
	if ids.is_empty():
		cancel_feeding()
		cancel_hunt()
		if is_instance_valid(pet):
			pet.hide()
			pet.queue_free()
		for prop in props.values(): prop.hide()
		return
	if not commerce_access.permits(state.selected): state.selected=Catalog.IDS.find(ids[0])
	if not world_started: _start_world()
	elif not is_instance_valid(pet) or pet.is_queued_for_deletion() or not commerce_access.permits(pet.species): choose_friend(state.selected)
	if is_instance_valid(pet) and not pet.is_queued_for_deletion():
		pet.set_available_species(ids)

func usable_screen() -> Rect2i:
	return DisplayServer.screen_get_usable_rect(DisplayServer.SCREEN_PRIMARY)

func default_prop_position(index: int) -> Vector2i:
	var rect=usable_screen()
	if index==6: return rect.position+Vector2i(int(rect.size.x*.75)-56,int(rect.size.y*.62)-48)
	if index==7: return rect.position+Vector2i(int(rect.size.x*.43)-56,int(rect.size.y*.72)-48)
	return rect.position+Vector2i(int(rect.size.x*(.11+.13*index))-56,int(rect.size.y*.84)-48)

func build_props() -> void:
	for i in range(State.PROPS.size()):
		var id=State.PROPS[i]
		var prop=Prop.new()
		prop.prop_id=id
		prop.kind=id
		prop.start_visible=false
		prop.species=state.selected
		prop.palette=state.palette
		prop.position=default_prop_position(i)
		if state.layout.has(id):
			var saved=state.layout[id]
			var point=Vector2i(int(saved[0]),int(saved[1]))
			var found=false
			for monitor in range(DisplayServer.get_screen_count()):
				if DisplayServer.screen_get_usable_rect(monitor).encloses(Rect2i(point,prop.size)): found=true
			if found: prop.position=point
		prop.moved.connect(persist_layout)
		prop.layer_changed.connect(request_layer_order)
		prop.moved.connect(func(): state.reward_activity(state.selected,"decorate"))
		prop.recolored.connect(func(): activity(6))
		if id=="bowl": prop.food_picked.connect(pick_up_food)
		if id in ["plant","lamp"]: prop.activated.connect(use_species_prop)
		if id=="acorn": prop.activated.connect(use_common_toy)
		if id in ["cushion","shelter","water","basket"]: prop.activated.connect(use_desktop_prop)
		add_child(prop)
		props[id]=prop

func choose_friend(species: int) -> void:
	if species<0 or species>=Catalog.IDS.size(): return
	if commerce_access!=null and not commerce_access.permits(species):
		commerce_access.show_account("선물받은 동물만 선택할 수 있어요.")
		return
	clear_falling_gifts()
	if is_instance_valid(gift_notice):
		gift_notice.hide()
		gift_notice.queue_free()
	if decorating:
		decorating=false
		for prop in props.values():
			prop.editing=false
			prop.refresh()
	cancel_feeding()
	cancel_hunt()
	var first=not is_instance_valid(pet)
	if not first: persist_layout()
	var previous_position=Vector2.INF
	if is_instance_valid(pet):
		previous_position=pet.motion.feet
		pet.hide()
		pet.queue_free()
	state.selected=species
	pet=Pet.new()
	pet.species=species
	pet.state=state
	if commerce_access!=null:
		pet.commerce_mode=true
		pet.available_species=commerce_access.allowed.duplicate()
	pet.theme=app_theme
	pet.decorating=decorating
	pet.returned.connect(shutdown)
	pet.companion_selected.connect(func(id): choose_friend.call_deferred(id))
	pet.activity_requested.connect(activity)
	pet.dropped_on_desktop.connect(on_pet_dropped)
	add_child(pet)
	pet.visibility_changed.connect(request_layer_order)
	request_layer_order()
	if commerce_access!=null:
		pet.menu.add_item("계정·이용권 확인",900)
	pet.menu.about_to_popup.connect(cancel_hunt)
	pet.motion.visited.connect(on_visit)
	pet.motion.activity_finished.connect(on_activity_finished)
	pet.motion.favorite_place=FAVORITES[species]
	if previous_position.is_finite(): pet.motion.move_to(previous_position)
	apply_personal_space(first)
	apply_growth()
	set_food(int(state.meals.get(str(species),Catalog.DEFAULT_MEALS[species])),false)
	apply_unlocks()
	refresh_destinations()
	state.save_game()
	pet.motion.react("greet",2.2 if pet.motion.affection>=18 else 1.6)
	pet.motion.speak()
	if not state.guide_seen: show_first_guide.call_deferred()

func show_first_guide() -> void:
	if not is_instance_valid(pet): return
	show_info("처음 만난 우리 친구","1. 동물을 짧게 클릭해서 쓰다듬어 주세요.\n2. 꾹 잡아 끌면 편한 자리로 옮길 수 있어요.\n3. 우클릭 메뉴에서 현재 목표와 다음 해금을 확인하세요.\n\n첫 목표: 쓰다듬기 3번 → 음식 그릇 선물!\n같은 행동의 교감 보상은 8초 간격이에요.\n음식을 집어 동물의 입 근처에 놓으면 먹여줄 수 있어요.\n\n교감 10: 마우스 따라오기 / 18: 소품에 부비기\n가이드는 우클릭 → 기록에서 다시 볼 수 있어요.")
	info.confirmed.connect(func(): state.guide_seen=true; state.save_game())

func apply_personal_space(first: bool) -> void:
	for id in ["bowl","water","plant","lamp"]:
		props[id].species=state.selected
		props[id].refresh()
	var places=state.personal_layout.get(str(state.selected),{})
	for id in ["cushion","shelter"]:
		var prop=props[id]
		prop.species=state.selected
		prop.title=(Profiles.BEDS[state.selected] if id=="cushion" else Profiles.RETREATS[state.selected])+" · 바탕화면 친구"
		prop.resize_for_friend()
		if not first: prop.position=default_prop_position(State.PROPS.find(id))
		if places.has(id):
			var value=places[id]
			var point=Vector2i(int(value[0]),int(value[1]))
			for monitor in range(DisplayServer.get_screen_count()):
				if DisplayServer.screen_get_usable_rect(monitor).encloses(Rect2i(point,prop.size)):
					prop.position=point
					break
		prop.refresh()

func set_food(id: int, serve: bool=true) -> void:
	if serve and not state.unlocked(state.selected,"bowl"): return
	if serve and not state.food_available(state.selected,id): return
	if not serve and not state.food_available(state.selected,id): id=Catalog.DEFAULT_MEALS[state.selected]
	cancel_feeding()
	id=clampi(id,0,31)
	state.meals[str(state.selected)]=id
	pet.motion.food_id=id
	pet.motion.favorite_food=id==Profiles.FAVORITE_FOOD[state.selected]
	props.bowl.food_texture=Food.icon_for(state.selected,id)
	props.bowl.title=Food.title_for(state.selected,id)+" · 바탕화면 친구"
	props.bowl.refresh()
	if serve:
		if decorating: activity(5)
		ensure_prop_nearby("bowl")
		pet.motion.cancel_play()
		pet.motion.rest_left=12
	state.save_game()
	refresh_destinations()

func ensure_prop_nearby(id: String) -> void:
	if not state.unlocked(state.selected,id): return
	if falling_gifts.has(id): finish_unlock_fall(id,false)
	var prop=props[id]
	state.hidden.erase(id)
	focus_prop=id
	apply_prop_visibility()
	var point=prop.feet_point()
	if not pet.motion.bounds.has_point(point):
		point=(pet.motion.feet+Vector2(120,20)).clamp(pet.motion.bounds.position,pet.motion.bounds.end)
		prop.position=Vector2i(point-prop.anchor_offset())
	persist_layout()

func use_desktop_prop(id: String) -> void:
	if not is_instance_valid(pet) or not state.unlocked(state.selected,id): return
	if id not in ["cushion","shelter","water","basket"]: return
	cancel_hunt()
	cancel_feeding()
	if decorating: return
	ensure_prop_nearby(id)
	props[id].confirm_drop()
	var point=props[id].dining_point(pet.motion.bounds) if id=="water" else props[id].feet_point()
	pet.motion.visit(point,{"cushion":"doze","shelter":"relax","water":"drink","basket":"askplay"}[id],id,true)
	pet.motion.stay_after_visit=id=="cushion"

func on_activity_finished(id: String) -> void:
	if id=="basket" and pet.motion.visit_action=="askplay": pet.motion.prepare_ball()
	if id in ["bowl","water"]: state.reward_activity(pet.species,id)
	if id in ["meal","bowl","snack","hand_feed"] and pet.motion.favorite_food:
		pet.motion.joy_left=1.8
		if not state.favorite_foods.get(str(pet.species),false):
			state.favorite_foods[str(pet.species)]=true
			state.add_affection(pet.species)
	if id in ["meal","bowl","snack","hand_feed"]:
		pet.motion.react("yum",2.8 if pet.motion.favorite_food else 1.6)
	if id=="acorn": pet.motion.react("happy",2.4)
	if id=="snack": cancel_hunt()

func refresh_destinations() -> void:
	if not is_instance_valid(pet): return
	pet.motion.destinations.clear()
	if decorating: return
	for id in props:
		var prop=props[id]
		if not prop.visible: continue
		if falling_gifts.has(id): continue
		var point=prop.feet_point()
		if id in ["bowl","water"]: point=prop.dining_point(pet.motion.bounds)
		if id=="acorn": point=(point+Vector2(-48,0)).clamp(pet.motion.bounds.position,pet.motion.bounds.end)
		if not pet.motion.bounds.has_point(point): continue
		var action={"cushion":"doze","bowl":Food.action(pet.motion.food_id),"water":"drink","basket":"sniff","plant":"prop_use","lamp":"prop_use","shelter":"relax","acorn":"prop_use"}[id]
		var destination={"point":point,"action":action,"id":id}
		pet.motion.destinations.append(destination)

func persist_layout() -> void:
	var places: Dictionary={}
	for id in props:
		var point: Vector2i=falling_gifts[id].target if falling_gifts.has(id) else props[id].position
		state.layout[id]=[point.x,point.y]
		if id in ["cushion","shelter"]: places[id]=[point.x,point.y]
	state.personal_layout[str(state.selected)]=places
	state.save_game()
	refresh_destinations()

func on_visit(id: String) -> void:
	if id in ["bowl","meal","snack","hand_feed","water"]:
		pet.motion.say("냠냠~" if pet.motion.phase=="eat" else "꿀꺽~")
	if id in ["plant","lamp","acorn"]: props[id].confirm_drop()
	if id=="acorn": pet.motion.react("surprised",1.1,"prop_use")
	if id in ["bowl","water"]:
		pet.motion.facing=1.0 if props[id].feet_point().x>=pet.motion.feet.x else -1.0
	if id==FAVORITES[pet.species] and not state.discoveries.has(str(pet.species)):
		state.discoveries[str(pet.species)]=id
		state.save_game()

func activity(id: int) -> void:
	if id==900 and commerce_access!=null:
		commerce_access.show_account("연결한 계정의 동물 이용권을 확인할 수 있어요.")
		return
	if commerce_access!=null and not commerce_access.permits(state.selected): return
	if not state.can_action(state.selected,id): return
	cancel_feeding()
	if id>=100 and id<132:
		set_food(id-100)
		return
	if id>=400 and id<404:
		cancel_hunt()
		if decorating: activity(5)
		pet.motion.cancel_play()
		pet.motion.react(["surprised","happy","angry","sleepy"][id-400],2.5)
		return
	match id:
		31:
			expanded_props=not expanded_props
			apply_prop_visibility()
			refresh_destinations()
		25: show_first_guide()
		26: show_info("함께할 목표",state.goal_text(state.selected)+"\n\n"+state.progress_text(state.selected))
		23,24:
			cancel_hunt()
			if decorating: activity(5)
			if not pet.motion.start_social("follow" if id==23 else "rub",true):
				show_info("부빌 곳이 필요해요","해금된 소품을 하나 이상 보이게 두어 주세요.")
		1:
			cancel_hunt()
			if decorating: activity(5)
			pet.motion.prepare_ball()
		16:
			cancel_hunt()
			if decorating: activity(5)
			pet.motion.start_personality(true)
		4: start_hunt()
		5:
			cancel_hunt()
			decorating=not decorating
			pet.decorating=decorating
			pet.motion.resting=decorating
			pet.motion.cancel_play()
			for prop in props.values():
				prop.editing=decorating
				prop.refresh()
			persist_layout()
			apply_prop_visibility()
			refresh_destinations()
		6:
			state.palette=(state.palette+1)%3
			state.reward_activity(state.selected,"decorate")
			for prop in props.values():
				prop.palette=state.palette
				prop.refresh()
			state.save_game()
		7:
			var hide_all=false
			for prop in props.values():
				if prop.visible: hide_all=true
			for key in State.PROPS:
				if not state.unlocked(state.selected,key): continue
				if hide_all and key not in state.hidden: state.hidden.append(key)
				elif not hide_all: state.hidden.erase(key)
			apply_unlocks()
			state.save_game()
			refresh_destinations()
		8:
			for i in range(State.PROPS.size()): props[State.PROPS[i]].position=default_prop_position(i)
			persist_layout()
		9:
			var favorite=state.discoveries.get(str(pet.species),"")
			var description="아직 알아가는 중이에요. 어디에서 오래 머무는지 지켜보세요." if favorite.is_empty() else "%s 근처를 좋아해요."%Prop.NAMES[favorite]
			description+="\n이 친구의 버릇: "+Profiles.HABITS[pet.species]
			description+="\n성격: "+pet.motion.Personality.TYPES[pet.species]+" · "+pet.motion.Personality.NAMES[pet.species]
			description+="\n"+pet.motion.Personality.DETAILS[pet.species]
			description+="\n침대: "+Profiles.BEDS[pet.species]+"\n쉼터: "+Profiles.RETREATS[pet.species]
			description+="\n좋아하는 음식: "+(Food.title_for(pet.species,Profiles.FAVORITE_FOOD[pet.species]) if state.favorite_foods.get(str(pet.species),false) else "함께 먹으며 알아가는 중")
			show_info("우리 친구의 취향",description)
		14: show_info("친밀도와 선물",state.progress_text(state.selected))
		19: show_info("전용 소품",Profiles.TOYS[state.selected]+" · "+preload("res://scripts/prop_interactions.gd").TOY_ACTIONS[state.selected]+"\n"+Profiles.COMFORTS[state.selected]+" · "+preload("res://scripts/prop_interactions.gd").COMFORT_ACTIONS[state.selected]+"\n\n소품 클릭 또는 동물 데려다 놓기 → 전용 동작\n동작 중 왼쪽 버튼을 잡고 움직이면 함께 놀아요.\n강아지 밧줄: 오른쪽으로 당기면 버티고, 놓으면 힘을 풀어요.\n우클릭으로 중단 · 사용하지 않을 때 소품 드래그로 배치")
		20: use_species_prop("plant")
		29: use_common_toy("acorn")
		21: use_species_prop("lamp")
		22:
			cancel_hunt()
			if decorating: activity(5)
			pet.motion.start_playful(true)
		18: show_info("우리 친구의 성장 기록",state.growth_text(state.selected))
		10: show_info("바탕화면 친구 사용법","처음에는 동물만 함께해요. 쓰다듬고 놀며 선물을 받아요.\n우클릭 → 다음 선물: 친밀도와 해금 목록\n가만히 두면 스스로 산책·몸단장·기지개·낮잠을 즐겨요.\n각자의 침대와 쉼터, 음식과 물도 찾아가요.\n\n클릭: 쓰다듬기 · 누른 채 작게 좌우: 연속 쓰다듬기\n위로/멀리 드래그: 들어 올리기 · 놓기: 낙하와 해롱해롱\n연못·침대·장난감 클릭: 찾아가 사용하기\n꾸미기 → 소품 표시: 간결하게 / 모두 펼치기\n우클릭 → 식당 음식 차려주기: 음식 32종 선택\n그릇의 음식을 입으로 드래그 → 초록 테두리에서 놓기\n다른 곳에 놓거나 우클릭하면 그릇으로 돌아와요\n침대에서 쉬기 / 쉼터로 가기 / 잠자리 토닥이기\n\n꾸미기 모드: 소품 드래그로 배치, 우클릭으로 색상 변경\n다시 선택하면 꾸미기를 마칩니다.\n동물별 침대·쉼터 배치와 음식, 교감은 자동 저장됩니다.")
		11,12,13:
			if decorating: activity(5)
			var place="shelter" if id==12 else "cushion"
			ensure_prop_nearby(place)
			pet.motion.visit(props[place].feet_point(),"cuddle" if id==13 else ("doze" if id==11 else "relax"),place,true)
			pet.motion.stay_after_visit=id==11

func show_info(title_text: String, body: String) -> void:
	if is_instance_valid(info): info.queue_free()
	info=AcceptDialog.new()
	info.force_native=true
	info.theme=app_theme
	info.title=title_text
	info.dialog_text=body
	info.get_ok_button().text="알겠어요"
	info.confirmed.connect(info.queue_free)
	info.canceled.connect(info.queue_free)
	add_child(info)
	info.size=Vector2i(530,310)
	info.position=usable_screen().get_center()-info.size/2
	info.popup()

func start_hunt() -> void:
	if not state.unlocked(state.selected,"bowl"): return
	cancel_hunt()
	if decorating: activity(5)
	pet.motion.cancel_play()
	hunt_previous_resting=pet.motion.resting
	pet.motion.resting=true
	hidden_snack=randi_range(0,2)
	hunt_resolved=false
	var center=pet.motion.feet
	var spacing=minf(140,pet.motion.bounds.size.x*.5)
	var first_x=clampf(center.x-spacing,pet.motion.bounds.position.x,pet.motion.bounds.end.x-spacing*2)
	for i in range(3):
		var bowl=Prop.new()
		bowl.kind="bowl"
		bowl.prop_id="hunt%d"%i
		bowl.number=i+1
		bowl.interactive=true
		bowl.palette=state.palette
		bowl.food_texture=Food.icon_for(pet.species,pet.motion.food_id)
		var point=Vector2(first_x+i*spacing,clampf(center.y-40,pet.motion.bounds.position.y,pet.motion.bounds.end.y))
		bowl.position=Vector2i(point-Vector2(56,63))
		bowl.activated.connect(func(_id): choose_bowl(i))
		bowl.layer_changed.connect(request_layer_order)
		add_child(bowl)
		hunt.append(bowl)

func choose_bowl(index: int) -> void:
	if hunt_resolved or index>=hunt.size() or hunt[index].empty: return
	var bowl=hunt[index]
	var point=Vector2(bowl.position)+Vector2(56,63)
	if index==hidden_snack:
		hunt_resolved=true
		for item in hunt:
			item.interactive=false
			item.refresh()
		bowl.number=0
		bowl.refresh()
		pet.motion.visit(point,Food.action(pet.motion.food_id),"snack",true)
	else:
		bowl.empty=true
		bowl.refresh()
		pet.motion.visit(point,"sniff","empty")

func cancel_hunt() -> void:
	if not hunt.is_empty() and is_instance_valid(pet):
		pet.motion.resting=hunt_previous_resting
	for bowl in hunt:
		if is_instance_valid(bowl):
			bowl.hide()
			bowl.queue_free()
	hunt.clear()
	hunt_resolved=false

func shutdown() -> void:
	cancel_feeding()
	persist_layout()
	get_tree().quit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: shutdown()

func pick_up_food() -> void:
	if not state.unlocked(state.selected,"bowl"): return
	if decorating or not is_instance_valid(pet) or is_instance_valid(held_food): return
	if pet.motion.phase in ["eat","drink"]: return
	cancel_hunt()
	pet.motion.cancel_play()
	pet.feeding=true
	pet.motion.react("anticipate",1.3)
	pet.motion.ask_left=55
	pet.motion.held=true
	held_food_id=pet.motion.food_id
	props.bowl.food_lifted=true
	props.bowl.refresh()
	held_food=HeldFood.new()
	held_food.food=Food.icon_for(pet.species,held_food_id)
	held_food.position=DisplayServer.mouse_get_position()-Vector2i(40,40)
	add_child(held_food)

func food_in_reach(cursor: Vector2) -> bool:
	var height=Catalog.DISPLAY_HEIGHT*Catalog.HEIGHTS[pet.species]*pet.motion.growth_scale
	var mouth=pet.motion.feet+pet.view.mouth_offset()
	var offset=(cursor-mouth)/Vector2(maxf(32,height*.35),maxf(28,height*.30))
	return offset.length_squared()<=1

func nearby_drop_prop(point: Vector2) -> String:
	if decorating or not hunt.is_empty(): return ""
	var chosen=""
	var best=INF
	for id in props:
		var prop=props[id]
		if falling_gifts.has(id): continue
		if not prop.visible or not state.unlocked(state.selected,id): continue
		# Select the closest visible prop surface, including generous space around
		# small bowls. Large beds remain easy to target across their full artwork.
		var area=Rect2(Vector2(prop.position)+Vector2(5,8)*prop.art_scale,Vector2(102,80)*prop.art_scale)
		var distance=point.distance_to(point.clamp(area.position,area.end))
		if distance>38: continue
		var score=distance+point.distance_to(prop.feet_point())*.12
		if score<best:
			best=score
			chosen=id
	return chosen

func on_pet_dropped(point: Vector2) -> void:
	var id=nearby_drop_prop(point)
	for prop in props.values(): prop.set_drop_hover(false)
	if id.is_empty(): return
	var prop=props[id]
	prop.confirm_drop()
	request_layer_order()
	if id=="bowl" and pet.motion.satiety>=97 and Food.action(pet.motion.food_id)=="eat":
		pet.motion.react("full",2.2)
		return
	var action={"bowl":Food.action(pet.motion.food_id),"water":"drink","cushion":"doze","shelter":"pet","plant":"prop_use","lamp":"prop_use","basket":"askplay","acorn":"prop_use"}[id]
	var destination=prop.dining_point(pet.motion.bounds) if id in ["bowl","water"] else prop.feet_point()
	if id=="acorn": destination=(destination+Vector2(-48,0)).clamp(pet.motion.bounds.position,pet.motion.bounds.end)
	pet.motion.visit(destination,action,id,id not in ["bowl","water"])
	pet.motion.stay_after_visit=id=="cushion"

func _process(_delta: float) -> void:
	advance_unlock_falls(_delta)
	try_gift_visit()
	restore_layer_order()
	for id in ["plant","lamp"]:
		if not props.has(id): continue
		var active=is_instance_valid(pet) and pet.motion.phase=="prop_use" and pet.motion.visit_id==id
		if active and (not props[id].visible or decorating):
			pet.motion.cancel_play()
			active=false
		props[id].set_in_use(active)
	if props.has("acorn"):
		var playing=is_instance_valid(pet) and pet.motion.phase=="prop_use" and pet.motion.visit_id=="acorn"
		if playing and (not props.acorn.visible or decorating):
			pet.motion.cancel_play()
			playing=false
		props.acorn.set_wobbling(playing)
	var hovered=""
	if is_instance_valid(pet) and pet.dragging and pet.motion.carried:
		hovered=nearby_drop_prop(pet.motion.feet)
	for id in props: props[id].set_drop_hover(id==hovered)
	if is_instance_valid(pet): pet.motion.cursor_position=Vector2(DisplayServer.mouse_get_position())
	if not is_instance_valid(held_food): return
	if not is_instance_valid(pet):
		cancel_feeding()
		return
	var cursor=Vector2(DisplayServer.mouse_get_position())
	var ready_to_feed=food_in_reach(cursor)
	held_food.follow_cursor(cursor,ready_to_feed)
	var buttons=DisplayServer.mouse_get_button_state()
	if buttons & MOUSE_BUTTON_MASK_RIGHT:
		cancel_feeding()
	elif not (buttons & MOUSE_BUTTON_MASK_LEFT):
		var meal=held_food_id
		cancel_feeding()
		if ready_to_feed:
			if pet.motion.satiety>=97 and Food.action(meal)=="eat":
				pet.motion.react("full",2.2)
				return
			pet.motion.food_id=meal
			pet.motion.favorite_food=meal==Profiles.FAVORITE_FOOD[pet.species]
			pet.motion.visit(pet.motion.feet,Food.action(meal),"hand_feed",true)

func cancel_feeding() -> void:
	if not is_instance_valid(held_food): return
	held_food.hide()
	held_food.queue_free()
	held_food=null
	held_food_id=-1
	if props.has("bowl"):
		props.bowl.food_lifted=false
		props.bowl.refresh()
	if is_instance_valid(pet):
		pet.feeding=false
		pet.motion.held=false
		pet.motion.cancel_play()
		pet.motion.rest_left=4

func apply_unlocks() -> void:
	apply_prop_visibility()
	if is_instance_valid(pet):
		pet.refresh_unlock_menu()
		pet.motion.affection=int(state.play_affection.get(str(state.selected),0))
		pet.motion.can_ask_play=state.unlocked(state.selected,"basket")
		pet.motion.can_playful=state.unlocked(state.selected,"playful")
		pet.motion.can_personality=state.unlocked(state.selected,"personality")
		pet.motion.can_follow=state.unlocked(state.selected,"follow")
		pet.motion.can_rub=state.unlocked(state.selected,"rub")
	refresh_destinations()

func apply_prop_visibility() -> void:
	if focus_prop in ["cushion","shelter","lamp"]: preferred_rest=focus_prop
	if focus_prop in ["acorn","plant","basket"]: preferred_toy=focus_prop
	var eligible: Array=[]
	for id in props:
		if state.unlocked(state.selected,id) and id not in state.hidden: eligible.append(id)
	var selected=eligible if expanded_props or decorating else preload("res://scripts/desktop_clutter.gd").visible_ids(eligible,preferred_rest,preferred_toy)
	for id in props:
		props[id].visible=id in selected or (id in eligible and (falling_gifts.has(id) or pending_gift_visits.has(id)))

func on_affection_changed(species: int, gifts: Array) -> void:
	if species!=state.selected: return
	if is_instance_valid(pet) and not is_equal_approx(pet.motion.growth_scale,state.growth_scale(species)): apply_growth()
	for id in gifts: state.hidden.erase(id)
	if not gifts.is_empty(): state.save_game()
	apply_unlocks()
	for id in gifts:
		if props.has(id): start_unlock_fall(id)
	if not gifts.is_empty(): show_gift.call_deferred(species,gifts)

func clear_falling_gifts() -> void:
	for id in falling_gifts:
		if props.has(id):
			props[id].position=falling_gifts[id].target
			props[id].mouse_passthrough=false
	falling_gifts.clear()
	pending_gift_visits.clear()

func start_unlock_fall(id: String) -> void:
	if not props.has(id) or falling_gifts.has(id): return
	focus_prop=id
	apply_prop_visibility()
	var prop=props[id]
	var target: Vector2i=prop.position
	var screen=DisplayServer.get_screen_from_rect(Rect2i(target,prop.size))
	if screen<0: screen=DisplayServer.SCREEN_PRIMARY
	var usable=DisplayServer.screen_get_usable_rect(screen)
	var start=Vector2i(target.x,usable.position.y-prop.size.y-12)
	falling_gifts[id]={"start":start,"target":target,"time":0.0,"duration":1.25}
	prop.position=start
	prop.show()
	prop.mouse_passthrough=true
	if is_instance_valid(pet) and not pet.motion.held and pet.motion.phase=="idle":
		pet.motion.react("surprised",1.15)
	refresh_destinations()

func finish_unlock_fall(id: String,visit: bool=true) -> void:
	if not falling_gifts.has(id): return
	var target: Vector2i=falling_gifts[id].target
	falling_gifts.erase(id)
	if props.has(id):
		props[id].position=target
		props[id].mouse_passthrough=false
		props[id].confirm_drop()
	if visit and not pending_gift_visits.has(id): pending_gift_visits.append(id)
	refresh_destinations()

func advance_unlock_falls(delta: float) -> void:
	for id in falling_gifts.keys():
		if not props.has(id): continue
		var fall: Dictionary=falling_gifts[id]
		fall.time=float(fall.time)+delta
		var progress=clampf(float(fall.time)/float(fall.duration),0.0,1.0)
		var start: Vector2i=fall.start
		var target: Vector2i=fall.target
		var y: float
		if progress<.78:
			var descent=progress/.78
			y=lerpf(float(start.y),float(target.y),descent*descent)
		else:
			var bounce=(progress-.78)/.22
			y=float(target.y)-sin(bounce*PI)*20.0*(1.0-bounce)
		props[id].position=Vector2i(target.x,roundi(y))
		falling_gifts[id]=fall
		if progress>=1.0: finish_unlock_fall(id)

func try_gift_visit() -> void:
	if pending_gift_visits.is_empty() or not is_instance_valid(pet) or decorating: return
	if pet.motion.held or pet.motion.carried or pet.motion.resting or pet.motion.phase!="idle": return
	if pet.menu.visible or is_instance_valid(held_food): return
	var id: String=pending_gift_visits.pop_front()
	focus_prop=id
	apply_prop_visibility()
	if not props.has(id) or not props[id].visible or not state.unlocked(state.selected,id): return
	var prop=props[id]
	var point=prop.dining_point(pet.motion.bounds) if id in ["bowl","water"] else prop.feet_point()
	if id=="acorn": point+=Vector2(-48,0)
	point=point.clamp(pet.motion.bounds.position,pet.motion.bounds.end)
	var action={"bowl":"inspect","water":"inspect","basket":"inspect","cushion":"relax","shelter":"relax","plant":"prop_use","lamp":"prop_use","acorn":"prop_use"}.get(id,"inspect")
	pet.motion.visit(point,action,id,false)

func apply_growth() -> void:
	if not is_instance_valid(pet): return
	pet.motion.growth_scale=state.growth_scale(state.selected)
	pet.motion.growth_stage=state.growth_stage(state.selected)
	pet.title=Catalog.NAMES[state.selected]+" · "+State.GROWTH_NAMES[state.growth_stage(state.selected)]+" · 바탕화면 친구"
	for prop in props.values():
		prop.growth_scale=pet.motion.growth_scale
		prop.refresh()
	refresh_destinations()

func on_growth_changed(species: int, stage: int) -> void:
	if species!=state.selected: return
	apply_growth()
	show_gift.call_deferred(species,[],stage)

func show_gift(species: int, gifts: Array, growth_stage: int=-1) -> void:
	if species!=state.selected or not is_instance_valid(pet): return
	pet.motion.pending_reaction="gift"
	if is_instance_valid(gift_notice): gift_notice.queue_free()
	var notice=Window.new()
	gift_notice=notice
	notice.visible=false
	notice.force_native=true
	notice.borderless=true
	notice.always_on_top=true
	notice.unfocusable=true
	notice.mouse_passthrough=true
	notice.size=Vector2i(390,86)
	notice.title="친구의 선물"
	var panel=Panel.new()
	var background=StyleBoxFlat.new()
	background.bg_color=Color("fff3da")
	panel.add_theme_stylebox_override("panel",background)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notice.add_child(panel)
	var label=Label.new()
	label.theme=app_theme
	label.add_theme_color_override("font_color",Color("604732"))
	label.position=Vector2(16,12)
	label.text=("함께 돌보며 자랐어요!\n성장: "+State.GROWTH_NAMES[growth_stage]) if growth_stage>=0 else ("조금 더 가까워졌어요!\n선물: "+State.GIFT_NAMES[gifts[0]])
	panel.add_child(label)
	add_child(notice)
	var area=Rect2i(pet.desktop_bounds())
	notice.position=Vector2i((pet.motion.feet+Vector2(-195,-240)).clamp(Vector2(area.position),Vector2((area.end-notice.size).max(area.position))))
	notice.show()
	get_tree().create_timer(5).timeout.connect(func():
		if is_instance_valid(notice): notice.queue_free())

func use_species_prop(id: String) -> void:
	if not is_instance_valid(pet) or id not in ["plant","lamp"]: return
	if not state.unlocked(state.selected,id): return
	cancel_hunt()
	if decorating: activity(5)
	ensure_prop_nearby(id)
	props[id].confirm_drop()
	pet.motion.visit(props[id].feet_point(),"prop_use",id,true)

func use_common_toy(id: String) -> void:
	if not is_instance_valid(pet) or id!="acorn": return
	if not state.unlocked(state.selected,id): return
	cancel_hunt()
	if decorating: activity(5)
	ensure_prop_nearby(id)
	props[id].confirm_drop()
	var point=(props[id].feet_point()+Vector2(-48,0)).clamp(pet.motion.bounds.position,pet.motion.bounds.end)
	pet.motion.visit(point,"prop_use",id,true)
