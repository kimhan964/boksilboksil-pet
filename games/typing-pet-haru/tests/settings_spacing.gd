extends SceneTree
const Cozy=preload("res://scripts/cozy_ui.gd")
var checks=0
func _initialize(): run.call_deferred()
func verify(node: Node) -> void:
 if node is BoxContainer and node.is_visible_in_tree():
  var controls=[]
  for child in node.get_children():
   if child is Control and child.visible: controls.append(child)
  for i in range(1,controls.size()):
   var a: Control=controls[i-1]
   var b: Control=controls[i]
   var gap=b.position.x-a.position.x-a.size.x if node is HBoxContainer else b.position.y-a.position.y-a.size.y
   assert(gap>=Cozy.GRID-.6,"Adjacent gap below 8px: "+str(node.get_path())+" gap="+str(gap))
   checks+=1
 if node is ScrollContainer and node.is_visible_in_tree():
  assert(node.get_h_scroll_bar().max_value<=node.size.x+1,"Horizontal content overflow: "+str(node.get_path()))
 if node is Label and node.is_visible_in_tree():
  assert(node.get_theme_font_size("font_size")>=Cozy.MIN_FONT)
 if node is Button and node.is_visible_in_tree():
  assert(node.size.y>=Cozy.BUTTON_HEIGHT-.5)
  if not node is OptionButton:
   var style=node.get_theme_stylebox("normal")
   var available=node.size.x-style.get_content_margin(SIDE_LEFT)-style.get_content_margin(SIDE_RIGHT)
   if node.icon!=null: available-=node.icon.get_width()+node.get_theme_constant("h_separation")
   for line in node.text.split("\n"):
    var width=node.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,node.get_theme_font_size("font_size")).x
    assert(width<=available+1,"Button text clipping: "+node.text)
 for child in node.get_children(): verify(child)
func run():
 var app=preload("res://tests/visual_app.gd").new()
 root.add_child(app)
 app.bridge.connected=true
 app.widget=preload("res://scripts/widget.gd").new()
 app.widget.app=app
 app.add_child(app.widget)
 var settings=preload("res://scripts/settings.gd").new()
 settings.app=app
 app.settings=settings
 app.add_child(settings)
 settings.show()
 for scale_ in [.9,1.0,1.3]:
  app.text_scale=scale_
  settings.rebuild()
  for tab in range(4):
   settings.tab_buttons[tab].pressed.emit()
   assert(settings.tabs.current_tab==tab)
   for i in range(4):
    var b=settings.tab_buttons[i]
    assert(b.button_pressed==(i==tab))
    assert(b.get_theme_stylebox("normal").bg_color==Color("f3c2be" if i==tab else "fffdf8"))
    assert(b.get_theme_stylebox("normal").border_width_left==2)
    assert(b.get_theme_constant("h_separation")==6)
    if i<3: assert(b.icon!=null and b.icon.get_width()==20)
    if i==tab: assert(b.get_theme_font("font") is FontVariation and b.get_theme_font("font").variation_embolden>0)
   for frame in range(8): await process_frame
   await RenderingServer.frame_post_draw
   verify(settings.content)
   var column=settings.content.get_child(0)
   assert(column.position.x>=Cozy.OUTER and column.position.y>=Cozy.OUTER)
   assert(settings.size.x-column.position.x-column.size.x>=Cozy.OUTER-.5)
   assert(settings.size.y-column.position.y-column.size.y>=Cozy.OUTER-.5)
   var footer=column.get_node("FooterButtons")
   var widths=[]
   for b in footer.get_children(): widths.append(b.size.x)
   assert(widths.max()-widths.min()<=1,"Footer buttons must have equal widths")
   assert(footer.size.y>=Cozy.FOOTER_HEIGHT)
   if scale_==1.0:
    settings.get_texture().get_image().save_png("res://builds/review/settings-%s.png"%["friend","gifts","cafe","report"][tab])
   elif scale_==1.3 and tab==0:
    settings.get_texture().get_image().save_png("res://builds/review/settings-friend-130.png")
   for scroller in settings.find_children("*","ScrollContainer",true,false):
    if scroller.is_visible_in_tree(): scroller.scroll_vertical=100000
   for frame in range(4): await process_frame
   verify(settings.content)
  settings.tabs.current_tab=0
 settings.show_present(app.collection.ITEMS[0])
 for frame in range(6): await process_frame
 verify(settings.present)
 var tutorial=preload("res://scripts/tutorial.gd").new()
 tutorial.app=app
 app.add_child(tutorial)
 tutorial.show()
 for scale_ in [.9,1.0,1.3]:
  app.text_scale=scale_
  for step in range(5):
   tutorial.step=step
   tutorial.render_step()
   for frame in range(5): await process_frame
   verify(tutorial.card)
   if scale_==1.3 and step==4:
    await RenderingServer.frame_post_draw
    tutorial.get_texture().get_image().save_png("res://builds/review/settings-help-130.png")
   var column=tutorial.card.get_child(0)
   assert(column.position==Vector2.ONE*Cozy.OUTER)
   assert(tutorial.size.y-column.position.y-column.size.y>=Cozy.OUTER-.5)
 app.free()
 print("SETTINGS_SPACING_PASS: 4 tabs + 5 help steps at 0.9/1/1.3; gaps >=8px, outer >=20px, selected tabs/icons, equal footer widths, no horizontal overflow (",checks," checks)")
 quit()
