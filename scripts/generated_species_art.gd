extends RefCounted
## VARCO full-character cels for all species, with separate baby/adult masters.
## Uses complete raster frames only; no anatomical part rig or recomposition.
const Catalog=preload("res://scripts/animal_catalog.gd")
const WalkArt=preload("res://scripts/walk_art.gd")
const ROOT=Vector2(128,232)
const SIZE=256
static var manifests: Dictionary={}
static var cache: Dictionary={}
static var dressed_cache: Dictionary={}

static func asset_root(species: int) -> String:
	var v3="res://assets/species-v3/"+Catalog.IDS[species]
	if FileAccess.file_exists(v3+"/manifest.json"):
		return v3
	if species==0:
		return "res://assets/rabbit-v3"
	return "res://assets/species-v2/"+Catalog.IDS[species]

static func data(species: int) -> Dictionary:
	if not manifests.has(species):
		manifests[species]=JSON.parse_string(FileAccess.get_file_as_string(asset_root(species)+"/manifest.json"))
	return manifests[species]

static func stage_name(motion) -> String:
	var baby=motion.growth_stage==0 if motion.growth_stage>=0 else motion.growth_scale<.7
	return "baby" if baby else "adult"

static func frames(species: int, stage: String, action: String) -> Array:
	var key=str(species)+"/"+stage+"/"+action
	if not cache.has(key):
		var spec=data(species).stages[stage].sequences[action]
		var sheet=Image.new()
		if sheet.load_png_from_buffer(FileAccess.get_file_as_bytes(asset_root(species)+"/"+str(spec.file)))!=OK: return []
		var sequence: Array=[]
		var columns=int(spec.get("columns",8))
		for i in range(int(spec.count)):
			sequence.append(ImageTexture.create_from_image(sheet.get_region(Rect2i(i%columns*SIZE,i/columns*SIZE,SIZE,SIZE))))
		cache[key]=sequence
	return cache[key]

static func dressed_frames(species: int, stage: String, style: int, action: String) -> Array:
	var key="%s/%s/%s/%s"%[Catalog.IDS[species],stage,["cape","vest","sweater"][style-1],action]
	if not dressed_cache.has(key):
		var path="res://assets/outfits-dressed-v2/"+key+".png"
		if not FileAccess.file_exists(path): return []
		var strip=Image.new()
		if strip.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK: return []
		if strip==null or strip.get_width()!=SIZE*16 or strip.get_height()!=SIZE: return []
		var sequence: Array=[]
		for i in range(16):
			sequence.append(ImageTexture.create_from_image(strip.get_region(Rect2i(i*SIZE,0,SIZE,SIZE))))
		dressed_cache[key]=sequence
	return dressed_cache[key]

static func action_for(motion) -> String:
	if motion.carried: return "carry"
	if motion.landing_left>0: return "land"
	if motion.phase=="drink" and motion.visit_id=="water": return "sniff"
	match motion.phase:
		"wander","chase","return","visit":
			return "idle" if motion.held else "walk"
		"eat","drink","look","sniff","stretch","groom","rub":
			return motion.phase
		"doze": return "sleep"
		"relax": return "rest"
		"pet","cuddle": return "pet"
		"signature","playful": return "jump"
		"askplay","greet": return "wave"
		"inspect","ball_ready": return "look"
		"prop_use": return "toy" if motion.visit_id in ["plant","acorn"] else "rest"
		"react":
			match motion.reaction:
				"pet","yum","full","gift","nest": return "pet"
				"greet","askplay": return "wave"
				"inspect","anticipate": return "look"
	if motion.joy_left>0: return "pet"
	return "idle"

static func consumption_phase(action: String, phase: float) -> float:
	# Generated cels are evenly spaced, but natural eating is not: approach,
	# repeated bites/sips, swallow, then a short neutral pause.
	if action=="eat":
		if phase<.16: return remap(phase,0.0,.16,0.0,.25)
		if phase<.68: return remap(phase,.16,.68,.25,.75)
		if phase<.84: return remap(phase,.68,.84,.75,.94)
		return .97
	if action=="drink":
		if phase<.20: return remap(phase,0.0,.20,0.0,.31)
		if phase<.72: return remap(phase,.20,.72,.31,.75)
		if phase<.86: return remap(phase,.72,.86,.75,.94)
		return .97
	return phase

static func sample(motion) -> Dictionary:
	var species: int=motion.species
	var stage=stage_name(motion)
	var action=action_for(motion)
	var sequence="carry" if action=="land" else action
	var spec=data(species).stages[stage].sequences[sequence]
	var smooth_walk=action=="walk" and not (motion.outfit_style>0 and motion.outfit_color==0) and WalkArt.frames(species,stage).size()==32
	var count=32 if smooth_walk else int(spec.count)
	var time=motion.reaction_time if motion.phase=="react" else motion.elapsed
	if action=="carry": time=motion.carry_elapsed
	var phase=fposmod(time/float(spec.duration),1.0)
	if motion.phase=="drink" and motion.visit_id=="water": phase=fposmod(time/3.2,1.0)
	if action=="walk": phase=fposmod(motion.walk_phase,1.0)
	if action=="stretch": phase=clampf(time/float(spec.duration),0,.99999)
	if action in ["eat","drink"]: phase=consumption_phase(action,phase)
	var index=mini(count-1,int(phase*count))
	if action=="idle":
		if count>8:
			index=mini(count-1,int(phase*count))
		else:
			var elapsed=fposmod(time,4.8)
			var holds=[1.8,.9,.06,.09,.06,.2,.7,.99]
			index=7
			for i in range(8):
				if elapsed<holds[i]:
					index=i
					break
				elapsed-=holds[i]
	elif action=="sleep":
		var quarter=maxi(2,count/4)
		if time<.7: index=mini(quarter-1,int(time/.7*quarter))
		elif not motion.stay_after_visit and motion.action_left<.45: index=count-quarter+mini(quarter-1,int((.45-motion.action_left)/.45*quarter))
		else: index=quarter+int(time/.45)%maxi(2,count-quarter*2)
	elif action=="rest":
		var quarter=maxi(2,count/4)
		if time<.7: index=mini(quarter-1,int(time/.7*quarter))
		elif motion.action_left>0 and motion.action_left<.3: index=count-1
		else: index=quarter+int(time/.55)%maxi(2,count-quarter*2)
	elif action=="carry":
		var quarter=maxi(2,count/4)
		index=mini(quarter-1,int(time/.18*quarter)) if time<.18 else quarter+int((time-.18)/.16)%maxi(2,count-quarter*2)
	elif action=="land":
		var quarter=maxi(2,count/4)
		var landing_duration=motion.DIZZY_LANDING if motion.phase=="dizzy" else .24
		index=count-quarter+mini(quarter-1,int(clampf(1-motion.landing_left/landing_duration,0,.99999)*quarter))
	elif motion.phase=="react" and action in ["pet","wave"]:
		index=mini(count-1,int(clampf(time/maxf(.01,motion.reaction_duration),0,.99999)*count))
	var result=sample_frame(species,stage,sequence,index >> 1 if smooth_walk else index)
	if smooth_walk:
		result.texture=WalkArt.texture(species,stage,index)
		result.index=index
	apply_dressed(result,motion)
	result.action=action
	return result

static func apply_dressed(result: Dictionary, motion) -> void:
	if motion.outfit_style<=0 or motion.outfit_color!=0: return
	var action: String=result.action
	var stage: String=result.stage
	var species: int=motion.species
	var dressed=dressed_frames(species,stage,int(motion.outfit_style),action)
	if dressed.size()!=frames(species,stage,action).size(): return
	result.texture=dressed[int(result.index)]
	result.dressed=true

static func sample_frame(species: int, stage: String, action: String, index: int) -> Dictionary:
	var spec=data(species).stages[stage].sequences[action]
	var anchor=spec.anchors[index]
	return {"texture":frames(species,stage,action)[index],"action":action,"stage":stage,
		"index":index,"height":float(data(species).stages[stage].reference_height),
		"mouth":Vector2(anchor.mouth[0],anchor.mouth[1]),"hand":Vector2(anchor.hand[0],anchor.hand[1])}
