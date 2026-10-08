extends SceneTree
const Access=preload("res://scripts/commerce_access.gd")
const Manager=preload("res://scripts/animal_pack_manager.gd")
const Pet=preload("res://scripts/desktop_pet.gd")
const State=preload("res://scripts/pet_state.gd")
var failures=[]
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	check(bool(ProjectSettings.get_setting("commerce/enabled",false)),"purchase package requires account")
	check(ProjectSettings.get_setting("commerce/site_url","")=="https://boksilboksil.kr","production account URL")
	var manager=Manager.new()
	root.add_child(manager)
	check(not manager.available(0),"default rabbit locked before account")
	check(not await manager.ensure(0),"default rabbit cannot bypass account")
	check(not await manager.ensure(1),"unowned animal cannot start download")
	check(manager.request==null and not manager.busy,"denied request creates no download")
	var access=Access.new()
	root.add_child(access)
	manager.authorization=access.permits
	access._accept_entitlements({"animalIds":["rabbit"],"validForSeconds":60})
	check(manager.available(0),"owned default is usable")
	check(await manager.ensure(0),"owned default needs no extra download")
	check(not await manager.ensure(1),"rabbit owner cannot request otter")
	manager.mounted.otter=true
	check(not manager.available(1),"mounted unowned pack cannot be used")
	check(not manager.mount_verified("unused","otter"),"unowned cached mount denied")
	check(not await manager.ensure(-1) and not await manager.ensure(16),"invalid animal IDs denied")
	var pet=Pet.new()
	pet.state=State.new()
	pet.commerce_mode=true
	pet.available_species=access.allowed.duplicate()
	root.add_child(pet)
	var friends=pet.menu.get_node("Friends")
	check(friends.item_count==1 and friends.get_item_id(0)==0,"only purchased rabbit in selector")
	access._accept_entitlements({"animalIds":["rabbit","otter"],"validForSeconds":60})
	pet.set_available_species(access.allowed)
	check(friends.item_count==2,"second actual entitlement adds second animal")
	manager.busy=true
	manager.species_id="otter"
	var cancelled=[]
	manager.finished.connect(func(ok): cancelled.append(ok))
	access._accept_entitlements({"animalIds":["rabbit"],"validForSeconds":60})
	manager.revalidate_permissions()
	check(not manager.busy and cancelled==[false],"revoked download stops without mounting")
	access.verified_until=0
	check(not manager.available(0) and not await manager.ensure(0),"expired entitlement blocks cached/default animal")
	manager.species_id="otter"
	manager.busy=true
	manager.begin_download()
	check(not manager.busy and manager.request==null,"retry cannot bypass expired access")
	pet.free()
	access.free()
	manager.free()
	print("PURCHASE_PACK_ACCESS: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
