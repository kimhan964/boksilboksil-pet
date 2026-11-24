extends SceneTree
const Access=preload("res://scripts/commerce_access.gd")
func _initialize() -> void:
	var access=Access.new()
	root.add_child(access)
	assert(not access.permits(0))
	assert(not access._accept_entitlements({"animalIds":["rabbit"],"validForSeconds":60}))
	assert(not access._accept_entitlements({"productId":"pet","animalIds":["rabbit"],"validForSeconds":60}))
	assert(access._accept_entitlements({"productId":"mate","animalIds":["rabbit","unknown","rabbit"],"validForSeconds":60}))
	assert(access.allowed.size()==1 and access.permits(0) and not access.permits(1))
	assert(access._accept_entitlements({"productId":"mate","animalIds":["otter"],"validForSeconds":60}))
	assert(not access.permits(0) and access.permits(1))
	access.verified_until=Time.get_ticks_msec()-1
	assert(not access.permits(1))
	assert(access._accept_entitlements({"productId":"mate","animalIds":[],"validForSeconds":60}))
	assert(not access.permits(1))
	access.free()
	print("MATE_COMMERCE_ACCESS_PASS")
	quit()
