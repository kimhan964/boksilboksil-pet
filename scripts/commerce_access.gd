extends Node
signal allowed_changed(animal_ids: PackedStringArray)
const Catalog=preload("res://scripts/animal_catalog.gd")
const SESSION_PATH="user://commerce-session.json"
var allowed=PackedStringArray()
var site_url=""
var access_token=""
var device_id=""
var device_secret=""
var device_deadline=0
var verified_until=0
var request_kind=""
var request_node: HTTPRequest
var poll_timer: Timer
var refresh_timer: Timer
var lease_timer: Timer
var panel: AcceptDialog

func begin() -> void:
	site_url=String(ProjectSettings.get_setting("commerce/site_url","")).trim_suffix("/")
	request_node=HTTPRequest.new()
	request_node.timeout=15
	request_node.max_redirects=0
	request_node.body_size_limit=65536
	add_child(request_node)
	request_node.request_completed.connect(_completed)
	poll_timer=Timer.new()
	poll_timer.wait_time=5
	poll_timer.timeout.connect(_poll)
	add_child(poll_timer)
	refresh_timer=Timer.new()
	refresh_timer.wait_time=45
	refresh_timer.timeout.connect(refresh)
	add_child(refresh_timer)
	lease_timer=Timer.new()
	lease_timer.wait_time=1
	lease_timer.timeout.connect(_check_lease)
	add_child(lease_timer)
	lease_timer.start()
	panel=AcceptDialog.new()
	panel.visible=false
	panel.force_native=true
	panel.transient=false
	panel.always_on_top=true
	panel.theme=preload("res://scripts/cozy_ui.gd").theme()
	panel.title="복슬복슬펫 · 구매한 친구 연결"
	panel.min_size=Vector2i(480,260)
	panel.size=Vector2i(480,260)
	panel.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.get_label().custom_minimum_size=Vector2(440,140)
	panel.get_ok_button().text="이용권 다시 확인"
	panel.confirmed.connect(refresh)
	panel.add_button("계정 연결",false,"connect")
	panel.add_button("종료",true,"quit")
	panel.custom_action.connect(func(action):
		if action=="connect": _start_link()
		elif action=="quit": get_tree().quit()
	)
	add_child(panel)
	if not site_url.begins_with("https://"):
		show_account("계정 연결 주소를 준비 중이에요.")
		return
	if FileAccess.file_exists(SESSION_PATH):
		var saved=JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
		if saved is Dictionary and saved.get("site_url")==site_url and saved.get("access_token") is String:
			access_token=saved.access_token
	refresh()

func permits(species: int) -> bool:
	return species>=0 and species<Catalog.IDS.size() and Time.get_ticks_msec()<verified_until and allowed.has(Catalog.IDS[species])

func show_account(message: String="구매한 동물이 있는 계정을 연결해 주세요.\n\n계정 연결 → 브라우저에서 로그인·PC 연결 승인\n→ 구매·등록한 동물만 다운로드하고 이용해요.\n선물을 받았다면 홈페이지에서 먼저 ‘내 계정에 받기’를 완료해 주세요.") -> void:
	if panel==null: return
	panel.dialog_text=message
	if DisplayServer.get_name()!="headless":
		var screen=DisplayServer.screen_get_usable_rect(DisplayServer.SCREEN_PRIMARY)
		panel.position=screen.position+(screen.size-panel.size)/2
	panel.show()

func authorize_pack(animal_id: String) -> Dictionary:
	var species=Catalog.IDS.find(animal_id)
	if not permits(species): return {}
	var grant_request=HTTPRequest.new()
	grant_request.timeout=15
	grant_request.max_redirects=0
	grant_request.body_size_limit=8192
	add_child(grant_request)
	var err=grant_request.request(site_url+"/api/game/pet-pack?animal="+animal_id.uri_encode(),PackedStringArray(["Authorization: Bearer "+access_token]))
	if err!=OK:
		grant_request.queue_free()
		return {}
	var response=await grant_request.request_completed
	grant_request.queue_free()
	if response[0]!=HTTPRequest.RESULT_SUCCESS or response[1]!=200 or not permits(species): return {}
	var grant=JSON.parse_string(response[3].get_string_from_utf8())
	if not grant is Dictionary or grant.get("animalId")!=animal_id: return {}
	if grant.get("url")!=site_url+"/api/game/pet-pack/file?animal="+animal_id: return {}
	return grant

func pack_headers() -> PackedStringArray:
	return PackedStringArray(["Authorization: Bearer "+access_token])

func _request(kind: String,path: String,data: Dictionary={},bearer: String="",method: int=HTTPClient.METHOD_POST) -> void:
	if not request_kind.is_empty(): return
	request_kind=kind
	var headers=PackedStringArray(["Content-Type: application/json"])
	if not bearer.is_empty(): headers.append("Authorization: Bearer "+bearer)
	var result=request_node.request(site_url+path,headers,method,"" if method==HTTPClient.METHOD_GET else JSON.stringify(data))
	if result!=OK:
		request_kind=""
		_block("계정 서버에 연결하지 못했어요. 저장한 친밀도는 유지돼요.")

func _start_link() -> void:
	if not site_url.begins_with("https://"): return
	poll_timer.stop()
	_request("start","/api/game/device/start")

func _poll() -> void:
	if Time.get_ticks_msec()>=device_deadline:
		poll_timer.stop()
		show_account("연결 시간이 지났어요. 계정 연결을 다시 눌러 주세요.")
		return
	_request("poll","/api/game/device/poll",{"deviceId":device_id},device_secret)

func refresh() -> void:
	if request_node==null or not site_url.begins_with("https://"): return
	if access_token.is_empty():
		show_account()
		return
	_request("rights","/api/game/entitlements",{},access_token,HTTPClient.METHOD_GET)

func _check_lease() -> void:
	if verified_until>0 and Time.get_ticks_msec()>=verified_until:
		_block("이용권 확인 시간이 지나 다시 연결하고 있어요. 인터넷 연결을 확인해 주세요.")

func _accept_entitlements(data: Dictionary) -> bool:
	if not data.get("animalIds") is Array: return false
	if not data.get("validForSeconds") is float and not data.get("validForSeconds") is int: return false
	if int(data.validForSeconds)<=0: return false
	var result=PackedStringArray()
	for id in data.animalIds:
		if id is String and Catalog.IDS.has(id) and not result.has(id): result.append(id)
	allowed=result
	verified_until=Time.get_ticks_msec()+clampi(int(data.get("validForSeconds",0)),0,60)*1000
	allowed_changed.emit(allowed)
	return true

func _completed(result: int,status: int,_headers: PackedStringArray,response: PackedByteArray) -> void:
	var kind=request_kind
	request_kind=""
	var data=JSON.parse_string(response.get_string_from_utf8())
	if result!=HTTPRequest.RESULT_SUCCESS or not data is Dictionary:
		_block("서버에 연결하지 못했어요. 인터넷 연결 후 다시 확인해 주세요.")
		return
	if status>=400:
		if kind=="rights" and status==401:
			access_token=""
			_save_session()
		if kind=="poll": poll_timer.stop()
		_block(String(data.get("error","계정을 다시 확인해 주세요.")))
		return
	if kind=="start":
		device_id=String(data.get("deviceId",""))
		device_secret=String(data.get("deviceSecret",""))
		device_deadline=Time.get_ticks_msec()+600000
		var link=String(data.get("verificationUrl",""))
		if not link.begins_with(site_url+"/payment.html?"):
			_block("연결 주소가 올바르지 않아요.")
			return
		show_account("브라우저에서 코드를 확인하고 연결해 주세요.\n연결 코드: "+String(data.get("userCode","")))
		OS.shell_open(link)
		poll_timer.start()
	elif kind=="poll" and data.get("status")=="approved":
		poll_timer.stop()
		access_token=String(data.get("accessToken",""))
		_save_session()
		refresh.call_deferred()
	elif kind=="rights":
		if not _accept_entitlements(data):
			_block("이용권 응답을 읽지 못했어요.")
			return
		refresh_timer.start()
		if allowed.is_empty(): show_account("받은 동물이 없어요. 웹에서 선물을 받은 뒤 다시 확인해 주세요.\n테스트 결제는 실제 게임 이용권으로 사용할 수 없어요.")
		else: panel.hide()

func _block(message: String) -> void:
	allowed.clear()
	verified_until=0
	allowed_changed.emit(allowed)
	show_account(message)

func _save_session() -> void:
	var file=FileAccess.open(SESSION_PATH,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"site_url":site_url,"access_token":access_token}))
