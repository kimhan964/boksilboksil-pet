extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var timer=preload("res://scripts/combo_timer.gd").new()
 for pair in [[.8,Color("a8d5a2")],[.5,Color("f6d98b")],[.1,Color("f2a3a0")]]:
  timer.value=pair[0]
  assert(timer.fill_color()==pair[1])
 timer.advance_shimmer(.375,4,1)
 assert(abs(timer.shimmer_amount-.12)<.001)
 timer.advance_shimmer(0,4,0)
 assert(timer.shimmer_amount==0)
 timer.free()
 var saved_app=preload("res://scripts/main.gd").new()
 saved_app.save_path="res://builds/review/combo-toggle-test.json"
 assert(saved_app.combo_effects,"Default is enabled")
 for enabled in [false,true]:
  saved_app.combo_effects=enabled
  saved_app.save_game()
  assert(not saved_app.save_error)
  saved_app.combo_effects=not enabled
  saved_app.load_game()
  assert(saved_app.combo_effects==enabled)
 saved_app.free()
 var r=preload("res://scripts/typing_report.gd").new()
 var stamp={"year":2026,"month":10,"day":14,"hour":10,"minute":0,"second":0}
 r.step(0,30,true,stamp)
 assert(r.combo==30 and r.tier==1)
 r.step(1000,60,true,stamp)
 assert(r.combo==90 and r.tier==2)
 r.step(60000,0,true,stamp)
 assert(r.combo==0) # sleep gap clears transient rate
 var timeout=preload("res://scripts/typing_report.gd").new()
 timeout.step(0,30,true,stamp)
 for ms in [1000,2000,3000,4000,4999]: timeout.step(ms,0,true,stamp)
 assert(timeout.combo==30 and timeout.remaining>0)
 timeout.step(5000,0,true,stamp)
 assert(timeout.combo==0 and timeout.tier==0 and timeout.remaining==0)
 timeout.step(5001,1,true,stamp)
 assert(timeout.combo==1 and timeout.remaining==1)
 var restored=preload("res://scripts/typing_report.gd").new()
 restored.restore(JSON.parse_string(JSON.stringify(r.days)))
 assert(restored.summary("2026-10-14").keys==90)
 assert(restored.summary("2026-10-14").combos==2)
 var rolling=preload("res://scripts/typing_report.gd").new()
 for sec in range(61): rolling.step(sec*1000,1,true,stamp)
 assert(rolling.combo==60)
 rolling.step(61000,0,false,stamp)
 assert(rolling.combo==0 and rolling.tier==0)
 var other=stamp.duplicate()
 other.day=15
 other.hour=0
 rolling.step(62000,5,true,other)
 assert(rolling.summary("2026-10-15").keys==5)
 var input=preload("res://scripts/typing_input.gd").new()
 input.socket=PacketPeerUDP.new()
 assert(input.socket.bind(0,"127.0.0.1")==OK)
 input.token="test"
 var sender=PacketPeerUDP.new()
 sender.set_dest_address("127.0.0.1",input.socket.get_local_port())
 sender.put_packet("test:7:4".to_ascii_buffer())
 await create_timer(.05).timeout
 assert(input.poll()==7 and input.key_delta==4)
 sender.put_packet("test:10:4".to_ascii_buffer())
 await create_timer(.05).timeout
 assert(input.poll()==3 and input.key_delta==0) # mouse-only: no combo inflation
 input.stop()
 sender.close()
 var app=preload("res://tests/visual_app.gd").new()
 app.combo_effects=false
 root.add_child(app)
 app.report=r
 app.bridge.connected=true
 app.widget=preload("res://scripts/widget.gd").new()
 app.widget.app=app
 app.add_child(app.widget)
 app.settings=preload("res://scripts/settings.gd").new()
 app.settings.app=app
 app.add_child(app.settings)
 app.settings.rebuild()
 var toggle_found=false
 for button in app.settings.find_children("*","Button",true,false):
  if button.text.begins_with("콤보 효과"):
   button.button_pressed=true
   assert(app.combo_effects)
   button.button_pressed=false
   assert(not app.combo_effects)
   toggle_found=true
 assert(toggle_found)
 app.settings.tabs.current_tab=3
 app.settings.show()
 app.widget.refresh_text()
 assert(app.widget.status.text.begins_with("COMBO"))
 assert(app.widget.apm_label.get_parent()==app.widget.footer_root)
 assert(app.widget.footer.position.y>=app.widget.position.y+app.widget.size.y-16)
 for scale_ in [.9,1.0,1.3]:
  app.text_scale=scale_
  app.widget.apply_text_size()
  assert(app.widget.gift_button.position.y+app.widget.gift_button.size.y<=app.widget.header_panel.size.y)
 # Restore the default scale before checking the fixed 334px default footprint.
 app.text_scale=1.0
 app.widget.apply_text_size()
 app.report.tier=4
 app.report.remaining=1.0
 app.widget.advance(.1,0)
 assert(app.widget.expression==Vector2.ZERO,"Haru rabbit eye deformation stays disabled")
 for species in range(1,16):
  app.species=species
  app.widget.load_friend()
  assert(app.widget.frames.size()==3,"Every species has usable typing frames")
  app.widget.advance(.1,0)
  assert(app.widget.expression==Vector2.ZERO,"All Danjjak species disable eye expressions")
 app.species=0
 app.widget.load_friend()
 assert(app.widget.sprite.material.get_shader_parameter("eye_expression")==Vector2.ZERO)
 for tier in range(5): app.widget.combo_fx.advance(.1,tier,true,false)
 await process_frame
 await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  DirAccess.make_dir_recursive_absolute("res://builds/review")
  app.settings.get_texture().get_image().save_png("res://builds/review/combo-report.png")
  root.get_texture().get_image().save_png("res://builds/review/combo-header.png")
  var header_image=root.get_texture().get_image()
  assert(header_image.get_pixel(0,0).a<.01,"HUD background must be transparent")
  assert(app.widget.gift_window.get_texture().get_image().get_pixel(20,20).a>.99,"Gift hit surface must stay opaque")
  assert(app.widget.footer.get_texture().get_image().get_pixel(0,0).a<.01)
  assert(app.widget.footprint_for(1).y<334)
  app.widget.footer.get_texture().get_image().save_png("res://builds/review/combo-footer.png")
  app.report.combo=300
  app.report.tier=4
  app.report.remaining=1.0
  app.bridge.key_delta=1
  app.widget.advance(.1,1)
  app.widget.advance(.12,0)
  app.widget.refresh_text()
  await process_frame
  await RenderingServer.frame_post_draw
  app.widget.get_texture().get_image().save_png("res://builds/review/combo-v2-super.png")
  root.get_texture().get_image().save_png("res://builds/review/combo-v2-super-header.png")
  assert(app.widget.body_offset==Vector2.ZERO)
  assert(app.widget.status.get_theme_font_size("font_size")>=12)
  assert(app.widget.status.get_theme_font_size("font_size")<=roundi(17*app.text_scale))
  assert(app.widget.combo_fx.particles.size()<=5)
  assert(not app.widget.combo_fx.visible)
  app.widget.combo_number.advance(0,7,0,true,1.0,false)
  await process_frame
  await RenderingServer.frame_post_draw
  var pop_frame=root.get_texture().get_image().get_data()
  app.widget.combo_number.advance(.25,7,0,false,1.0,false)
  await process_frame
  await RenderingServer.frame_post_draw
  assert(pop_frame==root.get_texture().get_image().get_data(),"Static counter must not pop")
  app.widget.combo_number.advance(0,8,0,true,1.0,true)
  assert(app.widget.combo_number.count==8,"Counter still updates")
  assert(app.widget.combo_number.pop_time==.12)
  app.widget.combo_number.advance(.13,8,0,false,1.0,true)
  assert(app.widget.combo_number.pop_time==0)
  app.widget.combo_fx.advance(.1,4,true,false)
  assert(app.widget.combo_fx.particles.is_empty())
  var report_view=app.settings.tabs.get_child(3)
  report_view.scroll_vertical=100000
  await process_frame
  await RenderingServer.frame_post_draw
  app.settings.get_texture().get_image().save_png("res://builds/review/combo-weekly.png")
 app.free()
 print("COMBO_REPORT_PASS: tier data, timeout, persistence, combo toggle save/UI, subtle counter pop, gauge shimmer, compact header")
 quit()
