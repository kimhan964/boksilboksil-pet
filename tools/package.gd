extends SceneTree
var packer=PCKPacker.new()
var failed=false
var rabbit_pilot=false
var species_pilot=false
var walk_trial_version=5
var source_root=""
var reuse_assets=false
var asset_overlay=""
func add_folder(folder: String,from_source: bool=false) -> void:
	if not from_source and not asset_overlay.is_empty() and folder=="res://"+asset_overlay: return
	var input_folder=folder if reuse_assets and not from_source and folder.begins_with("res://assets") else source_root.path_join(folder.trim_prefix("res://"))
	for filename in DirAccess.get_files_at(input_folder):
		if filename.ends_with(".tmp"): continue
		var path=folder.path_join(filename)
		if packer.add_file(path,input_folder.path_join(filename))!=OK: failed=true
	for directory in DirAccess.get_directories_at(input_folder): add_folder(folder.path_join(directory),from_source)
func _initialize() -> void:
	source_root=ProjectSettings.globalize_path("res://")
	var destination="res://builds/DesktopFriends-0.30.3-release"
	var base_pack=""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--overlay-assets="): asset_overlay=argument.trim_prefix("--overlay-assets=")
		if argument.begins_with("--reuse-assets-from="): base_pack=argument.trim_prefix("--reuse-assets-from=")
		if argument.begins_with("--destination="): destination=argument.trim_prefix("--destination=")
		if argument=="--rabbit-pilot": rabbit_pilot=true
		if argument=="--species-pilot": species_pilot=true
		if argument=="--walk-v7": walk_trial_version=7
		if argument=="--walk-v8": walk_trial_version=8
		if argument=="--walk-v10": walk_trial_version=10
		if argument=="--walk-v11": walk_trial_version=11
		if argument=="--walk-v12": walk_trial_version=12
		if argument=="--walk-v13": walk_trial_version=13
		if argument=="--walk-v14": walk_trial_version=14
	# Only for code-only hotfixes: read the already verified assets sequentially
	# from a prior PCK instead of reopening thousands of unchanged source PNGs.
	if not base_pack.is_empty():
		if not ProjectSettings.load_resource_pack(base_pack,true):
			push_error("Could not load the base asset package")
			quit(1)
			return
		reuse_assets=true
	DirAccess.make_dir_recursive_absolute(destination)
	if packer.pck_start(destination+"/DesktopFriends.pck")!=OK:
		quit(1)
		return
	for folder in ["res://assets","res://scripts","res://scenes","res://addons"]: add_folder(folder)
	# Explicit new asset folder; all other art remains from the verified base.
	if not asset_overlay.is_empty():
		if not asset_overlay.begins_with("assets/") or asset_overlay.contains(".."):
			push_error("Asset overlay must be a folder under assets/")
			quit(1)
			return
		add_folder("res://"+asset_overlay,true)
	# Native DLLs must also exist outside the PCK beside the executable.
	var native_dir="addons/windows_mouse_passthrough/bin"
	DirAccess.make_dir_recursive_absolute(destination.path_join(native_dir))
	for filename in DirAccess.get_files_at("res://"+native_dir):
		if DirAccess.copy_absolute("res://"+native_dir.path_join(filename),destination.path_join(native_dir).path_join(filename))!=OK: failed=true
	if packer.add_file("res://tools/check_package.gd","res://tools/check_package.gd")!=OK: failed=true
	if packer.add_file("res://.godot/global_script_class_cache.cfg","res://tools/runtime-global-classes.cfg")!=OK: failed=true
	var configuration="res://project.godot"
	if rabbit_pilot or species_pilot:
		configuration=destination+"/pilot-project.godot"
		var file=FileAccess.open(configuration,FileAccess.WRITE)
		var pilot_configuration=FileAccess.get_file_as_string("res://project.godot").replace('run/main_scene="res://scenes/main.tscn"','run/main_scene="res://scenes/rabbit_pilot.tscn"').replace('config/custom_user_dir_name="DesktopFriends"','config/custom_user_dir_name="DesktopFriendsRabbitPilot"')
		if species_pilot:
			pilot_configuration=pilot_configuration.replace("scenes/rabbit_pilot.tscn","scenes/species_walk_preview.tscn").replace("DesktopFriendsRabbitPilot","DesktopFriendsWalkPreview")
			pilot_configuration=pilot_configuration.replace("[testing]","[testing]\nwalk_trial_version=%d"%walk_trial_version)
		pilot_configuration=pilot_configuration.replace('renderer/rendering_method="gl_compatibility"','renderer/rendering_method="mobile"').replace('renderer/rendering_method.mobile="gl_compatibility"','renderer/rendering_method.mobile="mobile"').replace('"GL Compatibility"','"Mobile"')
		# This Windows machine's Vulkan compositor fills transparent hull gaps
		# black. D3D12 preserves per-pixel alpha (verified on the carrot bowl).
		if not pilot_configuration.contains('rendering_device/driver.windows="d3d12"'):
			pilot_configuration=pilot_configuration.replace("[rendering]","[rendering]\nrendering_device/driver.windows=\"d3d12\"")
		file.store_string(pilot_configuration)
		file.close()
	if packer.add_file("res://project.godot",configuration)!=OK: failed=true
	if packer.flush()!=OK: failed=true
	var license_file=FileAccess.open(destination+"/GODOT-LICENSE.txt",FileAccess.WRITE)
	license_file.store_string(Engine.get_license_text())
	var notices=FileAccess.open(destination+"/GODOT-THIRD-PARTY.json",FileAccess.WRITE)
	notices.store_string(JSON.stringify(Engine.get_copyright_info(),"\t"))
	print("PACKAGE_CREATED (game not launched or tested)")
	quit(1 if failed else 0)
