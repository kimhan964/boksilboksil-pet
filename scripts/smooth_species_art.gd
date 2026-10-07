extends RefCounted
## Whole-image 60-cel walking banks, calibrated once for each age.
const Catalog=preload("res://scripts/animal_catalog.gd")
static var manifests={}
static var banks={}
static var version=14
static func asset_version(species: int) -> int:
	return 14
static func select_version(value: int) -> void:
	version=14
	manifests.clear()
	banks.clear()
static func stage(motion) -> String:
	return "baby" if (motion.growth_stage==0 if motion.growth_stage>=0 else motion.growth_scale<.7) else "adult"
static func data(species: int) -> Dictionary:
	if not manifests.has(species):
		var path="res://assets/walk-v%d/"%asset_version(species)+Catalog.IDS[species]+"/manifest.json"
		manifests[species]=JSON.parse_string(FileAccess.get_file_as_string(path)) if preload("res://scripts/asset_images.gd").exists(path) else {}
	return manifests[species]
static func enabled(motion) -> bool:
	return motion.smooth_walk_enabled and motion.species>0 and data(motion.species).get("stages",{}).has(stage(motion))
static func spec(motion) -> Dictionary:
	var metadata: Dictionary=data(motion.species).stages[stage(motion)]
	if version<12: return metadata
	# Keep authored bank timing as provenance; runtime cadence is species based.
	var playback=metadata.duplicate()
	playback.authored_cycle_seconds=float(metadata.cycle_seconds)
	playback.cycle_seconds=preload("res://scripts/gait_profile.gd").playback_cycle(motion.species,float(metadata.cycle_seconds))
	return playback
static func frames(species: int,age: String,action: String="walk") -> Array:
	var key="%d/%s/%s"%[species,age,action]
	if not banks.has(key):
		# Retain only the selected pet's banks.
		for old in banks.keys():
			if not str(old).begins_with(str(species)+"/"): banks.erase(old)
		var metadata=data(species).stages[age]
		var path="res://assets/walk-v%d/"%asset_version(species)+Catalog.IDS[species]+"/"+str(metadata.idle_file if action=="idle" else metadata.file)
		var image=Image.new()
		if preload("res://scripts/asset_images.gd").decode_into(image,path)!=OK: return []
		var result=[]
		if action=="idle": result.append(ImageTexture.create_from_image(image))
		else:
			for i in range(int(metadata.count)):
				result.append(ImageTexture.create_from_image(image.get_region(Rect2i(i%8*256,i/8*256,256,256))))
		preload("res://scripts/animal_tone.gd").register(result,species,age)
		banks[key]=result
	return banks[key]
static func sample(motion,action: String) -> Dictionary:
	var age=stage(motion)
	var cels=frames(motion.species,age,action)
	var index=mini(cels.size()-1,int(fposmod(motion.walk_phase,1.0)*cels.size())) if action=="walk" else 0
	return {"texture":cels[index],"next_texture":cels[index],"frame_mix":0.0,"action":action,"stage":age,"index":index,
		"height":float(spec(motion).reference_height),"mouth":Vector2(158,124),"hand":Vector2(148,175),"smooth_walk":true,"bank":action,"root_offset":Vector2.ZERO}
