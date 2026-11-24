extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var app=preload("res://tests/visual_app.gd").new()
 app.commerce_enabled=true
 root.add_child(app)
 app.commerce=preload("res://scripts/commerce_access.gd").new()
 app.add_child(app.commerce)
 app.bridge=preload("res://tests/fake_typing_bridge.gd").new()
 app.commerce.usage=preload("res://tests/fake_runtime_usage.gd").new()
 app.commerce.add_child(app.commerce.usage)
 app.commerce.usage.changed.connect(app.commerce._usage_changed)
 app.widget=preload("res://scripts/widget.gd").new()
 app.widget.app=app
 app.add_child(app.widget)
 app.widget.hide()
 app.settings=preload("res://scripts/settings.gd").new()
 app.settings.app=app
 app.add_child(app.settings)
 app.commerce.allowed_changed.connect(app._rights_changed)
 var ids=preload("res://scripts/catalog.gd").IDS
 var attempts=0
 for owned in range(16):
  assert(app.commerce._accept_entitlements({"productId":"mate","animalIds":[ids[owned]],"validForSeconds":60}))
  await process_frame
  assert(app.species==owned and app.widget.visible)
  for target in range(16):
   app.choose_friend(target)
   assert(app.species==owned, "Unowned selection escaped gate")
   assert(app.can_use(target)==(target==owned))
   attempts+=1
  app.commerce._accept_entitlements({"productId":"mate","animalIds":[],"validForSeconds":60})
  await process_frame
  assert(not app.widget.visible)
 app.free()
 print("PASS: 16 single-animal entitlements; ",attempts," selection attempts; 16 revocations. Synthetic rights, not Toss payment.")
 quit()

