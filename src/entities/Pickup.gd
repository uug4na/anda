class_name Pickup
extends Area2D
## Roots, fish and hearts lying on the ground.

const ICONS := {
	"roots": {"tex": "items/item_weapons_grid01.png", "cell": 48, "idx": 13, "cols": 4},
	"fish": {"tex": "animals/animal_small_grid01.png", "cell": 48, "idx": 12, "cols": 4},
	"heart": {"tex": "ui/ui_hud_grid.png", "cell": 16, "idx": 0, "cols": 4},
	"arrows": {"tex": "items/item_weapons_grid01.png", "cell": 48, "idx": 10, "cols": 4},
}

var kind := "roots"
var t := 0.0
var sprite: Sprite2D


static func spawn(parent: Node, pos: Vector2, kind_name: String) -> Pickup:
	var pk := Pickup.new()
	pk.kind = kind_name
	pk.position = pos
	pk.add_to_group("pickup")
	pk.collision_layer = 1 << 5
	pk.collision_mask = 1 << 1
	var icon: Dictionary = ICONS[kind_name]
	pk.sprite = Sprite2D.new()
	pk.sprite.texture = Sheets.cell(icon.tex, icon.cell, icon.idx, icon.cols)
	pk.add_child(pk.sprite)
	var c := CollisionShape2D.new()
	var r := CircleShape2D.new()
	r.radius = 14.0
	c.shape = r
	pk.add_child(c)
	pk.body_entered.connect(pk._on_body)
	parent.add_child(pk)
	return pk


func _process(delta: float) -> void:
	t += delta
	if kind == "fish":
		sprite.position = Vector2(sin(t * 1.5) * 3.0, 0)
		sprite.rotation = sin(t * 3.0) * 0.15
	else:
		sprite.position = Vector2(0, roundf(sin(t * 3.0) * 2.0) - 4.0)


func _on_body(b: Node) -> void:
	if not b.is_in_group("hero"):
		return
	match kind:
		"roots":
			Game.add_item("roots")
			Vfx.float_text(get_parent(), global_position, "+1 roots")
		"fish":
			Game.add_item("fish")
			Vfx.play(get_parent(), "splash", global_position)
			Vfx.float_text(get_parent(), global_position, "+1 fish")
		"heart":
			Game.heal_hero(2)
			Vfx.float_text(get_parent(), global_position, "+1 heart", Color(1, 0.6, 0.6))
		"arrows":
			Game.add_arrows(3)
			Vfx.float_text(get_parent(), global_position, "+3 arrows")
	Sfx.play("pickup")
	set_deferred("monitoring", false)
	queue_free()
