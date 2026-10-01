extends RefCounted
const Metrics=preload("res://scripts/texture_metrics.gd")
const Art=preload("res://scripts/generated_species_art.gd")
static var neutral_heights: Dictionary={}
const UPRIGHT=["idle","walk","pet","eat","drink","carry","land","wave"]

static func neutral_height(species: int, stage: String) -> float:
	var key="%d/%s"%[species,stage]
	if not neutral_heights.has(key):
		var heights: Array=[]
		for cel in Art.frames(species,stage,"idle"): heights.append(float(Metrics.used_rect(cel).size.y))
		heights.sort()
		neutral_heights[key]=heights[heights.size()/2]
	return neutral_heights[key]

static func pose(species: int, sample: Dictionary, expression: bool=false) -> Dictionary:
	var texture: Texture2D=sample.texture
	var used=Metrics.used_rect(texture)
	var stage: String=sample.stage
	var action: String=sample.action
	var reference=neutral_height(species,stage)
	var correction=Vector2.ONE
	var anchor=Art.ROOT
	if action in UPRIGHT or expression:
		correction=Vector2.ONE*reference/maxf(1.0,used.size.y)
		anchor.y=used.end.y
		if action=="walk" and sample.get("walk_32",false) and int(sample.index)%2==1:
			var original=Art.frames(species,stage,"walk")
			var current=int(sample.index)/2
			var before=Metrics.used_rect(original[current])
			var after=Metrics.used_rect(original[(current+1)%original.size()])
			var first_scale=reference/maxf(1,before.size.y)
			var next_scale=reference/maxf(1,after.size.y)
			var width=(before.size.x*first_scale+after.size.x*next_scale)*.5
			var center=((before.get_center().x-Art.ROOT.x)*first_scale+(after.get_center().x-Art.ROOT.x)*next_scale)*.5
			correction.x=width/maxf(1,used.size.x)
			anchor.x=used.get_center().x-center/correction.x
	else:
		# Crouching/sleeping must retain their authored silhouette. Calibrate the
		# whole sequence from its standing start, rather than enlarging each crouch.
		var first=Art.frames(species,stage,action)[0]
		correction=Vector2.ONE*reference/maxf(1,Metrics.used_rect(first).size.y)
	return {"scale":correction,"anchor":anchor}
