extends SceneTree
const Catalog=preload("res://scripts/animal_catalog.gd")
const Baby=preload("res://scripts/baby_art.gd")
const Reactions=preload("res://scripts/reaction_art.gd")

func save_reference(texture: Texture2D, target: String) -> void:
	var source=texture.get_image()
	var used=source.get_used_rect()
	if not used.has_area(): return
	var crop=source.get_region(used)
	var factor=minf(760.0/crop.get_width(),760.0/crop.get_height())
	crop.resize(roundi(crop.get_width()*factor),roundi(crop.get_height()*factor),Image.INTERPOLATE_LANCZOS)
	var canvas=Image.create(1024,1024,false,Image.FORMAT_RGBA8)
	canvas.fill(Color("00ffff"))
	var at=Vector2i((1024-crop.get_width())/2,900-crop.get_height())
	canvas.blend_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),at)
	canvas.save_png(target)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://design/all-species-v1/references")
	for species in range(1,Catalog.IDS.size()):
		var folder="res://design/all-species-v1/references/"+Catalog.IDS[species]
		DirAccess.make_dir_recursive_absolute(folder)
		var baby=Baby.frames(species)
		var adult=Reactions.frames(species)
		if baby.size()>=1: save_reference(baby[0],folder+"/baby.png")
		if adult.size()>=1: save_reference(adult[0],folder+"/adult.png")
		print("REFERENCE_EXPORTED ",Catalog.IDS[species])
	quit()
