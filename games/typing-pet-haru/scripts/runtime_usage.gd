extends Node
signal changed
var site_url=""
var access_token=""
var product_id=""
var instance_id=Crypto.new().generate_random_bytes(16).hex_encode()
var session_id=""
var active=false
var valid_until=0
var next_request=0
var last_error=""
var request_kind=""
var request_node: HTTPRequest
var timer: Timer
var last_valid=false

func begin(origin: String) -> void:
	site_url=origin
	request_node=HTTPRequest.new()
	request_node.timeout=15
	request_node.max_redirects=0
	request_node.body_size_limit=16384
	add_child(request_node)
	request_node.request_completed.connect(_completed)
	timer=Timer.new()
	timer.wait_time=1
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()

func valid() -> bool:
	return active and not session_id.is_empty() and Time.get_ticks_msec()<valid_until

func set_target(product: String,token: String) -> void:
	if active and product_id==product and access_token==token:
		_tick()
		return
	stop()
	product_id=product
	access_token=token
	active=true
	next_request=0
	_tick()

func stop() -> HTTPRequest:
	var prior=session_id
	var prior_token=access_token
	active=false
	session_id=""
	valid_until=0
	next_request=0
	request_kind=""
	if request_node!=null: request_node.cancel_request()
	last_valid=false
	changed.emit()
	if not prior.is_empty(): return _stop_remote(prior,prior_token)
	return null

func finish() -> void:
	var closing=stop()
	if is_instance_valid(closing): await closing.request_completed

func _stop_remote(id: String,token: String) -> HTTPRequest:
	if not is_inside_tree() or site_url.is_empty(): return null
	var stop_request=HTTPRequest.new()
	stop_request.timeout=5
	stop_request.max_redirects=0
	add_child(stop_request)
	stop_request.request_completed.connect(func(_a,_b,_c,_d): stop_request.queue_free())
	var err=stop_request.request(site_url+"/api/game/usage/stop",PackedStringArray(["Content-Type: application/json","Authorization: Bearer "+token]),HTTPClient.METHOD_POST,JSON.stringify({"sessionId":id,"instanceId":instance_id}))
	if err!=OK:
		stop_request.queue_free()
		return null
	return stop_request

func _tick() -> void:
	var current=valid()
	if current!=last_valid:
		last_valid=current
		changed.emit()
	if not active or request_node==null or not request_kind.is_empty() or Time.get_ticks_msec()<next_request: return
	request_kind="start" if session_id.is_empty() else "heartbeat"
	var data={"productId":product_id} if request_kind=="start" else {"sessionId":session_id}
	data["instanceId"]=instance_id
	var err=request_node.request(site_url+"/api/game/usage/"+request_kind,PackedStringArray(["Content-Type: application/json","Authorization: Bearer "+access_token]),HTTPClient.METHOD_POST,JSON.stringify(data))
	if err!=OK: _failed()

func _accept(data: Dictionary) -> bool:
	if not data.get("sessionId") is String or data.sessionId.is_empty() or data.sessionId.length()>160: return false
	if not data.get("validForSeconds") is float and not data.get("validForSeconds") is int: return false
	if not data.get("heartbeatAfterSeconds") is float and not data.get("heartbeatAfterSeconds") is int: return false
	var seconds=float(data.validForSeconds)
	var heartbeat=float(data.heartbeatAfterSeconds)
	if not is_finite(seconds) or not is_finite(heartbeat) or seconds<=0 or seconds>90 or heartbeat<=0 or heartbeat>=seconds: return false
	if not session_id.is_empty() and data.sessionId!=session_id: return false
	session_id=data.sessionId
	valid_until=Time.get_ticks_msec()+int(seconds*1000)
	next_request=Time.get_ticks_msec()+int(minf(heartbeat,30)*1000)
	last_error=""
	return true

func _completed(result: int,status: int,_headers: PackedStringArray,response: PackedByteArray) -> void:
	if request_kind.is_empty() or not active: return
	request_kind=""
	var data=JSON.parse_string(response.get_string_from_utf8())
	if result!=HTTPRequest.RESULT_SUCCESS or status!=200 or not data is Dictionary or not _accept(data):
		_failed()
		return
	last_valid=valid()
	changed.emit()

func _failed() -> void:
	var prior=session_id
	session_id=""
	valid_until=0
	request_kind=""
	next_request=Time.get_ticks_msec()+30000
	last_valid=false
	last_error="실행시간 연결이 끊겨 잠시 쉬고 있어요. 인터넷 연결 후 자동으로 다시 확인해요."
	changed.emit()
	if not prior.is_empty(): _stop_remote(prior,access_token)
