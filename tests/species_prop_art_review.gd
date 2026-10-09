extends SceneTree
const Art=preload("res://scripts/decor_art.gd")
const IDs=["rabbit","otter","squirrel","hedgehog","raccoon","fox","bear","owl","cat","puppy","hamster","panda","red_panda","lamb","koala","penguin"]
func _initialize() -> void:
	var out=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var rows=[]
	for species in range(16):
		for kind in ["plant","lamp","cushion","shelter"]:
			var texture=Art.icon(kind,species)
			assert(texture!=null,"Missing species prop: "+IDs[species]+"/"+kind)
			var img=texture.get_image()
			assert(img!=null and not img.is_empty())
			assert(img.get_used_rect().has_area())
			var raw=Image.new()
			var path="res://assets/species-props-v2/"+IDs[species]+"-"+kind+".png"
			if FileAccess.file_exists(path):
				assert(raw.load_png_from_buffer(FileAccess.get_file_as_bytes(path))==OK)
				assert(raw.get_size()==img.get_size(),"Older atlas fallback used: "+path)
				var used=img.get_used_rect()
				assert(used.position.x>=4 and used.position.y>=4 and used.end.x<=img.get_width()-4 and used.end.y<=img.get_height()-4,"Sprite margin clipped: "+path)
			img.save_png(out+"/"+IDs[species]+"-"+kind+".png")
			rows.append({"animal":IDs[species],"kind":kind,"width":img.get_width(),"height":img.get_height()})
	var f=FileAccess.open(out+"/report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"\t"))
	print("SPECIES_PROP_ART: 64 textures decoded and exported")
	quit()
