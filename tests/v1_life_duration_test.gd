extends SceneTree
const Home=preload("res://scripts/home_animation.gd")
const Data=preload("res://scripts/v1_action_album_data.gd")
var checks=0
func _initialize(): run.call_deferred()
func run():
	for file in DirAccess.get_files_at("res://animal-packs"):
		if file.ends_with(".pck"): assert(ProjectSettings.load_resource_pack("res://animal-packs/"+file,false))
	for species in range(16):
		for baby in [false,true]:
			for id in ["home_sofa","home_tea","home_shelf","home_daybed","home_vanity","home_record_player","home_play_rug"]:
				var m=Data.motion_for(species,baby)
				var kind=Home.KINDS[id]
				var duration=Home.duration(id)
				assert(duration>=20.0 and duration<30.0)
				assert(is_equal_approx(duration/Home.CYCLE_DURATIONS[kind],round(duration/Home.CYCLE_DURATIONS[kind])))
				m.visit(m.feet,"home_use",id)
				for step in range(240):
					m.advance(1.0/60.0)
					if m.phase=="home_use": break
				assert(m.phase=="home_use",id)
				assert(is_equal_approx(m.action_left,duration),id)
				# A corresponding middle pose in all complete cycles must remain identical.
				var first=-1
				for cycle in range(int(round(duration/Home.CYCLE_DURATIONS[kind]))):
					m.elapsed=(cycle+.437)*Home.CYCLE_DURATIONS[kind]
					m.action_left=duration-m.elapsed
					var sample=Home.sample(m)
					assert(sample.texture!=null)
					if cycle==0: first=sample.index
					assert(sample.index==first)
				m.elapsed=0;m.action_left=duration
				for step in range(int(round(duration*60.0))-1):
					m.advance(1.0/60.0)
					assert(m.phase=="home_use",id+" ended early")
				m.advance(.04)
				assert(m.phase=="idle" and m.visit_id.is_empty(),id+" did not finish")
				checks+=1
		print("SPECIES_OK ",species)
	assert(is_equal_approx(Data.seconds(Data.motion_for(0,false),"read"),25.2))
	print("V1_LIFE_20S_PASS ",checks," complete visits; unchanged cycle tempo")
	quit()
