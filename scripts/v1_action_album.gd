extends Window
const Data=preload("res://scripts/v1_action_album_data.gd")
const Cozy=preload("res://scripts/cozy_ui.gd")
var pet_ref: WeakRef
var state
var motion
var baby=false
var selected=0
var clock=0.0
var paused=false
var flipped=false
var filter="전체"
var preview: TextureRect
var title_label: Label
var hint: Label
var requirement_label: Label
var progress: ProgressBar
var action_button: Button
var play_button: Button
var age: OptionButton
var rows: VBoxContainer
var row_buttons=[]
var loading: Label
var time_label: Label
var build_generation=0
var built=false
func text(value: String,size: int=14) -> Label:
	var l=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return l
func button(value: String,callback: Callable) -> Button:
	var b=Button.new();b.text=value;b.custom_minimum_size.y=36;b.pressed.connect(callback);return b
func open_for(pet) -> void:
	pet_ref=weakref(pet);state=pet.state;baby=pet.motion.growth_stage==0
	if not built: build()
	motion=Data.motion_for(pet.species,baby)
	age.select(0 if baby else 1);title_label.text=Data.Catalog.NAMES[pet.species]+"의 행동 도감"
	var screen=DisplayServer.screen_get_usable_rect()
	size=Vector2i(mini(760,screen.size.x-32),mini(760,screen.size.y-48));position=screen.position+(screen.size-size)/2
	show();reveal.call_deferred();rebuild.call_deferred()
func reveal() -> void:
	if not visible: return
	# Repeat first show when the executable is started by a hidden launcher.
	hide();show()
	preload("res://scripts/native_mouse.gd").apply(self,false,true);grab_focus()
func build() -> void:
	built=true;visible=false;force_native=true;always_on_top=true;title="복슬복슬펫 v1 · 행동 도감";min_size=Vector2i(570,520);theme=Cozy.theme()
	close_requested.connect(hide)
	var background=PanelContainer.new();background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.add_theme_stylebox_override("panel",Cozy.box("faf8f3",14));add_child(background)
	var col=VBoxContainer.new();col.add_theme_constant_override("separation",10);background.add_child(col)
	var top=HBoxContainer.new();col.add_child(top)
	title_label=text("행동 도감",20);title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title_label)
	age=OptionButton.new();age.add_item("새끼");age.add_item("성체");age.custom_minimum_size=Vector2(100,36);top.add_child(age)
	age.item_selected.connect(func(i): baby=i==0;motion=Data.motion_for(motion.species,baby);rebuild())
	col.add_child(text("카드를 누르면 움직임과 만나는 방법을 볼 수 있어요.",12))
	var card=PanelContainer.new();card.add_theme_stylebox_override("panel",Cozy.box("edf0e5",12));col.add_child(card)
	var line=HBoxContainer.new();line.add_theme_constant_override("separation",14);card.add_child(line)
	preview=TextureRect.new();preview.custom_minimum_size=Vector2(148,148);preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(preview)
	var detail=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_theme_constant_override("separation",7);line.add_child(detail)
	hint=text("",14);detail.add_child(hint)
	requirement_label=text("",12);detail.add_child(requirement_label)
	progress=ProgressBar.new();progress.custom_minimum_size.y=7;progress.show_percentage=false;progress.max_value=1;detail.add_child(progress)
	time_label=text("",12);detail.add_child(time_label)
	var controls=HBoxContainer.new();controls.add_theme_constant_override("separation",6);detail.add_child(controls)
	play_button=button("일시 정지",func(): paused=not paused;play_button.text="재생" if paused else "일시 정지");controls.add_child(play_button)
	controls.add_child(button("방향 바꾸기",func(): flipped=not flipped;preview.flip_h=flipped))
	action_button=button("가구 배치 열기",navigate);detail.add_child(action_button)
	var categories=HFlowContainer.new();categories.add_theme_constant_override("h_separation",5);col.add_child(categories)
	for name in ["전체","일상","교감","식사·휴식","가구·놀이","깜짝 행동"]:
		categories.add_child(button(name,func(): filter=name;apply_filter()))
	loading=text("그림을 준비하고 있어요…",12);col.add_child(loading)
	var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
	rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",7);scroll.add_child(rows)
	col.add_child(text("기본 모습 미리보기 · 실제 행동은 쓰다듬기·들기·가구 이용으로 만나요.",12))
	col.add_child(button("도감 닫기",hide))
func rebuild() -> void:
	build_generation+=1;var generation=build_generation
	row_buttons.clear();preview.texture=null
	for child in rows.get_children(): rows.remove_child(child);child.queue_free()
	loading.text="그림을 준비하고 있어요…"
	for i in range(Data.ROWS.size()):
		if generation!=build_generation or not visible: return
		var row=Data.ROWS[i]
		var b=button("",func(): select_action(i));b.custom_minimum_size.y=90;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var layout=HBoxContainer.new();layout.mouse_filter=Control.MOUSE_FILTER_IGNORE;layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layout.add_theme_constant_override("separation",12);b.add_child(layout)
		var ready=Data.ready(motion,row)
		var sample=Data.sample(motion,row[0],Data.seconds(motion,row[0])*.35) if ready else {}
		var picture=TextureRect.new();picture.custom_minimum_size=Vector2(92,88);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.texture=sample.get("texture");picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;layout.add_child(picture)
		var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.alignment=BoxContainer.ALIGNMENT_CENTER;info.mouse_filter=Control.MOUSE_FILTER_IGNORE;layout.add_child(info)
		var req=Data.requirement(state,row)
		for value in [row[2],row[3],req.text if ready else "전용 그림 준비 중"]:
			var l=text(value,14 if value==row[2] else 12);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;info.add_child(l)
		b.disabled=not ready;rows.add_child(b);row_buttons.append(b)
		apply_filter()
		if i==0: select_action(0)
		await get_tree().process_frame
	if generation==build_generation: loading.text="%d가지 행동 · 우리 집 교감 %d"%[row_buttons.size(),state.home_points()]
func apply_filter() -> void:
	for i in range(row_buttons.size()): row_buttons[i].visible=filter=="전체" or Data.ROWS[i][1]==filter
func select_action(index: int) -> void:
	selected=index;clock=0;paused=false;play_button.text="일시 정지"
	var row=Data.ROWS[index];var req=Data.requirement(state,row)
	hint.text=row[2]+"\n"+row[3];requirement_label.text=req.text+("\n쓰다듬기·함께 놀기로 교감을 쌓아요." if not req.open else "");progress.value=req.ratio
	action_button.visible=not row[4].is_empty();action_button.text="놀이감·가구 배치 열기"
	for i in range(row_buttons.size()): row_buttons[i].add_theme_stylebox_override("normal",Cozy.box("e4ebdc" if i==index else "fffdf8",10))
	update_preview()
func update_preview() -> void:
	var id: String=Data.ROWS[selected][0];var duration=Data.seconds(motion,id)
	var sample=Data.sample(motion,id,fposmod(clock,duration));preview.texture=sample.get("texture");preview.flip_h=flipped
	time_label.text="%s · %.1f초 미리보기"%["새끼" if baby else "성체",duration]
func navigate() -> void:
	var pet=pet_ref.get_ref() if pet_ref!=null else null
	if not is_instance_valid(pet): return
	hide();pet.activity_requested.emit(32)
func _process(delta: float) -> void:
	if not visible or paused or motion==null or preview==null or preview.texture==null: return
	clock+=delta;update_preview()
