class_name Sheets
extends RefCounted
## Helpers that slice the processed sprite sheets into textures and animations.

const ROOT := "res://assets/processed/"
static var _cache := {}


static func tex(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load(ROOT + path)
	return _cache[path]


static func atlas(path: String, rect: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex(path)
	a.region = rect
	return a


## One square cell out of a grid sheet, indexed left to right, top to bottom.
static func cell(path: String, size: int, index: int, cols: int = -1) -> AtlasTexture:
	var t := tex(path)
	if cols <= 0:
		cols = int(float(t.get_width()) / size)
	var x := index % cols
	var y := int(float(index) / cols)
	return atlas(path, Rect2(x * size, y * size, size, size))


## Every cell of a sheet as an array of textures.
static func cells(path: String, w: int, h: int) -> Array:
	var t := tex(path)
	var out := []
	for y in range(int(float(t.get_height()) / h)):
		for x in range(int(float(t.get_width()) / w)):
			out.append(atlas(path, Rect2(x * w, y * h, w, h)))
	return out


## A three direction sheet: {down, up, side}.
static func dir3(path: String, size: int) -> Dictionary:
	return {
		"down": cell(path, size, 0, 3),
		"up": cell(path, size, 1, 3),
		"side": cell(path, size, 2, 3),
	}


## SpriteFrames with one animation built from a strip or grid.
static func anim(path: String, w: int, h: int, fps: float, loop: bool, indices: Array = []) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", fps)
	sf.set_animation_loop("default", loop)
	var all := cells(path, w, h)
	if indices.is_empty():
		for c in all:
			sf.add_frame("default", c)
	else:
		for i in indices:
			sf.add_frame("default", all[i])
	return sf
