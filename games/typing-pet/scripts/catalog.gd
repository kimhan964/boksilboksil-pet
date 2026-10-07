extends RefCounted
const IDS=["rabbit","otter","squirrel","hedgehog","raccoon","fox","bear","owl","cat","puppy","hamster","panda","red_panda","lamb","koala","penguin"]
const NAMES=["모루 · 토끼","보리 · 수달","도토 · 다람쥐","밤이 · 고슴도치","누리 · 너구리","솔 · 여우","두리 · 곰","달 · 부엉이","치즈 · 고양이","쿠키 · 강아지","콩이 · 햄스터","포포 · 판다","단풍 · 레서판다","몽실 · 아기 양","코코 · 코알라","빙글 · 펭귄"]
# Pins sit on the side of the forehead, never on animated paws. Normalized cel coordinates.
const PINS=[Vector2(.64,.38),Vector2(.66,.32),Vector2(.66,.33),Vector2(.65,.33),Vector2(.66,.33),Vector2(.66,.33),Vector2(.66,.33),Vector2(.66,.33),Vector2(.68,.34),Vector2(.65,.34),Vector2(.66,.33),Vector2(.66,.33),Vector2(.66,.33),Vector2(.65,.34),Vector2(.65,.34),Vector2(.65,.34)]
static func folder(species: int) -> String:
	return "res://assets/typing-rabbit-v1" if species==0 else "res://assets/typing-animals-v1/"+IDS[species]
const HATS=[Vector2(.50,.305),Vector2(.50,.255),Vector2(.51,.25),Vector2(.50,.19),Vector2(.50,.25),Vector2(.50,.25),Vector2(.50,.22),Vector2(.50,.25),Vector2(.50,.235),Vector2(.50,.195),Vector2(.50,.24),Vector2(.50,.215),Vector2(.50,.25),Vector2(.50,.19),Vector2(.50,.25),Vector2(.50,.21)]
# Match the fox's warm, clear midtones without recoloring species or lifting eye ink.
# Fixed across idle/left/right. Cream fur remains cream and grey fur remains grey.
const TONES=[
	Vector4(-.025,.96,-.025,.004), # rabbit: soften broad bright cream
	Vector4(.065,1.02,0,.004), # otter
	Vector4(0,.96,-.004,0), # squirrel
	Vector4(.085,.95,-.004,.006), # hedgehog
	Vector4(.075,1.0,-.005,.010), # raccoon
	Vector4(0,1,0,0), # fox: reference, unchanged
	Vector4(-.008,.97,-.004,0), # bear
	Vector4(-.025,.90,-.008,.009), # owl: calm lilac
	Vector4(-.016,.95,-.006,0), # cat
	Vector4(-.035,.98,-.010,.002), # puppy
	Vector4(-.040,.96,-.012,0), # hamster
	Vector4(.045,.98,-.020,.004), # panda: dark fur, cream face
	Vector4(.090,.88,-.004,.003), # red panda: soften dense russet
	Vector4(-.025,.95,-.030,.004), # lamb
	Vector4(.028,.94,-.010,.010), # koala: warm grey
	Vector4(.080,.94,-.012,.010)] # penguin: soften charcoal
static func accessory_anchor(species: int,id: String) -> Vector2:
	return HATS[species] if preload("res://scripts/pin.gd").is_hat(id) else PINS[species]
static func frames(species: int) -> Array[Texture2D]:
	var result: Array[Texture2D]=[]
	for pose in ["idle","left","right"]:
		var image=Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(folder(species)+"/"+pose+".png"))!=OK: return []
		if not result.is_empty() and image.get_size()!=Vector2i(result[0].get_size()): return []
		image.generate_mipmaps()
		result.append(ImageTexture.create_from_image(image))
	return result
