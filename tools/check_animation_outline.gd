extends SceneTree
const Outline=preload("res://scripts/animation_outline.gd")
func _initialize() -> void:
	var first=Image.create(100,100,false,Image.FORMAT_RGBA8)
	first.fill(Color.TRANSPARENT)
	first.fill_rect(Rect2i(10,20,20,40),Color.WHITE)
	var second=Image.create(100,100,false,Image.FORMAT_RGBA8)
	second.fill(Color.TRANSPARENT)
	second.fill_rect(Rect2i(70,20,20,40),Color.WHITE)
	var sprite=Sprite2D.new()
	sprite.centered=false
	sprite.texture=ImageTexture.create_from_image(first)
	var material=ShaderMaterial.new()
	material.shader=load("res://scripts/animal_blend.gdshader")
	material.set_shader_parameter("next_frame",ImageTexture.create_from_image(second))
	sprite.material=material
	var left=false
	var right=false
	for point in Outline.blended_points(sprite):
		left=left or point.x<30
		right=right or point.x>70
	if not left or not right:
		push_error("Blend outline omitted one frame")
		quit(1)
		return
	sprite.position=Vector2(250,-100)
	sprite.scale=Vector2(-3,3)
	sprite.rotation=.1
	Outline.fit(sprite,Vector2(102,160),Vector2(204,190))
	for point in Outline.blended_points(sprite):
		if not Rect2(4,4,196,182).has_point(point):
			push_error("Animated outline outside window")
			quit(1)
			return
	sprite.free()
	print("ANIMATION_OUTLINE_CHECK_PASSED")
	quit()
