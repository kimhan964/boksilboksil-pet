extends RefCounted
# All 16 Danjjak species use the new artwork; eye deformation is disabled.
const HARU_NO_EYE_FX=true
const IDS=["rabbit","otter","squirrel","hedgehog","raccoon","fox","bear","owl","cat","puppy","hamster","panda","red_panda","lamb","koala","penguin"]
const NAMES=["모루 · 토끼","보리 · 수달","도토 · 다람쥐","밤이 · 고슴도치","누리 · 너구리","솔 · 여우","두리 · 곰","달 · 부엉이","치즈 · 고양이","쿠키 · 강아지","콩이 · 햄스터","포포 · 판다","단풍 · 레서판다","몽실 · 아기 양","코코 · 코알라","빙글 · 펭귄"]
# Pins sit on the side of the forehead, never on animated paws. Normalized cel coordinates.
const PINS=[Vector2(0.67431640625,0.3157958984375),Vector2(0.627734363079071,0.40234375),Vector2(0.688574194908142,0.3797607421875),Vector2(0.639453113079071,0.329296886920929),Vector2(0.626171886920929,0.361889660358429),Vector2(0.651074230670929,0.372094720602036),Vector2(0.625,0.358715832233429),Vector2(0.62890625,0.36767578125),Vector2(0.637011706829071,0.406420886516571),Vector2(0.637499988079071,0.374658197164536),Vector2(0.619433581829071,0.405444324016571),Vector2(0.641503930091858,0.3760986328125),Vector2(0.638867199420929,0.354394525289536),Vector2(0.640820324420929,0.346386730670929),Vector2(0.627734363079071,0.394604504108429),Vector2(0.639355480670929,0.374829113483429)]
static func folder(species: int) -> String:
	return "res://assets/typing-haru-v1/"+IDS[species]
const HATS=[Vector2(0.5,0.2412109375),Vector2(0.500244140625,0.318359375),Vector2(0.556640625,0.2880859375),Vector2(0.5,0.2001953125),Vector2(0.50244140625,0.2626953125),Vector2(0.45556640625,0.3046875),Vector2(0.500244140625,0.2578125),Vector2(0.50244140625,0.259765625),Vector2(0.50439453125,0.30859375),Vector2(0.50146484375,0.27734375),Vector2(0.50048828125,0.3076171875),Vector2(0.50341796875,0.2724609375),Vector2(0.506591796875,0.2587890625),Vector2(0.51025390625,0.2275390625),Vector2(0.501953125,0.2919921875),Vector2(0.503662109375,0.263671875)]
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
	Vector4(0,1,0,0), # panda v2: gentle taupe palette baked into all full cels
	Vector4(0,1,0,0), # red panda v2: muted cinnamon, no double color grading
	Vector4(-.025,.95,-.030,.004), # lamb
	Vector4(.028,.94,-.010,.010), # koala: warm grey
	Vector4(.080,.94,-.012,.010)] # penguin: soften charcoal
static func accessory_anchor(species: int,id: String) -> Vector2:
	return HATS[species] if preload("res://scripts/pin.gd").is_hat(id) else PINS[species]
const TEXTURE_SIZE=512
static var frame_cache: Dictionary={}
static var recent_species: Array[int]=[]
static func frames(species: int) -> Array[Texture2D]:
	if frame_cache.has(species):
		recent_species.erase(species)
		recent_species.append(species)
		return frame_cache[species]
	var result: Array[Texture2D]=[]
	for pose in ["idle","left","right"]:
		var image=Image.new()
		var path=folder(species)+"/"+pose+".png"
		if not FileAccess.file_exists(path): path=folder(species)+"/idle.png"
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK: return []
		if image.get_width()>TEXTURE_SIZE: image.resize(TEXTURE_SIZE,TEXTURE_SIZE,Image.INTERPOLATE_LANCZOS)
		if not result.is_empty() and image.get_size()!=Vector2i(result[0].get_size()): return []
		image.generate_mipmaps()
		result.append(ImageTexture.create_from_image(image))
	frame_cache[species]=result
	recent_species.append(species)
	while recent_species.size()>2: frame_cache.erase(recent_species.pop_front())
	return result

# Measured from aligned Danjjak idle images; see builds/review/haru-all-report.json.
const EYES=[Vector4(0.37548828125,0.46337890625,0.62451171875,0.46337890625),Vector4(0.4091796875,0.5673828125,0.59130859375,0.5673828125),Vector4(0.46240234375,0.55908203125,0.65087890625,0.55908203125),Vector4(0.400390625,0.578125,0.599609375,0.578125),Vector4(0.4140625,0.55517578125,0.5908203125,0.55517578125),Vector4(0.31591796875,0.427734375,0.59521484375,0.5849609375),Vector4(0.4111328125,0.55517578125,0.58935546875,0.55517578125),Vector4(0.412109375,0.5771484375,0.5927734375,0.5771484375),Vector4(0.40966796875,0.59716796875,0.59912109375,0.59716796875),Vector4(0.404296875,0.564453125,0.5986328125,0.564453125),Vector4(0.41552734375,0.59619140625,0.58544921875,0.59619140625),Vector4(0.40478515625,0.57763671875,0.60205078125,0.57763671875),Vector4(0.412109375,0.541015625,0.60107421875,0.541015625),Vector4(0.4169921875,0.576171875,0.603515625,0.576171875),Vector4(0.412109375,0.59423828125,0.591796875,0.59423828125),Vector4(0.40673828125,0.59033203125,0.6005859375,0.59033203125)]
