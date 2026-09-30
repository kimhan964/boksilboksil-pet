extends SceneTree

const Catalog=preload("res://scripts/animal_catalog.gd")
const CommerceAccess=preload("res://scripts/commerce_access.gd")
const Pet=preload("res://scripts/desktop_pet.gd")
const State=preload("res://scripts/pet_state.gd")
var failures=0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if value: return
	failures+=1
	push_error(message)

func run() -> void:
	var access=CommerceAccess.new()
	root.add_child(access)
	check(access._accept_entitlements({"animalIds":["otter","unknown","otter"],"validForSeconds":60}),"이용권 응답을 읽지 못했습니다")
	check(access.allowed==PackedStringArray(["otter"]),"알 수 없는 동물 또는 중복 이용권을 허용했습니다")
	check(access.permits(1) and not access.permits(0),"선물받지 않은 동물의 이용을 허용했습니다")
	var pet=Pet.new()
	pet.species=1
	pet.state=State.new()
	pet.commerce_mode=true
	pet.available_species=access.allowed.duplicate()
	root.add_child(pet)
	var friends: PopupMenu=pet.menu.get_node("Friends")
	check(friends.item_count==1 and friends.get_item_id(0)==1,"한 마리 선물 목록에 다른 동물이 보입니다")
	check(not pet.menu.friend_button.visible,"한 마리 선물에 친구 바꾸기 버튼이 보입니다")
	pet.set_available_species(PackedStringArray(["otter","rabbit"]))
	check(friends.item_count==2 and friends.get_item_id(0)==0 and friends.get_item_id(1)==1,"추가 이용권을 목록에 반영하지 못했습니다")
	check(pet.menu.friend_button.visible,"두 마리 선물에서 친구 바꾸기 버튼이 숨겨졌습니다")
	access._block("검증용 만료")
	check(not access.permits(1),"이용권 만료 후에도 동물 선택이 가능합니다")
	print("GIFT_ACCESS_CHECK FAILURES=",failures," SPECIES=",Catalog.IDS.size())
	quit(0 if failures==0 else 1)
