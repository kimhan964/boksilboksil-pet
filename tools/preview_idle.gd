extends SceneTree
const V=preload("res://scripts/desktop_pet_view.gd")
const M=preload("res://scripts/desktop_pet_motion.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 root.size=Vector2i.ONE
 var vp=SubViewport.new()
 vp.size=Vector2i(612,190)
 vp.transparent_bg=true
 vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(vp)
 for i in range(3):
  var m=M.new()
  m.species=4
  m.growth_stage=1
  m.growth_scale=.82
  m.phase=["baseline","idle","react"][i]
  m.reaction="pet"
  var v=V.new()
  v.motion=m
  v.position=Vector2(i*204,0)
  vp.add_child(v)
  v.refresh()
  if i==0:
   v.sprite.scale*=126.0/110.0
   v.sprite.position=V.FEET+(v.sprite.position-V.FEET)*126.0/110.0
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 vp.get_texture().get_image().save_png("res://builds/idle-comparison.png")
 print("IDLE_COMPARE=old,new,pet")
 quit()
