extends SceneTree
const Catalog=preload("res://scripts/catalog.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var viewport=SubViewport.new()
	viewport.size=Vector2i(660,500)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var bg=ColorRect.new()
	bg.size=viewport.size
	bg.color=Color("faf5ec")
	viewport.add_child(bg)
	for row in range(2):
		var im=Image.load_from_file("res://assets/accessories-varco-v%d/beret.png"%(row+1))
		im.generate_mipmaps()
		var texture=ImageTexture.create_from_image(im)
		for col in range(3):
			var species=[0,5,8][col]
			var pet=Sprite2D.new()
			pet.centered=false
			pet.texture=Catalog.frames(species)[0]
			pet.scale=Vector2.ONE*200/pet.texture.get_width()
			pet.position=Vector2(col*220+10,row*250+38)
			pet.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			var mat=ShaderMaterial.new()
			mat.shader=preload("res://scripts/tone.gdshader")
			mat.set_shader_parameter("balance",Catalog.TONES[species])
			pet.material=mat
			viewport.add_child(pet)
			var hat=Sprite2D.new()
			hat.texture=texture
			hat.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			hat.scale=Vector2.ONE*(44.0 if row==0 else 50.0)/texture.get_width()
			hat.position=pet.position+Catalog.HATS[species]*200+Vector2(0,4-texture.get_height()*hat.scale.y/2)
			viewport.add_child(hat)
			var label=Label.new()
			label.text=("OLD / " if row==0 else "GPT 2.5 / ")+Catalog.IDS[species]
			label.position=Vector2(col*220+25,row*250+8)
			label.add_theme_color_override("font_color",Color("665047"))
			viewport.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://builds/review/accessory-pilot.png")
	quit()
