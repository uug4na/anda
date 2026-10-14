extends Node2D
## Builds one map from Maps.gd: ground tiles, props, enemies, pickups, exits, triggers, the hero.
##
## Optional map keys beyond "rows": base, exits, growth, entity_ground, night, npc, enemies,
## when (char -> flag that must be set before the entity spawns), triggers (char -> story id).

const TILE := 32
const GROUND_CHARS := ".,:*o=~_k"
const HERO_SCENE := preload("res://scenes/Hero.tscn")
const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

const SOURCES := {"steppe": TileSets.SRC_STEPPE, "forest": TileSets.SRC_FOREST, "camp": TileSets.SRC_CAMP,
	"mud": TileSets.SRC_MUD, "mountain": TileSets.SRC_MOUNTAIN, "winter": TileSets.SRC_WINTER}
const VARIANTS := {
	"steppe": {".": [0, 0, 0, 1, 1, 13, 13, 14, 15, 15, 3], ",": [2, 2, 4, 5], ":": [6], "*": [8, 9], "o": [10, 11], "=": [12], "k": [10]},
	"forest": {".": [0, 0, 0, 1, 1, 2], ",": [4, 5, 6], ":": [12, 13, 14, 15], "*": [3], "o": [7], "=": [8, 9], "k": [10, 11]},
	"camp": {".": [0, 0, 1, 1, 2, 2, 3], ",": [4, 5], ":": [6, 7], "*": [8, 9], "o": [13, 14, 15], "=": [12], "k": [7]},
	"mud": {".": [0, 0, 1, 1, 2, 12, 13, 14, 15], ",": [4, 5], ":": [6, 7], "*": [8, 9], "o": [10, 11], "=": [3], "k": [3]},
	"mountain": {".": [0, 0, 1, 1, 2, 12, 13, 14, 15], ",": [4, 5], ":": [6, 7], "*": [3], "o": [10, 11], "=": [3], "k": [8, 9]},
	"winter": {".": [0, 0, 1, 1, 2, 3, 12, 13, 14, 15], ",": [4, 5], ":": [6, 7], "*": [10, 11], "o": [10, 11], "=": [8, 9], "k": [8]},
}
const DEFAULT_ENEMIES := {"W": "sword", "A": "archer", "&": "hunter", "$": "dog", "K": "begter", "%": "targhutai"}
const MAP_NAMES := {"camp": "Home camp", "overworld": "The steppe", "riverbank": "Onon river", "burkhan": "Burkhan Khaldun",
	"tayichiud": "Tayichiud camp", "sorkan": "Sorkan-Shira's ger", "thieves": "Thieves' trail", "ongkhan": "Ong Khan's tent",
	"merkit": "Merkit camp", "balzhut": "Dalan Balzhut", "tatar": "Tatar camp", "baljuna": "Lake Baljuna", "kereyit": "Kereyit camp", "naqu": "Mount Naqu"}

@onready var ground: TileMapLayer = $Ground
@onready var world: Node2D = $World

var map_id := ""
var map := {}
var rng := RandomNumberGenerator.new()
var hero: Node2D
var banners: Array = []
var night := false
var enemy_kinds := {}
var npc_kinds := {}
var pending_when: Array = []
var survive_left := 0.0
var wave_timer := 0.0
var map_w := 0
var map_h := 0
var exit_info := {}
var exit_labels := {}
var trigger_pos := {}


func _ready() -> void:
	Game.ui_busy = false
	get_tree().paused = false
	map_id = Game.pending_map
	map = Maps.get_map(map_id)
	Game.current_map = map_id
	Game.debug("level ready: %s ui_busy=%s" % [map_id, Game.ui_busy])
	rng.seed = hash(map_id)
	ground.tile_set = TileSets.build()
	night = map.get("night", false)
	Game.level_aggro_scale = float(map.get("aggro_scale", 1.0))
	enemy_kinds = DEFAULT_ENEMIES.duplicate()
	enemy_kinds.merge(map.get("enemies", {}), true)
	npc_kinds = {"M": "hoelun"}
	npc_kinds.merge(map.get("npc", {}), true)
	Game.on_level_ready(map_id)
	_build()
	for who in map.get("allies", []):
		if Game.flags.get(str(map.get("allies_flag", "")), true):
			Ally.spawn(world, hero.position + Vector2(-40, 10), str(who))
	if night:
		var cm := CanvasModulate.new()
		cm.color = Color(0.4, 0.44, 0.7)
		add_child(cm)
	Game.tails_changed.connect(_refresh_banners)
	Game.flags_changed.connect(_check_pending)
	Game.flags_changed.connect(_refresh_exit_labels)
	Game.inventory_changed.connect(_refresh_exit_labels)
	_refresh_exit_labels()
	Sfx.start_map_audio(map_id)
	# The checkpoint is written here, once the hero really stands on the map.
	Game.autosave.call_deferred()
	survive_left = float(map.get("survive", 0.0))
	if OS.has_environment("ANDA_SURVIVE") and survive_left > 0.0:
		survive_left = float(OS.get_environment("ANDA_SURVIVE"))
	Game.survive_left = survive_left
	Game.on_level_shown(map_id)


func _process(delta: float) -> void:
	if survive_left <= 0.0:
		return
	survive_left -= delta
	Game.survive_left = survive_left
	wave_timer -= delta
	if wave_timer <= 0.0 and map.has("waves"):
		var wave: Dictionary = map.waves
		wave_timer = float(wave.get("every", 6.0))
		var alive := get_tree().get_nodes_in_group("enemy").size()
		if alive < int(wave.get("max", 6)):
			for k in wave.get("kinds", ["sword"]):
				var side: int = rng.randi_range(0, 1)
				var x: float = (map_w - 2) * TILE if side == 0 else TILE * 1.5
				var y: float = rng.randi_range(2, map_h - 3) * TILE
				_enemy(Enemy.kind_named(str(k)), Vector2(x, y))
				Vfx.play(world, "dust", Vector2(x, y - 6))
	if survive_left <= 0.0:
		Game.survive_left = 0.0
		Game.story_trigger(str(map.get("survive_trigger", "")))


func _build() -> void:
	var rows: Array = map.rows
	var h := rows.size()
	var w: int = rows[0].length()
	map_w = w
	map_h = h
	var base: String = map.get("base", "steppe")
	var entity_ground: Dictionary = map.get("entity_ground", {})
	var exits: Dictionary = map.get("exits", {})
	var growth: Dictionary = map.get("growth", {})
	var when: Dictionary = map.get("when", {})
	var unless: Dictionary = map.get("unless", {})
	var triggers: Dictionary = map.get("triggers", {})
	var spawn_char: String = Game.pending_spawn
	var spawn_pos := Vector2(w * TILE / 2.0, h * TILE / 2.0)
	# The tiles beside an exit along the map edge stay clear, so the gap in the treeline can be seen.
	var clear := {}
	for y in h:
		for x in w:
			var ec: String = rows[y][x]
			if exits.has(ec) and not GROUND_CHARS.contains(ec):
				var along := Vector2i(0, 1) if (x == 0 or x == w - 1) else Vector2i(1, 0)
				clear[Vector2i(x, y) + along] = true
				clear[Vector2i(x, y) - along] = true
	for y in h:
		var row: String = rows[y]
		assert(row.length() == w, "map %s row %d has width %d, expected %d" % [map_id, y, row.length(), w])
		for x in w:
			var ch := row[x]
			var is_ground := GROUND_CHARS.contains(ch)
			if clear.has(Vector2i(x, y)) and "TPBQ".contains(ch):
				_paint(Vector2i(x, y), ":", base)
				continue
			var gch: String = ch if is_ground else str(entity_ground.get(ch, ":" if exits.has(ch) else "."))
			_paint(Vector2i(x, y), gch, base)
			if is_ground:
				continue
			var feet := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE)
			var centre := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			if ch == spawn_char:
				if ch == "@":
					spawn_pos = feet
				else:
					var inward := Vector2i(1 if x == 0 else (-1 if x == w - 1 else 0), 1 if y == 0 else (-1 if y == h - 1 else 0))
					# Well clear of the exit tile, so arriving never counts as stepping onto it.
					spawn_pos = centre + Vector2(inward) * (TILE + 14.0) + Vector2(0, TILE / 2.0)
			if exits.has(ch):
				var edge_in := Vector2(1 if x == 0 else (-1 if x == w - 1 else 0), 1 if y == 0 else (-1 if y == h - 1 else 0))
				_add_exit(centre, ch, exits.get(ch), edge_in)
			elif ch.is_valid_int():
				pass
			elif triggers.has(ch):
				_add_trigger(centre, str(triggers[ch]))
			elif ch == "@":
				pass
			elif Game.tails < int(growth.get(ch, 0)):
				pass
			elif unless.has(ch) and Game.flags.get(str(unless[ch]), false):
				pass
			elif when.has(ch) and not Game.flags.get(str(when[ch]), false):
				pending_when.append({"ch": ch, "feet": feet, "flag": str(when[ch])})
			else:
				_spawn_entity(ch, feet)
	_add_bounds(w, h)
	hero = HERO_SCENE.instantiate()
	hero.position = spawn_pos
	Game.debug("spawn: default %s pending %s" % [spawn_pos, Game.pending_position])
	if Game.pending_position != null:
		var p: Vector2 = Game.pending_position
		# A saved position must lie inside the map, off the border; anything else is a bad save.
		if p.x > TILE and p.y > TILE and p.x < (w - 1) * TILE and p.y < (h - 1) * TILE + TILE / 2.0:
			hero.position = p
		Game.pending_position = null
	world.add_child(hero)
	hero.set_camera_limits(Rect2(0, 0, w * TILE, h * TILE))


func _check_pending() -> void:
	var still: Array = []
	for item in pending_when:
		if Game.flags.get(item.flag, false):
			_spawn_entity(item.ch, item.feet)
			Vfx.play(world, "dust", item.feet + Vector2(0, -6))
		else:
			still.append(item)
	pending_when = still


func _paint(cell: Vector2i, gch: String, base: String) -> void:
	match gch:
		"~":
			ground.set_cell(cell, TileSets.SRC_WATER, Vector2i(0, 0))
		"_":
			ground.set_cell(cell, TileSets.SRC_WATER, Vector2i(rng.randi_range(0, 3), 1))
		_:
			var src: int = SOURCES.get(base, TileSets.SRC_STEPPE)
			if not ground.tile_set.has_source(src):
				src = TileSets.SRC_STEPPE
				base = "steppe"
			var table: Dictionary = VARIANTS[base]
			var options: Array = table.get(gch, table["."])
			var idx: int = options[rng.randi_range(0, options.size() - 1)]
			ground.set_cell(cell, src, Vector2i(idx % 4, int(float(idx) / 4)))


func _spawn_entity(ch: String, feet: Vector2) -> void:
	if enemy_kinds.has(ch) and enemy_kinds[ch] != "":
		_enemy(Enemy.kind_named(str(enemy_kinds[ch])), feet)
		return
	if npc_kinds.has(ch):
		Npc.spawn(world, feet, str(npc_kinds[ch]))
		return
	match ch:
		"T": _prop("larch", rng.randi_range(0, 2), feet)
		"P": _prop("pine", rng.randi_range(0, 1), feet)
		"B": _prop("boulder", rng.randi_range(0, 2), feet)
		"Q": _prop("bush", rng.randi_range(0, 2), feet)
		"Y": _prop("tallgrass", 0, feet)
		"G": _prop("ger", 0, feet)
		"J": _prop("ger_small", 0, feet)
		"E": _prop("ger_enemy", 0, feet)
		"F": _prop("campfire", 0, feet)
		"H": _prop("haystack", 0, feet)
		"L": _prop("hitching", 0, feet)
		"O": _prop("ovoo", 0, feet)
		"N": banners.append(_prop("banner", Game.tails, feet))
		"C": _prop("cart", 0, feet)
		"D": _prop("wool_cart", 0, feet)
		"I": _prop("torch", 0, feet)
		"Z": _prop("fence_h", 0, feet)
		"V": _prop("fence_v", 0, feet)
		"|": _prop("palisade_v", 0, feet)
		"-": _prop("palisade_h", 0, feet)
		"S": _prop("sheep", rng.randi_range(0, 2), feet)
		"U": _prop("horse", rng.randi_range(0, 1), feet)
		"R": Pickup.spawn(world, feet + Vector2(0, -8), "roots")
		"X": Pickup.spawn(world, feet + Vector2(0, -12), "fish")
		"+": _prop("ger", 0, feet)
		"#": _prop("ger_small", 0, feet)
		"{": _prop("golden_tent", 0, feet)
		"<", ">", "(", ")", "9": pass
		"}": _prop("merkit_standard", 0, feet)
		"[": _prop("cauldron", 0, feet)
		_: push_warning("unknown map char '%s'" % ch)


func _prop(kind: String, variant: int, feet: Vector2) -> Prop:
	var p := Prop.make(kind, variant)
	p.position = feet
	world.add_child(p)
	if night and (p.kind == "torch" or p.kind == "campfire"):
		_add_light(p, 1.3 if p.kind == "campfire" else 0.9)
	return p


func _add_light(node: Node2D, energy: float) -> void:
	var light := PointLight2D.new()
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	light.texture = tex
	light.color = Color(1.0, 0.82, 0.55)
	light.energy = energy
	light.position = Vector2(0, -24)
	node.add_child(light)


func _enemy(kind: int, feet: Vector2) -> void:
	# A boss already beaten stays beaten, whatever brings the hero back to its map.
	var flag: String = str(Enemy.PARAMS[kind].get("flag", ""))
	if flag != "" and Game.flags.get(flag, false):
		return
	var e := ENEMY_SCENE.instantiate()
	e.kind = kind
	e.position = feet
	world.add_child(e)


func _area(centre: Vector2) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	area.add_child(shape)
	area.position = centre
	add_child(area)
	return area


func _add_exit(centre: Vector2, digit: String, target, inward: Vector2) -> void:
	if target == null:
		return
	var dest := str(target.map) if target is Dictionary else str(target)
	if dest == map_id:
		# The steppe's return point from Sorkan-Shira's ger doubles as the way back while the captain lives.
		if map_id == "overworld" and digit == "5" and Game.flags.get("cangue_off", false) and not Game.flags.get("captain", false):
			dest = "sorkan"
			target = "sorkan"
		else:
			return
	exit_info[digit] = {"pos": centre, "map": dest}
	if dest != map_id:
		var sign := Label.new()
		sign.text = MAP_NAMES.get(dest, dest)
		sign.label_settings = Game.label_settings(Color(0.95, 0.91, 0.82), 2)
		sign.size = Vector2(160, 24)
		sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var ly := centre.y - 44.0 if centre.y > 64.0 else centre.y + 18.0
		sign.position = Vector2(clampf(centre.x - 80.0, 4.0, map_w * TILE - 164.0), ly)
		sign.z_index = 12
		sign.modulate = Color(1, 1, 1, 0.8)
		add_child(sign)
		exit_labels[digit] = sign
	var area := _area(centre)
	var armed := [true]
	var push := inward if inward != Vector2.ZERO else Vector2.DOWN
	var attempt: Callable
	attempt = func(b: Node) -> void:
		if not b.is_in_group("hero") or not armed[0]:
			return
		if Game._busy_fade:
			# Still fading in from the last map: not a real step yet. Look again once the fade is done,
			# so a hero who is still standing here then does leave, and the exit never goes dead.
			get_tree().create_timer(0.5).timeout.connect(func() -> void:
				if is_instance_valid(b) and armed[0] and not Game._busy_fade and area.overlaps_body(b):
					attempt.call(b))
			return
		armed[0] = false
		Game.debug("exit %s to %s: %s" % [digit, dest, "open" if Game.exit_open(dest) else "closed"])
		if Game.exit_open(dest):
			Game.take_exit(target, digit)
		else:
			# Closed for now: say where the story is instead, and nudge the hero back onto the map.
			Vfx.float_text(world, centre + push * 24.0, "Not now. " + Game.objective_text(), Color(1, 0.8, 0.6))
			Sfx.play("ui")
			if b.has_method("shove"):
				b.shove(push)
	area.body_entered.connect(attempt)
	area.body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("hero"):
			armed[0] = true)


func _add_trigger(centre: Vector2, story_id: String) -> void:
	trigger_pos[story_id] = centre
	var area := _area(centre)
	var armed := [true]
	area.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("hero") and armed[0]:
			armed[0] = false
			Game.story_trigger(story_id))


func _add_bounds(w: int, h: int) -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	walls.collision_mask = 0
	var pw := float(w * TILE)
	var ph := float(h * TILE)
	for r in [Rect2(-32, -32, pw + 64, 32), Rect2(-32, ph, pw + 64, 32), Rect2(-32, 0, 32, ph), Rect2(pw, 0, 32, ph)]:
		var s := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		s.shape = rect
		s.position = r.position + r.size / 2.0
		walls.add_child(s)
	add_child(walls)


func _refresh_banners() -> void:
	for b in banners:
		if is_instance_valid(b):
			b.set_variant(Game.tails)


# ---------------------------------------------------------------- guide

## The exit on this map that leads toward another map: directly, or back through the steppe.
func _exit_toward(dest: String) -> String:
	for digit in exit_info:
		if exit_info[digit].map == dest:
			return digit
	if dest != map_id and map_id != "overworld":
		for digit in exit_info:
			if exit_info[digit].map == "overworld":
				return digit
	return ""


## Where the HUD guide should point: a world position, or null when there is nothing to show.
func guide_target():
	var obj: Dictionary = Game.objective()
	var kind: String = obj.kind
	if kind == "done" or obj.map == "":
		return null
	if obj.map != map_id:
		var digit := _exit_toward(obj.map)
		return exit_info[digit].pos if digit != "" else null
	match kind:
		"npc":
			for n in get_tree().get_nodes_in_group("npc"):
				if n.who == obj.who:
					return n.global_position
			return null
		"boss":
			var boss := get_tree().get_first_node_in_group("boss")
			if boss != null:
				return boss.global_position
			return _nearest(get_tree().get_nodes_in_group("enemy"))
		"pickup":
			var wanted: PackedStringArray = str(obj.who).split(",", false)
			var picks := []
			for pk in get_tree().get_nodes_in_group("pickup"):
				if pk.kind in wanted:
					picks.append(pk)
			return _nearest(picks)
		"trigger":
			return trigger_pos.get(obj.who)
	return null


func _nearest(nodes: Array):
	if hero == null or nodes.is_empty():
		return null
	var best = null
	var best_d := INF
	for n in nodes:
		var d: float = hero.global_position.distance_squared_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n.global_position
	return best


## The sign on the exit the objective lies through glows; the others stay quiet.
func _refresh_exit_labels() -> void:
	var obj: Dictionary = Game.objective()
	var lit := "" if obj.map == map_id or obj.map == "" else _exit_toward(str(obj.map))
	for digit in exit_labels:
		var l: Label = exit_labels[digit]
		var open: bool = Game.exit_open(str(exit_info[digit].map))
		var tint := Color(1.0, 0.86, 0.4) if digit == lit else (Color(0.95, 0.91, 0.82) if open else Color(0.62, 0.62, 0.68))
		l.label_settings = Game.label_settings(tint, 2)
		l.modulate = Color(1, 1, 1, 1.0 if digit == lit else (0.75 if open else 0.5))


# ---------------------------------------------------------------- walk grid (automated player)

var _grid: AStarGrid2D
const CELL := 16


## Where the hero can stand, as a 16 px grid built from the physics world, with A* on top.
func walk_grid() -> AStarGrid2D:
	if _grid != null:
		return _grid
	var g := AStarGrid2D.new()
	g.region = Rect2i(0, 0, map_w * 2, map_h * 2)
	g.cell_size = Vector2(CELL, CELL)
	g.offset = Vector2(CELL / 2.0, CELL / 2.0)
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	g.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	g.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	g.update()
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 10)
	q.shape = rect
	q.collision_mask = 1
	q.collide_with_areas = false
	q.collide_with_bodies = true
	for y in map_h * 2:
		for x in map_w * 2:
			var feet := Vector2(x * CELL + CELL / 2.0, y * CELL + CELL / 2.0)
			q.transform = Transform2D(0.0, feet + Vector2(0, -5))
			if not space.intersect_shape(q, 1).is_empty():
				g.set_point_solid(Vector2i(x, y), true)
	_grid = g
	return g


func grid_cell(pos: Vector2) -> Vector2i:
	return Vector2i(clampi(int(pos.x / CELL), 0, map_w * 2 - 1), clampi(int(pos.y / CELL), 0, map_h * 2 - 1))


## The nearest standable cell to a position, for targets that sit on something solid.
func free_cell_near(pos: Vector2) -> Vector2i:
	var g := walk_grid()
	var c := grid_cell(pos)
	if not g.is_point_solid(c):
		return c
	for r in range(1, 8):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if g.region.has_point(n) and not g.is_point_solid(n):
					return n
	return c
