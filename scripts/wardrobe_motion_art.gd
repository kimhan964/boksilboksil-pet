extends RefCounted
## Whole-character costume cels. Enabled only by the isolated wardrobe review.
## Geometry is evaluated from the original art before swapping the texture.
const ROOT="res://assets/wardrobe-motion-v3/"
const SPECIES={0:"rabbit",1:"otter",2:"squirrel",3:"hedgehog",4:"raccoon",5:"fox",6:"bear",7:"owl",8:"cat",9:"puppy",10:"hamster",11:"panda",12:"red_panda",13:"lamb",14:"koala",15:"penguin"}
const STYLES=["vest","knit","apron"]
const EMOTIONS=["surprised","happy","angry","sleepy"]
static var manifests: Dictionary={}
static var cache: Dictionary={}
static var loaded_style=""

static func data(species: int=0) -> Dictionary:
	if not SPECIES.has(species): return {}
	if not manifests.has(species):
		var path=ROOT+SPECIES[species]+"/adult/manifest.json"
		manifests[species]=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return manifests[species]

static func style_for(motion) -> String:
	if not ProjectSettings.get_setting("testing/wardrobe_v3",false): return ""
	if not SPECIES.has(motion.species): return ""
	if motion.species==0 and not motion.rabbit_pilot: return ""
	if motion.species>0 and not motion.smooth_walk_enabled: return ""
	var baby=motion.growth_stage==0 if motion.growth_stage>=0 else motion.growth_scale<.7
	if baby: return ""
	var style=str(motion.get_meta("wardrobe_v3_style",""))
	return style if style in STYLES else ""

static func frames(style: String,bank: String,species: int=0) -> Array:
	var cache_key=str(species)+"/"+style
	if loaded_style!=cache_key:
		cache.clear()
		loaded_style=cache_key
	if not data(species).get("styles",{}).get(style,{}).has(bank): return []
	if not cache.has(bank):
		var spec=data(species).styles[style][bank]
		var image=Image.new()
		if preload("res://scripts/asset_images.gd").decode_into(image,ROOT+SPECIES[species]+"/adult/"+spec.file)!=OK: return []
		var cels=[]
		var columns=int(spec.columns)
		var side=int(spec.get("cell_size",256))
		for i in range(int(spec.count)):
			cels.append(ImageTexture.create_from_image(image.get_region(Rect2i(i%columns*side,i/columns*side,side,side))))
		cache[bank]=cels
	return cache[bank]

static func prewarm(style: String,species: int=0) -> void:
	if not style in STYLES: return
	for bank in data(species).get("styles",{}).get(style,{}):
		for cel in frames(style,bank,species):
			preload("res://scripts/animation_outline.gd").local_hull(cel)

static func resolve(motion,sample: Dictionary) -> Dictionary:
	var bank=str(sample.get("bank",""))
	var index=int(sample.get("index",0))
	if sample.get("action","")=="expression":
		bank="emotions"
		index=EMOTIONS.find(motion.reaction) if motion.phase=="react" else 1
	elif sample.get("action","")=="dizzy" and not sample.get("hold_visual",false):
		bank="dizzy"
		var age=maxf(0.0,motion.elapsed-motion.DIZZY_LANDING)
		index=0 if age<.5 else (3 if age>3.8 else (1+int((age-.5)/.48)%2))
	elif bank=="struggle-v1": bank="struggle"
	elif not sample.get("pilot",false) and not sample.get("smooth_walk",false) and not bank.begins_with("hold-"):
		return {}
	return {"bank":bank,"index":index}

static func apply(view) -> void:
	var style=style_for(view.motion)
	if style.is_empty(): return
	var pose=resolve(view.motion,view.generated_sample)
	if pose.is_empty(): return
	var cels=frames(style,pose.bank,view.motion.species)
	if cels.is_empty() or pose.index<0 or pose.index>=cels.size(): return
	var texture: Texture2D=cels[pose.index]
	view.sprite.texture=texture
	var metadata=data(view.motion.species).styles[style][pose.bank]
	var padding=metadata.get("padding",[0,0])
	var offset=Vector2(padding[0],padding[1])
	# Extra transparent canvas keeps wide tails inside calibrated hold bridges.
	# Subtract its transformed origin so the actual body and grip do not move.
	view.sprite.position-=view.sprite.transform.x*offset.x+view.sprite.transform.y*offset.y
	view.sprite.material.set_shader_parameter("next_frame",texture)
	view.sprite.material.set_shader_parameter("frame_mix",0.0)
	# Do not recolor cream/peach/sage clothing through the original fur palette.
	preload("res://scripts/animal_tone.gd").apply(view.sprite.material,texture)
	view.generated_sample.wardrobe_v3=true
	view.generated_sample.wardrobe_bank=pose.bank
	view.generated_sample.wardrobe_style=style
	view.generated_sample.wardrobe_padding=offset

static func release_other_species(species: int) -> void:
	if not loaded_style.begins_with(str(species)+"/"):
		cache.clear()
		loaded_style=""
