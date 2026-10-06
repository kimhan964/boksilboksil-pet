extends SceneTree
const Activity=preload("res://scripts/activity.gd")
const Collection=preload("res://scripts/collection.gd")
const Catalog=preload("res://scripts/catalog.gd")
var failures=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
func run() -> void:
	var a=Activity.new()
	a.update(0,0,true)
	for t in range(200,120001,200): a.update(t,1,true)
	check(abs(a.apm-300)<=1,"steady 5/s should equal 300 APM")
	var before=a.apm
	a.update(120000,1,true)
	check(a.apm-before<=2,"one established input must not add 20 APM")
	var weighted=a.weighted_actions
	a.update(177000,0,true)
	check(absf(a.weighted_actions-weighted/exp(1))<.0001,"APMAlert 57-second exponential decay")
	check(a.active_ms==149800,"idle activity grace is exactly 30 seconds after first input at 200 ms")
	a.suspend(180000)
	a.update(240000,100,false)
	check(a.apm==0 and a.total==601 and a.active_ms==149800,"pause does not credit activity")
	var b=Activity.new()
	b.update(0,1,true)
	check(b.apm>0 and b.apm<=6,"APM is numeric immediately without a startup spike")
	b.update(10000,0,true)
	check(b.apm<6,"startup tap decays without a measuring label")
	var c=Collection.new()
	check(not c.equip(0,"pin","ribbon"),"locked cosmetics cannot be equipped")
	c.credit(60,14999)
	check(not c.claim("ribbon"),"time AND actions required")
	c.credit(0,1)
	check(c.claim("ribbon") and not c.claim("ribbon"),"exact milestone and duplicate protection")
	check(c.equip(0,"pin","ribbon"),"claim allows equipment")
	check(c.selected(1,"pin")=="","equipment isolated by species")
	check(not c.equip(0,"skin","ribbon"),"slot validation")
	var restored=Collection.new()
	restored.restore(JSON.parse_string(JSON.stringify(c.serialize())))
	check(restored.selected(0,"pin")=="ribbon" and restored.actions==60,"progress save roundtrip")
	c.credit(10000,3600000)
	for item in c.ITEMS:
		if item.id not in c.claimed: check(c.claim(item.id),"all seven rewards claimable")
	check(c.claimed.size()==7,"complete collection")
	for species in range(16):
		var frames=Catalog.frames(species)
		check(frames.size()==3,"three full cels per species")
		var anchor=Catalog.PINS[species]*frames[0].get_size()
		for frame in frames:
			check(frame.get_image().get_pixelv(Vector2i(anchor)).a>.8,"pin must rest on opaque fur in every pose")
	if failures==0: print("PASS: APMAlert rate/decay/stable numeric start; activity/pause; permanent claims/save/equip; 48 cels and pin anchors")
	if "--capture" in OS.get_cmdline_user_args(): await visual()
	quit(1 if failures else 0)

func visual() -> void:
	var app=preload("res://scripts/main.gd").new()
	# Prevent reading or overwriting the player's save, or opening a real input helper.
	app.set_script(preload("res://tests/visual_app.gd"))
	root.add_child(app)
	var widget=preload("res://scripts/widget.gd").new()
	widget.app=app
	app.widget=widget
	app.add_child(widget)
	var settings=preload("res://scripts/settings.gd").new()
	settings.app=app
	app.settings=settings
	app.add_child(settings)
	var folder="res://builds/review"
	DirAccess.make_dir_recursive_absolute(folder)
	app.bridge.connected=true
	app.activity.update(0,0,true)
	for t in range(200,60001,200): app.activity.update(t,1,true)
	for zoom_ in range(3):
		app.zoom=zoom_
		widget.place()
		widget.refresh_text()
		await process_frame
		# Explicitly leave the PET window click-through: settings must still receive input.
		preload("res://scripts/native_mouse.gd").apply(widget,true,true)
		check(not widget.header.mouse_passthrough,"header remains interactive when pet is click-through")
		var point=widget.settings_button.get_global_rect().get_center()
		for down in [true,false]:
			var event=InputEventMouseButton.new()
			event.position=point
			event.button_index=MOUSE_BUTTON_LEFT
			event.pressed=down
			widget.header.push_input(event,true)
			await process_frame
		check(settings.visible,"header button opens settings at every size")
		settings.hide()
		await RenderingServer.frame_post_draw
		var composed=widget.get_texture().get_image()
		composed.blend_rect(widget.header.get_texture().get_image(),Rect2i(Vector2i.ZERO,widget.header.size),widget.header.position-widget.position)
		composed.save_png(folder+"/widget-%d.png"%zoom_)
	app.zoom=1
	widget.place()
	app.set_size(.7)
	check(is_equal_approx(widget.root.scale.x,.7),"70% size slider")
	app.set_size(1.5)
	check(is_equal_approx(widget.root.scale.x,1.5),"150% size slider")
	app.set_size(1)
	widget.move_enabled=true
	var down=InputEventMouseButton.new()
	down.button_index=MOUSE_BUTTON_LEFT
	down.pressed=true
	widget.on_input(down)
	check(widget.moving,"move tool captures a held pet")
	down.pressed=false
	widget.on_input(down)
	check(app.custom_position and not widget.moving and app.saved_position==widget.position,"drag release persists position")
	app.show_lights=false
	widget.advance(0,0)
	check(not widget.light_tray.visible,"input light setting hides tray")
	app.show_lights=true
	app.custom_position=false
	widget.place()
	app.open_settings()
	await process_frame
	await RenderingServer.frame_post_draw
	settings.get_texture().get_image().save_png(folder+"/settings.png")
	settings.tabs.current_tab=1
	await process_frame
	await RenderingServer.frame_post_draw
	settings.get_texture().get_image().save_png(folder+"/locked.png")
	app.collection.credit(60,15000)
	settings.rebuild()
	await process_frame
	var claim_buttons=settings.find_children("*","Button",true,false)
	for candidate in claim_buttons:
		if candidate.text=="선물 받기":
			candidate.pressed.emit()
			break
	await process_frame
	await process_frame
	check(app.collection.selected(0,"pin")=="ribbon" and is_instance_valid(settings.present),"gift button claims, equips, and opens reveal")
	if is_instance_valid(settings.present): settings.present.queue_free()
	await process_frame
	app.collection.credit(10000,3600000)
	for entry in app.collection.ITEMS:
		if entry.id not in app.collection.claimed: app.collection.claim(entry.id)
	app.collection.equip(0,"pin","ribbon")
	app.collection.equip(0,"skin","rose")
	widget.apply_cosmetics()
	settings.rebuild()
	await process_frame
	await RenderingServer.frame_post_draw
	settings.get_texture().get_image().save_png(folder+"/unlocked.png")
	settings.show_present(app.collection.ITEMS[0])
	await process_frame
	await RenderingServer.frame_post_draw
	settings.get_texture().get_image().save_png(folder+"/gift-arrival.png")
	var gift_card=settings.present.get_child(1)
	for child in gift_card.get_children():
		if child.get_script()==preload("res://scripts/gift_button.gd"): child.pressed.emit()
	await create_timer(.35).timeout
	await RenderingServer.frame_post_draw
	settings.get_texture().get_image().save_png(folder+"/gift-opened.png")
	settings.present.queue_free()
	settings.hide()
	for species in range(16):
		app.species=species
		app.collection.equip(species,"pin","ribbon")
		widget.load_friend()
		var start_scale=widget.sprite.scale
		var start_position=widget.sprite.position
		for j in range(180):
			widget.advance(1.0/60,1)
			check(widget.sprite.scale==start_scale and widget.sprite.position==start_position,"typing never changes scale or anchor")
		widget.advance(1,0)
		await process_frame
		await RenderingServer.frame_post_draw
		widget.get_texture().get_image().save_png(folder+"/species-%02d.png"%species)
	app.queue_free()
	await process_frame
	print("PASS: independent header click while pet passthrough / 3 sizes / 16 species / centered settings and collection renders")
