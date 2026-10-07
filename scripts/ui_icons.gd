extends RefCounted
static var cache={}
static func texture(id: String) -> Texture2D:
	if not cache.has(id):
		var file="res://assets/ui-cozy-v1/"+id+".png"
		if not FileAccess.file_exists(file): return null
		var img=Image.new()
		if img.load_png_from_buffer(FileAccess.get_file_as_bytes(file))!=OK: return null
		cache[id]=ImageTexture.create_from_image(img)
	return cache[id]
static func decorate(button: Button,id: String,size: int=32) -> void:
	button.icon=texture(id)
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",size)
	button.add_theme_constant_override("h_separation",8)
