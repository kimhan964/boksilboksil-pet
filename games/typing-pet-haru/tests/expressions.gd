extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var app=preload("res://tests/visual_app.gd").new()
 root.add_child(app)
 app.bridge.connected=true
 app.widget=preload("res://scripts/widget.gd").new()
 app.widget.app=app
 app.add_child(app.widget)
 var sheet=Image.create(1008,992,false,Image.FORMAT_RGBA8)
 for species in range(16):
  app.species=species
  app.widget.load_friend()
  app.report.tier=4
  app.report.combo=300
  app.report.remaining=1
  for tick in range(30): app.widget.advance(1.0/60,1)
  await process_frame
  await RenderingServer.frame_post_draw
  var frame=app.widget.get_texture().get_image()
  assert(app.widget.expression.x>.4)
  assert(app.widget.mouse_passthrough_polygon.is_empty())
  sheet.blit_rect(frame,Rect2i(0,0,252,248),Vector2i((species%4)*252,(species/4)*248))
 sheet.save_png("res://builds/review/expressions-all.png")
 app.report.tier=3
 for tick in range(30): app.widget.advance(1.0/60,1)
 assert(abs(app.widget.expression.x-app.widget.expression.y)<.001,"No asymmetric wink")
 var fx=app.widget.combo_fx
 fx.advance(.7,3,true,true)
 assert(fx.judgment>0 and fx.judgment_tier==3)
 fx.advance(.7,3,true,true)
 assert(fx.judgment>0,"Judgment repeats during continued typing")
 fx.advance(.7,3,false,true)
 assert(fx.judgment==0,"Judgment fades without input")
 assert(not app.widget.settings_button.visible)
 assert(app.widget.gift_button.size.x==36)
 app.settings=preload("res://scripts/settings.gd").new()
 app.settings.app=app
 app.add_child(app.settings)
 app.settings.hide()
 var right=InputEventMouseButton.new()
 right.button_index=MOUSE_BUTTON_RIGHT
 right.pressed=true
 right.position=Vector2(100,40)
 app.widget.on_header_input(right)
 assert(app.settings.visible,"Right-click must open settings")
 app.settings.hide()
 app.widget.gift_button.pressed.emit()
 await process_frame
 assert(app.settings.visible,"Compact gift must still open rewards")
 app.free()
 print("EXPRESSIONS_PASS: 16 species, padded canvas, compact controls")
 quit()
