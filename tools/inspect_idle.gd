extends SceneTree
func _initialize() -> void:
 var c=preload("res://scripts/animal_catalog.gd")
 for i in range(16):
  var a=load(c.path(i))
  var t=a.frames[0][0]
  print(c.IDS[i]," ",t.get_size())
  if i==4: t.get_image().save_png("res://builds/raccoon-idle-before.png")
 quit()
