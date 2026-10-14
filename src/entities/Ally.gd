class_name Ally
extends CharacterBody2D
## A companion who follows the hero through a dungeon and fights nearby enemies.
## Allies cannot be hurt; they exist to make the raid feel shared, not to tank.

const SHEETS := {
	"jamukha": {"idle": "companions/comp_jamukha_idle_3dir.png", "attack": "companions/comp_jamukha_attack_3dir.png", "walk": "companions/comp_jamukha_walk_%s_6f.png", "name": "Jamukha"},
	"qasar": {"idle": "companions/comp_qasar_idle_3dir.png", "attack": "companions/comp_qasar_bow_3dir.png", "walk": "", "name": "Qasar", "ranged": true},
	"jelme": {"idle": "companions/comp_jelme_idle_3dir.png", "attack": "companions/comp_jelme_idle_3dir.png", "walk": "", "name": "Jelme"},
	"jebe": {"idle": "companions/comp_jebe_idle_3dir.png", "attack": "companions/comp_jebe_idle_3dir.png", "walk": "", "name": "Jebe", "ranged": true},
	"subutai": {"idle": "companions/comp_subutai_idle_3dir.png", "attack": "companions/comp_subutai_idle_3dir.png", "walk": "", "name": "Subutai"},
	"boorchu": {"idle": "companions/comp_boorchu_idle_3dir.png", "attack": "companions/comp_boorchu_idle_3dir.png", "walk": "", "name": "Bo'orchu"},
}
enum State { FOLLOW, APPROACH, WINDUP, STRIKE, RECOVER }

var who := "jamukha"
var cfg := {}
var state := State.FOLLOW
var state_time := 0.0
var t := 0.0
var facing := "down"
var flip := false
var hero: Node2D
var target: Node2D
var idle_poses := {}
var attack_poses := {}
var walk := {}
var body: Sprite2D
var hitbox: Area2D
var hitshape: CollisionShape2D
var shot_cooldown := 0.0


static func spawn(parent: Node, pos: Vector2, who_name: String) -> Ally:
	var a := Ally.new()
	a.who = who_name
	a.position = pos
	parent.add_child(a)
	return a


func _ready() -> void:
	add_to_group("ally")
	cfg = SHEETS[who]
	collision_layer = 0
	collision_mask = 1
	var idle: String = cfg.idle
	if not ResourceLoader.exists(Sheets.ROOT + idle):
		idle = "companions/comp_boorchu_idle_3dir.png"
	idle_poses = Sheets.dir3(idle, 96)
	var atk: String = cfg.attack
	attack_poses = Sheets.dir3(atk, 96) if ResourceLoader.exists(Sheets.ROOT + atk) else idle_poses
	if cfg.walk != "":
		for d in ["down", "up", "side"]:
			var path: String = cfg.walk % d
			if ResourceLoader.exists(Sheets.ROOT + path):
				walk[d] = Sheets.cells(path, 96, 96)
	body = Sprite2D.new()
	body.offset = Vector2(0, -48)
	add_child(body)
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 10)
	shape.shape = r
	shape.position = Vector2(0, -5)
	add_child(shape)
	hitbox = Area2D.new()
	hitbox.collision_layer = 1 << 6
	hitbox.collision_mask = 0
	hitbox.add_to_group("hero_attack")
	hitbox.set_meta("damage", 1)
	hitshape = CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(40, 36)
	hitshape.shape = hr
	hitshape.disabled = true
	hitbox.add_child(hitshape)
	add_child(hitbox)
	t = randf() * 10.0


func _physics_process(delta: float) -> void:
	t += delta
	state_time += delta
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	if hero == null or not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero")
		if hero == null:
			return
	if target != null and not is_instance_valid(target):
		target = null
	match state:
		State.FOLLOW:
			_pick_target()
			var to_hero := hero.global_position - global_position
			if to_hero.length() > 56.0:
				velocity = to_hero.normalized() * 118.0
				_face(to_hero)
			else:
				velocity = Vector2.ZERO
			if target != null:
				state = State.APPROACH
				state_time = 0.0
		State.APPROACH:
			if target == null or target.global_position.distance_to(hero.global_position) > 260.0:
				target = null
				_go(State.FOLLOW)
			else:
				var to_t := target.global_position - global_position
				_face(to_t)
				var reach := 150.0 if cfg.get("ranged", false) else 34.0
				if to_t.length() > reach:
					velocity = to_t.normalized() * 110.0
				else:
					velocity = Vector2.ZERO
					if shot_cooldown <= 0.0:
						_go(State.WINDUP)
		State.WINDUP:
			velocity = Vector2.ZERO
			if state_time >= 0.3:
				_strike()
		State.STRIKE:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			if state_time >= 0.15:
				hitshape.disabled = true
				_go(State.RECOVER)
		State.RECOVER:
			velocity = Vector2.ZERO
			if state_time >= 0.6:
				_go(State.FOLLOW)
	move_and_slide()
	_apply_pose()


func _go(s: State) -> void:
	state = s
	state_time = 0.0


func _pick_target() -> void:
	var best: Node2D = null
	var best_d := 150.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		var d: float = e.global_position.distance_to(hero.global_position)
		if d < best_d and e.get("state") != 0:  # not dormant
			best_d = d
			best = e
	target = best


func _face(v: Vector2) -> void:
	if v == Vector2.ZERO:
		return
	if absf(v.x) > absf(v.y):
		facing = "side"
		flip = v.x < 0.0
	else:
		facing = "down" if v.y > 0.0 else "up"


func _facing_vector() -> Vector2:
	match facing:
		"up":
			return Vector2.UP
		"side":
			return Vector2.LEFT if flip else Vector2.RIGHT
		_:
			return Vector2.DOWN


func _strike() -> void:
	_go(State.STRIKE)
	var fwd := (target.global_position - global_position).normalized() if target != null else _facing_vector()
	if cfg.get("ranged", false):
		Arrow.spawn(get_parent(), global_position + fwd * 14.0 + Vector2(0, -30), fwd, true)
		Sfx.play("arrow", -6.0)
		shot_cooldown = 1.4
		return
	velocity = fwd * 60.0
	hitbox.position = fwd * 24.0 + Vector2(0, -24)
	hitshape.disabled = false
	SlashArc.spawn(get_parent(), global_position + fwd * 10.0 + Vector2(0, -26), fwd.angle(), 1 if flip else -1, 30.0, Color(0.8, 0.9, 1.0))
	Sfx.play("swoosh", -6.0)
	shot_cooldown = 0.5


func _apply_pose() -> void:
	var attacking := state == State.WINDUP or state == State.STRIKE
	if attacking:
		body.texture = attack_poses[facing]
	elif velocity.length() > 5.0 and walk.has(facing):
		body.texture = walk[facing][int(t * 11.0) % 6]
	else:
		body.texture = idle_poses[facing]
	body.flip_h = flip and facing == "side"
	if velocity.length() > 5.0 and not walk.has(facing):
		body.position = Vector2(0, -absf(sin(t * 11.0)) * 3.0)
	else:
		body.position = Vector2.ZERO
