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
		if item.id not in c.claimed: check(c.claim(item.id),"all rewards claimable")
	check(c.claimed.size()==Collection.ITEMS.size(),"complete collection")
	for id in ["headphones","sleepcap","friedegg","teacup","mushroom"]:
		check(c.equip(8,"pin",id),"new accessory equips after reward claim: "+id)
		restored.restore(c.serialize())
		check(restored.selected(8,"pin")==id,"new accessory survives save reload: "+id)
	var cafe=Collection.new()
	cafe.credit(99,299999)
	check(not cafe.claim_order("first_keys") and not cafe.claim_order("coffee_break"),"daily orders require exact thresholds")
	cafe.credit(1,1)
	check(cafe.claim_order("first_keys") and cafe.claim_order("coffee_break") and cafe.stamps==3,"daily orders pay stated stamp amounts")
	check(not cafe.claim_order("first_keys"),"daily reward cannot be claimed twice")
	check(not cafe.buy_light("lavender_keys") and cafe.stamps==3,"unaffordable shop purchase preserves balance")
	check(cafe.buy_light("rose_keys") and cafe.stamps==0 and cafe.light_style=="rose_keys","shop spends stamps once and equips reward")
	check(not cafe.buy_light("rose_keys"),"owned light cannot be purchased twice")
	var cafe_save=Collection.new()
	cafe_save.restore(cafe.serialize())
	check(cafe_save.light_style=="rose_keys" and cafe_save.daily_claims.size()==2,"daily claims and owned rewards survive reload")
	cafe_save.roll_day("2098-01-02")
	check(cafe_save.daily_actions==0 and cafe_save.daily_claims.is_empty() and cafe_save.light_style=="rose_keys","new day resets only daily goals")
	cafe_save.daily_actions=100
	check(cafe_save.claim_order("first_keys"),"new day can earn reward again")
	cafe_save.roll_day("2098-01-01")
	check(not cafe_save.claim_order("first_keys"),"clock rollback cannot reset the same daily claim")
	for species in range(16):
		var frames=Catalog.frames(species)
		check(frames.size()==3,"three full cels per species")
		var anchor=Catalog.PINS[species]*frames[0].get_size()
		for frame in frames:
			check(frame.get_image().get_pixelv(Vector2i(anchor)).a>.8,"pin must rest on opaque fur in every pose")
	if failures==0: print("PASS: APMAlert rate/decay/stable numeric start; activity/pause; permanent claims/save/equip; 48 cels and pin anchors")
	var cached=Catalog.frames(0)
	check(cached[0]==Catalog.frames(0)[0],"reopening same pet reuses texture")
	check(Catalog.frame_cache.size()<=2 and cached[0].get_width()==512,"pet cache is bounded and uses runtime resolution")
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
		check(not widget.header.transparent and not widget.header.mouse_passthrough,"opaque header always receives native input")
		check(widget.header==root and not root.unfocusable,"settings controls must use the focusable primary OS window")
		check(not Rect2i(widget.position,widget.size).intersects(Rect2i(widget.header.position,widget.header.size)),"pet surface must never cover settings controls")
		check(not widget.settings_button.get_global_rect().intersects(widget.gift_button.get_global_rect()),"settings and gift controls must not overlap")
		check(is_equal_approx(widget.settings_button.size.x,widget.gift_button.size.x),"compact action buttons share a width")
		check(not widget.mouse_passthrough and widget.mouse_passthrough_polygon.size()>3,"pet uses a fixed native input region")
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
		var footprint=widget.footprint_for(widget.root.scale.x)
		var composed=Image.create(footprint.x,footprint.y,false,Image.FORMAT_RGBA8)
		composed.blend_rect(widget.get_texture().get_image(),Rect2i(Vector2i.ZERO,widget.size),widget.position-widget.anchor_position)
		var header_image=widget.header.get_texture().get_image()
		header_image.convert(Image.FORMAT_RGBA8)
		composed.blend_rect(header_image,Rect2i(Vector2i.ZERO,widget.header.size),widget.header.position-widget.anchor_position)
		composed.save_png(folder+"/widget-%d.png"%zoom_)
	# Reopen an already-visible minimized settings window through the real entry point.
	app.open_settings()
	settings.mode=Window.MODE_MINIMIZED
	await process_frame
	app.open_settings()
	await process_frame
	check(settings.mode==Window.MODE_WINDOWED,"settings click restores a minimized window")
	settings.mode=Window.MODE_WINDOWED
	settings.hide()
	widget.moving=true
	app.open_settings()
	check(not widget.moving,"opening settings ends a drag whose release was lost")
	settings.hide()
	widget.moving=true
	widget.focus_exited.emit()
	check(not widget.moving,"pet focus loss ends dragging without a release event")
	for cycle in range(4):
		widget.moving=true
		var click=InputEventMouseButton.new()
		click.button_index=MOUSE_BUTTON_LEFT
		click.position=widget.settings_button.get_global_rect().get_center()
		click.pressed=true
		widget.header.push_input(click,true)
		await process_frame
		click.pressed=false
		widget.header.push_input(click,true)
		await process_frame
		check(settings.visible and not widget.moving,"repeated header clicks open settings and stop stale drag")
		settings.hide()
	app.zoom=1
	widget.place()
	app.set_size(.7)
	check(is_equal_approx(widget.root.scale.x,.7),"70% size slider")
	app.set_size(1.5)
	check(is_equal_approx(widget.root.scale.x,1.5),"150% size slider")
	app.set_size(1)
	widget.move_enabled=false
	var down=InputEventMouseButton.new()
	down.button_index=MOUSE_BUTTON_LEFT
	down.pressed=true
	widget.on_input(down)
	check(widget.moving,"move tool captures a held pet")
	var destination=widget.anchor_position-Vector2i(100,60)
	widget.grab_offset=DisplayServer.mouse_get_position()-destination
	widget.advance(0,0)
	check(widget.anchor_position==destination,"drag updates real window position")
	check(widget.header.position==destination+Vector2i(20,0),"header follows drag exactly")
	down.pressed=false
	widget.on_input(down)
	check(app.custom_position and not widget.moving and app.saved_position==widget.anchor_position,"drag release persists position without enabling a mode")
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
	app.open_tutorial()
	await process_frame
	for step in range(app.tutorial.STEPS.size()):
		app.tutorial.step=step
		app.tutorial.render_step()
		await process_frame
		await RenderingServer.frame_post_draw
		app.tutorial.get_texture().get_image().save_png(folder+"/tutorial-%d.png"%step)
	app.tutorial.finish()
	check(app.tutorial_seen and not app.tutorial.visible,"tutorial completion dismisses and records seen flag")
	app.open_tutorial()
	check(app.tutorial.visible and app.tutorial.step==0,"help reopens tutorial at first step")
	app.tutorial.hide()
	var save_probe=preload("res://scripts/main.gd").new()
	save_probe.save_path="res://builds/review/tutorial-save-test.json"
	check(not save_probe.tutorial_seen,"fresh installation needs onboarding")
	save_probe.tutorial_seen=true
	save_probe.save_game()
	save_probe.tutorial_seen=false
	save_probe.load_game()
	check(save_probe.tutorial_seen,"tutorial completion survives save reload")
	save_probe.free()
	app.set_text_size(.9)
	app.set_size(.7)
	check(widget.header_root.scale.x>=1 and widget.detail.get_theme_font_size("font_size")>=12,"small pet preserves at least 12px header text")
	for label_ in settings.find_children("*","Label",true,false):
		check(label_.get_theme_font_size("font_size")>=12,"every setting label respects 12px minimum at 90 percent")
	app.set_size(1.0)
	app.set_text_size(1.0)
	for candidate in settings.find_children("*","Button",true,false):
		if candidate.text=="크게 · 120%": candidate.pressed.emit()
	await create_timer(.07).timeout
	check(widget.root.scale.x>1.0 and widget.root.scale.x<1.2,"size preset interpolates instead of jumping")
	await create_timer(.22).timeout
	check(is_equal_approx(widget.root.scale.x,1.2),"size preset reaches exact target")
	app.set_size(1.0)
	app.set_text_size(1.3)
	await process_frame
	await RenderingServer.frame_post_draw
	settings.get_texture().get_image().save_png(folder+"/settings-large-text.png")
	check(widget.status.get_theme_font_size("font_size")==23,"header respects independent text scale")
	check(not widget.settings_button.get_global_rect().intersects(widget.gift_button.get_global_rect()),"large text keeps action buttons separated")
	app.set_text_size(1.0)
	app.custom_position=true
	app.saved_position=widget.screen_rect.position+Vector2i(120,120)
	widget.place()
	var original_pivot=Vector2(widget.anchor_position)+widget.resize_pivot_offset(widget.root.scale.x)
	var cached_points=widget.base_input_points.duplicate()
	for percent in range(100,131): app.set_size(percent/100.0)
	check((Vector2(widget.anchor_position)+widget.resize_pivot_offset(widget.root.scale.x)).distance_to(original_pivot)<1.0,"continuous resizing preserves bottom center without rounding drift")
	check(widget.base_input_points==cached_points,"resize reuses alpha hit geometry")
	app.custom_position=false
	app.set_size(1.0)
	settings.tabs.current_tab=1
	await process_frame
	await RenderingServer.frame_post_draw
	settings.get_texture().get_image().save_png(folder+"/locked.png")
	app.collection.credit(60,15000)
	widget.refresh_text()
	widget.gift_button.age=30
	widget.refresh_text()
	check(widget.gift_button.modulate==Color.WHITE,"gift arrival must not tint the entire button")
	for control in [widget.settings_button,widget.gift_button]:
		for state_ in ["normal","hover","pressed","hover_pressed","disabled"]:
			check(control.has_theme_stylebox_override(state_),"header explicitly styles "+state_)
			check(control.get_theme_stylebox(state_).bg_color.get_luminance()>.65,"header stays pastel in "+state_)
		check(control.get_theme_stylebox("focus").bg_color.a==0,"focus outline must not darken button fill")
	widget.gift_button.grab_focus()
	check(widget.gift_button.count==1 and widget.gift_button.tooltip_text.contains("선물 1개"),"gift notice persists after 30 seconds until claimed")
	await process_frame
	await RenderingServer.frame_post_draw
	widget.header.get_texture().get_image().save_png(folder+"/gift-notification.png")
	widget.gift_button.toggle_mode=true
	widget.gift_button.set_pressed_no_signal(true)
	await process_frame
	await RenderingServer.frame_post_draw
	var pressed_image=widget.header.get_texture().get_image()
	var sample=Vector2i((widget.gift_button.position+Vector2(65,27))*widget.header_root.scale)
	check(pressed_image.get_pixelv(sample).get_luminance()>.65,"rendered pressed gift background stays light")
	pressed_image.save_png(folder+"/gift-pressed.png")
	widget.gift_button.set_pressed_no_signal(false)
	widget.gift_button.toggle_mode=false
	widget.gift_button.release_focus()
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
	settings.tabs.current_tab=2
	await process_frame
	await RenderingServer.frame_post_draw
	settings.get_texture().get_image().save_png(folder+"/cafe-orders.png")
	for row in settings.cafe_rows:
		if row.order.id in ["first_keys","coffee_break"]: row.button.pressed.emit()
	check(app.collection.stamps==3,"UI order buttons grant stamps")
	var store_scroll=settings.tabs.get_child(2)
	store_scroll.scroll_vertical=10000
	await process_frame
	await RenderingServer.frame_post_draw
	settings.get_texture().get_image().save_png(folder+"/cafe-shop.png")
	for candidate in settings.find_children("*","Button",true,false):
		if candidate.text=="스탬프 3개로 교환": candidate.pressed.emit(); break
	await process_frame
	await process_frame
	check(app.collection.light_style=="rose_keys" and app.collection.stamps==0,"UI shop redeems and equips theme")
	widget.advance(0,1)
	check(widget.lights[widget.light_index].bg_color==app.collection.light_color(),"equipped reward changes live input lights")
	settings.tabs.current_tab=1
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
		check(widget.sprite.material.get_shader_parameter("balance")==Catalog.TONES[species],"every species uses its calibrated tone across poses")
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
	print("PASS: opaque non-overlapping header / static native input region / direct drag / 3 sizes / 16 species / settings and collection renders")
