extends SceneTree
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Catalog=preload("res://scripts/animal_catalog.gd")
const State=preload("res://scripts/pet_state.gd")
var views: Array=[]
var motions: Array=[]
var animal: OptionButton
var action: OptionButton
var actual_size: CheckButton
var hosts: Array=[]
const PHASES=["idle","wander","eat","drink","pet","doze","carry","signature"]
func _initialize() -> void:
	call_deferred("setup")
func label_at(text: String, pos: Vector2, font_size: int=20) -> void:
	var label=Label.new()
	label.text=text
	label.position=pos
	label.add_theme_font_size_override("font_size",font_size)
	root.add_child(label)
func setup() -> void:
	preload("res://scripts/baby_art.gd").preview_puppy=true
	Engine.max_fps=30
	root.title="새끼 · 성체 그림체 비교"
	root.borderless=false
	root.transparent=false
	root.transparent_bg=false
	root.unresizable=true
	root.size=Vector2i(800,530)
	root.position=DisplayServer.screen_get_usable_rect().get_center()-root.size/2
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Malgun Gothic"])
	var theme=Theme.new()
	theme.default_font=font
	theme.default_font_size=17
	root.theme=theme
	var background=ColorRect.new()
	background.color=Color("324454")
	background.size=Vector2(800,530)
	root.add_child(background)
	label_at("새끼와 성체 · 그림체 비교",Vector2(25,20),25)
	animal=OptionButton.new()
	animal.position=Vector2(25,70)
	animal.size=Vector2(235,40)
	for name in Catalog.NAMES: animal.add_item(name)
	root.add_child(animal)
	action=OptionButton.new()
	action.position=Vector2(275,70)
	action.size=Vector2(185,40)
	for name in ["서 있기","걷기","먹기","마시기","좋아하기","잠자기","들어 올리기","특수 행동"]: action.add_item(name)
	root.add_child(action)
	actual_size=CheckButton.new()
	actual_size.text="실제 성장 크기"
	actual_size.position=Vector2(490,70)
	root.add_child(actual_size)
	label_at("새끼 · 기존 형태 유지 / 채색 수정",Vector2(25,132),18)
	label_at("성체 · 기존 그림",Vector2(435,132))
	for side in range(2):
		var container=SubViewportContainer.new()
		container.position=Vector2(32+side*395,178)
		container.size=Vector2(340,285)
		root.add_child(container)
		var viewport=SubViewport.new()
		viewport.size=Vector2i(340,285)
		viewport.transparent_bg=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		container.add_child(viewport)
		hosts.append(viewport)
	label_at("기본은 같은 높이로 비교합니다. 위에서 동물과 모션을 바꿔보세요.",Vector2(25,485),16)
	var state=State.new()
	state.load_game()
	animal.select(9)
	animal.item_selected.connect(func(_id): rebuild())
	action.item_selected.connect(func(_id): reset_action())
	actual_size.toggled.connect(func(_value): reset_action())
	rebuild()
	root.grab_focus()
func rebuild() -> void:
	for view in views: view.free()
	views.clear()
	motions.clear()
	for side in range(2):
		var motion=Motion.new()
		motion.species=animal.selected
		motion.growth_stage=0 if side==0 else 2
		motion.food_id=Catalog.DEFAULT_MEALS[animal.selected]
		var view=View.new()
		view.motion=motion
		view.position=Vector2(27,12)
		view.scale=Vector2.ONE*1.4
		hosts[side].add_child(view)
		motions.append(motion)
		views.append(view)
	reset_action()
func reset_action() -> void:
	for i in range(motions.size()):
		var motion=motions[i]
		motion.growth_scale=.62 if i==0 and actual_size.button_pressed else 1.0
		motion.phase=PHASES[action.selected]
		motion.elapsed=0
		motion.carried=motion.phase=="carry"
		motion.visit_id="water" if motion.phase=="drink" else "hand_feed"
		motion.stay_after_visit=true
func _process(delta: float) -> bool:
	for i in range(motions.size()):
		var motion=motions[i]
		motion.elapsed+=delta
		motion.carry_elapsed=motion.elapsed
		motion.action_left=5
		views[i].refresh()
	return false
