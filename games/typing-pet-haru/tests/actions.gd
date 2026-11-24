extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var app=preload("res://tests/visual_app.gd").new()
 app.combo_effects=false
 root.add_child(app)
 app.bridge.connected=true
 app.bridge.key_delta=1
 app.widget=preload("res://scripts/widget.gd").new()
 app.widget.app=app
 app.add_child(app.widget)
 var tested_states=0
 var sheet=Image.create(1008,1984,false,Image.FORMAT_RGBA8)
 for species in range(16):
  for action in range(5):
   app.species=species
   app.widget.load_friend()
   assert(app.widget.action_frames.is_empty())
   app.widget.side=0
   tested_states+=1
   app.report.tier=action
   app.report.combo=action*100
   app.report.remaining=1
   for tick in range(24): app.widget.advance(1.0/60,1)
   assert(app.widget.index==1,"Fixed typing cadence independent of tier")
   assert(app.widget.action_time==0)
   assert(app.widget.body_offset==Vector2.ZERO)
   assert(app.widget.pet_root.position==Vector2.ZERO)
   assert(app.widget.sprite.modulate==Color.WHITE)
   assert(app.widget.sprite.material.get_shader_parameter("body_motion")==Vector2.ZERO)
   assert(app.widget.combo_fx.particles.is_empty())
   assert(not app.widget.action_sprite.visible and app.widget.sprite.modulate.a==1)
   await process_frame
   await RenderingServer.frame_post_draw
   var frame=app.widget.get_texture().get_image()
   var slot=species*2+mini(action,1)
   sheet.blit_rect(frame,Rect2i(0,0,252,248),Vector2i((slot%4)*252,(slot/4)*248))
 sheet.save_png("res://builds/review/actions-48.png")
 app.species=0
 app.widget.load_friend()
 app.report.tier=2
 app.report.combo=90
 for tick in range(24): app.widget.advance(1.0/60,1)
 app.widget.refresh_text()
 await process_frame
 await RenderingServer.frame_post_draw
 var layout=Image.create(app.widget.footprint_for(1).x,app.widget.footprint_for(1).y,false,Image.FORMAT_RGBA8)
 for win in [root,app.widget,app.widget.footer,app.widget.gift_window]:
  var im=win.get_texture().get_image()
  layout.blend_rect(im,Rect2i(Vector2i.ZERO,im.get_size()),win.position-app.widget.anchor_position)
 layout.save_png("res://builds/review/actions-layout.png")
 for zoom in [.7,1.,1.5]:
  app.scale_factor=zoom
  app.widget.place()
  var animal_center=app.widget.position.x+app.widget.WIDGET_WIDTH/2*zoom
  var number_center=root.position.x+(app.widget.combo_number.position.x+app.widget.combo_number.size.x/2)*app.widget.header_root.scale.x
  assert(abs(animal_center-number_center)<2,"Shared visual center")
  var gauge_bottom=root.position.y+72*app.widget.header_root.scale.y
  var head_top=app.widget.position.y+(app.widget.animal_root_y()+app.widget.HEAD_TOP_PX*200/1024)*zoom
  assert(abs(head_top-gauge_bottom-app.widget.HEAD_GAP*zoom)<1.5,"Head gap stays fixed at all zooms")
  assert(app.widget.footprint_for(zoom).y<ceil(232*zoom+(68+app.widget.footer_height())*maxf(1,zoom)))
 app.report.tier=0
 app.widget.advance(.3,0)
 assert(not app.widget.action_sprite.visible and app.widget.sprite.modulate.a==1)
 for tier in range(1,5):
  for retry in range(3):
   app.widget.action_time=0
   app.widget.action_cooldown=0
   app.widget.advance_action(.1,tier,true)
   assert(app.widget.action_time==0 and not app.widget.action_sprite.visible,"All combo poses disabled")
 app.bridge.key_delta=0
 app.widget.advance(1,1)
 assert(app.widget.levels.all(func(v): return v==0),"Mouse input must not light keyboard")
 app.bridge.key_delta=1
 app.widget.advance(.016,1)
 assert(app.widget.levels.has(1.0),"Keyboard input lights a key")
 assert(app.widget.gift_window.position.x+38*app.widget.footer_root.scale.x<app.widget.footer.position.x+app.widget.apm_label.position.x*app.widget.footer_root.scale.x)
 assert(abs(app.widget.gift_window.position.y-app.widget.footer.position.y)<=3)
 # Capture the ordinary idle state as well as the existing lie/cheer reviews.
 app.species=12
 app.scale_factor=1.0
 app.text_scale=1.0
 app.widget.load_friend()
 app.widget.place()
 app.report.tier=0
 app.report.combo=0
 app.report.remaining=0
 app.bridge.key_delta=0
 app.widget.advance(1.0,0)
 app.widget.refresh_text()
 await process_frame
 await RenderingServer.frame_post_draw
 var idle_layout=Image.create(app.widget.footprint_for(1).x,app.widget.footprint_for(1).y,false,Image.FORMAT_RGBA8)
 for win in [root,app.widget,app.widget.footer,app.widget.gift_window]:
  var im=win.get_texture().get_image()
  idle_layout.blend_rect(im,Rect2i(Vector2i.ZERO,im.get_size()),win.position-app.widget.anchor_position)
 assert(idle_layout.save_png("res://builds/review/haru-compact-typing.png")==OK)
 app.combo_effects=true
 var fx=app.widget.combo_fx
 for level in range(1,5):
  app.report.tier=level
  app.report.combo=[0,30,90,180,300][level]
  app.report.remaining=1
  app.bridge.key_delta=1
  fx.reset(0)
  app.widget.advance(.01,1)
  assert(fx.particles.size()==[0,3,3,4,5][level])
  assert(fx.bubble_time>1.3)
  var previous=fx.bubble_text
  for repeat in range(8):
   fx.reset(0)
   app.widget.advance(.01,1)
   assert(fx.bubble_text!=previous,"No consecutive repeated phrase")
   previous=fx.bubble_text
  for zoom in [.7,1.,1.5]:
   app.scale_factor=zoom
   app.widget.place()
   for species in range(16):
    app.species=species
    app.widget.load_friend()
    app.widget.advance(.01,1)
    for phrase in fx.WORDS[level]:
     for side in [-1,1]:
      fx.bubble_side=side
      fx.bubble_text=phrase
      var local_rect=fx.bubble_rect().grow(7)
      var rect=fx.get_global_transform()*local_rect
      assert(Rect2(Vector2.ZERO,Vector2(app.widget.size)).encloses(rect),"Bubble inside native window")
      var screen_rect=Rect2(rect.position+Vector2(app.widget.position),rect.size)
      assert(not screen_rect.intersects(Rect2(Vector2(root.position),Vector2(root.size))),"Bubble avoids header")
  app.species=12
  app.scale_factor=1
  app.widget.load_friend()
  app.widget.place()
  fx.reset(0)
  app.widget.advance(.01,1)
  app.widget.advance(.1,1)
  app.widget.refresh_text()
  if level in [1,4]: await capture(app,"combo-fun-rise-%d.png"%app.report.combo)
  fx.reset(level)
  var seen={}
  for tick in range(151):
   app.widget.advance(.1,1)
   assert(fx.ambient_count()<=4,"Ambient particle limit")
   for p in fx.particles: seen[p.kind]=true
   assert(abs(app.widget.combo_bar.shimmer_amount)<=.12001)
   if level==2 and tick==72 or level in [3,4] and tick==52:
    if level==4: fx.emit_particle("tap",.8,1)
    await capture(app,"combo-fun-typing-%d.png"%level)
  assert(seen.has("note"))
  if level>=2: assert(seen.has("sweat") and fx.blush>0)
  if level>=3: assert(seen.has("steam") and seen.has("sparkle"))
  if level==4: assert(seen.has("tap") and fx.bob>=0 and fx.bob<=1.5)
  app.bridge.key_delta=0
  var sighs=fx.rest_count
  for tick in range(10): app.widget.advance(.1,0)
  assert(fx.ambient_count()==0 and fx.blush==0 and fx.bob==0 and app.widget.combo_bar.shimmer_amount==0)
  for tick in range(21): app.widget.advance(.1,0)
  assert(fx.rest_count==sighs+(1 if level>=2 else 0),"One rest bubble after 3 seconds")
  if level>=2: assert(fx.bubble_text=="휴…" and fx.bubble_time>0)
  for tick in range(30): app.widget.advance(.1,0)
  assert(fx.rest_count==sighs+(1 if level>=2 else 0) and fx.bubble_time==0)
  app.combo_effects=false
  app.bridge.key_delta=1
  app.widget.advance(.01,1)
  assert(fx.particles.is_empty() and fx.bubble_time==0 and fx.blush==0 and fx.bob==0 and fx.hop_remaining==0)
  assert(app.widget.combo_number.pop_time==0 and app.widget.pet_root.position==Vector2.ZERO)
  app.combo_effects=true
 assert(await verify_particle_render(app))
 var idle_sheet=Image.create(640,640,false,Image.FORMAT_RGBA8)
 for y in range(640):
  for x in range(640): idle_sheet.set_pixel(x,y,Color("e0d8ce") if (x/10+y/10)%2==0 else Color("fff7ec"))
 for species in range(16):
  var thumb=Image.new()
  thumb.load_png_from_buffer(FileAccess.get_file_as_bytes(preload("res://scripts/catalog.gd").folder(species)+"/idle.png"))
  thumb.resize(160,160,Image.INTERPOLATE_LANCZOS)
  idle_sheet.blend_rect(thumb,Rect2i(0,0,160,160),Vector2i((species%4)*160,(species/4)*160))
 assert(idle_sheet.save_png("res://builds/review/haru-16-idle.png")==OK)
 app.free()
 assert(tested_states==80)
 print("ACTIONS_PASS: 80 states, ambient <=4, hearts=3/3/4/5, bubbles bounded/header clear at 3 zooms, toggle off=0, idle 1s=0, sigh once; rendered tap/steam overlap=0")
 quit()

func capture(app,path: String):
 await process_frame
 await RenderingServer.frame_post_draw
 var image=Image.create(app.widget.footprint_for(1).x,app.widget.footprint_for(1).y,false,Image.FORMAT_RGBA8)
 for win in [root,app.widget,app.widget.footer,app.widget.gift_window]:
  var im=win.get_texture().get_image()
  image.blend_rect(im,Rect2i(Vector2i.ZERO,im.get_size()),win.position-app.widget.anchor_position)
 assert(image.save_png("res://builds/review/"+path)==OK)

func verify_particle_render(app):
 app.scale_factor=1
 app.widget.place()
 var fx=app.widget.combo_fx
 var hidden=[]
 for child in app.widget.root.get_children():
  if child!=fx and child!=app.widget.pet_root and child is CanvasItem and child.visible:
   hidden.append(child)
   child.hide()
 for species in range(16):
  app.species=species
  app.widget.load_friend()
  fx.reset(4)
  fx.activity=1
  fx.blush=0
  fx.bubble_time=0
  app.widget.pet_root.position=Vector2.ZERO
  app.widget.pet_root.scale=Vector2.ONE
  for frame in app.widget.frames:
   app.widget.sprite.texture=frame
   fx.hide()
   await process_frame
   await RenderingServer.frame_post_draw
   var animal=app.widget.get_texture().get_image()
   app.widget.pet_root.hide()
   fx.show()
   fx.particles.clear()
   for side in [-1,1]:
    fx.emit_particle("tap",.8,side)
    fx.emit_particle("steam",1.2,side)
   fx.queue_redraw()
   await process_frame
   await RenderingServer.frame_post_draw
   var effect=app.widget.get_texture().get_image()
   for y in range(effect.get_height()):
    for x in range(effect.get_width()):
     if animal.get_pixel(x,y).a>.05 and effect.get_pixel(x,y).a>.05:
      print("OVERLAP species=",species," x=",x," y=",y)
      animal.save_png("res://builds/review/debug-animal.png")
      effect.save_png("res://builds/review/debug-effect.png")
      return false
   app.widget.pet_root.show()
 fx.reset()
 for child in hidden: child.show()
 return true
