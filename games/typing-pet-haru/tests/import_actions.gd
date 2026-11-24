extends SceneTree
func _initialize():
 var rows=[[0,390,703,1058,1448],[0,352,710,1076,1448],[0,362,724,1086,1448],[0,362,724,1086,1448]]
 var config_path="res://assets/combo-actions-v1/rows.json"
 if FileAccess.file_exists(config_path): rows=JSON.parse_string(FileAccess.get_file_as_string(config_path))
 for group in range(4):
  var path="res://assets/combo-actions-v1/group-%d.png"%group
  if not FileAccess.file_exists(path): continue
  var source=Image.new()
  source.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
  for row in range(4):
   for col in range(3):
    var x0=roundi(source.get_width()*col/3.0)
    var x1=roundi(source.get_width()*(col+1)/3.0)
    var cel=source.get_region(Rect2i(x0,rows[group][row],x1-x0,rows[group][row+1]-rows[group][row]))
    var used=cel.get_used_rect()
    # Locate the keyboard on the bottom tenth of each cutout, using solid pixels only.
    var left=cel.get_width()
    var right=0
    var bottom=0
    for y in range(cel.get_height()):
     for x in range(cel.get_width()):
      if cel.get_pixel(x,y).a>.8: bottom=maxi(bottom,y)
    for y in range(maxi(0,bottom-18),bottom+1):
     for x in range(cel.get_width()):
      if cel.get_pixel(x,y).a>.8:
       left=mini(left,x)
       right=maxi(right,x)
    var factor=384.0/maxi(1,right-left+1)
    factor=minf(factor,450.0/maxi(1,used.size.y))
    var center=(left+right)/2.0
    cel.resize(roundi(cel.get_width()*factor),roundi(cel.get_height()*factor),Image.INTERPOLATE_LANCZOS)
    var out=Image.create(512,512,false,Image.FORMAT_RGBA8)
    out.blit_rect(cel,Rect2i(Vector2i.ZERO,cel.get_size()),Vector2i(roundi(256-center*factor),roundi(472-bottom*factor)))
    out.save_png("res://assets/combo-actions-v1/pet-%d-action-%d.png"%[group*4+row,col])
 print("ACTION_CELS_IMPORTED")
 quit()
