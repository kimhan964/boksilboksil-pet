from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
def edit(p,a,b):
    f=R/p;s=f.read_text(encoding='utf-8');assert a in s,(p,a);f.write_text(s.replace(a,b),encoding='utf-8')
def append(p,s):
    with (R/p).open('a',encoding='utf-8') as f:f.write(s)
append('scripts/baby_art.gd','''
static var extras: Dictionary={}
static func extra_frames(species: int) -> Array:
	var group=species/4
	if not extras.has(group):
		var path="res://assets/babies/extra-%d.png"%group
		extras[group]=Regions.frames(path,Keyed.pixels(path))
	return extras[group].slice((species%4)*8,(species%4)*8+8)
''')
edit('tools/build_animation_regions.py','manifest={}; report=[]',"SHEETS.update({f'assets/babies/extra-{i}.png':(8,4) for i in range(4)})\nmanifest={}; report=[]")
edit('scripts/decor_art.gd','static var new_icons: Array=[]','static var new_icons: Array=[]\nstatic var species_icons: Dictionary={}')
edit('scripts/decor_art.gd','\tif species>=8 and kind', '''	if kind in ["plant","lamp"]:
		if not species_icons.has(kind):
			var path="res://assets/decor/species-%s.png"%("toys" if kind=="plant" else "comfort")
			species_icons[kind]=Keyed.cells(path,4,4,true)
		return species_icons[kind][clampi(species,0,15)]
	if species>=8 and kind''')
toys=['당근 씹기 장난감','조약돌 쌓기 트레이','도토리 퍼즐','잎사귀 터널','조개 씻기 대야','낙엽 사냥 장난감','벌집 퍼즐','깃털 모빌','스크래처와 장난감 쥐','매듭 로프','나무 쳇바퀴','대나무 롤러','오르기 통나무','풀밭 디딤 언덕','유칼립투스 오르기 나무','얼음 미끄럼틀']
comfort=['클로버 그늘','강가 돌 쉼터','도토리 보관함','마른 잎 은신처','체크 담요','낙엽 그늘집','등 비비기 나무','달 모양 횃대','숨바꼭질 상자','포근한 빨간 담요','모래 목욕통','대나무 그늘막','단풍잎 그늘','양털 쿠션','유칼립투스 그늘','눈 쉼터']
append('scripts/companion_profiles.gd','\nconst TOYS='+json.dumps(toys,ensure_ascii=False)+'\nconst COMFORTS='+json.dumps(comfort,ensure_ascii=False)+'\n')
edit('scripts/desktop_prop.gd','"plant":"화분","lamp":"작은 조명"','"plant":"전용 놀이 소품","lamp":"전용 휴식 소품"')
edit('scripts/desktop_prop.gd','func refresh() -> void:\n','func refresh() -> void:\n\tif kind in ["plant","lamp"]: title=(Profiles.TOYS[species] if kind=="plant" else Profiles.COMFORTS[species])+" · 클릭하면 친구가 찾아와요"\n')
edit('scripts/desktop_prop.gd','elif interactive and not editing','elif (interactive or kind in ["plant","lamp"]) and not editing')
edit('scripts/desktop_prop.gd','\tif kind in ["bowl","water","cushion","shelter"]: factor*=growth_scale','\tif kind in ["plant","lamp"]: factor=clampf(126*Catalog.HEIGHTS[species]/100.0,.5,1.3)\n\tif kind in ["bowl","water","cushion","shelter","plant","lamp"]: factor*=growth_scale')
edit('scripts/main.gd','\t\tif id=="bowl": prop.food_picked.connect(pick_up_food)','\t\tif id=="bowl": prop.food_picked.connect(pick_up_food)\n\t\tif id in ["plant","lamp"]: prop.activated.connect(use_species_prop)')
edit('scripts/main.gd','for id in ["bowl","water"]:','for id in ["bowl","water","plant","lamp"]:')
edit('scripts/main.gd','"plant":"sniff"','"plant":"askplay"')
edit('scripts/main.gd','"plant":"inspect","lamp":"pet"','"plant":"askplay","lamp":"relax"')
edit('scripts/main.gd','\t\t18: show_info','\t\t19: show_info("전용 소품",Profiles.TOYS[state.selected]+" · 클릭하면 다가와 놀이 반응을 보여요.\\n"+Profiles.COMFORTS[state.selected]+" · 클릭하면 다가와 쉬어요.\\n\\n소품은 드래그해서 옮길 수 있어요.\\n동물을 직접 소품에 데려다 놓아도 반응해요.")\n\t\t20: use_species_prop("plant")\n\t\t21: use_species_prop("lamp")\n\t\t18: show_info')
append('scripts/main.gd','''
func use_species_prop(id: String) -> void:
	if not is_instance_valid(pet) or id not in ["plant","lamp"]: return
	if not state.unlocked(state.selected,id): return
	cancel_hunt()
	if decorating: activity(5)
	ensure_prop_nearby(id)
	props[id].confirm_drop()
	pet.motion.visit(props[id].feet_point(),"askplay" if id=="plant" else "relax",id,true)
''')
edit('scripts/desktop_pet.gd','\tmenu.add_item("성장 기록','\tmenu.add_item("전용 소품 안내",19)\n\tmenu.add_item(Profiles.TOYS[species]+"에서 놀기",20)\n\tmenu.add_item(Profiles.COMFORTS[species]+"에서 쉬기",21)\n\tmenu.add_item("성장 기록')
edit('scripts/pet_state.gd','"plant":"작은 화분","lamp":"따뜻한 조명"','"plant":"동물 전용 놀이 소품","lamp":"동물 전용 휴식 소품"')
edit('scripts/pet_state.gd','"personality","bowl","water"]','"personality","bowl","water","plant"]')
edit('scripts/desktop_pet_view.gd','var baby_frames: Array=[]','var baby_frames: Array=[]\nvar baby_extra: Array=[]')
edit('scripts/desktop_pet_view.gd','baby_frames=Baby.frames(motion.species)','baby_frames=Baby.frames(motion.species)\n\tbaby_extra=Baby.extra_frames(motion.species)')
edit('scripts/desktop_pet_view.gd','\tvar texture: Texture2D=baby_frames[index]\n\tvar neutral: Rect2i=Baby.bounds[motion.species]', '''	var extra=-1
	if not motion.carried and motion.landing_left<=0 and not moving and baby_extra.size()==8:
		var t=motion.reaction_time if motion.phase=="react" else motion.elapsed
		if motion.phase=="eat": extra=int(t*4)%2
		elif motion.phase=="drink": extra=2+int(t*3)%2
		elif motion.phase in ["sniff","look","inspect"] or (motion.phase=="react" and motion.reaction in ["inspect","anticipate"]): extra=4+int(t*2)%2
		elif motion.phase in ["signature","askplay"] or (motion.phase=="react" and motion.reaction in ["askplay","pet","greet"]):
			var plan=[6,6,7,7,5,4] if motion.species%2==0 else [4,5,6,7,7,5]
			extra=plan[int(t*4)%plan.size()]
	var texture: Texture2D=baby_extra[extra] if extra>=0 else baby_frames[index]
	var neutral: Rect2i=baby_extra[5].get_image().get_used_rect() if extra>=0 else Baby.bounds[motion.species]''')
edit('scripts/desktop_pet_view.gd','if motion.species>=12 and index==2: direction=-direction','if extra<0 and motion.species>=12 and index==2: direction=-direction')
edit('scripts/desktop_pet_view.gd','var water=index==4 and','var water=motion.phase=="drink" and')
edit('scripts/desktop_pet_view.gd','var serving=index in [3,4] and','var serving=motion.phase in ["eat","drink"] and')
edit('scripts/desktop_pet_view.gd','"food_bite",index==3','"food_bite",motion.phase=="eat"')
edit('tools/package.gd','DesktopFriends-0.20-test','DesktopFriends-0.21-test')
print('Updated baby motions and species props')
