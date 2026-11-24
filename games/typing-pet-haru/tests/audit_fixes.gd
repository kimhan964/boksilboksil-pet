extends SceneTree
const Report=preload("res://scripts/typing_report.gd")
const Widget=preload("res://scripts/widget.gd")
var failures=0
class SaveCounter extends "res://scripts/main.gd":
	var saves=0
	func save_game() -> void:
		saves+=1
		save_dirty=false
class QuietWidget extends RefCounted:
	func advance(_delta: float,_count: int) -> void: pass
class QuietSettings extends RefCounted:
	var visible=false
class InputProbe extends RefCounted:
	var count=0
	var key_delta=0
	var connected=true
	func poll() -> int: return count
	func stop() -> void: pass
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
func run() -> void:
	var report=Report.new()
	var late={"year":2026,"month":11,"day":9,"hour":23,"minute":59,"second":59}
	var early={"year":2026,"month":11,"day":10,"hour":0,"minute":0,"second":0}
	report.step(0,1,true,late)
	report.step(1000,0,true,early)
	report.step(1100,0,true,early)
	check(not report.days.get("2026-11-10",{}).has("first"),"midnight activity tail is not first typing")
	var morning=early.duplicate()
	morning.hour=9
	report.step(32401000,1,true,morning)
	check(report.days["2026-11-10"].first=="09:00","actual morning key sets first typing")
	report.step(32401016,0,true,morning)
	check(report.remaining<1 and report.remaining>.99,"countdown still changes every frame")
	report.step(32413000,0,true,morning)
	var revision=report.revision
	for i in range(120): report.step(32413000+i*16,0,true,morning)
	check(report.revision==revision and report.combo==0,"idle report does not dirty persistent state")
	var cutoff=report.date_stamp("2026-11-10")-369*86400
	var retained=Time.get_date_string_from_unix_time(cutoff)
	var expired=Time.get_date_string_from_unix_time(cutoff-86400)
	var restored=Report.new()
	restored.restore({retained:{"hours":{}},expired:{"hours":{}},"2026-02-30":{"hours":{}},"2026-11-11":{"hours":{}}},early)
	check(restored.days.has(retained) and not restored.days.has(expired) and not restored.days.has("2026-02-30"),"370-day cutoff validates real calendar dates")
	check(restored.days.has("2026-11-11"),"clock rollback preserves valid future history")
	restored.prune("2026-11-11")
	check(not restored.days.has(retained),"new day advances retention cutoff")
	var screens=[Rect2i(0,0,1920,1040),Rect2i(-1600,0,1600,860)]
	check(Widget.screen_for_bounds(Rect2i(-1200,100,252,334),screens)==screens[1],"saved secondary-monitor position survives")
	check(Widget.screen_for_bounds(Rect2i(-200,100,252,334),screens)==screens[1],"largest monitor overlap wins")
	check(Widget.screen_for_bounds(Rect2i(4000,100,252,334),screens)==screens[0],"disconnected monitor falls back to primary")
	check(Widget.screen_for_point(Vector2i(-500,880),screens)==screens[1],"taskbar pointer stays on nearest monitor")
	var counter=SaveCounter.new()
	counter.widget=QuietWidget.new()
	counter.settings=QuietSettings.new()
	counter.bridge=InputProbe.new()
	counter.collection.credit(0,0)
	counter.save_dirty=false
	for i in range(120): counter._process(.1)
	check(counter.saves==0,"idle frames do not rewrite save")
	counter.bridge.count=1
	counter.bridge.key_delta=1
	counter._process(.1)
	check(counter.save_dirty,"new input marks save dirty")
	counter.bridge.count=0
	counter._process(5.0)
	check(counter.saves==1,"dirty progress is autosaved")
	counter.free()
	var app=preload("res://tests/visual_app.gd").new()
	root.add_child(app)
	app.bridge.connected=true
	app.widget=Widget.new()
	app.widget.app=app
	app.add_child(app.widget)
	app.settings=preload("res://scripts/settings.gd").new()
	app.settings.app=app
	app.add_child(app.settings)
	app.widget.refresh_text()
	check(app.widget.footer_row_height()==17 and app.widget.footer.size.y==34 and app.widget.footprint_for(1)==Vector2i(252,334),"100% footer keeps original pixel geometry")
	check(app.widget.gift_window.position.y==app.widget.footer.position.y-2,"100% gift keeps original vertical placement")
	app.text_scale=1.3
	app.widget.apply_text_size()
	var label_=app.widget.detail
	check(app.widget.footer_row_height()>=label_.get_theme_font("font").get_height(label_.get_theme_font_size("font_size"))+8,"large footer fits font and outline")
	check(app.widget.footer.size.y==app.widget.footer_row_height()*2,"footer native bounds follow measured rows")
	check(abs((app.widget.gift_window.position.y+19)-(app.widget.footer.position.y+app.widget.footer.size.y/2.0))<=1,"large footer gift stays vertically centered")
	app.settings.rebuild()
	var view=app.settings.tabs.get_child(3)
	var heading=view.body.get_child(0).get_child(0).get_child(0)
	var pixels=heading.get_theme_font_size("font_size")
	view.rebuild()
	heading=view.body.get_child(0).get_child(0).get_child(0)
	check(pixels==26 and heading.get_theme_font_size("font_size")==pixels,"report refresh does not shrink double-scaled text")
	app.report.tier=1
	app.widget.advance_action(.01,1,true)
	app.widget.advance_action(1.5,1,false)
	app.widget.advance_action(.01,2,true)
	check(app.widget.action_index==1 and app.widget.action_time>0 and app.widget.action_cooldown>0,"tier-up cooldown bypass remains intentional")
	app.widget.combo_fx.advance(.01,2,true,true)
	check(app.widget.combo_fx.judgment>0 and not app.widget.combo_fx.particles.is_empty(),"effects start immediately on input")
	app.widget.combo_fx.advance(2,0,false,true)
	check(app.widget.combo_fx.particles.is_empty() and app.widget.combo_fx.judgment==0,"effects expire completely")
	app.widget.combo_fx.advance(.01,2,true,true)
	app.widget.combo_fx.advance(0,2,false,false)
	check(app.widget.combo_fx.particles.is_empty() and not app.widget.combo_fx.aura.visible,"effects off clears existing visuals")
	var sparkles=preload("res://scripts/gift_sparkles.gd").new()
	app.add_child(sparkles)
	sparkles.restart()
	sparkles._process(2.1)
	check(not sparkles.visible and not sparkles.is_processing(),"expired gift sparkles stop processing")
	sparkles.restart()
	check(sparkles.visible and sparkles.is_processing() and sparkles.age==0,"gift sparkles restart immediately")
	await process_frame
	await process_frame
	app.queue_free()
	await process_frame
	await process_frame
	if failures==0: print("AUDIT_FIXES_PASS: save dirtiness, midnight, retention, monitors, footer, report scale, effect restart, intended cooldown bypass")
	quit(1 if failures else 0)
