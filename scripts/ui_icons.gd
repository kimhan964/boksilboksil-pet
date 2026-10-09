extends RefCounted
static var cache={}
static func texture(id: String) -> Texture2D:
	if not cache.has(id):
		var file="res://assets/ui-cozy-v1/"+id+".png"
		if not preload("res://scripts/asset_images.gd").exists(file): return null
		var img=Image.new()
		if preload("res://scripts/asset_images.gd").decode_into(img,file)!=OK: return null
		if id in ["play-toys","cursor-follow","play-guide"]:
			# Match visible size, independent of the generated PNG's transparent margins.
			img=img.get_region(img.get_used_rect())
			var factor=60.0/maxi(img.get_width(),img.get_height())
			img.resize(maxi(1,roundi(img.get_width()*factor)),maxi(1,roundi(img.get_height()*factor)),Image.INTERPOLATE_LANCZOS)
			var tile=Image.create(64,64,false,Image.FORMAT_RGBA8)
			tile.blit_rect(img,Rect2i(Vector2i.ZERO,img.get_size()),(Vector2i(64,64)-img.get_size())/2)
			img=tile
		cache[id]=ImageTexture.create_from_image(img)
	return cache[id]
static func decorate(button: Button,id: String,size: int=32) -> void:
	button.icon=texture(id)
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",size)
	button.add_theme_constant_override("h_separation",8)
