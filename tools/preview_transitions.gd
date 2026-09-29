extends SceneTree
const V=preload("res://scripts/desktop_pet_view.gd")
const M=preload("res://scripts/desktop_pet_motion.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 root.size=Vector2i.ONE
 var vp=SubViewport.new()
 vp.size=Vector2i(1224,570)
 vp.transparent_bg=true
 vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(vp)
 var actions=["idle","wander","look","react","eat","signature","doze","prop_use","prop_use","idle","react","signature","idle","wander","eat","prop_use","doze","react"]
 for i in range(18):
  var m=M.new()
  m.species=4
  m.growth_stage=2 if i<12 else 0
  m.growth_scale=1.0 if i<12 else .62
  m.phase=actions[i]
  m.carried=i==9
  m.visit_id="plant" if i in [7,15] else "lamp"
  m.prop_progress=1.5
  m.reaction="yum" if i==10 else "pet"
  m.elapsed=.4 if i<6 else 1.2
  m.reaction_time=m.elapsed
  m.walk_phase=.1 if i<6 else .6
  var v=V.new()
  v.motion=m
  v.position=Vector2(i%6*204,i/6*190)
  vp.add_child(v)
  v.refresh()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 vp.get_texture().get_image().save_png("res://builds/raccoon-all-after.png")
 quit()
