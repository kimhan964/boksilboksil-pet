from pathlib import Path
root=Path(__file__).resolve().parents[1]
def edit(name,a,b):
 p=root/name;s=p.read_text(encoding='utf-8');assert a in s,name;p.write_text(s.replace(a,b),encoding='utf-8')
edit('scripts/pet_state.gd','var furniture: Dictionary={}','var furniture: Dictionary={}\nvar furniture_styles: Dictionary={}')
edit('scripts/pet_state.gd','load_furniture(data.get("furniture",{}))','load_furniture(data.get("furniture",{}))\n\tfurniture_styles.clear()\n\tvar styles=data.get("furniture_styles",{})\n\tif styles is Dictionary:\n\t\tfor id in Furniture.ITEMS:\n\t\t\tif styles.has(id): furniture_styles[id]=Furniture.normalize_style(styles[id])')
edit('scripts/pet_state.gd','"furniture":furniture}', '"furniture":furniture,"furniture_styles":furniture_styles}')
edit('scripts/pet_state.gd','"home_aquarium":84}', '"home_aquarium":84,"home_alarm_clock":18}')
edit('scripts/furniture_room.gd','"home_aquarium":"aquarium"}', '"home_aquarium":"aquarium","home_alarm_clock":"alarm_clock"}')
edit('scripts/furniture_room.gd','"home_aquarium":"look"}', '"home_aquarium":"look","home_alarm_clock":"look"}')
edit('scripts/furniture_room.gd','"home_aquarium":"물고기가 헤엄쳐"}', '"home_aquarium":"물고기가 헤엄쳐","home_alarm_clock":"아직은 여유 있어"}')
edit('scripts/furniture_room.gd','piece.item_id=id\n\tadd_child(piece)', 'piece.item_id=id\n\tpiece.appearance=Catalog.normalize_style(app.state.furniture_styles.get(id,{}))\n\tadd_child(piece)')
edit('scripts/furniture_room.gd','if pieces[id].mirrored: app.state.furniture[id].append(true)', 'if pieces[id].mirrored: app.state.furniture[id].append(true)\n\t\tapp.state.furniture_styles[id]=pieces[id].appearance.duplicate()')
edit('scripts/furniture_room.gd','preview.texture=Catalog.texture(id)\n\t\tpreview.material=Catalog.material()', 'var appearance=Catalog.normalize_style(app.state.furniture_styles.get(id,{}))\n\t\tpreview.texture=Catalog.texture(id,appearance.design)\n\t\tpreview.material=Catalog.material()\n\t\tCatalog.apply_style(preview.material,appearance)')
edit('scripts/furniture_room.gd','placement_buttons[id]=[]', '''var choices=HBoxContainer.new()
		choices.add_theme_constant_override("separation",6)
		item.add_child(choices)
		for field in (["design","color","finish"] if id=="alarm_clock" else ["color","finish"]):
			var picker=OptionButton.new()
			var labels=Catalog.DESIGNS if field=="design" else (Catalog.COLOR_NAMES if field=="color" else Catalog.FINISH_NAMES)
			for text in labels: picker.add_item(text)
			picker.select(appearance[field])
			picker.custom_minimum_size=Vector2(120 if id=="alarm_clock" else 185,32)
			picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			picker.tooltip_text={"design":"동물 디자인","color":"가구 색상","finish":"표면 질감과 마감"}[field]
			style_button(picker)
			picker.item_selected.connect(func(index):
				var selected=Catalog.normalize_style(app.state.furniture_styles.get(id,{}))
				selected[field]=index
				app.state.furniture_styles[id]=selected
				if pieces.has(id): pieces[id].set_appearance(selected,true)
				else: app.state.save_game()
				preview.texture=Catalog.texture(id,selected.design)
				Catalog.apply_style(preview.material,selected))
			choices.add_child(picker)
		placement_buttons[id]=[]''')
print('Furniture appearance pickers and save data integrated')
