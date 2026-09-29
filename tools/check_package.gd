extends Node
const View=preload("res://scripts/desktop_pet_view.gd")
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const Main=preload("res://scripts/main.gd")
const Catalog=preload("res://scripts/animal_catalog.gd")
const Food=preload("res://scripts/food_catalog.gd")
const Decor=preload("res://scripts/decor_art.gd")
const Outfits=preload("res://scripts/outfit_catalog.gd")
const State=preload("res://scripts/pet_state.gd")
func _ready() -> void: call_deferred("run")
func run() -> void:
	var failures=0
	var poses=0
	var natural_foods=0
	var outfit_options=0
	var outfit_images=0
	var app=Main.new()
	app.free()
	var icon=Image.load_from_file("res://assets/icon/pet-icon.png")
	if icon==null or icon.is_empty(): failures+=1
	for species in range(16):
		print("PACKAGE_SPECIES=",species)
		if Food.icon_for(species,Catalog.DEFAULT_MEALS[species])==null or Food.title_for(species,Catalog.DEFAULT_MEALS[species]).is_empty(): failures+=1
		else: natural_foods+=1
		for style in range(1,4):
			if Outfits.style_name(species,style).is_empty(): failures+=1
			else: outfit_options+=1
		var motion=Motion.new()
		motion.species=species
		motion.food_id=0
		var view=View.new()
		view.motion=motion
		add_child(view)
		for stage in [0,1,2]:
			motion.growth_stage=stage
			motion.growth_scale=State.GROWTH_SCALES[stage]
			if stage!=1:
				var stage_name="baby" if stage==0 else "adult"
				for style in range(1,4):
					for color in range(6):
						var garment=view.outfit_layer.outfit_texture(species,stage_name,style,color)
						if garment==null or garment.get_width()!=256 or garment.get_height()!=256: failures+=1
						else: outfit_images+=1
			for action in ["idle","eat","drink","doze","playful","wander","look","react"]:
				motion.phase=action
				motion.reaction="greet"
				motion.elapsed=.4
				motion.reaction_time=.4
				poses+=1
				motion.walk_phase=.47
				motion.visit_id="hand_feed"
				view.refresh()
				if view.sprite.texture==null: failures+=1
		view.free()
	if Decor.icon("water")==null: failures+=1
	print("PACKAGE_POSES=",poses," NATURAL_FOODS=",natural_foods," OUTFITS=",outfit_options," OUTFIT_IMAGES=",outfit_images," FAILURES=",failures)
	get_tree().quit(0 if failures==0 else 1)
