extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var vp=SubViewport.new()
 vp.size=Vector2i(960,560)
 vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(vp)
 var bg=ColorRect.new()
 bg.size=vp.size
 bg.color=Color("faf5ec")
 vp.add_child(bg)
 for row in range(2):
  var animal=["panda","red_panda"][row]
  for col in range(4):
   var path="res://assets/typing-animals-v1/"+animal+"/idle.png" if col==0 else "res://assets/typing-soft-v2/"+animal+"/"+["idle","left","right"][col-1]+".png"
   var im=Image.new()
   im.load(path)
   var s=Sprite2D.new()
   s.texture=ImageTexture.create_from_image(im)
   s.scale=Vector2.ONE*220/im.get_width()
   s.position=Vector2(120+240*col,155+280*row)
   vp.add_child(s)
   var l=Label.new()
   l.text=animal+" "+["BEFORE","NEW idle","NEW left","NEW right"][col]
   l.position=Vector2(15+240*col,10+280*row)
   l.modulate=Color("60524a")
   vp.add_child(l)
 await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://builds/review")
 vp.get_texture().get_image().save_png("res://builds/review/soft-friends.png")
 quit()
