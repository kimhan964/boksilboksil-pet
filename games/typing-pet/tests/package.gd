extends SceneTree
var packer=PCKPacker.new()
var failed=false
func folder(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".import") or file.ends_with(".uid") or file.ends_with(".log"): continue
		if file=="generation-records.json": continue
		if packer.add_file(path.path_join(file),path.path_join(file))!=OK: failed=true
	for child in DirAccess.get_directories_at(path): folder(path.path_join(child))
func _initialize() -> void:
	var destination="res://builds/release"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--destination="): destination=arg.trim_prefix("--destination=")
	DirAccess.make_dir_recursive_absolute(destination)
	if packer.pck_start(destination+"/TypingFriends.pck")!=OK:
		quit(1)
		return
	for path in ["res://scripts","res://scenes","res://assets","res://addons","res://tests"]: folder(path)
	if packer.add_file("res://project.godot","res://project.godot")!=OK: failed=true
	if packer.add_file("res://.godot/global_script_class_cache.cfg","res://tests/global-classes.cfg")!=OK: failed=true
	if packer.flush()!=OK: failed=true
	var license_=FileAccess.open(destination+"/GODOT-LICENSE.txt",FileAccess.WRITE)
	license_.store_string(Engine.get_license_text())
	var notice=FileAccess.open(destination+"/GODOT-THIRD-PARTY.json",FileAccess.WRITE)
	notice.store_string(JSON.stringify(Engine.get_copyright_info(),"\t"))
	print("TYPING_PCK_BUILT ",destination)
	quit(1 if failed else 0)
