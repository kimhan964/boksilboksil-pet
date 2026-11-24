extends SceneTree
const Catalog=preload("res://scripts/catalog.gd")
const Pin=preload("res://scripts/pin.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var ids=Pin.GENERATED
	for arg in OS.get_cmdline_user_args():
		if arg=="--new-five": ids=["headphones","sleepcap","friedegg","teacup","mushroom"]
	for page in range(2):
		var viewport=SubViewport.new()
		viewport.size=Vector2i(ids.size()*160,1360)
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var bg=ColorRect.new()
		bg.size=viewport.size
		bg.color=Color("faf5ec")
		viewport.add_child(bg)
		for row in range(8):
			var species=page*8+row
			var frames=Catalog.frames(species)
			for col in range(ids.size()):
				var id=ids[col]
				var sprite=Sprite2D.new()
				sprite.centered=false
				sprite.texture=frames[0]
				sprite.scale=Vector2.ONE*(140.0/frames[0].get_width())
				sprite.position=Vector2(col*160+10,row*170+20)
				sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				var material_=ShaderMaterial.new()
				material_.shader=preload("res://scripts/tone.gdshader")
				material_.set_shader_parameter("balance",Catalog.TONES[species])
				sprite.material=material_
				viewport.add_child(sprite)
				var pin=Pin.new()
				pin.kind=id
				pin.worn=true
				pin.position=sprite.position+Catalog.accessory_anchor(species,id)*140
				pin.scale=Vector2.ONE*.7
				viewport.add_child(pin)
				var label=Label.new()
				label.text=Catalog.IDS[species]+" / "+id
				label.position=Vector2(col*160,row*170)
				label.size=Vector2(160,18)
				label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
				label.add_theme_font_size_override("font_size",12)
				label.add_theme_color_override("font_color",Color("665047"))
				viewport.add_child(label)
				var rect=pin.asset_rect()
				assert((pin.position+rect.position*.7).y>=row*170+18,"hat must not clip")
		await process_frame
		await RenderingServer.frame_post_draw
		var prefix="accessories-new-five" if ids.size()==5 else "accessories"
		viewport.get_texture().get_image().save_png("res://builds/review/%s-%d.png"%[prefix,page])
		viewport.queue_free()
	for id in Pin.GENERATED:
		var im=Pin.texture_for(id).get_image()
		assert(im.get_pixel(0,0).a==0)
		assert(im.get_used_rect().size.x>im.get_width()*.8)
	print("PASS: %d VARCO alpha assets / %d species-accessory layouts / canvas bounds"%[Pin.GENERATED.size(),ids.size()*16])
	quit()
