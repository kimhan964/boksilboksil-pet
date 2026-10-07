extends Window
const Cozy=preload("res://scripts/cozy_ui.gd")
const STEPS=[
	["paw","반가워요, 복슬복슬메이트예요!","키보드를 누르거나 마우스를 클릭하면\n작은 친구가 함께 타자를 쳐요.\nAPM은 입력 속도, 활동은 함께한 시간이에요."],
	["move","잡아서, 원하는 곳에 쏙","자유 이동은 처음부터 켜져 있어요.\n동물이나 위쪽 APM 영역을 잡아 끌어보세요.\n놓은 위치는 다음 실행에도 기억해요."],
	["text","내 눈에 편한 크기로","설정에서 펫 크기와 글씨 크기를 따로 조절해요.\n작게 · 보통 · 크게 버튼이나 슬라이더를 사용하세요.\n작은 글씨도 최소 12px로 표시해요."],
	["gift","함께한 시간이 선물이 돼요","입력과 활동이 쌓이면 선물 상자에 숫자가 떠요.\n상자 → 선물 받기 → 장착하기 순서로 꾸며보세요.\n모은 액세서리는 계속 소장할 수 있어요."],
	["coffee","오늘의 주문도 받아볼까요?","카페 노트에서 매일 세 가지 주문을 만나요.\n완료하면 스탬프를 받아 불빛 테마와 교환해요.\n모은 스탬프는 다음 날에도 그대로 남아요."]]
var app
var step=0
var card: PanelContainer
func _init() -> void:
	visible=false
	force_native=true
	always_on_top=true
	unresizable=true
	size=Vector2i(540,440)
	title="복슬복슬메이트 · 처음 만나는 작은 친구"
func _ready() -> void:
	theme=app.skin
	close_requested.connect(finish)
func show_guide() -> void:
	step=0
	render_step()
	var screen=DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen())
	position=screen.position+(screen.size-size)/2
	show()
	grab_focus()
func text(value: String,font_size: int) -> Label:
	var result=Label.new()
	result.text=value
	result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",maxi(12,roundi(font_size*app.text_scale)))
	return result
func render_step() -> void:
	if is_instance_valid(card):
		remove_child(card)
		card.queue_free()
	card=PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper=Cozy.box("faf6ef",0)
	paper.content_margin_left=24
	paper.content_margin_right=24
	paper.content_margin_top=24
	paper.content_margin_bottom=24
	card.add_theme_stylebox_override("panel",paper)
	add_child(card)
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	card.add_child(column)
	column.add_child(text("처음 만나는 친구  ·  %d / %d"%[step+1,STEPS.size()],13))
	var symbol=TextureRect.new()
	symbol.texture=Cozy.icon(STEPS[step][0],56)
	symbol.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	symbol.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol.custom_minimum_size=Vector2(0,56)
	column.add_child(symbol)
	var title_label=text(STEPS[step][1],25)
	title_label.add_theme_font_override("font",Cozy.heading_font())
	column.add_child(title_label)
	var description=text(STEPS[step][2],16)
	description.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(description)
	var actions=HBoxContainer.new()
	actions.add_theme_constant_override("separation",10)
	column.add_child(actions)
	var previous=Button.new()
	previous.text="이전"
	previous.disabled=step==0
	previous.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	previous.pressed.connect(func(): step-=1; render_step())
	actions.add_child(previous)
	var next=Button.new()
	next.text="시작하기" if step==STEPS.size()-1 else "다음"
	next.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	next.pressed.connect(func():
		if step==STEPS.size()-1: finish()
		else: step+=1; render_step())
	actions.add_child(next)
func finish() -> void:
	app.tutorial_seen=true
	app.save_game()
	hide()
