from pathlib import Path
root=Path(__file__).resolve().parents[1]
def replace(file, before, after):
 p=root/file
 s=p.read_text(encoding='utf-8')
 assert before in s, (file,before)
 p.write_text(s.replace(before,after),encoding='utf-8')
new={'wall_clock':('look','몇 시일까',8),'wall_shelf':('read','여기서 한 장 더',16),'plant_stand':('look','잎이 싱그럽네',24),'dresser':('groom','보송하게 정리',38),'fireplace':('rest','따뜻하고 포근해',64),'aquarium':('look','물고기가 헤엄쳐',84)}
replace('scripts/pet_state.gd','"home_turntable":110}', '"home_turntable":110,'+','.join('"home_%s":%s'%(k,v[2]) for k,v in new.items())+'}')
replace('scripts/furniture_room.gd','"home_turntable":"turntable"}', '"home_turntable":"turntable",'+','.join('"home_%s":"%s"'%(k,k) for k in new)+'}')
replace('scripts/furniture_room.gd','"home_turntable":"look"}[id]', '"home_turntable":"look",'+','.join('"home_%s":"%s"'%(k, ('home_use' if v[0] in ['read','groom','rest'] else 'look')) for k,v in new.items())+'}.get(id,"look")')
replace('scripts/furniture_room.gd','"home_turntable":"이 곡 좋아"}[id]', '"home_turntable":"이 곡 좋아",'+','.join('"home_%s":"%s"'%(k,v[1]) for k,v in new.items())+'}.get(id,"함께 쉬자")')
replace('scripts/home_animation.gd','"home_turntable":"music"}', '"home_turntable":"music","home_wall_shelf":"read","home_dresser":"groom","home_fireplace":"rest"}')
replace('scripts/furniture_room.gd','piece.floor_locked=app.state.activity_space=="floor"', 'piece.floor_locked=app.state.activity_space=="floor" and not Catalog.is_wall(piece.item_id)\n\tif Catalog.is_wall(piece.item_id): return')
replace('scripts/furniture_room.gd','if app.state.activity_space=="floor":\n\t\t\t# Prefer', 'if Catalog.is_wall(id): at.y=preload("res://scripts/living_space.gd").ground(Rect2(rect))-260-piece.size.y\n\t\tif app.state.activity_space=="floor":\n\t\t\t# Prefer')
replace('scripts/furniture_room.gd','app.state.activity_space=="floor" and previous.has(id)', 'app.state.activity_space=="floor" and not Catalog.is_wall(id) and previous.has(id)')
replace('scripts/furniture_room.gd','return point.clamp(m.bounds.position,m.bounds.end)', 'if Catalog.is_wall(p.item_id): point.y=m.bounds.get_center().y if app.state.activity_space=="floor" else minf(m.bounds.end.y,point.y+100)\n\treturn point.clamp(m.bounds.position,m.bounds.end)')
replace('scripts/furniture_room.gd','preview.texture=Catalog.texture(id)', 'preview.texture=Catalog.texture(id)\n\t\tpreview.material=Catalog.material()')
replace('scripts/furniture_room.gd','가구 끌기 / ← →: 이동 · 좌우 반전: 방향 바꾸기', '가구 끌기 / ← →: 이동 · 좌우 반전: 방향 바꾸기\\n벽시계·벽 선반은 위아래로도 배치할 수 있어요.')
print('Expanded cozy furniture catalog, progression, use and wall placement')
