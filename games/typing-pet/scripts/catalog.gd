extends RefCounted
const IDS=["rabbit","otter","squirrel","hedgehog","raccoon","fox","bear","owl","cat","puppy","hamster","panda","red_panda","lamb","koala","penguin"]
const NAMES=["모루 · 토끼","보리 · 수달","도토 · 다람쥐","밤이 · 고슴도치","누리 · 너구리","솔 · 여우","두리 · 곰","달 · 부엉이","치즈 · 고양이","쿠키 · 강아지","콩이 · 햄스터","포포 · 판다","단풍 · 레서판다","몽실 · 아기 양","코코 · 코알라","빙글 · 펭귄"]
# Pins sit on the side of the forehead, never on animated paws. Normalized cel coordinates.
const PINS=[Vector2(.64,.38),Vector2(.66,.32),Vector2(.66,.33),Vector2(.65,.33),Vector2(.66,.33),Vector2(.66,.33),Vector2(.66,.33),Vector2(.66,.33),Vector2(.68,.34),Vector2(.65,.34),Vector2(.66,.33),Vector2(.66,.33),Vector2(.66,.33),Vector2(.65,.34),Vector2(.65,.34),Vector2(.65,.34)]
static func folder(species: int) -> String:
	return "res://assets/typing-rabbit-v1" if species==0 else "res://assets/typing-animals-v1/"+IDS[species]
const HATS=[Vector2(.50,.305),Vector2(.50,.255),Vector2(.51,.25),Vector2(.50,.19),Vector2(.50,.25),Vector2(.50,.25),Vector2(.50,.22),Vector2(.50,.25),Vector2(.50,.235),Vector2(.50,.195),Vector2(.50,.24),Vector2(.50,.215),Vector2(.50,.25),Vector2(.50,.19),Vector2(.50,.25),Vector2(.50,.21)]
static func accessory_anchor(species: int,id: String) -> Vector2:
	return HATS[species] if preload("res://scripts/pin.gd").is_hat(id) else PINS[species]
static func frames(species: int) -> Array[Texture2D]:
	var result: Array[Texture2D]=[]
	for pose in ["idle","left","right"]:
		var image=Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(folder(species)+"/"+pose+".png"))!=OK: return []
		if not result.is_empty() and image.get_size()!=Vector2i(result[0].get_size()): return []
		result.append(ImageTexture.create_from_image(image))
	return result
