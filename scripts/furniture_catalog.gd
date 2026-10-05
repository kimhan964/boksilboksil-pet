extends RefCounted
const ITEMS={
	"sofa":{"name":"토끼 귀 미니 소파","size":Vector2(142,112)},
	"table":{"name":"고양이 발 미니 식탁","size":Vector2(126,86)},
	"shelf":{"name":"다람쥐 도토리 책장","size":Vector2(108,126)},
	"lamp":{"name":"졸린 곰 리넨 램프","size":Vector2(84,126)},
	"reading_chair":{"name":"여우 꼬리 독서 의자","size":Vector2(124,122)},
	"daybed":{"name":"발바닥 리넨 데이베드","size":Vector2(168,88)},
	"vanity":{"name":"고양이 거울 화장대","size":Vector2(118,125)},
	"record_player":{"name":"곰 음악 장식장","size":Vector2(114,94)},
	"play_rug":{"name":"포근한 발바닥 놀이 러그","size":Vector2(146,76)},
	"window_seat":{"name":"잎새 창가 벤치","size":Vector2(160,105)},
	"tv":{"name":"고양이 원목 TV장","size":Vector2(158,138)},
	"turntable":{"name":"곰 LP 리스닝 테이블","size":Vector2(132,112)}
}
const USE_LABELS={"sofa":"소파에서 쉬기","table":"앉아서 티타임","shelf":"책 읽기","lamp":"조명 곁에서 낮잠","reading_chair":"의자에서 독서","daybed":"누워 낮잠 자기","vanity":"거울 보고 단장","record_player":"음악 듣기","play_rug":"러그에서 놀이","window_seat":"벤치에서 쉬기"}
static var textures={}
static func use_label(id: String) -> String:
	return {"tv":"TV 보며 쉬기","turntable":"LP 감상하기"}.get(id,USE_LABELS.get(id,"곁에서 쉬기"))
static func texture(id: String) -> Texture2D:
	if not ITEMS.has(id) and id!="water-cup": return null
	if not textures.has(id):
		var path="res://assets/furniture-v1/"+id+".png"
		if FileAccess.file_exists("res://assets/furniture-v2/"+id+".png"): path="res://assets/furniture-v2/"+id+".png"
		if FileAccess.file_exists("res://assets/furniture-v3/"+id+".png"): path="res://assets/furniture-v3/"+id+".png"
		if not FileAccess.file_exists(path): return null
		var image=Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK: return null
		var used=image.get_used_rect()
		# This generated cup includes almost invisible alpha specks far from
		# the ceramic. Use its reviewed atlas region; preserve the PNG original.
		if id=="water-cup": used=Rect2i(447,261,685,487)
		if not used.has_area(): return null
		textures[id]=ImageTexture.create_from_image(image.get_region(used))
	return textures[id]
