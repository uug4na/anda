class_name TileSets
extends RefCounted
## Builds the game TileSet from the processed 32 px tile grids at runtime.
## Grids that have not been generated yet are skipped; Level falls back to the steppe.

const SRC_STEPPE := 0
const SRC_FOREST := 1
const SRC_CAMP := 2
const SRC_WATER := 3
const SRC_MUD := 4
const SRC_MOUNTAIN := 5
const SRC_WINTER := 6

const SOLID_RECT := [Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)]


static func build() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	_add_grid(ts, SRC_STEPPE, "tiles/tile_steppe_summer_grid01.png", 4, 4, [])
	_add_grid(ts, SRC_FOREST, "tiles/tile_forest_grid01.png", 4, 4, [10, 11])
	_add_grid(ts, SRC_CAMP, "tiles/tile_camp_ground_grid01.png", 4, 4, [])
	_add_water(ts)
	_add_grid(ts, SRC_MUD, "tiles/tile_shore_mud_grid01.png", 4, 4, [])
	_add_grid(ts, SRC_MOUNTAIN, "tiles/tile_mountain_grid01.png", 4, 4, [8, 9])
	_add_grid(ts, SRC_WINTER, "tiles/tile_steppe_winter_grid01.png", 4, 4, [])
	return ts


static func _add_grid(ts: TileSet, id: int, path: String, cols: int, rows: int, solid: Array) -> void:
	if not ResourceLoader.exists(Sheets.ROOT + path):
		return
	var src := TileSetAtlasSource.new()
	src.texture = Sheets.tex(path)
	src.texture_region_size = Vector2i(32, 32)
	ts.add_source(src, id)
	for y in rows:
		for x in cols:
			var c := Vector2i(x, y)
			src.create_tile(c)
			if (y * cols + x) in solid:
				_solid(src, c)


static func _add_water(ts: TileSet) -> void:
	var src := TileSetAtlasSource.new()
	src.texture = Sheets.tex("tiles/tile_water_strip.png")
	src.texture_region_size = Vector2i(32, 32)
	ts.add_source(src, SRC_WATER)
	var w := Vector2i(0, 0)
	src.create_tile(w)
	src.set_tile_animation_frames_count(w, 4)
	for i in 4:
		src.set_tile_animation_frame_duration(w, i, 0.3)
	_solid(src, w)
	for x in 4:
		src.create_tile(Vector2i(x, 1))


static func _solid(src: TileSetAtlasSource, c: Vector2i) -> void:
	var td := src.get_tile_data(c, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array(SOLID_RECT))
