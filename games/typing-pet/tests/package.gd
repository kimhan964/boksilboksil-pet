extends SceneTree
var packer=PCKPacker.new()
var failed=false
func folder(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".import") or file.ends_with(".uid") or file.ends_with(".log"): continue
		if file=="generation-records.json": continue
		if file=="source.png" and "typing-soft-v2" in path: continue
		if file in ["typing-friends-source.png","typing-friends.ico"]: continue
		var source=path.path_join(file)
		var limit=0
		if file.ends_with(".png"):
			if "typing-rabbit-v1" in path or "typing-animals-v1" in path or "typing-soft-v2" in path: limit=512
			elif "accessories-varco-v2" in path: limit=192
		var packed_source=source
		if limit>0:
			var image=Image.new()
			if image.load_png_from_buffer(FileAccess.get_file_as_bytes(source))!=OK:
				failed=true
				continue
			if image.get_width()>limit: image.resize(limit,maxi(1,roundi(image.get_height()*float(limit)/image.get_width())),Image.INTERPOLATE_LANCZOS)
			packed_source="res://builds/runtime-assets/"+source.trim_prefix("res://")
			DirAccess.make_dir_recursive_absolute(packed_source.get_base_dir())
			if image.save_png(packed_source)!=OK:
				failed=true
				continue
		if packer.add_file(source,packed_source)!=OK: failed=true
	for child in DirAccess.get_directories_at(path):
		if child=="accessories-varco-v1": continue
		if child=="source" and "accessories-varco-" in path: continue
		folder(path.path_join(child))
func _initialize() -> void:
	var destination="res://builds/release"
	var commerce_site=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--commerce-site="): commerce_site=arg.trim_prefix("--commerce-site=")
		if arg.begins_with("--destination="): destination=arg.trim_prefix("--destination=")
	DirAccess.make_dir_recursive_absolute(destination)
	if packer.pck_start(destination+"/TypingFriends.pck")!=OK:
		quit(1)
		return
	for path in ["res://scripts","res://scenes","res://assets","res://addons","res://tests"]: folder(path)
	var config_path="res://project.godot"
	if not commerce_site.is_empty():
		if commerce_site!="https://boksilboksil.kr":
			quit(1)
			return
		var config=ConfigFile.new()
		config.load(config_path)
		config.set_value("commerce","enabled",true)
		config.set_value("commerce","site_url",commerce_site)
		config.set_value("application","config/version","0.1.7-commerce")
		config_path=destination+"/commerce-project.godot"
		config.save(config_path)
	if packer.add_file("res://project.godot",config_path)!=OK: failed=true
	if packer.add_file("res://.godot/global_script_class_cache.cfg","res://tests/global-classes.cfg")!=OK: failed=true
	if packer.flush()!=OK: failed=true
	var license_=FileAccess.open(destination+"/GODOT-LICENSE.txt",FileAccess.WRITE)
	license_.store_string(Engine.get_license_text())
	var notice=FileAccess.open(destination+"/GODOT-THIRD-PARTY.json",FileAccess.WRITE)
	notice.store_string(JSON.stringify(Engine.get_copyright_info(),"\t"))
	var fonts_notice=FileAccess.open(destination+"/FONTS-LICENSES.txt",FileAccess.WRITE)
	fonts_notice.store_string(FileAccess.get_file_as_string("res://assets/fonts/Jua-OFL.txt")+"\n\n"+FileAccess.get_file_as_string("res://assets/fonts/GowunDodum-OFL.txt"))
	print("TYPING_PCK_BUILT ",destination)
	quit(1 if failed else 0)

