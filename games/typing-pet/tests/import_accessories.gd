extends SceneTree
# Convert VARCO's neutral preview backdrop into an alpha cutout. Preserve the sources.
func _initialize() -> void:
	var folder="res://assets/accessories-varco-v1/"
	for id in ["jester","crown","beret","ribbon","wizard","sprout"]:
		var source=folder+"source/"+id+".png"
		var im=Image.new()
		assert(im.load(source)==OK)
		im.convert(Image.FORMAT_RGBA8)
		var w=im.get_width()
		var h=im.get_height()
		var seen=PackedByteArray()
		seen.resize(w*h)
		var queue=PackedInt32Array()
		for x in range(w):
			queue.append(x)
			queue.append((h-1)*w+x)
		for y in range(1,h-1):
			queue.append(y*w)
			queue.append(y*w+w-1)
		var i=0
		while i<queue.size():
			var index=queue[i]
			i+=1
			if seen[index]: continue
			seen[index]=1
			var x=index%w
			var y=int(index/w)
			var c=im.get_pixel(x,y)
			if minf(c.r,minf(c.g,c.b))<.70 or maxf(c.r,maxf(c.g,c.b))-minf(c.r,minf(c.g,c.b))>.045: continue
			im.set_pixel(x,y,Color(0,0,0,0))
			if x>0: queue.append(index-1)
			if x<w-1: queue.append(index+1)
			if y>0: queue.append(index-w)
			if y<h-1: queue.append(index+w)
		var bounds=im.get_used_rect()
		assert(bounds.position.x>0 and bounds.position.y>0 and bounds.end.x<w and bounds.end.y<h)
		var cut=im.get_region(bounds.grow(4).intersection(Rect2i(0,0,w,h)))
		assert(cut.save_png(folder+id+".png")==OK)
		print(id," alpha cutout ",cut.get_size())
	quit()
