extends SceneTree
const Art=preload("res://scripts/generated_species_art.gd")
const Presentation=preload("res://scripts/character_presentation.gd")
const Struggle=preload("res://scripts/struggle_art.gd")
const Catalog=preload("res://scripts/animal_catalog.gd")
func _initialize() -> void: call_deferred("run")
func save_pose(folder: String,name: String,sample: Dictionary,species: int,expression: bool=false) -> Dictionary:
	var fixed=sample.get("pilot",false) or sample.get("smooth_walk",false) or sample.get("fixed_cels",false)
	var pose={"scale":Vector2.ONE,"anchor":Vector2(128,232)} if fixed else Presentation.pose(species,sample,expression)
	sample.texture.get_image().save_png(folder+"/"+name+".png")
	return {"height":sample.height,"scale":[pose.scale.x,pose.scale.y],"anchor":[pose.anchor.x,pose.anchor.y]}
func run() -> void:
	for species in range(16):
		for stage in ["adult","baby"]:
			var folder="res://design/hold-transitions-v1/%s/%s"%[Catalog.IDS[species],stage]
			DirAccess.make_dir_recursive_absolute(folder)
			var m=preload("res://scripts/desktop_pet_motion.gd").new()
			m.species=species
			m.growth_stage=0 if stage=="baby" else 2
			m.rabbit_pilot=species==0
			m.smooth_walk_enabled=species!=0
			var meta={}
			meta.idle=save_pose(folder,"idle",Art.sample(m),species)
			var carry=Art.sample_frame(species,stage,"carry",4)
			meta.carry=save_pose(folder,"carry",carry,species)
			for i in range(4):
				var sample={"texture":Struggle.frames(species,stage)[i*15],"action":"carry","stage":stage,"height":Struggle.data(species).stages[stage].reference_height,"fixed_cels":true}
				meta["kick%d"%i]=save_pose(folder,"kick%d"%i,sample,species)
			for i in [0,3]:
				var sample=carry.duplicate()
				sample.texture=preload("res://scripts/dizzy_art.gd").texture(species,stage,i)
				meta["dizzy%d"%i]=save_pose(folder,"dizzy%d"%i,sample,species,true)
			FileAccess.open(folder+"/poses.json",FileAccess.WRITE).store_string(JSON.stringify(meta,"\t"))
	print("HOLD_ENDPOINT_EXPORT 32 banks; exact presentation calibration")
	quit()
