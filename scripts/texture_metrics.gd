extends RefCounted
# Animation textures are immutable. Keep only their small bounds metadata.
static var bounds: Dictionary={}
static func used_rect(texture: Texture2D) -> Rect2i:
	var key=texture.get_instance_id()
	if not bounds.has(key): bounds[key]=texture.get_image().get_used_rect()
	return bounds[key]
