extends Node
var shutting_down=false
const Catalog=preload("res://scripts/catalog.gd")
var collection=preload("res://scripts/collection.gd").new()
var report=preload("res://scripts/typing_report.gd").new()
var activity=preload("res://scripts/activity.gd").new()
var bridge=preload("res://scripts/typing_input.gd").new()
var skin=preload("res://scripts/cozy_ui.gd").theme()
var commerce_enabled=bool(ProjectSettings.get_setting("commerce/enabled",false))
var commerce
var species=0
var corner=3
var zoom=1
var scale_factor=0.0
var text_scale=1.0
var resize_pivot=Vector2.ZERO
var resize_last_position=Vector2i(-100000,-100000)
var custom_position=false
var saved_position=Vector2i.ZERO
var show_lights=true
var gift_effects=true
var combo_effects=true
var paused=false
var tutorial_seen=false
var tutorial
var widget
var settings
var save_timer=0.0
var save_error=false
var save_dirty=true
var save_blocked=false
var instance_socket: TCPServer
var save_path="user://typing-friends.json"

func _ready() -> void:
	# The primary Window is still adding this scene during _ready. Add its UI after that.
	start_game.call_deferred()

func start_game() -> void:
	Engine.max_fps=60
	# Keep all controls in the primary Windows input window, never a passive host.
	get_tree().root.transparent=false
	get_tree().root.transparent_bg=false
	get_tree().root.unfocusable=false
	get_tree().root.mouse_passthrough=false
	var icon=Image.new()
	if icon.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/icon/pet-icon.png"))==OK:
		DisplayServer.set_icon(icon)
	get_tree().root.gui_embed_subwindows=false
	# A second launch must not create a second hook/helper or race the save file.
	instance_socket=TCPServer.new()
	if instance_socket.listen(38474,"127.0.0.1")!=OK:
		get_tree().quit()
		return
	load_game()
	widget=preload("res://scripts/widget.gd").new()
	widget.app=self
	add_child(widget)
	settings=preload("res://scripts/settings.gd").new()
	settings.app=self
	add_child(settings)
	if commerce_enabled:
		commerce=preload("res://scripts/commerce_access.gd").new()
		add_child(commerce)
		commerce.allowed_changed.connect(_rights_changed)
		widget.hide()
		commerce.preferred_species=species
		commerce.begin()
		commerce.panel.title="단짝 타자친구 · 계정 연결"
	else: bridge.start()
	get_tree().auto_accept_quit=false
	get_tree().root.close_requested.connect(shutdown)
	if "--settings" in OS.get_cmdline_user_args(): open_settings.call_deferred()
	if "--report" in OS.get_cmdline_user_args():
		settings.tab=3
		open_settings.call_deferred()
	if "--startup-check" in OS.get_cmdline_user_args(): check_startup.call_deferred()
	elif not tutorial_seen and not commerce_enabled: open_tutorial.call_deferred()

func check_startup() -> void:
	await get_tree().process_frame
	open_settings()
	await get_tree().process_frame
	var ok=widget.header_root.is_inside_tree() and widget.settings_button.is_inside_tree() and settings.visible and not widget.header.mouse_passthrough
	print("NATIVE_STARTUP_PASS" if ok else "NATIVE_STARTUP_FAILED")
	bridge.stop()
	get_tree().quit(0 if ok else 1)

func _process(delta: float) -> void:
	if not is_instance_valid(widget): return
	var count=bridge.poll() if not paused and can_run(species) else 0
	var before=activity.active_ms
	var report_before=report.revision
	var day_before=collection.day
	activity.update(Time.get_ticks_msec(),count,not paused and bridge.connected and can_run(species))
	report.step(Time.get_ticks_msec(),bridge.key_delta if count>0 else 0,not paused and bridge.connected and can_run(species))
	collection.credit(count,activity.active_ms-before)
	if count>0 or activity.active_ms!=before or report.revision!=report_before or collection.day!=day_before: save_dirty=true
	widget.advance(delta,count)
	save_timer+=delta
	if save_timer>=5:
		save_timer=0
		if save_dirty and not save_blocked: save_game()
		if settings.visible: settings.refresh_progress()

func toggle_pause() -> void:
	activity.suspend(Time.get_ticks_msec())
	paused=not paused
	if paused: bridge.stop()
	elif can_run(species): bridge.start()
	settings.rebuild.call_deferred()
func choose_friend(value: int) -> void:
	if not can_use(value): return
	if commerce_enabled and not commerce.activate(value): return
	species=clampi(value,0,15)
	widget.load_friend()
	save_game()
	settings.rebuild.call_deferred()
func open_settings() -> void:
	widget.finish_drag()
	var was_visible=settings.visible
	if not was_visible: settings.rebuild()
	if settings.mode==Window.MODE_MINIMIZED: settings.mode=Window.MODE_WINDOWED
	var screen=DisplayServer.screen_get_usable_rect(settings.current_screen) if was_visible else widget.screen_rect
	if not was_visible:
		settings.position=screen.position+(screen.size-settings.size)/2
	elif screen.size.x>0:
		settings.position=settings.position.clamp(screen.position,(screen.end-settings.size).max(screen.position))
	settings.show()
	preload("res://scripts/native_mouse.gd").apply(settings,false,true)
	settings.grab_focus()

func can_use(value: int) -> bool:
	return value>=0 and value<Catalog.IDS.size() and (not commerce_enabled or (is_instance_valid(commerce) and commerce.permits(value)))

func can_run(value: int) -> bool:
	return can_use(value) and (not commerce_enabled or commerce.can_run(value))

func _rights_changed(ids: PackedStringArray) -> void:
	if not ids.is_empty() and commerce.active_species>=0:
		if species!=commerce.active_species:
			species=commerce.active_species
			widget.load_friend()
			save_game()
	widget.visible=can_run(species)
	if can_run(species) and not paused:
		if bridge.helper_pid<=0: bridge.start()
	else: bridge.stop()
	settings.rebuild.call_deferred()
func open_gifts() -> void:
	open_settings()
	settings.tabs.current_tab=1
	var available=false
	for entry in collection.ITEMS:
		if collection.eligible(entry.id) and entry.id not in collection.claimed: available=true
	if not available and collection.ready_orders()>0: settings.tabs.current_tab=2
func open_tutorial() -> void:
	if not is_instance_valid(tutorial):
		tutorial=preload("res://scripts/tutorial.gd").new()
		tutorial.app=self
		add_child(tutorial)
	tutorial.show_guide()
func set_size(value: float) -> void:
	var previous=widget.root.scale.x
	scale_factor=clampf(value,.7,1.5)
	save_dirty=true
	if custom_position:
		if resize_last_position!=widget.anchor_position:
			resize_pivot=Vector2(widget.anchor_position)+widget.resize_pivot_offset(previous)
		saved_position=Vector2i((resize_pivot-widget.resize_pivot_offset(scale_factor)).round())
	widget.place()
	resize_last_position=widget.anchor_position if custom_position and saved_position==widget.anchor_position else Vector2i(-100000,-100000)
	# Autosave and slider release persist the final size, not every mouse pixel.
func set_text_size(value: float) -> void:
	text_scale=clampf(value,.9,1.3)
	settings.apply_text_size()
	widget.apply_text_size()
	save_game()
func save_game() -> void:
	save_dirty=true
	if save_blocked:
		save_error=true
		return
	var contents=JSON.stringify({"version":1,"species":species,"corner":corner,"zoom":zoom,"scale_factor":scale_factor,"text_scale":text_scale,"tutorial_seen":tutorial_seen,"custom_position":custom_position,"position":[saved_position.x,saved_position.y],"show_lights":show_lights,"gift_effects":gift_effects,"combo_effects":combo_effects,"collection":collection.serialize(),"typing_report":report.days})
	var file=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if not file:
		save_error=true
		return
	var written=file.store_string(contents)
	file.flush()
	var write_error=file.get_error()
	file.close()
	if not written or write_error!=OK or FileAccess.get_file_as_string(save_path+".tmp")!=contents:
		save_error=true
		return
	# Only a verified snapshot may replace the last good copy.
	var backup_source=""
	if read_save(save_path) is Dictionary:
		backup_source=save_path
	elif FileAccess.file_exists(save_path) and not quarantine_save(save_path):
		save_blocked=true
		save_error=true
		return
	if backup_source.is_empty() and not read_save(save_path+".bak") is Dictionary: backup_source=save_path+".tmp"
	if not backup_source.is_empty():
		var backup_text=FileAccess.get_file_as_string(backup_source)
		if DirAccess.copy_absolute(backup_source,save_path+".bak.tmp")!=OK or FileAccess.get_file_as_string(save_path+".bak.tmp")!=backup_text:
			save_error=true
			return
		if DirAccess.rename_absolute(save_path+".bak.tmp",save_path+".bak")!=OK:
			save_error=true
			return
	save_error=DirAccess.rename_absolute(save_path+".tmp",save_path)!=OK
	if not save_error: save_dirty=false
func read_save(path_: String) -> Variant:
	var file=FileAccess.open(path_,FileAccess.READ)
	if not file: return null
	var contents=file.get_as_text()
	var read_error=file.get_error()
	file.close()
	if read_error!=OK and read_error!=ERR_FILE_EOF: return null
	var json=JSON.new()
	if json.parse(contents)!=OK: return null
	var data=json.data
	if not data is Dictionary or not data.get("collection") is Dictionary: return null
	if data.has("version") and data.version!=1: return null
	if data.has("typing_report") and not data.typing_report is Dictionary: return null
	return data
func quarantine_save(path_: String) -> bool:
	if not FileAccess.file_exists(path_): return true
	var prefix=path_+".corrupt-"+str(int(Time.get_unix_time_from_system()))
	var target=prefix
	var suffix=0
	while FileAccess.file_exists(target):
		suffix+=1
		target=prefix+"-"+str(suffix)
	return DirAccess.rename_absolute(path_,target)==OK
func has_corrupt_save() -> bool:
	for name_ in DirAccess.get_files_at(save_path.get_base_dir()):
		if name_.begins_with(save_path.get_file()+".corrupt-") or name_.begins_with(save_path.get_file()+".bak.corrupt-"): return true
	return false
func load_game() -> void:
	save_blocked=false
	save_error=false
	var data=read_save(save_path)
	save_dirty=not data is Dictionary
	if not data is Dictionary:
		data=read_save(save_path+".bak")
		if data is Dictionary:
			if not quarantine_save(save_path): save_blocked=true
		else:
			if not FileAccess.file_exists(save_path) and not FileAccess.file_exists(save_path+".bak") and not has_corrupt_save(): return
			save_blocked=true
			quarantine_save(save_path)
			quarantine_save(save_path+".bak")
			save_error=true
			return
	save_error=save_blocked
	tutorial_seen=data.get("tutorial_seen",false)==true
	species=collection.number(data.get("species"),15)
	corner=collection.number(data.get("corner",3),3)
	zoom=collection.number(data.get("zoom",1),2)
	var scale_=data.get("scale_factor",0)
	var text_=data.get("text_scale",1.0)
	if typeof(text_) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(text_)): text_scale=clampf(text_,.9,1.3)
	if typeof(scale_) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(scale_)): scale_factor=clampf(scale_,.7,1.5) if scale_>0 else 0.0
	var point=data.get("position")
	if point is Array and point.size()==2 and typeof(point[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(point[1]) in [TYPE_INT,TYPE_FLOAT]:
		saved_position=Vector2i(clampi(int(point[0]),-100000,100000),clampi(int(point[1]),-100000,100000))
		custom_position=data.get("custom_position",false)==true
	show_lights=data.get("show_lights",true)==true
	gift_effects=data.get("gift_effects",true)==true
	combo_effects=data.get("combo_effects",true)==true
	collection.restore(data.get("collection"))
	report.restore(data.get("typing_report"))
	if collection.serialize()!=data.collection or report.days!=data.get("typing_report",{}): save_dirty=true
func shutdown() -> void:
	if shutting_down: return
	shutting_down=true
	save_game()
	bridge.stop()
	if commerce_enabled and is_instance_valid(commerce): await commerce.shutdown_usage()
	get_tree().quit()
func _exit_tree() -> void:
	bridge.stop()
	if instance_socket: instance_socket.stop()

