extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var app=preload("res://tests/visual_app.gd").new()
	app.commerce_enabled=true
	root.add_child(app)
	app.commerce=preload("res://scripts/commerce_access.gd").new()
	app.add_child(app.commerce)
	app.widget=preload("res://scripts/widget.gd").new()
	app.widget.app=app
	app.add_child(app.widget)
	app.widget.hide()
	app.settings=preload("res://scripts/settings.gd").new()
	app.settings.app=app
	app.add_child(app.settings)
	app.commerce.allowed_changed.connect(app._rights_changed)
	app.choose_friend(5)
	assert(app.species==0 and not app.widget.visible)
	app.commerce._accept_entitlements({"productId":"mate","animalIds":["fox"],"validForSeconds":60})
	await process_frame
	await process_frame
	assert(app.species==5 and app.widget.visible)
	app.choose_friend(0)
	assert(app.species==5)
	app.commerce._accept_entitlements({"productId":"mate","animalIds":[],"validForSeconds":60})
	await process_frame
	assert(not app.widget.visible and app.bridge.helper_pid<=0)
	app.free()
	print("MATE_COMMERCE_UI_PASS")
	quit()
