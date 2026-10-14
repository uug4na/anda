class_name Vfx
extends RefCounted
## One-shot effects and floating text.

const KINDS := {
	"slash": {"tex": "vfx/vfx_slash_4f.png", "cell": 48, "idx": [0, 1, 2, 3], "fps": 18.0},
	"spark": {"tex": "vfx/vfx_small_fx_grid.png", "cell": 32, "idx": [0, 1, 2, 3], "fps": 16.0},
	"dust": {"tex": "vfx/vfx_small_fx_grid.png", "cell": 32, "idx": [4, 5, 6, 7], "fps": 14.0},
	"splash": {"tex": "vfx/vfx_small_fx_grid.png", "cell": 32, "idx": [8, 9, 10, 11], "fps": 14.0},
	"burst": {"tex": "vfx/vfx_small_fx_grid.png", "cell": 32, "idx": [12, 13, 14, 15], "fps": 16.0},
	"hoof": {"tex": "vfx/vfx_hoofdust_4f.png", "cell": 48, "idx": [0, 1, 2, 3], "fps": 12.0},
}


static func play(parent: Node, kind: String, pos: Vector2, rot := 0.0, flip := false) -> AnimatedSprite2D:
	var k: Dictionary = KINDS[kind]
	var a := AnimatedSprite2D.new()
	a.sprite_frames = Sheets.anim(k.tex, k.cell, k.cell, k.fps, false, k.idx)
	a.position = pos
	a.rotation = rot
	a.flip_h = flip
	a.z_index = 5
	a.animation_finished.connect(a.queue_free)
	parent.add_child(a)
	a.play("default")
	return a


static func float_text(parent: Node, pos: Vector2, text: String, color := Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.modulate = color
	l.label_settings = Game.label_settings(Color.WHITE, 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size = Vector2(320, 72)
	l.position = pos + Vector2(-160, -108)
	l.z_index = 20
	# Keep the text inside the camera view, so a line spoken at the map edge is not cut off.
	var hero := parent.get_tree().get_first_node_in_group("hero")
	if hero != null and hero.has_node("Camera2D"):
		var c: Vector2 = hero.get_node("Camera2D").get_screen_center_position()
		l.position.x = clampf(l.position.x, c.x - 316.0, c.x + 316.0 - l.size.x)
		l.position.y = clampf(l.position.y, c.y - 176.0, c.y + 176.0 - l.size.y)
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 22.0, 1.1)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.5)
	tw.tween_callback(l.queue_free)
