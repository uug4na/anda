extends Control
## Portrait dialog box. show_lines([{name, portrait, text}, ...]) and it runs itself.

signal finished

const TEXT_WIDTH := 640 - 32 - 160
const TEXT_LINES := 3

var lines: Array = []
var idx := 0
var typing := false
var chars := 0.0
var guard := 0.0
var panel: NinePatchRect
var portrait: TextureRect
var name_plate: Panel
var name_label: Label
var text_label: Label
var hint: Label


func _ready() -> void:
	add_to_group("dialog")
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = NinePatchRect.new()
	panel.texture = Sheets.tex("ui/ui_dialog_9slice.png")
	panel.patch_margin_left = 16
	panel.patch_margin_right = 16
	panel.patch_margin_top = 16
	panel.patch_margin_bottom = 16
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 16
	panel.offset_right = -16
	panel.offset_top = -152
	panel.offset_bottom = -12
	add_child(panel)
	portrait = TextureRect.new()
	portrait.position = Vector2(10, 8)
	portrait.size = Vector2(128, 128)
	panel.add_child(portrait)
	# The speaker's name sits on a plate that straddles the frame above the portrait, so the
	# name, the face and the words read as one thing.
	name_plate = Panel.new()
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.1, 0.08, 0.14)
	plate.border_color = Color(0.79, 0.66, 0.29)
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(3)
	name_plate.add_theme_stylebox_override("panel", plate)
	name_plate.position = Vector2(22, -12)
	name_plate.size = Vector2(100, 24)
	panel.add_child(name_plate)
	name_label = Label.new()
	name_label.position = Vector2(0, 0)
	name_label.size = name_plate.size
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.label_settings = _settings(11, Color(0.96, 0.84, 0.5))
	name_plate.add_child(name_label)
	text_label = Label.new()
	text_label.position = Vector2(150, 22)
	text_label.size = Vector2(TEXT_WIDTH, Game.line_height() * TEXT_LINES)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_label.label_settings = _settings(11, Color(0.95, 0.91, 0.82))
	panel.add_child(text_label)
	hint = Label.new()
	hint.text = "E"
	hint.label_settings = _settings(9, Color(0.79, 0.66, 0.29))
	hint.position = Vector2(640 - 32 - 30, 110)
	panel.add_child(hint)
	visible = false


func _settings(_size: int, color: Color) -> LabelSettings:
	return Game.label_settings(color, 0)


func show_lines(new_lines: Array) -> void:
	if new_lines.is_empty():
		return
	# Long lines are split over several pages so nothing runs past the panel.
	lines = []
	for line in new_lines:
		for page in Game.paginate(str(line.get("text", "")), TEXT_WIDTH, TEXT_LINES):
			var copy: Dictionary = line.duplicate()
			copy.text = page
			lines.append(copy)
	idx = 0
	visible = true
	Game.debug("dialog shown, %d lines, panel rect %s, box size %s" % [lines.size(), panel.get_rect(), size])
	guard = 0.15
	Game.ui_busy = true
	_start_line()


func _start_line() -> void:
	var line: Dictionary = lines[idx]
	hint.text = Settings.key_name("interact")
	name_label.text = str(line.get("name", ""))
	var w: float = Game.font().get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.font_size).x + 20.0
	name_plate.size = Vector2(w, 24)
	name_label.size = name_plate.size
	name_plate.visible = name_label.text != ""
	text_label.text = str(line.get("text", ""))
	var port: String = str(line.get("portrait", ""))
	portrait.texture = Sheets.tex(port) if port != "" else null
	text_label.visible_characters = 0
	chars = 0.0
	typing = true
	hint.visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	guard = maxf(0.0, guard - delta)
	if typing:
		chars += delta * 45.0
		text_label.visible_characters = int(chars)
		if text_label.visible_characters >= text_label.text.length():
			text_label.visible_characters = -1
			typing = false
			hint.visible = true
	else:
		hint.visible = fmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.5
	if guard <= 0.0 and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack")):
		_advance()


func _advance() -> void:
	Sfx.play("ui")
	if typing:
		text_label.visible_characters = -1
		typing = false
		return
	idx += 1
	if idx >= lines.size():
		visible = false
		Game.ui_busy = false
		finished.emit()
	else:
		_start_line()
