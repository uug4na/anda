class_name Arrow
extends Area2D
## A flying arrow from the hero or an archer.

var dir := Vector2.RIGHT
var speed := 320.0
var from_hero := true
var life := 1.2
var pierce := false


static func spawn(parent: Node, pos: Vector2, direction: Vector2, hero_owned: bool) -> Arrow:
	var a := Arrow.new()
	a.dir = direction.normalized()
	a.from_hero = hero_owned
	a.position = pos
	a.rotation = a.dir.angle()
	a.z_index = 3
	a.add_to_group("hero_attack" if hero_owned else "enemy_attack")
	a.set_meta("damage", 1)
	a.collision_layer = (1 << 6) if hero_owned else (1 << 7)
	a.collision_mask = (1 << 4) if hero_owned else (1 << 3)
	var s := Sprite2D.new()
	s.texture = Sheets.cell("items/item_weapons_grid01.png", 48, 8, 4)
	s.rotation = PI / 4.0
	a.add_child(s)
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(22, 6)
	c.shape = r
	a.add_child(c)
	a.area_entered.connect(a._on_area)
	parent.add_child(a)
	return a


func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var q := PhysicsPointQueryParameters2D.new()
	q.position = global_position + dir * 10.0
	q.collision_mask = 1
	q.collide_with_areas = false
	q.collide_with_bodies = true
	if not get_world_2d().direct_space_state.intersect_point(q, 1).is_empty():
		Vfx.play(get_parent(), "spark", global_position)
		queue_free()


func _on_area(_a: Area2D) -> void:
	# The hurtbox on the other side applies the damage; the arrow just disappears, unless it pierces.
	Vfx.play(get_parent(), "spark", global_position)
	if pierce:
		return
	set_deferred("monitoring", false)
	queue_free()
