extends RefCounted
# Independent implementation of the mathematical estimator in BW APMAlert/Main.pas.
# https://github.com/tec27/APMAlert/blob/321411a11ce649d47fd7c3f44b7ef5ed6271375b/Main.pas
const TAU_MS=57000.0
const MIN_DURATION_MS=10000
const IDLE_MS=30000
var total=0
var apm=0
var active_ms=0
var elapsed_ms=0
var weighted_actions=0.0
var last_tick=-1
var last_action=-1
var sampling=false

func update(now: int, actions: int, enabled: bool) -> void:
	var dt=maxi(0,now-last_tick) if last_tick>=0 and sampling and enabled else 0
	if last_action>=0 and dt>0:
		active_ms+=maxi(0,mini(now,last_action+IDLE_MS)-last_tick)
	last_tick=now
	sampling=enabled
	if not enabled:
		last_action=-1
		weighted_actions=0.0
		elapsed_ms=0
		apm=0
		return
	elapsed_ms+=dt
	weighted_actions*=exp(-float(dt)/TAU_MS)
	if actions>0:
		total+=actions
		weighted_actions+=actions
		last_action=now
	# Numeric from the first input; a 10-second minimum denominator prevents startup spikes.
	var duration_factor=maxf(.01,1.0-exp(-float(maxi(elapsed_ms,MIN_DURATION_MS))/TAU_MS))
	apm=int(weighted_actions/(.95*duration_factor))

func suspend(now: int) -> void:
	update(now,0,sampling)
	update(now,0,false)
func time_text() -> String:
	var seconds=int(active_ms/1000)
	return "%02d:%02d:%02d"%[int(seconds/3600),int(seconds/60)%60,seconds%60]
