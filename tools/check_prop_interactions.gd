extends SceneTree
const Motion=preload("res://scripts/desktop_pet_motion.gd")
const View=preload("res://scripts/desktop_pet_view.gd")
const Interactions=preload("res://scripts/prop_interactions.gd")
const Outline=preload("res://scripts/animation_outline.gd")
var failures: Array=[]
var rewards: Array=[]
func verify(value: bool, description: String) -> void:
	if not value: failures.append(description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var count=0
	for baby in [true,false]:
		var sheet=Image.create(1024,2048,false,Image.FORMAT_RGBA8)
		sheet.fill(Color("324454"))
		for species in range(16):
			var motion=Motion.new()
			motion.species=species
			motion.growth_stage=0 if baby else 2
			motion.growth_scale=.62 if baby else 1.0
			motion.autonomy=false
			motion.bounds=Rect2(0,0,1280,720)
			motion.feet=Vector2(400,400)
			motion.activity_bonded.connect(func(id): rewards.append(id))
			var view=View.new()
			view.motion=motion
			root.add_child(view)
			for kind in ["plant","lamp"]:
				var frames=Interactions.frames(species,baby,kind)
				verify(frames.size()==4,"missing %s/%d/%s"%[baby,species,kind])
				if frames.size()!=4: continue
				motion.visit(motion.feet,"prop_use",kind,true)
				motion.advance(.01)
				verify(motion.phase=="prop_use","arrival")
				for i in range(4):
					var img=frames[i].get_image()
					var used=img.get_used_rect()
					verify(used.has_area() and used.position.x>=2 and used.position.y>=2 and used.end.x<img.get_width()-2 and used.end.y<img.get_height()-2,"frame edge %s/%d/%s/%d"%[baby,species,kind,i])
					var factor=minf(120.0/img.get_width(),120.0/img.get_height())
					img.resize(maxi(1,int(img.get_width()*factor)),maxi(1,int(img.get_height()*factor)))
					sheet.blend_rect(img,Rect2i(Vector2i.ZERO,img.get_size()),Vector2i((i+(4 if kind=="lamp" else 0))*128,species*128))
					motion.elapsed=float(i)/Interactions.SPEEDS[species]
					motion.prop_progress=float(i)
					motion.prop_dragging=species==9 and kind=="plant"
					motion.prop_strength=float(i)/3
					view.refresh()
					verify(view.sprite.texture in frames,"wrong animation")
					Outline.fit(view.sprite,View.FEET,Vector2(204,190))
					var points=Outline.blended_points(view.sprite)
					for p in points: verify(p.x>=4.9 and p.y>=4.9 and p.x<=199.1 and p.y<=185.1,"window clipping")
					count+=1
				motion.prop_dragging=false
				if species==9 and kind=="plant":
					motion.begin_prop_drag(Vector2.ZERO)
					motion.drag_prop(Vector2(80,0))
					verify(motion.prop_strength>.9 and Interactions.pose(motion)==3,"rope not driven by input")
					motion.drag_prop(Vector2(0,0))
					verify(Interactions.pose(motion)==0,"rope slack not responsive")
					motion.release_prop_drag()
				var before=rewards.size()
				motion.advance(20)
				verify(motion.phase=="idle" and rewards.size()==before+1,"completion/reward")
				motion.advance(0)
				verify(rewards.size()==before+1,"duplicate reward")
				motion.visit(motion.feet,"prop_use",kind,true)
				motion.advance(.01)
				motion.begin_prop_drag(Vector2.ZERO)
				motion.cancel_play()
				verify(not motion.prop_dragging and motion.visit_id.is_empty(),"cancel leaves stale interaction")
			view.free()
		sheet.save_png("res://builds/frame-audit/interactions-%s.png"%("baby" if baby else "adult"))
	print("INTERACTION_POSES=",count," FAILURES=",failures.size())
	for failure in failures.slice(0,15): print(failure)
	quit(0 if failures.is_empty() else 1)
