extends RefCounted
const IDS=["rabbit","otter","squirrel","hedgehog","raccoon","fox","bear","owl","cat","puppy","hamster","panda","red_panda","lamb","koala","penguin"]
const NAMES=["모루 · 토끼","보리 · 수달","도토 · 다람쥐","밤이 · 고슴도치","누리 · 너구리","솔 · 여우","두리 · 곰","달 · 부엉이","치즈 · 고양이","쿠키 · 강아지","콩이 · 햄스터","포포 · 판다","단풍 · 레서판다","몽실 · 아기 양","코코 · 코알라","빙글 · 펭귄"]
const HEIGHTS=[1.0,.64,.69,.48,.76,.93,1.04,.64,.82,.73,.46,1.0,.76,.67,.72,.66]
const CYCLE_SECONDS=[2.0,2.4,1.9,2.5,2.4,2.1,2.7,2.5,2.0,1.8,1.7,2.7,2.0,2.2,2.6,2.3]
const DEFAULT_MEALS=[0,4,8,12,16,20,24,28,4,24,10,17,20,9,18,5]
static func path(species: int) -> String:
	return "res://assets/animals/%s.res"%IDS[species]
