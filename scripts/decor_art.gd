extends RefCounted

const Keyed=preload("res://scripts/keyed_art.gd")
const ITEMS={"bowl":16,"water":17,"basket":18,"plant":19,"lamp":20,"ball":21}
static var icons: Array=[]
static var new_icons: Array=[]
static var species_icons: Dictionary={}

static func icon(kind: String, species: int=0) -> Texture2D:
	if kind in ["plant","lamp"]:
		if not species_icons.has(kind):
			var path="res://assets/decor/species-%s.png"%("toys" if kind=="plant" else "comfort")
			species_icons[kind]=[]
			for frame in Keyed.AnimationRegions.frames(path,Keyed.pixels(path)):
				var image=frame.get_image()
				species_icons[kind].append(ImageTexture.create_from_image(image.get_region(image.get_used_rect())))
		return species_icons[kind][clampi(species,0,15)]
	if species>=8 and kind in ["cushion","shelter"]:
		# The generated rows are not equal-height: the house row starts near 600
		# and ends before the next row's tent poles at 910. Equal quarters clipped
		# roofs and included those poles as floating fragments below the houses.
		if new_icons.is_empty(): new_icons=Keyed.cells("res://assets/decor/new-friends-homes.png",4,4,true,[0,305,600,895,1254],[0,317,620,938,1254])
		return new_icons[species-8+(8 if kind=="shelter" else 0)] if new_icons.size()==16 else null
	var index=int(ITEMS.get(kind,-1))
	if kind=="cushion": index=clampi(species,0,7)
	if kind=="shelter": index=8+clampi(species,0,7)
	if index<0: return null
	if icons.is_empty(): icons=Keyed.cells("res://assets/decor/character-style-v2.png",4,6,true,[0,289,533,794,1058,1287,1536])
	return icons[index] if icons.size()==24 else null
