extends Node2D

## VARCO illustrated garments, fitted to each whole-character animation cel.
const Catalog=preload("res://scripts/animal_catalog.gd")
const Metrics=preload("res://scripts/texture_metrics.gd")
static var textures: Dictionary={}
static var idle_bounds: Dictionary={}
var view
var fitting_material: ShaderMaterial

func _ready() -> void:
	fitting_material=ShaderMaterial.new()
	fitting_material.shader=preload("res://scripts/outfit_mask.gdshader")
	material=fitting_material

func outfit_texture(species: int, stage: String, style: int, color: int) -> Texture2D:
	var key="%s/%s-%s-%d"%[Catalog.IDS[species],stage,["cape","vest","sweater"][style-1],color]
	if not textures.has(key):
		var path="res://assets/outfits-varco-v1/"+key+".png"
		if not FileAccess.file_exists(path): return null
		var image=Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK: return null
		textures[key]=ImageTexture.create_from_image(image)
	return textures[key]

func idle_box(species: int, stage: String) -> Rect2:
	var key=Catalog.IDS[species]+"/"+stage
	if not idle_bounds.has(key):
		var path="res://assets/outfits-varco-v1/"+Catalog.IDS[species]+"/manifest.json"
		if not FileAccess.file_exists(path): return Rect2(Vector2(32,20),Vector2(192,212))
		var manifest=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not manifest is Dictionary: return Rect2(Vector2(32,20),Vector2(192,212))
		var box: Array=manifest.get(stage+"-cape",{}).get("target_box",[32,20,224,232])
		idle_bounds[key]=Rect2(Vector2(float(box[0]),float(box[1])),Vector2(float(box[2]-box[0]),float(box[3]-box[1])))
	return idle_bounds[key]

func _draw() -> void:
	if view==null or view.motion==null or view.sprite==null or view.sprite.texture==null: return
	var style=clampi(int(view.motion.outfit_style),0,3)
	if style==0: return
	if view.generated_sample.get("dressed",false): return
	var species=clampi(int(view.motion.species),0,Catalog.IDS.size()-1)
	var stage="baby" if view.motion.growth_stage==0 else "adult"
	var color=clampi(int(view.motion.outfit_color),0,5)
	var garment=outfit_texture(species,stage,style,color)
	if garment==null: return
	var source=idle_box(species,stage)
	var used=Metrics.used_rect(view.sprite.texture)
	if not used.has_area(): return
	var scale=Vector2(clampf(float(used.size.x)/source.size.x,.68,1.35),clampf(float(used.size.y)/source.size.y,.68,1.35))
	var origin=Vector2(used.position)-source.position*scale
	var fit=Transform2D(Vector2(scale.x,0),Vector2(0,scale.y),origin)
	# Complete-body cels remain intact. Clip only the garment overlay to the
	# current silhouette; a standing garment otherwise covers a sleeping face.
	var sample: Dictionary=view.generated_sample
	var neutral=preload("res://scripts/character_presentation.gd").neutral_height(species,stage)
	var lying=sample.get("action","") in ["sleep","rest","sniff"] and used.size.y<neutral*.83
	if lying:
		origin.x-=used.size.x*.16
		origin.y-=used.size.y*.12
		fit.origin=origin
	if fitting_material:
		fitting_material.set_shader_parameter("body_texture",view.sprite.texture)
		fitting_material.set_shader_parameter("fit_origin",origin)
		fitting_material.set_shader_parameter("fit_scale",scale)
		fitting_material.set_shader_parameter("garment_size",garment.get_size())
		fitting_material.set_shader_parameter("lying",lying)
		var mouth: Vector2=sample.get("mouth",Vector2(128,140))
		fitting_material.set_shader_parameter("head_boundary",used.position.x+used.size.x*.57 if lying else mouth.y+used.size.y*.09)
	draw_set_transform_matrix(view.sprite.transform*fit)
	draw_texture(garment,Vector2.ZERO)
