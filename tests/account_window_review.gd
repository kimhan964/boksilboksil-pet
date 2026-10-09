extends SceneTree
const Access=preload("res://scripts/commerce_access.gd")
var access
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(260,210)
	root.transparent=true
	root.transparent_bg=true
	access=Access.new()
	root.add_child(access)
	access.begin()
	await create_timer(1).timeout
	var panel=access.panel
	var report={"native":panel.force_native,"visible":panel.visible,"size":[panel.size.x,panel.size.y],"embedded":panel.is_embedded(),"text":panel.get_label().text,"buttons":[]}
	for child in panel.get_ok_button().get_parent().get_children():
		if child is Button: report.buttons.append({"text":child.text,"visible":child.is_visible_in_tree(),"rect":[child.position.x,child.position.y,child.size.x,child.size.y]})
	var output=OS.get_environment("PET_ACCOUNT_REVIEW_OUT")
	if not output.is_empty():
		var file=FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify(report))
	print("ACCOUNT_WINDOW_REVIEW ",JSON.stringify(report))
