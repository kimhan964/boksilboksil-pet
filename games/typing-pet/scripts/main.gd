extends Node
const Catalog=preload("res://scripts/catalog.gd")
var collection=preload("res://scripts/collection.gd").new()
var activity=preload("res://scripts/activity.gd").new()
var bridge=preload("res://scripts/typing_input.gd").new()
var skin=preload("res://scripts/cozy_ui.gd").theme()
var species=0
var corner=3
var zoom=1
var scale_factor=0.0
var custom_position=false
var saved_position=Vector2i.ZERO
var show_lights=true
var gift_effects=true
var paused=false
var widget
var settings
var save_timer=0.0
var save_error=false
var instance_socket: TCPServer
var save_path="user://typing-friends.json"

func _ready() -> void:
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
	if instance_socket.listen(38473,"127.0.0.1")!=OK:
		get_tree().quit()
		return
	load_game()
	widget=preload("res://scripts/widget.gd").new()
	widget.app=self
	add_child(widget)
	settings=preload("res://scripts/settings.gd").new()
	settings.app=self
	add_child(settings)
	bridge.start()
	get_tree().auto_accept_quit=false
	get_tree().root.close_requested.connect(shutdown)
	if "--settings" in OS.get_cmdline_user_args(): open_settings.call_deferred()

func _process(delta: float) -> void:
	if not is_instance_valid(widget): return
	var count=bridge.poll() if not paused else 0
	var before=activity.active_ms
	activity.update(Time.get_ticks_msec(),count,not paused and bridge.connected)
	collection.credit(count,activity.active_ms-before)
	widget.advance(delta,count)
	save_timer+=delta
	if save_timer>=5:
		save_timer=0
		save_game()
		if settings.visible: settings.refresh_progress()

func toggle_pause() -> void:
	activity.suspend(Time.get_ticks_msec())
	paused=not paused
	if paused: bridge.stop()
	else: bridge.start()
	settings.rebuild.call_deferred()
func choose_friend(value: int) -> void:
	species=clampi(value,0,15)
	widget.load_friend()
	save_game()
	settings.rebuild.call_deferred()
func open_settings() -> void:
	if settings.visible:
		settings.grab_focus()
		return
	settings.rebuild()
	var screen=DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen())
	settings.position=screen.position+(screen.size-settings.size)/2
	settings.show()
	settings.grab_focus()
func open_gifts() -> void:
	open_settings()
	settings.tabs.current_tab=1
func set_size(value: float) -> void:
	scale_factor=clampf(value,.7,1.5)
	widget.place()
	save_game()
func save_game() -> void:
	var file=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if not file:
		save_error=true
		return
	file.store_string(JSON.stringify({"version":1,"species":species,"corner":corner,"zoom":zoom,"scale_factor":scale_factor,"custom_position":custom_position,"position":[saved_position.x,saved_position.y],"show_lights":show_lights,"gift_effects":gift_effects,"collection":collection.serialize()}))
	file.close()
	save_error=DirAccess.rename_absolute(save_path+".tmp",save_path)!=OK
func load_game() -> void:
	if not FileAccess.file_exists(save_path): return
	var data=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary: return
	species=collection.number(data.get("species"),15)
	corner=collection.number(data.get("corner",3),3)
	zoom=collection.number(data.get("zoom",1),2)
	var scale_=data.get("scale_factor",0)
	if typeof(scale_) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(scale_)): scale_factor=clampf(scale_,.7,1.5) if scale_>0 else 0.0
	var point=data.get("position")
	if point is Array and point.size()==2 and typeof(point[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(point[1]) in [TYPE_INT,TYPE_FLOAT]:
		saved_position=Vector2i(clampi(int(point[0]),-100000,100000),clampi(int(point[1]),-100000,100000))
		custom_position=data.get("custom_position",false)==true
	show_lights=data.get("show_lights",true)==true
	gift_effects=data.get("gift_effects",true)==true
	collection.restore(data.get("collection"))
func shutdown() -> void:
	save_game()
	bridge.stop()
	get_tree().quit()
func _exit_tree() -> void:
	bridge.stop()
	if instance_socket: instance_socket.stop()
