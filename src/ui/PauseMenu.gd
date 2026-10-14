extends Control
## Escape pauses the game and shows resume / save / title / quit.

var menu: Menu
var dim: ColorRect
var open := false
var note: Label
var settings: SettingsMenu
var settings_guard := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim = ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.07, 0.55)
	dim.size = size
	add_child(dim)
	menu = Menu.new()
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu)
	var items := [
		{"id": "resume", "label": "Resume"},
		{"id": "save", "label": "Save game"},
		{"id": "settings", "label": "Settings"},
		{"id": "title", "label": "Title screen"},
	]
	if OS.get_name() != "Web":
		items.append({"id": "quit", "label": "Quit"})
	menu.setup(items, "Paused")
	menu.position = ((size - menu.size) / 2.0).round()
	menu.chosen.connect(_on_chosen)
	note = Label.new()
	note.label_settings = Game.label_settings(Color(0.85, 0.8, 0.7), 2)
	note.size = Vector2(640, 20)
	note.position = Vector2(0, menu.position.y + menu.size.y + 10)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)
	settings = SettingsMenu.new()
	settings.visible = false
	settings.closed.connect(_on_settings_closed)
	add_child(settings)
	visible = false


func _process(delta: float) -> void:
	settings_guard = maxf(0.0, settings_guard - delta)
	if settings.visible or settings_guard > 0.0:
		return
	if Input.is_action_just_pressed("pause") and not (Game.ui_busy and not open):
		_toggle()


func _on_settings_closed() -> void:
	menu.visible = true
	menu.guard = 0.25
	settings_guard = 0.25


func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open
	Game.ui_busy = open
	note.text = ""
	if open:
		menu.index = 0
		menu._highlight()
		menu.guard = 0.15
		Sfx.play("ui")
	else:
		var h := get_tree().get_first_node_in_group("hero")
		Game.debug("resume: hero %s" % ("missing" if h == null else "%s visible=%s mod=%s state=%s mask=%d parent=%s" % [h.global_position, h.visible, h.get_node("Body").modulate, h.state, h.collision_mask, h.get_parent().name]))


func _on_chosen(id: String) -> void:
	match id:
		"resume":
			_toggle()
		"save":
			Game.autosave()
			note.text = "Saved"
		"settings":
			menu.visible = false
			settings.open()
		"title":
			open = false
			visible = false
			Game.to_title()
		"quit":
			get_tree().quit()
