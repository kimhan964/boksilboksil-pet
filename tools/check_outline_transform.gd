extends SceneTree
const Outline=preload("res://scripts/animation_outline.gd")
func _initialize() -> void:
	var textures=[]
	for size in [Vector2i(32,48),Vector2i(64,24)]:
		var image=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		image.fill_rect(Rect2i(4,5,size.x-9,size.y-11),Color.WHITE)
		textures.append(ImageTexture.create_from_image(image))
	var sprite=Sprite2D.new()
	sprite.texture=textures[0]
	sprite.material=ShaderMaterial.new()
	sprite.material.shader=preload("res://scripts/animal_blend.gdshader")
	sprite.material.set_shader_parameter("next_frame",textures[1])
	var failures=0
	for i in range(128):
		sprite.rotation=i*.05
		sprite.scale=Vector2(-.62 if i%2 else 1.0,.8+i*.001)
		sprite.position=Vector2(102,160)
		var expected=PackedVector2Array()
		for texture in textures:
			var ratio=sprite.texture.get_size()/texture.get_size()
			for point in Outline.local_hull(texture): expected.append(sprite.transform*(point*ratio))
		var actual=Outline.blended_points(sprite)
		if actual.size()!=expected.size(): failures+=1
		else:
			for j in range(actual.size()):
				if actual[j].distance_to(expected[j])>.0001: failures+=1
	sprite.free()
	print("OUTLINE_TRANSFORMS=128 FAILURES=",failures)
	quit(0 if failures==0 else 1)
