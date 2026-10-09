extends SceneTree
const Prop=preload("res://scripts/desktop_prop.gd")
const Art=preload("res://scripts/decor_art.gd")
var windows=[]
func _initialize() -> void:
	call_deferred("review")
func review() -> void:
	root.size=Vector2i(1100,690)
	root.title="복슬복슬펫 · 동물 전용 소품 색감 검수"
	root.borderless=false
	root.transparent=false
	root.transparent_bg=false
	root.mouse_passthrough=false
	root.unfocusable=false
	var bg=ColorRect.new()
	bg.color=Color("faf8f3")
	bg.size=Vector2(1100,690)
	root.add_child(bg)
	var title=Label.new()
	title.text="전용 물품 · 새 그림체 / 게임 표시 크기"
	title.position=Vector2(24,16)
	title.theme=preload("res://scripts/cozy_ui.gd").theme()
	root.add_child(title)
	var start=0
	var args=OS.get_cmdline_user_args()
	if args.size()>0: start=int(args[0])
	for row in range(8):
		var species=start+row
		var name=Label.new()
		name.text=preload("res://scripts/animal_catalog.gd").NAMES[species]
		name.position=Vector2(20,74+row*72)
		name.theme=title.theme
		root.add_child(name)
		var col=0
		for kind in ["plant","lamp","cushion","shelter"]:
			var prop=Prop.new()
			prop.species=species
			prop.kind=kind
			prop.start_visible=false
			root.add_child(prop)
			var draw=Prop.PropDrawing.new()
			draw.prop=prop
			draw.position=Vector2(200+col*205,55+row*72)
			draw.scale=Vector2(.70,.70)
			root.add_child(draw)
			windows.append(prop)
			col+=1
	await process_frame
	print("SPECIES_PROP_NATIVE_REVIEW: ",start,"..",start+7," actual PropDrawing; no saves touched")
	if args.size()>1:
		await create_timer(.25).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(args[1])
		quit()
