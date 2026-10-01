extends SceneTree
## Live QA: the actual game controller, native pet/prop windows, isolated saves.
const Main=preload("res://scripts/main.gd")
const State=preload("res://scripts/pet_state.gd")
const Catalog=preload("res://scripts/animal_catalog.gd")
const Art=preload("res://scripts/generated_species_art.gd")
const View=preload("res://scripts/desktop_pet_view.gd")
var app
var controls: Window
var label: Label
var stage=2
var auto=false
var jobs: Array=[]
var active: Dictionary={}
var age=0.0
var sample_clock=0.0
var captures: Array=[]
var folder="res://design/gameplay-audit-2026-10-02"
const ACTIONS=["idle","walk","pet","eat","drink","sleep","carry","jump","look","sniff","wave","groom","stretch","rub","toy","rest","surprised","happy","angry","sleepy","drop","dizzy"]

class AuditState extends State:
	func load_game() -> void:
		guide_seen=true
		for i in range(16):
			play_affection[str(i)]=70
			growth[str(i)]=36
	func save_game() -> void: pass
	func reward_activity(_species: int,_action: String) -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Live gameplay review requires native game windows.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	app=Main.new()
	app.state=AuditState.new()
	root.add_child(app)
	controls=Window.new()
	controls.visible=false
	controls.force_native=true
	controls.title="실제 게임 플레이 점검 · 16종"
	controls.size=Vector2i(700,250)
	controls.position=DisplayServer.screen_get_usable_rect().position+Vector2i(35,35)
	controls.always_on_top=true
	controls.close_requested.connect(func(): quit())
	root.add_child(controls)
	var column=VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls.add_child(column)
	label=Label.new()
	label.text="실제 게임 창 · 저장 기록을 변경하지 않는 점검"
	column.add_child(label)
	var grid=GridContainer.new()
	grid.columns=8
	column.add_child(grid)
	for i in range(16):
		var button=Button.new()
		button.text=Catalog.NAMES[i].split(" · ")[1]
		button.pressed.connect(func(): auto=false; select_friend(i,stage); set_action("idle"))
		grid.add_child(button)
	var row=HBoxContainer.new()
	column.add_child(row)
	for age_stage in [0,2]:
		var button=Button.new()
		button.text="새끼" if age_stage==0 else "성체"
		button.pressed.connect(func(): auto=false; select_friend(app.state.selected,age_stage); set_action("idle"))
		row.add_child(button)
	var actions=OptionButton.new()
	for action in ACTIONS: actions.add_item(action)
	actions.item_selected.connect(func(index): auto=false; set_action(ACTIONS[index]))
	row.add_child(actions)
	var begin=Button.new()
	begin.text="16종 새끼·성체 전체 행동 순회"
	begin.pressed.connect(start_sweep)
	row.add_child(begin)
	var pause=Button.new()
	pause.text="멈추고 직접 조작"
	pause.pressed.connect(func(): auto=false; app.pet.motion.cancel_play(); app.pet.motion.resting=true)
	row.add_child(pause)
	var hint=Label.new()
	hint.text="순회 중 걷기는 실제 속도, 나머지는 프레임 검수를 위해 빠르게 재생합니다.\n멈추면 펫·음식·연못·장난감·우클릭 메뉴를 직접 조작할 수 있습니다."
	column.add_child(hint)
	controls.show()
	select_friend(0,2)
	set_action("idle")
	if OS.get_cmdline_user_args().has("--sweep"): start_sweep()
	if OS.get_cmdline_user_args().has("--repair-sweep"):
		folder+="/repaired"
		DirAccess.make_dir_recursive_absolute(folder)
		for job in [{"species":7,"stage":2,"action":"sleep"},{"species":0,"stage":0,"action":"rest"},{"species":0,"stage":2,"action":"rest"},{"species":2,"stage":2,"action":"rest"}]: jobs.append(job)
		auto=true
		next_job()
	if OS.get_cmdline_user_args().has("--outfit-sweep"):
		folder+="/outfits"
		DirAccess.make_dir_recursive_absolute(folder)
		for species in range(16):
			for age_stage in [0,2]:
				for style in range(1,4):
					for action in ["idle","walk","sleep"]: jobs.append({"species":species,"stage":age_stage,"style":style,"action":action})
		auto=true
		next_job()

func select_friend(species: int, age_stage: int) -> void:
	stage=age_stage
	app.state.growth[str(species)]=0 if stage==0 else 36
	app.choose_friend(species)
	app.pet.title="[플레이 점검] "+Catalog.NAMES[species]+(" · 새끼" if stage==0 else " · 성체")
	app.pet.motion.autonomy=false
	app.pet.motion.resting=true
	var usable=DisplayServer.screen_get_usable_rect()
	app.pet.motion.move_to(Vector2(usable.position)+Vector2(usable.size.x*.45,usable.size.y*.58))
	app.pet.motion.voice_left=0
	app.layers_dirty=true

func set_action(action: String) -> void:
	var m=app.pet.motion
	m.cancel_play()
	m.joy_left=0
	m.resting=true
	m.voice_left=0
	m.elapsed=0
	m.carry_elapsed=0
	m.action_left=20
	match action:
		"pet": m.phase="pet"; m.joy_left=20
		"wave": m.react("greet",10)
		"walk":
			m.phase="wander"
			m.target=(m.feet+Vector2(300,0)).clamp(m.bounds.position,m.bounds.end)
		"sleep": m.phase="doze"
		"rest": m.phase="relax"
		"carry": m.carried=true
		"jump": m.phase="playful"; m.action_left=20
		"toy":
			app.ensure_prop_nearby("plant")
			m.phase="prop_use"
			m.visit_id="plant"
		"surprised","happy","angry","sleepy": m.react(action,10)
		"drop": m.begin_drop()
		"dizzy": m.begin_dizzy()
		_: m.phase=action
	if action=="eat": m.visit_id="bowl"
	if action=="drink": m.visit_id="water"
	label.text="%s · %s · %s"%[Catalog.NAMES[m.species],"새끼" if stage==0 else "성체",action]

func start_sweep() -> void:
	jobs.clear()
	for species in range(16):
		for age_stage in [0,2]:
			for action in ACTIONS: jobs.append({"species":species,"stage":age_stage,"action":action})
	auto=true
	next_job()

func next_job() -> void:
	if jobs.is_empty():
		auto=false
		var file=FileAccess.open(folder+"/native-gameplay-report.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"native_windows":true,"cases":captures},"\t"))
		print("NATIVE_GAMEPLAY_SWEEP_DONE cases=",captures.size())
		label.text="%d행동 확인 기록 완료 · 직접 조작 가능"%captures.size()
		return
	active=jobs.pop_front()
	if app.state.selected!=active.species or stage!=active.stage: select_friend(active.species,active.stage)
	if active.has("style"):
		app.pet.menu_action(300+int(active.style))
	set_action(active.action)
	age=0
	sample_clock=0

func _process(delta: float) -> bool:
	if not auto or app==null or not is_instance_valid(app.pet): return false
	age+=delta
	var action: String=active.action
	var m=app.pet.motion
	var duration=1.6 if action=="walk" else (.8 if action in ["drop","dizzy"] else .4)
	if active.has("style"): duration=.65 if action=="walk" else .18
	if action not in ["walk","drop","dizzy"]:
		m.elapsed=age/duration*4.8
		m.carry_elapsed=m.elapsed
		m.reaction_time=age/duration*8.0
		m.action_left=20
	if age>=duration:
		auto=false
		capture.call_deferred()
	return false

func capture() -> void:
	await RenderingServer.frame_post_draw
	var file="%s/%02d-%s-%s.png"%[folder,active.species,"baby" if active.stage==0 else "adult",active.action]
	if active.has("style"): file=file.trim_suffix(".png")+"-%d.png"%active.style
	var image=app.pet.get_texture().get_image()
	var error=image.save_png(file)
	captures.append({"species":Catalog.IDS[active.species],"stage":active.stage,"style":app.pet.motion.outfit_style,"action":active.action,"actual_phase":app.pet.motion.phase,"actual_art":app.pet.view.generated_sample.action,"window_id":app.pet.get_window_id(),"image":file,"error":error})
	print("NATIVE_CASE ",Catalog.IDS[active.species],"/",active.stage,"/",active.action," error=",error)
	auto=true
	next_job()
