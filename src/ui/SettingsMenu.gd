class_name SettingsMenu
extends Control
## Volumes, fullscreen and key bindings on one panel. Up and down pick a row, left and right
## change a value, the talk key on a key row waits for the next key press, Esc or Back closes.

signal closed

const WIDTH := 400

var rows: Array = []
var index := 0
var labels: Array = []
var values: Array = []
var panel: NinePatchRect
var hint: Label
var waiting := false
var guard := 0.2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows = [
		{"id": "music", "label": "Music volume", "kind": "slider"},
		{"id": "sound", "label": "Sound volume", "kind": "slider"},
		{"id": "fullscreen", "label": "Fullscreen", "kind": "toggle"},
	]
	for pair in Settings.BINDABLE:
		rows.append({"id": pair[0], "label": pair[1], "kind": "key"})
	rows.append({"id": "back", "label": "Back", "kind": "action"})
	var line_h := 19
	var height := 44 + rows.size() * line_h + 34
	panel = NinePatchRect.new()
	panel.texture = Sheets.tex("ui/ui_menu_panel_9slice.png")
	panel.patch_margin_left = 16
	panel.patch_margin_right = 16
	panel.patch_margin_top = 16
	panel.patch_margin_bottom = 16
	panel.size = Vector2(WIDTH, height)
	panel.position = Vector2(roundf((640 - WIDTH) / 2.0), roundf((360 - height) / 2.0))
	add_child(panel)
	var title := Label.new()
	title.text = "Settings"
	title.label_settings = Game.label_settings(Color(0.96, 0.84, 0.5), 0)
	title.position = Vector2(0, 10)
	title.size = Vector2(WIDTH, 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	var y := 38
	for r in rows:
		var l := Label.new()
		l.text = r.label
		l.position = Vector2(28, y)
		l.size = Vector2(200, line_h)
		panel.add_child(l)
		labels.append(l)
		var v := Label.new()
		v.position = Vector2(WIDTH - 28 - 170, y)
		v.size = Vector2(170, line_h)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel.add_child(v)
		values.append(v)
		y += line_h
	hint = Label.new()
	hint.label_settings = Game.label_settings(Color(0.85, 0.8, 0.7), 0)
	hint.position = Vector2(0, height - 28)
	hint.size = Vector2(WIDTH, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)
	_refresh()


func open() -> void:
	Game.debug("settings opened")
	visible = true
	index = 0
	waiting = false
	guard = 0.2
	_refresh()


func _refresh() -> void:
	for i in rows.size():
		var r: Dictionary = rows[i]
		var on := i == index
		var tint := Color(1.0, 0.88, 0.45) if on else Color(0.95, 0.91, 0.82)
		labels[i].label_settings = Game.label_settings(tint, 0)
		values[i].label_settings = Game.label_settings(tint, 0)
		labels[i].text = ("> " + r.label) if on else r.label
		match r.kind:
			"slider":
				var v: int = Settings.music if r.id == "music" else Settings.sound
				values[i].text = "%s %d" % [_bar(v), v]
			"toggle":
				values[i].text = "On" if Settings.fullscreen else "Off"
			"key":
				values[i].text = "press a key..." if (waiting and on) else Settings.key_name(r.id)
			_:
				values[i].text = ""
	var r: Dictionary = rows[index]
	match r.kind:
		"slider", "toggle":
			hint.text = "Left / right to change"
		"key":
			hint.text = "%s to rebind, Esc to cancel" % Settings.key_name("interact") if not waiting else "Press the new key"
		_:
			hint.text = "%s to go back" % Settings.key_name("interact")


func _bar(v: int) -> String:
	var s := ""
	for i in 10:
		s += "|" if i < v else "."
	return s


func _input(event: InputEvent) -> void:
	# Capturing a new key happens here so the key press never reaches the game underneath.
	if not is_visible_in_tree() or not waiting:
		return
	if event is InputEventJoypadButton and event.pressed:
		# Pad buttons stay as they are; a press just leaves the prompt.
		get_viewport().set_input_as_handled()
		waiting = false
		guard = 0.2
		_refresh()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		waiting = false
		if event.physical_keycode != KEY_ESCAPE:
			Settings.bind_key(rows[index].id, event.physical_keycode)
			Settings.save_file()
			Sfx.play("pickup")
		else:
			Sfx.play("ui")
		guard = 0.2
		_refresh()


func _process(delta: float) -> void:
	if not is_visible_in_tree() or waiting:
		return
	guard = maxf(0.0, guard - delta)
	if guard > 0.0:
		return
	var r: Dictionary = rows[index]
	if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		index = (index + 1) % rows.size()
		Sfx.play("ui")
		_refresh()
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		index = (index - 1 + rows.size()) % rows.size()
		Sfx.play("ui")
		_refresh()
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		_adjust(r, -1)
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		_adjust(r, 1)
	elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel"):
		_close()
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
		match r.kind:
			"key":
				waiting = true
				guard = 0.2
				Sfx.play("ui")
				_refresh()
			"toggle":
				_adjust(r, 1)
			"action":
				_close()
			_:
				_adjust(r, 1)


func _adjust(r: Dictionary, dir: int) -> void:
	match r.id:
		"music":
			Settings.music = clampi(Settings.music + dir, 0, 10)
		"sound":
			Settings.sound = clampi(Settings.sound + dir, 0, 10)
		"fullscreen":
			Settings.fullscreen = not Settings.fullscreen
		_:
			return
	Settings.apply()
	Settings.save_file()
	Sfx.play("ui")
	guard = 0.12
	_refresh()


func _close() -> void:
	Game.debug("settings closed")
	Sfx.play("ui")
	visible = false
	closed.emit()
