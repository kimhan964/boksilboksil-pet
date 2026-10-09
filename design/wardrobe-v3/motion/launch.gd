extends SceneTree
## Isolated native wardrobe review. Uses the actual Pet/Motion/View classes.
## The user's save and released game configuration are never changed.
const Pet=preload("res://scripts/desktop_pet.gd")
const State=preload("res://scripts/pet_state.gd")
const Wardrobe=preload("res://scripts/wardrobe_motion_art.gd")
class MemoryState extends State:
	func load_game() -> void: pass
	func save_game() -> void: pass
class ReviewPet extends Pet:
	signal wardrobe_requested
	func open_menu() -> void: wardrobe_requested.emit()
var pet
var panel: Window
var status: Label
var heading: Label
var idle_age=0.0
var patrol=true
var direction=1
var pending_style=""
func _initialize() -> void: call_deferred("run")
func run() -> void:
	ProjectSettings.set_setting("testing/wardrobe_v3",true)
	Engine.max_fps=60
	root.transparent_bg=true
	root.mouse_passthrough=true
	root.unfocusable=true
	preload("res://scripts/native_mouse.gd").apply(root,true,true)
	build_panel()
	select_species(0 if OS.get_cmdline_user_args().has("--rabbit") else 8)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--style=") and arg.trim_prefix("--style=") in Wardrobe.STYLES:
			pending_style=arg.trim_prefix("--style=")
	process_frame.connect(tick)
	print("WARDROBE_REVIEW_READY all available adult species vest,knit,apron; isolated memory state")
	await process_frame
	await RenderingServer.frame_post_draw
	panel.get_texture().get_image().save_png("res://builds/wardrobe-v3-native/controls.png")
func select_species(species: int) -> void:
	if is_instance_valid(pet): pet.free()
	var state=MemoryState.new()
	state.growth[str(species)]=36
	state.guide_seen=true
	state.activity_space="floor"
	pet=ReviewPet.new()
	pet.species=species
	pet.state=state
	pet.motion.rabbit_pilot=true
	pet.motion.smooth_walk_enabled=species>0
	pet.motion.set_meta("wardrobe_v3_style","vest")
	Wardrobe.prewarm("vest",species)
	root.add_child(pet)
	pet.returned.connect(quit)
	pet.wardrobe_requested.connect(func(): panel.show();panel.grab_focus())
	pet.motion.cancel_play()
	pet.motion.autonomy=false
	pet.motion.resting=true
	pet.motion.move_to(Vector2(pet.motion.bounds.get_center().x,pet.motion.bounds.position.y))
	heading.text=preload("res://scripts/animal_catalog.gd").NAMES[species]+" · 성체 의상"
	idle_age=0
	pending_style=""
func build_panel() -> void:
	panel=Window.new()
	panel.visible=false
	panel.title="복슬복슬 · 의상 동작 확인"
	panel.force_native=true
	panel.size=Vector2i(350,415)
	panel.position=Vector2i(60,100)
	panel.always_on_top=true
	panel.theme=preload("res://scripts/cozy_ui.gd").theme()
	panel.close_requested.connect(quit)
	root.add_child(panel)
	var background=ColorRect.new()
	background.color=Color("fff8ed")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(background)
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,18)
	panel.add_child(margin)
	var box=VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	margin.add_child(box)
	heading=Label.new()
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var species_list=OptionButton.new()
	species_list.custom_minimum_size.y=38
	box.add_child(species_list)
	for species in Wardrobe.SPECIES:
		if Wardrobe.data(species).get("styles",{}).size()!=3: continue
		species_list.add_item(preload("res://scripts/animal_catalog.gd").NAMES[species],species)
	species_list.select(species_list.get_item_index(0 if OS.get_cmdline_user_args().has("--rabbit") else 8))
	species_list.item_selected.connect(func(index): select_species(species_list.get_item_id(index)))
	for i in range(3):
		var style=Wardrobe.STYLES[i]
		var button=Button.new()
		button.text=["산책 조끼","포근한 니트","카페 앞치마"][i]
		button.custom_minimum_size.y=38
		button.pressed.connect(func(): pending_style=style)
		box.add_child(button)
	var pause=Button.new()
	pause.text="산책 잠깐 쉬기"
	pause.custom_minimum_size.y=38
	pause.pressed.connect(func(): patrol=not patrol;pause.text="산책 잠깐 쉬기" if patrol else "다시 산책하기")
	box.add_child(pause)
	var help=Label.new()
	help.text="동물을 눌러 쓰다듬거나 들어 보세요.\n2초 뒤 버둥거림 · 3초 이상 들고 놓기\n의상은 다음 대기 자세에서 바뀝니다."
	help.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size",13)
	box.add_child(help)
	status=Label.new()
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size",12)
	box.add_child(status)
	panel.show()
func tick() -> void:
	if not is_instance_valid(pet): return
	var m=pet.motion
	if m.phase=="idle" and not m.held and m.hold_release.is_empty():
		if not pending_style.is_empty():
			Wardrobe.prewarm(pending_style,m.species)
			m.set_meta("wardrobe_v3_style",pending_style)
			pending_style=""
			pet.view.refresh()
		idle_age+=root.get_process_delta_time()
		if patrol and idle_age>1.5:
			direction=-direction
			m.phase="wander"
			m.target=(m.feet+Vector2(direction*140,0)).clamp(m.bounds.position,m.bounds.end)
			idle_age=0.0
	else:
		idle_age=0.0
	# Retired hold metadata is no longer needed once the original recovery ends.
	if m.phase=="idle" and not m.hold_release.is_empty() and m.hold_release.elapsed>1.2:
		m.hold_release.clear()
	var applied=pet.view.generated_sample.get("wardrobe_v3",false)
	status.text="성체 의상 3벌 · 동작 검수 중" if applied else "미지원 동작: "+str(m.phase)
	if not pending_style.is_empty(): status.text="다음 대기 자세에서 의상을 바꿔요"
