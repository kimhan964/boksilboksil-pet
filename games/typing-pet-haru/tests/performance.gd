extends SceneTree
const Catalog=preload("res://scripts/catalog.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var start=Time.get_ticks_usec()
	var bytes=0
	for species in range(16):
		for texture in Catalog.frames(species): bytes+=texture.get_image().get_data_size()
	var cold_ms=(Time.get_ticks_usec()-start)/1000.0
	start=Time.get_ticks_usec()
	for i in range(12): Catalog.frames(0)
	print("PERF ",JSON.stringify({"all_species_decode_ms":cold_ms,"twelve_same_pet_loads_ms":(Time.get_ticks_usec()-start)/1000.0,"all_cel_rgba_mipmap_bytes":bytes}))
	quit()
