extends SceneTree

# Sheet order: idle, left, right / action-1, action-2, action-0.
const MAP = {
	"idle": "moru-idle-2arm0.png",
	"left": "left-c1.png",
	"right": "right-c0.png",
	"action-1": "lie-c1.png",
	"action-2": "cheer-c0.png",
	"action-0": "moru-idle-2arm0.png",
}
const SOURCE = "res://assets/typing-haru-v1/source/"
const OUTPUT = "res://assets/typing-haru-v1/rabbit/"
const SHEET = "res://builds/review/haru-poses.png"
const SIDE = 1024
const TILE = 256
const KEY_START = 0.06 # Preserve brown ink and weak green differences.
const KEY_END = 0.90
const ALPHA_CUTOFF = 0.10
const OPAQUE_ALPHA = 0.90

func _initialize() -> void:
	run.call_deferred()

func key_and_resize(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var c = image.get_pixel(x, y)
			var other = maxf(c.r, c.b)
			var dominance = maxf(0.0, c.g - other)
			# Yellow (r ~= g) and pink (r > g) have no green dominance.
			c.a *= 1.0 - smoothstep(KEY_START, KEY_END, dominance)
			# No green character pigments: remove spill without reducing brown ink.
			if dominance > 0.0:
				c.g = lerpf(c.g, other, smoothstep(0.0, KEY_START, dominance))
			if c.a < ALPHA_CUTOFF:
				c = Color.TRANSPARENT
			# Premultiplied resize avoids dark/green fringes from transparent RGB.
			image.set_pixel(x, y, Color(c.r * c.a, c.g * c.a, c.b * c.a, c.a))
	image.resize(SIDE, SIDE, Image.INTERPOLATE_LANCZOS)
	for y in range(SIDE):
		for x in range(SIDE):
			var c = image.get_pixel(x, y)
			if c.a < ALPHA_CUTOFF:
				image.set_pixel(x, y, Color.TRANSPARENT)
			else:
				image.set_pixel(x, y, Color(clampf(c.r / c.a, 0, 1), clampf(c.g / c.a, 0, 1), clampf(c.b / c.a, 0, 1), c.a))

func measurements(image: Image) -> Dictionary:
	var low = Vector2i(SIDE, SIDE)
	var high = Vector2i(-1, -1)
	var widths = PackedInt32Array()
	widths.resize(SIDE)
	var widest = 0
	var start = int(SIDE * 0.60)
	for y in range(SIDE):
		for x in range(SIDE):
			if image.get_pixel(x, y).a < OPAQUE_ALPHA:
				continue
			low = low.min(Vector2i(x, y))
			high = high.max(Vector2i(x, y))
			widths[y] += 1
		if y >= start:
			widest = maxi(widest, widths[y])
	var keyboard_y = -1
	# First near-widest row in the bottom 40%; heuristic, never a crop/offset.
	if widest > 0:
		for y in range(start, SIDE):
			if widths[y] >= int(ceil(widest * 0.90)):
				keyboard_y = y
				break
	var bbox = Rect2i() if high.x < 0 else Rect2i(low, high - low + Vector2i.ONE)
	return {"bbox": bbox, "keyboard_y": keyboard_y, "widest": widest}


# Keyboard measurement excludes the body: inspect the lowest 128px of the
# broad bottom silhouette and require cream/pink fill, not just stray ink.
func keyboard_bounds(image: Image) -> Rect2i:
	var bottom = -1
	for y in range(SIDE - 1, int(SIDE * .60) - 1, -1):
		var count = 0
		for x in range(SIDE):
			if image.get_pixel(x, y).a >= OPAQUE_ALPHA: count += 1
		if count >= SIDE * .40:
			bottom = y
			break
	if bottom < 0: return Rect2i()
	var left = SIDE
	var right = -1
	for y in range(maxi(int(SIDE * .60), bottom - 128), bottom + 1):
		var row_left = SIDE
		var row_right = -1
		var fill_count = 0
		for x in range(SIDE):
			var c = image.get_pixel(x, y)
			if c.a < OPAQUE_ALPHA: continue
			row_left = mini(row_left, x)
			row_right = maxi(row_right, x)
			if c.r > .65 and c.g > .35 and c.b > .25: fill_count += 1
		if fill_count >= SIDE * .40:
			left = mini(left, row_left)
			right = maxi(right, row_right)
	return Rect2i(left, bottom - 128, right - left + 1, 129) if right >= left else Rect2i()

# Head silhouette proxy for idle/left/right: broad face, excluding ears and paws.
func head_bounds(image: Image, keyboard: Rect2i) -> Rect2i:
	var low = Vector2i(SIDE, SIDE)
	var high = Vector2i(-1, -1)
	var stop = keyboard.end.y - 210
	for y in range(int(SIDE * .25), stop):
		var left = SIDE
		var right = -1
		for x in range(SIDE):
			if image.get_pixel(x, y).a >= OPAQUE_ALPHA:
				left = mini(left, x)
				right = maxi(right, x)
		if right - left < keyboard.size.x * .50: continue
		low = low.min(Vector2i(left, y))
		high = high.max(Vector2i(right, y))
	return Rect2i(low, high - low + Vector2i.ONE) if high.x >= 0 else Rect2i()

func align_pose(image: Image, reference: Rect2i, key: String) -> Dictionary:
	var measured = keyboard_bounds(image)
	if not measured.has_area():
		push_error("HARU_ALIGN_ERROR: no keyboard for " + key)
		return {}
	var scale_factor = float(reference.size.x) / measured.size.x
	# A square image resized to a square preserves a uniform scale.
	var scaled_side = roundi(SIDE * scale_factor)
	scale_factor = float(scaled_side) / SIDE
	var offset = Vector2i(roundi(reference.get_center().x - measured.get_center().x * scale_factor), roundi(reference.end.y - measured.end.y * scale_factor))
	var original_bbox: Rect2i = measurements(image).bbox
	var transformed = Rect2(Vector2(original_bbox.position) * scale_factor + Vector2(offset), Vector2(original_bbox.size) * scale_factor)
	if not Rect2(0, 0, SIDE, SIDE).encloses(transformed.grow(2)):
		push_warning("HARU_CLIP_RISK: %s transformed_bbox=%s" % [key, transformed])
	var scaled = image.duplicate()
	if scaled_side != SIDE: scaled.resize(scaled_side, scaled_side, Image.INTERPOLATE_LANCZOS)
	var result = Image.create(SIDE, SIDE, false, Image.FORMAT_RGBA8)
	result.blit_rect(scaled, Rect2i(0, 0, scaled_side, scaled_side), offset)
	var after = keyboard_bounds(result)
	# Compensate the final integer rasterization shift, keeping the uniform scale.
	var correction = Vector2i(reference.get_center().x - after.get_center().x, reference.end.y - after.end.y)
	if correction != Vector2i.ZERO:
		var corrected = Image.create(SIDE, SIDE, false, Image.FORMAT_RGBA8)
		corrected.blit_rect(result, Rect2i(0, 0, SIDE, SIDE), correction)
		result = corrected
		offset += correction
		after = keyboard_bounds(result)
	if abs(after.size.x - reference.size.x) > 2 or abs(after.end.y - reference.end.y) > 2 or abs(after.get_center().x - reference.get_center().x) > 2:
		push_warning("HARU_ALIGNMENT_TOLERANCE: %s actual=%s target=%s" % [key, after, reference])
	return {"image": result, "scale": scale_factor, "offset": offset, "keyboard": after}

func eye_center(image: Image, region: Rect2i) -> Vector2:
	# Largest connected dark component isolates the eye from nearby eyebrow tips.
	var visited = PackedByteArray()
	visited.resize(region.size.x * region.size.y)
	var best_count = 0
	var best_center = Vector2.ZERO
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var local_index = (y - region.position.y) * region.size.x + x - region.position.x
			if visited[local_index] != 0: continue
			visited[local_index] = 1
			if not is_eye_ink(image.get_pixel(x, y)): continue
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			var low = Vector2i(x, y)
			var high = low
			var cursor = 0
			while cursor < queue.size():
				var point = queue[cursor]
				cursor += 1
				low = low.min(point)
				high = high.max(point)
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + direction
					if not region.has_point(next): continue
					var index = (next.y - region.position.y) * region.size.x + next.x - region.position.x
					if visited[index] != 0: continue
					visited[index] = 1
					if is_eye_ink(image.get_pixelv(next)): queue.append(next)
			if queue.size() > best_count:
				best_count = queue.size()
				best_center = (Vector2(low + high) * .5 + Vector2(.5, .5)) / SIDE
	return best_center

func is_eye_ink(c: Color) -> bool:
	return c.a >= OPAQUE_ALPHA and c.r < .35 and c.g < .30 and c.b < .30

func run() -> void:
	# Regression: opaque yellow sparkles and pink hearts must survive chroma key.
	var swatches = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	swatches.fill(Color("ffe58b"))
	key_and_resize(swatches)
	assert(swatches.get_pixel(512, 512).a == 1.0)
	swatches.fill(Color("f7c6c7"))
	key_and_resize(swatches)
	assert(swatches.get_pixel(512, 512).a == 1.0)
	print("MORU_COLOR_PASS: yellow sparkle and pink heart remain opaque")
	for directory in [OUTPUT, SHEET.get_base_dir()]:
		var err = DirAccess.make_dir_recursive_absolute(directory)
		if err != OK:
			push_error("HARU_IMPORT_ERROR: mkdir %s error=%d" % [directory, err])
			quit(1)
			return
	var sheet = Image.create(TILE * 3, TILE * 2, false, Image.FORMAT_RGBA8)
	for y in range(sheet.get_height()):
		for x in range(sheet.get_width()):
			var dark = (floori(x / 16.0) + floori(y / 16.0)) % 2 == 0
			sheet.set_pixel(x, y, Color("ded8d0") if dark else Color("fff7ec"))
	var completed = 0
	var skipped = 0
	var failed = 0
	var reference_image = Image.new()
	if reference_image.load_png_from_buffer(FileAccess.get_file_as_bytes(SOURCE + MAP.idle)) != OK:
		push_error("HARU_IMPORT_ERROR: idle reference required")
		quit(1)
		return
	key_and_resize(reference_image)
	var reference_keyboard = keyboard_bounds(reference_image)
	if not reference_keyboard.has_area():
		push_error("HARU_IMPORT_ERROR: idle keyboard not found")
		quit(1)
		return
	var reference_head = head_bounds(reference_image, reference_keyboard)
	print("HARU_REFERENCE: keyboard=%s head=%s eyes=%s,%s" % [reference_keyboard, reference_head, eye_center(reference_image, Rect2i(375, 485, 90, 85)), eye_center(reference_image, Rect2i(555, 485, 95, 85))])
	var slot = 0
	var cache: Dictionary = {}
	for key in MAP:
		var source_path = SOURCE + MAP[key]
		var cell = Vector2i((slot % 3) * TILE, int(slot / 3) * TILE)
		slot += 1
		if not FileAccess.file_exists(source_path):
			push_warning("HARU_SKIP: %s missing %s (output unchanged; sheet cell empty)" % [key, source_path])
			skipped += 1
			continue
		if not cache.has(source_path):
			var loaded = Image.new()
			var err = loaded.load_png_from_buffer(FileAccess.get_file_as_bytes(source_path))
			if err != OK:
				push_error("HARU_IMPORT_ERROR: %s load error=%d" % [key, err])
				failed += 1
				continue
			key_and_resize(loaded)
			cache[source_path] = loaded
		var aligned = align_pose(cache[source_path], reference_keyboard, key)
		if aligned.is_empty():
			failed += 1
			continue
		var result: Image = aligned.image
		var head = head_bounds(result, aligned.keyboard)
		print("HARU_ALIGN: %s scale=%.6f offset=%s keyboard=%s head_center_delta=%s%s" % [key, aligned.scale, aligned.offset, aligned.keyboard, head.get_center() - reference_head.get_center(), " (pose proxy only)" if key in ["action-1", "action-2"] else ""])
		if key in ["left", "right"] and Vector2(head.get_center() - reference_head.get_center()).length() > 12:
			push_warning("HARU_HEAD_DRIFT: %s source pose differs from idle; keyboard alignment retained" % key)
		var save_error = result.save_png(OUTPUT + key + ".png")
		if save_error != OK:
			push_error("HARU_IMPORT_ERROR: %s save error=%d" % [key, save_error])
			failed += 1
			continue
		var stats = measurements(result)
		print("HARU_RESULT: %s size=1024x1024 bbox=%s keyboard_top_y_est=%d widest_row=%d" % [key, stats.bbox, stats.keyboard_y, stats.widest])
		var thumb = result.duplicate()
		thumb.resize(TILE, TILE, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(thumb, Rect2i(0, 0, TILE, TILE), cell)
		completed += 1
	var sheet_error = sheet.save_png(SHEET)
	if sheet_error != OK:
		push_error("HARU_IMPORT_ERROR: sheet save error=%d" % sheet_error)
		failed += 1
	print("HARU_IMPORT_DONE: written=%d skipped=%d failed=%d sheet=%s" % [completed, skipped, failed, SHEET])
	quit(1 if failed > 0 else 0)
