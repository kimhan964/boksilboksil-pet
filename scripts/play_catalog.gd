extends RefCounted
const ITEMS=[
	{"id":"acorn","title":"도토리 오뚝이","description":"톡 건드리면 흔들흔들. 동물을 놓아 함께 살펴봐요.","threshold":0},
	{"id":"follow","title":"마우스 산책","description":"커서를 천천히 움직이며 함께 산책해요.","threshold":0},
	{"id":"home_play_rug","title":"포근한 러그 놀이","description":"집 꾸미기에서 러그를 놓고, 동물을 데려다 놓아 놀아요.","threshold":0},
	{"id":"home_toy_ball","title":"실뜨개 공 굴리기","description":"공을 클릭해 톡 굴리거나 드래그해 던져 주세요. 동물이 뒤따라가요.","threshold":4},
	{"id":"home_toy_mouse","title":"생쥐 따라잡기","description":"작은 생쥐를 움직이면 뒤따라가 킁킁 살펴보고 톡 건드려요.","threshold":10}
]
static func rows(state,species: int) -> Array:
	var result=[]
	for item in ITEMS:
		var row=item.duplicate()
		row.open=state.unlocked(species,row.id)
		row.points=state.home_points()
		row.hint="처음부터 함께해요" if row.threshold==0 else ("해금 완료" if row.open else state.route_hint(species,row.id))
		row.progress=1.0 if row.open else preload("res://scripts/home_unlocks.gd").progress(state,row.id.trim_prefix("home_"))
		result.append(row)
	return result
static func icon(id: String) -> Texture2D:
	if id=="acorn": return preload("res://scripts/decor_art.gd").icon("acorn")
	if id=="follow": return preload("res://scripts/ui_icons.gd").texture("cursor-follow")
	return preload("res://scripts/furniture_catalog.gd").texture(id.trim_prefix("home_"))
