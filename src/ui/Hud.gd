extends Control
## Hearts, arrows, tails, foraged food, the objective line and the boss bar.

var hearts: Array = []
var arrow_label: Label
var tail_label: Label
var fish_label: Label
var roots_label: Label
var objective: Label
var survive: Label
var comp_icon: TextureRect
var comp_label: Label
var comp_shown := ""
var boss_bar: ProgressBar
var boss_name: Label
var poll := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(640, 360)
	_build()
	Game.hp_changed.connect(_refresh)
	Game.inventory_changed.connect(_refresh)
	Game.tails_changed.connect(_refresh)
	Game.flags_changed.connect(_refresh)
	Game.boss_changed.connect(_on_boss)
	_refresh()
	_on_boss(Game.active_boss)


func _build() -> void:
	for i in 6:
		var h := TextureRect.new()
		h.position = Vector2(8 + i * 18, 8)
		h.texture = Sheets.cell("ui/ui_hud_grid.png", 16, 2, 4)
		h.visible = i < 3
		add_child(h)
		hearts.append(h)
	arrow_label = _counter(Sheets.cell("ui/ui_hud_grid.png", 16, 3, 4), Vector2(8, 28), 16)
	tail_label = _counter(Sheets.cell("ui/ui_hud_grid.png", 16, 12, 4), Vector2(8, 48), 16)
	fish_label = _counter(Sheets.cell("items/item_weapons_grid01.png", 48, 14, 4), Vector2(548, 6), 24)
	roots_label = _counter(Sheets.cell("items/item_weapons_grid01.png", 48, 13, 4), Vector2(596, 6), 24)
	objective = Label.new()
	objective.label_settings = Game.label_settings(Color(0.95, 0.91, 0.82), 2)
	objective.position = Vector2(100, 4)
	objective.size = Vector2(440, 48)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(objective)
	survive = Label.new()
	survive.label_settings = Game.label_settings(Color(1.0, 0.88, 0.45), 2)
	survive.position = Vector2(220, 54)
	survive.size = Vector2(200, 20)
	survive.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(survive)
	comp_icon = TextureRect.new()
	comp_icon.position = Vector2(8, 296)
	comp_icon.custom_minimum_size = Vector2(64, 64)
	comp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	comp_icon.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(comp_icon)
	comp_label = Label.new()
	comp_label.label_settings = Game.label_settings(Color(0.95, 0.91, 0.82), 2)
	comp_label.position = Vector2(76, 300)
	add_child(comp_label)
	boss_name = Label.new()
	boss_name.label_settings = Game.label_settings(Color(0.95, 0.91, 0.82), 2)
	boss_name.position = Vector2(170, 320)
	boss_name.size = Vector2(300, 20)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(boss_name)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(220, 342)
	boss_bar.size = Vector2(200, 8)
	boss_bar.show_percentage = false
	boss_bar.max_value = 1.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.08, 0.14)
	bg.border_color = Color(0.79, 0.66, 0.29)
	bg.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.7, 0.23, 0.18)
	boss_bar.add_theme_stylebox_override("background", bg)
	boss_bar.add_theme_stylebox_override("fill", fill)
	add_child(boss_bar)
	boss_bar.visible = false
	boss_name.visible = false


func _counter(icon: Texture2D, pos: Vector2, icon_size: int) -> Label:
	var tr := TextureRect.new()
	tr.texture = icon
	tr.position = pos
	tr.custom_minimum_size = Vector2(icon_size, icon_size)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(tr)
	var l := Label.new()
	l.label_settings = Game.label_settings(Color(0.95, 0.91, 0.82), 2)
	l.position = pos + Vector2(icon_size + 4, (icon_size - 18) / 2.0)
	add_child(l)
	return l


func _refresh() -> void:
	var shown: int = int(Game.max_hp() / 2)
	for i in 6:
		hearts[i].visible = i < shown
		var pips: int = clampi(Game.hp - i * 2, 0, 2)
		var idx := 0 if pips == 2 else (1 if pips == 1 else 2)
		hearts[i].texture = Sheets.cell("ui/ui_hud_grid.png", 16, idx, 4)
	arrow_label.text = str(Game.arrows)
	tail_label.text = "%d / 9" % Game.tails
	fish_label.text = str(Game.inventory.get("fish", 0))
	roots_label.text = str(Game.inventory.get("roots", 0))
	objective.text = Game.objective_text()


func _on_boss(boss: Node) -> void:
	var on := boss != null and is_instance_valid(boss)
	boss_bar.visible = on
	boss_name.visible = on
	if on:
		boss_name.text = boss.p.name


func _process(delta: float) -> void:
	poll -= delta
	if poll <= 0.0:
		poll = 0.3
		objective.text = Game.objective_text()
	var boss: Node = Game.active_boss
	if boss != null and is_instance_valid(boss):
		boss_bar.value = float(boss.hp) / float(boss.max_hp)
	elif boss_bar.visible:
		_on_boss(null)
	survive.text = ("Hold out: %d" % int(ceil(Game.survive_left))) if Game.survive_left > 0.0 else ""
	queue_redraw()
	var comp := Game.companion()
	var shown := comp + "|" + Settings.key_name("ability")
	if shown != comp_shown:
		comp_shown = shown
		if comp == "":
			comp_icon.texture = null
			comp_label.text = ""
		else:
			var port: String = Game.COMPANIONS[comp].portrait
			comp_icon.texture = Sheets.tex(port) if ResourceLoader.exists(Sheets.ROOT + port) else null
			comp_label.text = "%s  [%s] %s" % [Game.COMPANIONS[comp].name, Settings.key_name("ability"), Game.COMPANIONS[comp].ability]


# ---------------------------------------------------------------- guide

## Points at the current objective: a marker bobbing over it when on screen, an arrow at the
## screen edge when it is not. The level decides what the target is.
func _draw() -> void:
	var bar := Rect2(8, 70, 60, 6)
	var frac := clampf(Game.stamina / Game.STAMINA_MAX, 0.0, 1.0)
	var low := Game.stamina < Game.ROLL_COST
	draw_rect(bar, Color(0.1, 0.08, 0.14))
	draw_rect(Rect2(bar.position + Vector2(1, 1), Vector2((bar.size.x - 2.0) * frac, bar.size.y - 2.0)), Color(0.85, 0.3, 0.25) if low else Color(1.0, 0.86, 0.4))
	draw_rect(bar, Color(0.79, 0.66, 0.29), false, 1.0)
	if Game.ui_busy:
		return
	var level := get_tree().current_scene
	var hero := get_tree().get_first_node_in_group("hero")
	if level == null or hero == null or not level.has_method("guide_target"):
		return
	var target = level.guide_target()
	if target == null:
		return
	var cam: Camera2D = hero.get_node("Camera2D")
	var centre: Vector2 = cam.get_screen_center_position()
	var sp: Vector2 = (target as Vector2) - centre + Vector2(320, 180)
	var gold := Color(1.0, 0.86, 0.4)
	var dark := Color(0.1, 0.08, 0.14)
	var rect := Rect2(Vector2(26, 60), Vector2(640 - 52, 360 - 100))
	var pulse := absf(sin(Time.get_ticks_msec() / 1000.0 * 4.0))
	if rect.has_point(sp):
		var tip := sp + Vector2(0, -74 - pulse * 5.0)
		_chevron(tip, Vector2.DOWN, gold, dark)
		return
	var from: Vector2 = hero.global_position + Vector2(0, -30) - centre + Vector2(320, 180)
	from = Vector2(clampf(from.x, rect.position.x, rect.end.x), clampf(from.y, rect.position.y, rect.end.y))
	var d := sp - from
	if d.length() < 1.0:
		return
	d = d.normalized()
	var reach := INF
	if d.x > 0.0:
		reach = minf(reach, (rect.end.x - from.x) / d.x)
	elif d.x < 0.0:
		reach = minf(reach, (rect.position.x - from.x) / d.x)
	if d.y > 0.0:
		reach = minf(reach, (rect.end.y - from.y) / d.y)
	elif d.y < 0.0:
		reach = minf(reach, (rect.position.y - from.y) / d.y)
	if reach == INF:
		return
	var edge := from + d * reach
	edge = Vector2(clampf(edge.x, rect.position.x, rect.end.x), clampf(edge.y, rect.position.y, rect.end.y))
	_chevron(edge + d * pulse * 3.0, d, gold, dark)


func _chevron(tip: Vector2, d: Vector2, fill: Color, outline: Color) -> void:
	var n := d.orthogonal()
	var pts := PackedVector2Array([tip, tip - d * 16.0 + n * 9.0, tip - d * 10.0, tip - d * 16.0 - n * 9.0])
	draw_colored_polygon(pts, fill)
	var ring := pts.duplicate()
	ring.append(pts[0])
	draw_polyline(ring, outline, 2.0)
