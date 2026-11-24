extends SceneTree
const Main=preload("res://scripts/main.gd")
var failures=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
func write_text(path_: String,text_: String) -> void:
	var file=FileAccess.open(path_,FileAccess.WRITE)
	assert(file!=null)
	assert(file.store_string(text_))
	file.close()
func run() -> void:
	# Never load the player's save. Keep all failure fixtures for inspection.
	var folder="res://builds/review/save-recovery-%d-%d"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	assert(DirAccess.make_dir_recursive_absolute(folder)==OK)
	var app=Main.new()
	app.save_path=folder+"/progress.json"
	app.collection.actions=123
	app.save_game()
	check(not app.save_error and not app.save_dirty,"first save succeeds and clears dirty flag")
	check(app.read_save(app.save_path+".bak").collection.actions==123,"first save creates a valid backup")
	app.collection.actions=456
	app.save_game()
	check(app.read_save(app.save_path).collection.actions==456,"new state replaces primary")
	check(app.read_save(app.save_path+".bak").collection.actions==123,"backup retains previous good state")
	var good=FileAccess.get_file_as_string(app.save_path+".bak")
	for bad in ["{broken","{}",'{"collection":null}']:
		write_text(app.save_path,bad)
		app.load_game()
		check(not app.save_blocked and app.save_dirty and app.collection.actions==123,"bad primary recovers backup: "+bad)
		check(app.has_corrupt_save() and not FileAccess.file_exists(app.save_path),"bad primary is archived")
		app.save_game()
		check(not app.save_error and FileAccess.get_file_as_string(app.save_path+".bak")==good,"recovery save preserves known good backup")
	app.quarantine_save(app.save_path)
	app.load_game()
	check(not app.save_blocked and app.collection.actions==123,"missing primary recovers backup")
	app.save_game()
	write_text(app.save_path,"bad primary")
	write_text(app.save_path+".bak","bad backup")
	app.load_game()
	check(app.save_blocked and app.save_error,"both corrupt copies block saving")
	var files=DirAccess.get_files_at(folder)
	app.save_game()
	check(not FileAccess.file_exists(app.save_path) and files==DirAccess.get_files_at(folder),"blocked save leaves quarantined files unchanged")
	var restarted=Main.new()
	restarted.save_path=app.save_path
	restarted.load_game()
	check(restarted.save_blocked,"quarantine keeps save blocked after restart")
	write_text(restarted.save_path+".bak",good)
	restarted.load_game()
	check(not restarted.save_blocked and restarted.collection.actions==123,"restoring a valid backup clears the block")
	restarted.save_game()
	check(not restarted.save_error,"recovered save can be persisted")
	for suffix in [".tmp",".bak.tmp"]:
		var path_=folder+"/failed"+suffix.replace(".","-")+".json"
		write_text(path_,good)
		write_text(path_+".bak",good)
		assert(DirAccess.make_dir_absolute(path_+suffix)==OK)
		restarted.save_path=path_
		restarted.collection.actions=999
		restarted.save_game()
		check(restarted.save_error and restarted.save_dirty,"write/copy failure stays dirty: "+suffix)
		check(FileAccess.get_file_as_string(path_)==good and FileAccess.get_file_as_string(path_+".bak")==good,"write/copy failure preserves primary and backup: "+suffix)
	app.free()
	restarted.free()
	if failures==0: print("SAVE_RECOVERY_PASS: validated writes, backup, corrupt/missing primary, blocked restart, recovery, failed writes preserve snapshots")
	print("SAVE_RECOVERY_FIXTURES: "+folder)
	quit(1 if failures else 0)
