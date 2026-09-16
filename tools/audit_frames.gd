extends SceneTree
const Catalog=preload("res://scripts/animal_catalog.gd")
const BaseArt=preload("res://scripts/base_art.gd")
const Habits=preload("res://scripts/habit_art.gd")
const Carry=preload("res://scripts/carry_art.gd")
const Sleep=preload("res://scripts/sleep_art.gd")
const Reactions=preload("res://scripts/reaction_art.gd")
var stage="before"
var total=0
func export_bank(id: String, bank: String, frames: Array) -> void:
	var path="res://builds/frame-audit/%s/%s/%s"%[stage,id,bank]
	DirAccess.make_dir_recursive_absolute(path)
	for i in range(frames.size()):
		frames[i].get_image().save_png(path+"/%03d.png"%i)
		total+=1
func _initialize() -> void:
	if not OS.get_cmdline_user_args().is_empty(): stage=OS.get_cmdline_user_args()[0]
	for species in range(16):
		var id=Catalog.IDS[species]
		var animal=BaseArt.resource(species)
		for bank in range(animal.frames.size()): export_bank(id,"base%d"%bank,animal.frames[bank])
		export_bank(id,"habit",Habits.frames(species))
		export_bank(id,"carry",Carry.frames(species))
		export_bank(id,"sleep",Sleep.frames(species))
		export_bank(id,"reaction",Reactions.frames(species))
		print("EXPORTED ",id)
	print("TOTAL_FRAMES=",total)
	quit()
