extends RefCounted
static var cache={}
static func has_pose(species: int,action: int) -> bool:
 return FileAccess.file_exists(preload("res://scripts/catalog.gd").folder(species)+"/action-%d.png"%action)
static func frames(species: int) -> Array[Texture2D]:
 if cache.has(species): return cache[species]
 var result: Array[Texture2D]=[]
 for action in range(3):
  var folder=preload("res://scripts/catalog.gd").folder(species)
  var path=folder+"/action-%d.png"%action
  if not FileAccess.file_exists(path): path=folder+"/idle.png"
  var image=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK: return []
  image.generate_mipmaps()
  result.append(ImageTexture.create_from_image(image))
 cache.clear()
 cache[species]=result
 return result
