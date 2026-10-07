extends SceneTree
const Catalog=preload("res://scripts/animal_catalog.gd")
func opaque_rect(image: Image) -> Rect2i:
	var left=image.get_width();var top=image.get_height();var right=0;var bottom=0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a>.25:
				left=mini(left,x);top=mini(top,y);right=maxi(right,x+1);bottom=maxi(bottom,y+1)
	return Rect2i(left,top,right-left,bottom-top)
func _initialize() -> void:
	for age in ["adult","baby"]:
		var source=Image.load_from_file("res://assets/emotions-v2/otter/"+age+"-generated.png")
		var master=Image.load_from_file("res://assets/walk-v14/otter/"+age+"-idle.png")
		var reference=opaque_rect(master)
		var cells=[];var bounds=[];var heights=[]
		for i in range(4):
			var cel=source.get_region(Rect2i(i%2*(source.get_width()/2),i/2*(source.get_height()/2),source.get_width()/2,source.get_height()/2))
			cells.append(cel);bounds.append(opaque_rect(cel));heights.append(bounds[-1].size.y)
		heights.sort()
		# One common import camera for the entire atlas, never per-expression
		# runtime body width/area fitting. Only trim, uniform resample and pack.
		var scale=float(reference.size.y)/float(heights[heights.size()/2])
		var atlas=Image.create(1024,256,false,Image.FORMAT_RGBA8)
		var entries=[]
		for i in range(4):
			var region=cells[i].get_region(bounds[i])
			region.resize(roundi(region.get_width()*scale),roundi(region.get_height()*scale),Image.INTERPOLATE_LANCZOS)
			var at=Vector2i(roundi(reference.position.x+reference.size.x*.5-region.get_width()*.5),reference.end.y-region.get_height())
			atlas.blit_rect(region,Rect2i(Vector2i.ZERO,region.get_size()),at+Vector2i(i*256,0))
			entries.append({"kind":["surprised","happy","angry","sleepy"][i],"source_bounds":[bounds[i].position.x,bounds[i].position.y,bounds[i].size.x,bounds[i].size.y],"packed_bounds":[at.x,at.y,region.get_width(),region.get_height()]})
		atlas.save_png("res://assets/emotions-v2/otter/"+age+".png")
		FileAccess.open("res://assets/emotions-v2/otter/"+age+"-import.json",FileAccess.WRITE).store_string(JSON.stringify({"common_import_scale":scale,"reference_height":reference.size.y,"cels":entries},"\t"))
		print(age," common scale ",scale," cels ",entries)
	quit()
