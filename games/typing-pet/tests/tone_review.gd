extends SceneTree
const Catalog=preload("res://scripts/catalog.gd")
var reports=[]
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var captures=[]
	for corrected in [false,true]:
		var viewport=SubViewport.new()
		viewport.size=Vector2i(960,1040)
		viewport.transparent_bg=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var bg=ColorRect.new()
		bg.size=viewport.size
		bg.color=Color("faf5ec")
		viewport.add_child(bg)
		for species in range(16):
			var sprite=Sprite2D.new()
			sprite.centered=false
			sprite.texture=Catalog.frames(species)[0]
			sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.scale=Vector2.ONE*(220.0/sprite.texture.get_width())
			sprite.position=Vector2(species%4*240+10,int(species/4)*260+28)
			var mat=ShaderMaterial.new()
			mat.shader=preload("res://scripts/tone.gdshader")
			mat.set_shader_parameter("balance",Catalog.TONES[species] if corrected else Vector4(0,1,0,0))
			sprite.material=mat
			viewport.add_child(sprite)
			var title=Label.new()
			title.text=Catalog.IDS[species]+(" (reference)" if species==5 else "")
			title.position=Vector2(species%4*240,int(species/4)*260)
			title.size=Vector2(240,25)
			title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			title.add_theme_font_size_override("font_size",15)
			title.add_theme_color_override("font_color",Color("655149"))
			viewport.add_child(title)
		await process_frame
		await RenderingServer.frame_post_draw
		var capture=viewport.get_texture().get_image()
		captures.append(capture)
		capture.save_png("res://builds/review/tones-"+("after" if corrected else "before")+".png")
		viewport.queue_free()
	for species in range(16):
		var base=Vector2i(species%4*240,int(species/4)*260)
		var max_difference=0.0
		for y in range(198,244):
			for x in range(10,230):
				var a=captures[0].get_pixelv(base+Vector2i(x,y))
				var b=captures[1].get_pixelv(base+Vector2i(x,y))
				max_difference=maxf(max_difference,Vector3(a.r-b.r,a.g-b.g,a.b-b.b).length())
		assert(max_difference<.001,"keyboard must retain its colors")
		if species==5:
			var rect=Rect2i(base,Vector2i(240,260))
			assert(captures[0].get_region(rect).get_data()==captures[1].get_region(rect).get_data(),"fox reference must be unchanged")
	print("PASS: 16 calibrated materials; fox unchanged; all keyboard regions unchanged")
	quit()
