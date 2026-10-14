class_name Menu
extends Control
## A vertical list of options on a panel. Keyboard and gamepad driven.

signal chosen(id: String)

var items: Array = []
var index := 0
var labels: Array = []
var panel: NinePatchRect
var title_label: Label
var guard := 0.15


func setup(new_items: Array, title := "", width := 220) -> void:
	items = new_items
	for c in get_children():
		c.queue_free()
	labels.clear()
	index = 0
	var rows := items.size()
	var height := 24 + (28 if title != "" else 0) + rows * 24
	panel = NinePatchRect.new()
	panel.texture = Sheets.tex("ui/ui_menu_panel_9slice.png")
	panel.patch_margin_left = 16
	panel.patch_margin_right = 16
	panel.patch_margin_top = 16
	panel.patch_margin_bottom = 16
	panel.size = Vector2(width, height)
	add_child(panel)
	size = panel.size
	var y := 12
	if title != "":
		title_label = Label.new()
		title_label.text = title
		title_label.label_settings = Game.label_settings(Color(0.96, 0.84, 0.5), 0)
		title_label.position = Vector2(0, y)
		title_label.size = Vector2(width, 20)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(title_label)
		y += 28
	for it in items:
		var l := Label.new()
		l.text = it.label
		l.label_settings = Game.label_settings(Color(0.95, 0.91, 0.82), 0)
		l.position = Vector2(0, y)
		l.size = Vector2(width, 20)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(l)
		labels.append(l)
		y += 24
	guard = 0.15
	_highlight()


func _highlight() -> void:
	for i in labels.size():
		var l: Label = labels[i]
		l.label_settings = Game.label_settings(Color(1.0, 0.88, 0.45) if i == index else Color(0.95, 0.91, 0.82), 0)
		l.text = ("> %s <" % items[i].label) if i == index else items[i].label


func _process(delta: float) -> void:
	if not is_visible_in_tree() or items.is_empty():
		return
	guard = maxf(0.0, guard - delta)
	if guard > 0.0:
		return
	if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		index = (index + 1) % items.size()
		Sfx.play("ui")
		_highlight()
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		index = (index - 1 + items.size()) % items.size()
		Sfx.play("ui")
		_highlight()
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
		Sfx.play("pickup")
		guard = 0.2
		chosen.emit(items[index].id)
