class_name Hero
extends CharacterBody2D
## Temüjin. Static poses from the sheets, all motion done in code.

const SPEED := 110.0
const DODGE_SPEED := 260.0
const DODGE_TIME := 0.34
const ATTACK_TIME := 0.3
const HURT_TIME := 0.3
const COMBO_MAX := 3
const COMBO_REST := 0.5
const SWING_COST := 4.0

enum State { IDLE, MOVE, ATTACK, BOW, DODGE, HURT, DEAD }

var state := State.IDLE
var facing := "down"
var flip := false
var dir := Vector2.DOWN
var t := 0.0
var state_time := 0.0
var invuln := 0.0
var combo := 1
var ghost_timer := 0.0
var poses := {}
var dodge_tex: Texture2D
var death_tex: Array = []
var walk := {}
var shake_amt := 0.0
var cangue := false
var mounted := false
var nag := 0.0
var queued := ""
var pass_through := false
var stamina_wait := 0.0
var step_frame := -1
var combo_count := 0
var combo_rest := 0.0
var bot_dir := Vector2.ZERO
var bot_cmd := ""
var bot_hold_bow := false

@onready var body: Sprite2D = $Body
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var hitshape: CollisionShape2D = $Hitbox/Shape
@onready var reach: Area2D = $Interact
@onready var cam: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("hero")
	poses = {
		"idle": Sheets.dir3("hero/hero_temujin_idle_3dir.png", 96),
		"sword": Sheets.dir3("hero/hero_temujin_sword_3dir.png", 96),
		"bow": Sheets.dir3("hero/hero_temujin_bow_3dir.png", 96),
		"hurt": Sheets.dir3("hero/hero_temujin_hurt_3dir.png", 96),
	}
	dodge_tex = Sheets.cell("hero/hero_temujin_roll_side.png", 96, 0, 1)
	death_tex = Sheets.cells("hero/hero_temujin_death_2cells.png", 96, 96)
	cangue = Game.flags.get("cangue", false)
	set_mounted(Game.flags.get("mounted", false))
	hurtbox.area_entered.connect(_on_hurt_area)
	hitbox.set_meta("damage", 1)
	hitbox.add_to_group("hero_attack")
	_apply_pose()


## Switch between walking and riding. Riding uses the 144 px mounted sheets.
func set_mounted(on: bool) -> void:
	mounted = on and ResourceLoader.exists(Sheets.ROOT + "hero/hero_temujin_mounted_idle_3dir.png")
	walk.clear()
	var cell := 144 if mounted else 96
	if mounted:
		poses.idle = Sheets.dir3("hero/hero_temujin_mounted_idle_3dir.png", 144)
		poses.bow = Sheets.dir3("hero/hero_temujin_mounted_bow_3dir.png", 144) if ResourceLoader.exists(Sheets.ROOT + "hero/hero_temujin_mounted_bow_3dir.png") else poses.idle
		poses.sword = poses.idle
		poses.hurt = poses.idle
		for d in ["down", "up", "side"]:
			var path := "hero/hero_temujin_mounted_gallop_%s_6f.png" % d
			if ResourceLoader.exists(Sheets.ROOT + path):
				walk[d] = Sheets.cells(path, 144, 144)
	else:
		var prefix := "hero/hero_temujin_cangue" if cangue else "hero/hero_temujin"
		poses.idle = Sheets.dir3(prefix + "_idle_3dir.png", 96) if cangue and ResourceLoader.exists(Sheets.ROOT + prefix + "_idle_3dir.png") else Sheets.dir3("hero/hero_temujin_idle_3dir.png", 96)
		poses.bow = Sheets.dir3("hero/hero_temujin_bow_3dir.png", 96)
		poses.sword = Sheets.dir3("hero/hero_temujin_sword_3dir.png", 96)
		poses.hurt = Sheets.dir3("hero/hero_temujin_hurt_3dir.png", 96)
		for d in ["down", "up", "side"]:
			var path := "%s_walk_%s_6f.png" % [prefix, d]
			if not ResourceLoader.exists(Sheets.ROOT + path):
				path = "hero/hero_temujin_walk_%s_6f.png" % d
			if ResourceLoader.exists(Sheets.ROOT + path):
				walk[d] = Sheets.cells(path, 96, 96)
	body.offset = Vector2(0, -cell / 2.0)
	var hs := Vector2(40, 88) if mounted else Vector2(26, 52)
	($Hurtbox/Shape.shape as RectangleShape2D).size = hs
	$Hurtbox/Shape.position = Vector2(0, -hs.y / 2.0)
	($Shape.shape as RectangleShape2D).size = Vector2(28, 14) if mounted else Vector2(18, 10)
	Game.flags["mounted"] = mounted
	_apply_pose()


func set_camera_limits(r: Rect2) -> void:
	cam.limit_left = int(r.position.x)
	cam.limit_top = int(r.position.y)
	cam.limit_right = int(r.end.x)
	cam.limit_bottom = int(r.end.y)
	cam.reset_smoothing()


func _process(delta: float) -> void:
	if shake_amt > 0.0:
		cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_amt
		shake_amt = move_toward(shake_amt, 0.0, delta * 14.0)
	else:
		cam.offset = Vector2.ZERO


func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)


func _physics_process(delta: float) -> void:
	t += delta
	state_time += delta
	invuln = maxf(0.0, invuln - delta)
	if stamina_wait > 0.0:
		stamina_wait -= delta
	else:
		Game.stamina = minf(Game.STAMINA_MAX, Game.stamina + 26.0 * delta)
	combo_rest = maxf(0.0, combo_rest - delta)
	match state:
		State.IDLE, State.MOVE:
			_free_state()
		State.ATTACK:
			_attack_state(delta)
		State.BOW:
			_bow_state()
		State.DODGE:
			_dodge_state(delta)
		State.HURT:
			_hurt_state(delta)
		State.DEAD:
			velocity = Vector2.ZERO
	move_and_slide()
	if pass_through and state != State.DODGE and state != State.HURT and not _touching_enemy():
		pass_through = false
		collision_mask = 5
	_apply_pose()
	_motion()


## While rolling or knocked back the hero slips through enemy bodies, and stays able to until clear of them.
func _ghost_through() -> void:
	pass_through = true
	collision_mask = 1


func _touching_enemy() -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = $Shape.shape
	q.transform = $Shape.global_transform
	q.collision_mask = 4
	q.collide_with_areas = false
	q.collide_with_bodies = true
	return not get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


func _set_state(s: State) -> void:
	state = s
	state_time = 0.0


func _input_vector() -> Vector2:
	if Game.ui_busy:
		return Vector2.ZERO
	if Game.bot:
		return bot_dir
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## A press of an action this frame: from the keyboard or pad, or from the automated player.
func _pressed(action: String) -> bool:
	if Game.bot:
		if bot_cmd == action:
			bot_cmd = ""
			return true
		return false
	return Input.is_action_just_pressed(action)


func _held(action: String) -> bool:
	if Game.bot:
		return bot_hold_bow if action == "bow" else false
	return Input.is_action_pressed(action)


func _face(v: Vector2) -> void:
	if v == Vector2.ZERO:
		return
	dir = v.normalized()
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


# ---------------------------------------------------------------- states

func _free_state() -> void:
	var v := _input_vector()
	_face(v)
	velocity = v * SPEED * (0.95 if cangue else (1.7 if mounted else 1.0))
	var moving := v != Vector2.ZERO
	if moving and state != State.MOVE:
		_set_state(State.MOVE)
	elif not moving and state != State.IDLE:
		_set_state(State.IDLE)
	if Game.ui_busy:
		return
	nag -= get_physics_process_delta_time()
	if state_time > 0.4:
		combo_count = 0
	if cangue and (_pressed("attack") or _pressed("bow")):
		if nag <= 0.0:
			nag = 1.2
			Vfx.float_text(get_parent(), global_position, "The cangue binds your arms", Color(1, 0.8, 0.6))
		return
	if mounted and _pressed("attack"):
		if nag <= 0.0:
			nag = 1.2
			Vfx.float_text(get_parent(), global_position, "Not from the saddle. Use the bow.", Color(1, 0.8, 0.6))
		return
	if _pressed("attack"):
		if combo_rest <= 0.0:
			_start_attack()
	elif _pressed("bow"):
		if Game.arrows > 0:
			_set_state(State.BOW)
		else:
			Vfx.float_text(get_parent(), global_position, "No arrows", Color(1, 0.8, 0.6))
	elif _pressed("roll"):
		_try_dodge(v)
	elif _pressed("interact"):
		_try_interact()
	elif _pressed("ability"):
		Game.use_ability(self)


func _start_attack() -> void:
	_set_state(State.ATTACK)
	combo = -combo
	combo_count += 1
	# Every swing costs a little breath, so a sword wall leaves nothing for the roll.
	Game.stamina = maxf(0.0, Game.stamina - SWING_COST)
	stamina_wait = maxf(stamina_wait, 0.15)
	var fwd := _facing_vector()
	var last := combo_count >= COMBO_MAX
	velocity = fwd * (120.0 if last else 55.0)
	hitbox.position = fwd * (30.0 if last else 26.0) + Vector2(0, -24)
	hitshape.disabled = false
	# The arc sweeps across the front of the hero; alternate the sweep so two hits read as a combo.
	SlashArc.spawn(get_parent(), global_position + fwd * 10.0 + Vector2(0, -26), fwd.angle(), combo, 38.0 if last else 32.0)
	Sfx.play("swoosh", 2.0 if last else 0.0)


func _attack_state(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	if state_time > 0.16:
		hitshape.disabled = true
	_buffer_input()
	# A press during the swing is kept, so mashing chains up to three swings; after the third the
	# sword needs a moment before it can start again. A roll can cut the recovery short.
	if state_time > 0.18 and queued == "attack" and combo_count < COMBO_MAX:
		queued = ""
		_start_attack()
	elif state_time > 0.16 and queued == "roll":
		queued = ""
		_try_dodge(_input_vector())
	elif state_time >= ATTACK_TIME:
		queued = ""
		if combo_count >= COMBO_MAX:
			combo_rest = COMBO_REST
			combo_count = 0
		_set_state(State.IDLE)


func _buffer_input() -> void:
	if Game.ui_busy:
		return
	if _pressed("attack"):
		queued = "attack"
	elif _pressed("roll"):
		queued = "roll"


func _bow_state() -> void:
	velocity = Vector2.ZERO
	_face(_input_vector())
	if Game.ui_busy or not _held("bow"):
		if state_time > 0.1 and Game.use_arrow():
			var fwd := _facing_vector()
			Arrow.spawn(get_parent(), global_position + fwd * 14.0 + Vector2(0, -30), fwd, true)
			Sfx.play("arrow")
		_set_state(State.IDLE)


## Rolling costs stamina, so it is an escape, not a way of life.
func _try_dodge(v: Vector2) -> void:
	if Game.stamina < Game.ROLL_COST:
		if nag <= 0.0:
			nag = 0.8
			Vfx.float_text(get_parent(), global_position, "Winded", Color(1, 0.8, 0.6))
		return
	Game.stamina -= Game.ROLL_COST
	stamina_wait = 0.5
	Game.debug("f%d roll %s stamina %.0f" % [Engine.get_physics_frames(), v.round(), Game.stamina])
	_start_dodge(v)


## A push without damage, used when a way is closed.
func shove(dir: Vector2) -> void:
	if state == State.DEAD:
		return
	_set_state(State.HURT)
	velocity = dir * 200.0


func _start_dodge(v: Vector2) -> void:
	_set_state(State.DODGE)
	dir = v.normalized() if v != Vector2.ZERO else _facing_vector()
	velocity = dir * (DODGE_SPEED * 1.5 if mounted else DODGE_SPEED)
	if mounted:
		Vfx.play(get_parent(), "hoof", global_position + Vector2(0, -4), 0.0, dir.x < 0.0)
	invuln = DODGE_TIME + 0.05
	ghost_timer = 0.0
	hitshape.disabled = true
	queued = ""
	_ghost_through()
	Vfx.play(get_parent(), "dust", global_position + Vector2(0, -6))
	Sfx.play("dodge")


func _dodge_state(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	ghost_timer -= delta
	if ghost_timer <= 0.0 and state_time < DODGE_TIME * 0.8 and not mounted:
		ghost_timer = 0.08
		_spawn_ghost()
	if state_time > DODGE_TIME * 0.5:
		_buffer_input()
	if state_time >= DODGE_TIME:
		Vfx.play(get_parent(), "dust", global_position + Vector2(0, -6))
		_set_state(State.IDLE)
		if queued == "attack" and not cangue and not mounted:
			queued = ""
			_start_attack()
		queued = ""


func _spawn_ghost() -> void:
	var g := Sprite2D.new()
	g.texture = body.texture
	g.flip_h = body.flip_h
	g.offset = body.offset
	g.rotation = body.rotation
	g.scale = body.scale
	g.global_position = body.global_position
	g.modulate = Color(0.55, 0.75, 1.0, 0.3)
	var layer: Node = get_tree().get_first_node_in_group("ghost_layer")
	(layer if layer != null else get_parent()).add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.22)
	tw.tween_callback(g.queue_free)


func _on_hurt_area(a: Area2D) -> void:
	if a.is_in_group("enemy_attack"):
		take_hit(int(a.get_meta("damage", 1)), a.global_position)


func take_hit(dmg: int, from: Vector2) -> void:
	if invuln > 0.0 or state == State.DEAD or state == State.DODGE:
		return
	Game.debug("f%d hero takes %d, hp %d (state %d)" % [Engine.get_physics_frames(), dmg, Game.hp - dmg, state])
	Game.damage_hero(dmg)
	Vfx.play(get_parent(), "burst", global_position + Vector2(0, -30))
	Sfx.play("hurt")
	shake(4.0)
	var away := global_position - from
	var knock := (away.normalized() if away.length() > 1.0 else -_facing_vector()) * 240.0
	invuln = 1.1
	queued = ""
	hitshape.set_deferred("disabled", true)
	if Game.hp <= 0:
		_die()
		return
	_set_state(State.HURT)
	_ghost_through()
	velocity = knock


func _hurt_state(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	if state_time >= HURT_TIME:
		_set_state(State.IDLE)


func _die() -> void:
	_set_state(State.DEAD)
	velocity = Vector2.ZERO
	await get_tree().create_timer(1.6).timeout
	Game.respawn()


func _try_interact() -> void:
	var best: Node = null
	var best_d := INF
	for a in reach.get_overlapping_areas():
		var n := a.get_parent()
		if n != null and n.has_method("interact"):
			var d := global_position.distance_to(n.global_position)
			if d < best_d:
				best_d = d
				best = n
	if best != null:
		best.interact(self)


# ---------------------------------------------------------------- visuals

func _apply_pose() -> void:
	var tex: Texture2D
	match state:
		State.ATTACK:
			tex = poses.sword[facing]
		State.BOW:
			tex = poses.bow[facing]
		State.HURT:
			tex = poses.hurt[facing]
		State.DODGE:
			tex = (walk[facing][int(state_time * 16.0) % 6] if walk.has(facing) else poses.idle[facing]) if mounted else dodge_tex
		State.DEAD:
			tex = death_tex[0] if state_time < 0.5 else death_tex[1]
		State.MOVE:
			if walk.has(facing):
				var frames: Array = walk[facing]
				var fi := int(state_time * (13.0 if mounted else 11.0)) % frames.size()
				tex = frames[fi]
				# A footfall as each foot comes down, twice per cycle.
				if fi != step_frame:
					step_frame = fi
					if not mounted and (fi == 0 or fi == 3):
						Sfx.play("step", -14.0, 0.15)
			else:
				tex = poses.idle[facing]
		_:
			tex = poses.idle[facing]
	body.texture = tex
	# The roll frame is a tucked ball low in its cell; pivot on the ball so the turn stays on the ground.
	var rolling := state == State.DODGE and not mounted
	body.offset = Vector2(0, -24) if rolling else Vector2(0, -(144 if mounted else 96) / 2.0)
	match state:
		State.DODGE:
			body.flip_h = dir.x < 0.0 if absf(dir.x) > 0.01 else flip
		State.DEAD:
			body.flip_h = false
		State.ATTACK:
			# Side attacks follow the facing; front and back attacks mirror on alternate swings.
			body.flip_h = flip if facing == "side" else combo < 0
		_:
			body.flip_h = flip and facing == "side"


func _motion() -> void:
	var bob := 0.0
	var tilt := 0.0
	var sc := Vector2.ONE
	match state:
		State.MOVE:
			if walk.has(facing):
				bob = -absf(sin(state_time * 11.0 * PI / 3.0)) * 1.0
			else:
				bob = -absf(sin(t * 12.0)) * 3.0
				tilt = sin(t * 12.0) * 0.05
				sc = Vector2(1.0 + 0.03 * sin(t * 24.0), 1.0 - 0.03 * sin(t * 24.0))
		State.IDLE:
			sc = Vector2(1.0 + 0.01 * sin(t * 2.5), 1.0 - 0.01 * sin(t * 2.5))
		State.DODGE:
			var k := clampf(state_time / DODGE_TIME, 0.0, 1.0)
			if mounted:
				var hop := sin(k * PI)
				bob = -hop * 4.0
				sc = Vector2(1.0 + 0.04 * hop, 1.0 - 0.04 * hop)
			else:
				# A tucked roll: one full turn in four clean quarter steps, forward in the travel direction.
				var sgn := 1.0 if (dir.x > 0.01 or (absf(dir.x) <= 0.01 and dir.y > 0.0)) else -1.0
				tilt = float(mini(int(k * 4.0), 3)) * (PI / 2.0) * sgn
				bob = -24.0
		State.ATTACK:
			var k := state_time / ATTACK_TIME
			bob = -2.0 if k < 0.4 else 0.0
			tilt = 0.06 * (1.0 - k) * float(-combo) * (-1.0 if body.flip_h else 1.0)
	body.position = Vector2(0, roundf(bob))
	body.rotation = tilt
	body.scale = sc
	if invuln > 0.0 and state != State.DODGE and state != State.DEAD:
		body.modulate = Color(1, 1, 1, 0.45 if fmod(t, 0.16) < 0.08 else 1.0)
	else:
		body.modulate = Color.WHITE
