class_name Snare
extends Area2D
## Subutai's trap: the first enemy to step on it is stopped and hurt.

var t := 0.0
var sprite: Sprite2D


static func spawn(parent: Node, pos: Vector2) -> Snare:
	var s := Snare.new()
	s.position = pos + Vector2(0, -2)
	s.collision_layer = 0
	s.collision_mask = 1 << 2
	s.sprite = Sprite2D.new()
	s.sprite.texture = Sheets.cell("items/item_weapons_grid01.png", 48, 7, 4)
	s.sprite.scale = Vector2(0.6, 0.6)
	s.sprite.modulate = Color(1, 1, 1, 0.85)
	s.add_child(s.sprite)
	var c := CollisionShape2D.new()
	var r := CircleShape2D.new()
	r.radius = 18.0
	c.shape = r
	s.add_child(c)
	s.body_entered.connect(s._on_body)
	parent.add_child(s)
	return s


func _process(delta: float) -> void:
	t += delta
	sprite.rotation = sin(t * 2.0) * 0.1
	if t > 20.0:
		queue_free()


func _on_body(b: Node) -> void:
	if not b.is_in_group("enemy") or not b.has_method("stun"):
		return
	b.stun(1.6)
	b.call_deferred("take_hit", 2, global_position)
	Vfx.play(get_parent(), "dust", global_position)
	Sfx.play("hit", -4.0)
	set_deferred("monitoring", false)
	queue_free()
