extends Control
## Full screen illustration with captions. Reads Game.pending_cutscene.

const PANEL_Y := 256
const CAPTION_WIDTH := 564
const CAPTION_LINES := 3

var lines: Array = []
var idx := 0
var caption: Label
var next_map := "camp"
var done := false
var guard := 0.3


func _ready() -> void:
	Game.ui_busy = false
	get_tree().paused = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var data: Dictionary = Game.pending_cutscene
	for line in data.get("lines", ["..."]):
		lines.append_array(Game.paginate(str(line), CAPTION_WIDTH, CAPTION_LINES))
	next_map = data.get("next", "camp")
	var back := ColorRect.new()
	back.color = Color(0.05, 0.04, 0.07)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var image_path: String = str(data.get("image", ""))
	if image_path != "" and ResourceLoader.exists(Sheets.ROOT + image_path):
		var img := TextureRect.new()
		img.texture = Sheets.tex(image_path)
		# Pictures come in a few sizes. Whole-number scaling keeps pixels crisp; a picture that would
		# stay small at a whole number is stretched to the screen instead.
		var tex_size: Vector2 = img.texture.get_size()
		var s := floorf(minf(640.0 / tex_size.x, 360.0 / tex_size.y))
		if s * tex_size.x < 640.0 * 0.75:
			s = minf(640.0 / tex_size.x, 360.0 / tex_size.y)
		img.scale = Vector2(s, s)
		tex_size *= s
		img.position = Vector2((640 - tex_size.x) / 2.0, maxf(0.0, (PANEL_Y - tex_size.y) / 2.0))
		add_child(img)
	var panel := NinePatchRect.new()
	panel.texture = Sheets.tex("ui/ui_dialog_9slice.png")
	panel.patch_margin_left = 16
	panel.patch_margin_right = 16
	panel.patch_margin_top = 16
	panel.patch_margin_bottom = 16
	panel.position = Vector2(24, PANEL_Y)
	panel.size = Vector2(592, 360 - PANEL_Y - 8)
	add_child(panel)
	caption = Label.new()
	caption.position = Vector2(14, 12)
	caption.size = Vector2(CAPTION_WIDTH, Game.line_height() * CAPTION_LINES)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.label_settings = Game.label_settings(Color(0.95, 0.91, 0.82), 0)
	panel.add_child(caption)
	_show()


func _show() -> void:
	caption.text = str(lines[idx])


func _process(delta: float) -> void:
	guard = maxf(0.0, guard - delta)
	if done or guard > 0.0:
		return
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
		idx += 1
		guard = 0.15
		if idx >= lines.size():
			done = true
			match next_map:
				"credits":
					Game.run_cutscene("credits")
				"title":
					Game.to_title()
				_:
					Game.goto_map(next_map, "@")
		else:
			_show()
