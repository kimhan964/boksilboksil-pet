extends SceneTree
const Catalog=preload("res://scripts/animal_catalog.gd")
func _initialize() -> void:
	var stage="after"
	if not OS.get_cmdline_user_args().is_empty(): stage=OS.get_cmdline_user_args()[0]
	for id in Catalog.IDS:
		var sheet=Image.create(1440,1100,false,Image.FORMAT_RGBA8)
		sheet.fill(Color("324454"))
		var row=0
		for bank in ["base0","base1","base2","base3","habit","carry","sleep","reaction"]:
			var directory="res://builds/frame-audit/%s/%s/%s"%[stage,id,bank]
			if not DirAccess.dir_exists_absolute(directory):
				row+=1
				continue
			var files=DirAccess.get_files_at(directory)
			files.sort()
			var index=0
			for file in files:
				var cell=Image.new()
				cell.load_png_from_buffer(FileAccess.get_file_as_bytes(directory+"/"+file))
				var scale=minf(84.0/cell.get_width(),92.0/cell.get_height())
				cell.resize(maxi(1,int(cell.get_width()*scale)),maxi(1,int(cell.get_height()*scale)),Image.INTERPOLATE_BILINEAR)
				var origin=Vector2i((index%16)*90+(90-cell.get_width())/2,(row+int(index/16))*100+(96-cell.get_height())/2)
				sheet.blend_rect(cell,Rect2i(Vector2i.ZERO,cell.get_size()),origin)
				index+=1
			row+=ceili(files.size()/16.0)
		# 7 banks plus four reaction rows = 11 rows; allocate the full page.
		sheet.save_png("res://builds/frame-audit/%s/%s-contact.png"%[stage,id])
	quit()
