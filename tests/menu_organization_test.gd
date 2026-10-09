extends SceneTree
const Main=preload("res://scripts/main.gd")
const State=preload("res://scripts/pet_state.gd")
class MemoryState extends State:
	func load_game() -> void: pass
	func save_game() -> void: pass
var failures=[]
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	ProjectSettings.set_setting("commerce/enabled",false)
	var app=Main.new()
	app.state=MemoryState.new()
	app.state.guide_seen=true
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.pet.set_process(false)
	app.furniture_room.set_process(false)
	var menu=app.pet.menu
	menu.prepare()
	var chosen=[]
	menu.id_pressed.disconnect(app.pet.menu_action)
	menu.id_pressed.connect(func(id): chosen.append(id))
	for section in range(4):
		menu.section=section
		menu.source=null
		menu.rebuild()
		await process_frame
		var action_buttons=[]
		for node in menu.body.get_children():
			if node is Button: action_buttons.append(node)
		check(action_buttons.size()==menu.SECTIONS[section].filter(func(id): return menu.get_item_index(id)>=0).size(),"section action count")
		for button in action_buttons:
			check(not "옷" in button.text,"clothing hidden")
			check(button.icon!=null,"action icon")
		if section==0:
			check(not 32 in menu.SECTIONS[section],"no furniture in together")
			for i in range(3):
				action_buttons[i].pressed.emit()
				await process_frame
				check(chosen[-1]==menu.SECTIONS[section][i],"together button routing")
		if DisplayServer.get_name()!="headless":
			menu.show()
			await process_frame
			await RenderingServer.frame_post_draw
			menu.get_texture().get_image().save_png("user://menu-tab-%d.png"%section)
	var room=app.furniture_room
	for kind in ["home","toys","home"]:
		room.open(kind)
		await process_frame
		await process_frame
		await process_frame
		for id in room.item_rows:
			check(room.item_rows[id].visible==((id in room.TOY_IDS)==(kind=="toys")),"panel category "+id)
		check(room.space_picker.visible==(kind=="home"),"space setting belongs to home")
		check(room.panel_done.get_global_rect().end.y<=room.panel.size.y,"close button inside window")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			room.panel.get_texture().get_image().save_png("user://menu-%s.png"%kind)
	var play_rows=preload("res://scripts/play_catalog.gd").rows(app.state,0)
	check(play_rows.size()==5,"five real play entries")
	check(play_rows[0].open and not play_rows[3].open and not play_rows[4].open,"basic and locked play")
	app.state.activity_counts={"0":{"acorn":3}}
	play_rows=preload("res://scripts/play_catalog.gd").rows(app.state,0)
	check(play_rows[3].open and not play_rows[4].open,"ball unlocks after three plays")
	app.state.activity_counts={"0":{"acorn":8}}
	check(preload("res://scripts/play_catalog.gd").rows(app.state,0)[4].open,"mouse unlocks after eight plays")
	app.state.activity_counts={}
	app.set_acorn_visible(false)
	room.acorn_button.pressed.emit()
	check(app.props.acorn.visible,"acorn show")
	app.use_common_toy("acorn")
	check(app.pet.motion.visit_id=="acorn","acorn object starts pet visit")
	room.acorn_button.pressed.emit()
	check(not app.props.acorn.visible,"acorn hide")
	var art=preload("res://scripts/decor_art.gd").icon("acorn")
	check(art!=null and art.get_width()>700,"new generated acorn")
	var poly=app.props.acorn.input_polygon()
	check(poly.size()>3,"acorn wobble mask")
	var prop=app.props.acorn
	var factor=minf(47.0/art.get_width(),57.0/art.get_height())
	var dimensions=art.get_size()*factor
	var hull=preload("res://scripts/animation_outline.gd").local_hull(art)
	for i in range(181):
		var angle=lerpf(-prop.WOBBLE_ANGLE,prop.WOBBLE_ANGLE,i/180.0)
		for point in hull:
			var at=(Vector2(56,86)+(point*factor-Vector2(dimensions.x*.5,dimensions.y)).rotated(angle))*prop.art_scale
			check(Geometry2D.is_point_in_polygon(at,poly),"generated acorn clipped during wobble")
	if DisplayServer.get_name()!="headless":
		app.set_acorn_visible(true)
		prop.set_wobbling(true)
		await process_frame
		await RenderingServer.frame_post_draw
		prop.get_texture().get_image().save_png("user://acorn-game-v2.png")
		app.set_acorn_visible(false)

	room.place("toy_ball",Vector2.INF,false)
	check(not room.pieces.has("toy_ball"),"locked toy cannot be placed")
	app.state.play_affection={"0":200}
	app.state.activity_counts={"0":{"acorn":3}}
	room.refresh_buttons()
	room.buttons.toy_ball.pressed.emit()
	check(room.pieces.has("toy_ball"),"toy place works")
	room.buttons.toy_ball.pressed.emit()
	check(not room.pieces.has("toy_ball"),"toy remove works")
	app.activity(23)
	check(app.pet.motion.social_kind=="follow","cursor follow starts")
	# Preview access must not hide the real earning requirements or next goal.
	app.state.activity_counts={"0":{"acorn":2}}
	app.state.home_owned={}
	var unlocks=app.state.unlock_rows(0)
	var ball=unlocks.filter(func(row): return row.id=="home_toy_ball")[0]
	check(not ball.earned and not ball.open and is_equal_approx(ball.progress,2.0/3),"normal unlock progress 2/3")
	check(app.state.goal_text(0).contains(ball.title),"next goal points to nearest unlock")
	app.state.activity_counts["0"].acorn=3
	ball=app.state.unlock_rows(0).filter(func(row): return row.id=="home_toy_ball")[0]
	check(ball.open and ball.earned,"unlock at exact threshold")
	check(not app.state.goal_text(0).contains(ball.title),"goal advances after earning")
	app.state.activity_counts["0"].acorn=2
	app.state.home_owned={}
	ProjectSettings.set_setting("testing/unlock_all",true)
	ball=app.state.unlock_rows(0).filter(func(row): return row.id=="home_toy_ball")[0]
	check(ball.open and not ball.earned and is_equal_approx(ball.progress,2.0/3),"preview access keeps actual progress")
	check(ball.hint.contains("2 / 3회"),"threshold remains visible in preview")
	menu.source=null
	menu.section=3
	menu.rebuild()
	await process_frame
	await process_frame
	check(menu.tabs[3].text=="목표·해금","discoverable unlock tab")
	check(menu.size.x==440,"menu remains compact")
	if DisplayServer.get_name()!="headless":
		menu.show()
		await RenderingServer.frame_post_draw
		menu.get_texture().get_image().save_png("user://menu-unlocks-preview.png")
	ProjectSettings.set_setting("testing/unlock_all",false)
	print("MENU_ORGANIZATION_FAILURES=",failures.size())
	app.free()
	quit(0 if failures.is_empty() else 1)
