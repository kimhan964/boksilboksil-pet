extends SceneTree
var packer=PCKPacker.new()
var failed=false
func add_folder(folder: String) -> void:
	for filename in DirAccess.get_files_at(folder):
		if filename.ends_with(".tmp"): continue
		var path=folder.path_join(filename)
		if packer.add_file(path,path)!=OK: failed=true
	for directory in DirAccess.get_directories_at(folder): add_folder(folder.path_join(directory))
func _initialize() -> void:
	var destination="res://builds/DesktopFriends-0.24-test"
	DirAccess.make_dir_recursive_absolute(destination)
	if packer.pck_start(destination+"/DesktopFriends.pck")!=OK:
		quit(1)
		return
	for folder in ["res://assets","res://scripts","res://scenes"]: add_folder(folder)
	if packer.add_file("res://project.godot","res://project.godot")!=OK: failed=true
	if packer.flush()!=OK: failed=true
	var license_file=FileAccess.open(destination+"/GODOT-LICENSE.txt",FileAccess.WRITE)
	license_file.store_string(Engine.get_license_text())
	var notices=FileAccess.open(destination+"/GODOT-THIRD-PARTY.json",FileAccess.WRITE)
	notices.store_string(JSON.stringify(Engine.get_copyright_info(),"\t"))
	print("PACKAGE_CREATED (game not launched or tested)")
	quit(1 if failed else 0)
