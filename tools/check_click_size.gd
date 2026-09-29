extends SceneTree
const V=preload("res://scripts/desktop_pet_view.gd")
const M=preload("res://scripts/desktop_pet_motion.gd")
const Outline=preload("res://scripts/animation_outline.gd")
var failures=0
func _initialize() -> void: call_deferred("run")
func height(v) -> float:
 return v.Metrics.used_rect(v.sprite.texture).size.y*absf(v.sprite.scale.y)
func run() -> void:
 for species in range(16):
  var m=M.new()
  m.species=species
  var v=V.new()
  v.motion=m
  root.add_child(v)
  for stage in range(3):
   m.growth_stage=stage
   m.growth_scale=[.62,.82,1.0][stage]
   m.phase="idle"
   m.joy_left=0
   v.refresh()
   Outline.fit(v.sprite,V.FEET,Vector2(204,190))
   var idle=height(v)
   m.phase="react"
   m.reaction="pet"
   for tick in range(27):
    m.reaction_time=tick*.1
    v.refresh()
    Outline.fit(v.sprite,V.FEET,Vector2(204,190))
    if absf(height(v)/idle-1)>.03:
     failures+=1
     print("SIZE_MISMATCH ",species," stage=",stage," tick=",tick," ratio=",height(v)/idle)
  v.free()
 print("CLICK_SIZE_POSES=1296 FAILURES=",failures)
 quit(1 if failures else 0)
