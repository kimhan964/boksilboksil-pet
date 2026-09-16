extends SceneTree
# Separate commerce-enabled package. Existing developer builds and project settings are untouched.
var packer=PCKPacker.new()
var failed=false
func add_folder(folder: String) -> void:
	for filename in DirAccess.get_files_at(folder):
		if filename.ends_with(".tmp"): continue
		var path=folder.path_join(filename)
		if packer.add_file(path,path)!=OK: failed=true
	for directory in DirAccess.get_directories_at(folder): add_folder(folder.path_join(directory))
func _initialize() -> void:
	var site=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--site-url="): site=arg.trim_prefix("--site-url=").trim_suffix("/")
	if not site.begins_with("https://") or site.contains("\"") or site.contains("\n"):
		push_error("Pass --site-url=https://your-deployed-site")
		quit(1)
		return
	var config=ConfigFile.new()
	if config.load("res://project.godot")!=OK:
		quit(1)
		return
	config.set_value("commerce","enabled",true)
	config.set_value("commerce","site_url",site)
	var temporary="user://commerce-project.godot"
	if config.save(temporary)!=OK:
		quit(1)
		return
	var destination="res://builds/DesktopFriends-Commerce-0.11"
	DirAccess.make_dir_recursive_absolute(destination)
	if packer.pck_start(destination+"/DesktopFriends.pck")!=OK:
		quit(1)
		return
	for folder in ["res://assets","res://scripts","res://scenes"]: add_folder(folder)
	if packer.add_file("res://project.godot",ProjectSettings.globalize_path(temporary))!=OK: failed=true
	if packer.flush()!=OK: failed=true
	var license_file=FileAccess.open(destination+"/GODOT-LICENSE.txt",FileAccess.WRITE)
	if license_file!=null: license_file.store_string(Engine.get_license_text())
	var notices=FileAccess.open(destination+"/GODOT-THIRD-PARTY.json",FileAccess.WRITE)
	if notices!=null: notices.store_string(JSON.stringify(Engine.get_copyright_info(),"\t"))
	print("COMMERCE_PACKAGE_CREATED; online account and live entitlement required")
	quit(1 if failed else 0)
