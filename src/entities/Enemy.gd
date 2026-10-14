class_name Enemy
extends CharacterBody2D
## Every enemy and boss shares one state machine; the numbers and attack type differ per kind.

enum Kind { SWORD, ARCHER, HUNTER, DOG, BEGTER, TARGHUTAI, CAPTAIN, THIEF, THIEFLEADER, MERKIT, CHILGER, TATAR, TATARCHIEF, KEREYIT, SENGGUM, NAIMAN, TAYANG, JAMUKHA }
enum State { DORMANT, IDLE, CHASE, WINDUP, STRIKE, RECOVER, HURT, DEAD }

const PARAMS := {
	Kind.SWORD: {"hp": 3, "speed": 62.0, "aggro": 180.0, "range": 34.0, "windup": 0.4, "strike": 0.16, "recover": 0.7, "lunge": 170.0,
		"idle": "enemies/enemy_tayichiud_sword_idle_3dir.png", "attack": "enemies/enemy_tayichiud_sword_attack_3dir.png",
		"type": "lunge", "name": "Tayichiud", "slash": true, "walk": "enemies/enemy_tayichiud_sword_walk_%s_6f.png"},
	Kind.ARCHER: {"hp": 2, "speed": 55.0, "aggro": 230.0, "range": 200.0, "windup": 0.55, "strike": 0.1, "recover": 1.4, "lunge": 0.0,
		"idle": "enemies/enemy_tayichiud_archer_idle_3dir.png", "attack": "enemies/enemy_tayichiud_archer_attack_3dir.png",
		"type": "arrow", "name": "Tayichiud archer", "walk": "enemies/enemy_tayichiud_archer_walk_%s_6f.png"},
	Kind.HUNTER: {"hp": 3, "speed": 70.0, "aggro": 210.0, "range": 48.0, "windup": 0.5, "strike": 0.18, "recover": 0.8, "lunge": 150.0,
		"idle": "enemies/enemy_hunter_idle_3dir.png", "attack": "enemies/enemy_hunter_idle_3dir.png",
		"type": "lunge", "name": "Tayichiud hunter", "drop": "arrows", "walk": "enemies/enemy_hunter_walk_%s_6f.png"},
	Kind.DOG: {"hp": 2, "speed": 125.0, "aggro": 250.0, "range": 28.0, "windup": 0.36, "strike": 0.14, "recover": 0.55, "lunge": 230.0,
		"sheet": "animals/animal_small_grid01.png", "cell": 48, "idle_idx": [0, 1, 2], "attack_idx": [3, 3, 3],
		"type": "lunge", "name": "Hunting dog", "hurt_size": Vector2(26, 24), "body_size": Vector2(14, 8), "walk": "animals/animal_dog_run_%s_4f.png"},
	Kind.BEGTER: {"hp": 12, "speed": 58.0, "aggro": 110.0, "range": 100.0, "windup": 0.6, "strike": 0.3, "recover": 1.0, "lunge": 280.0,
		"idle": "bosses/boss_begter_idle_3dir.png", "attack": "bosses/boss_begter_attack_down.png",
		"type": "lunge", "name": "Begter", "boss": true, "flag": "begter", "walk": "bosses/boss_begter_walk_%s_6f.png"},
	Kind.TARGHUTAI: {"hp": 18, "speed": 46.0, "aggro": 230.0, "range": 96.0, "windup": 0.6, "strike": 0.25, "recover": 1.0, "lunge": 0.0,
		"idle": "bosses/boss_targhutai_idle_3dir.png", "attack": "bosses/boss_targhutai_whip_down.png", "horn": "bosses/boss_targhutai_horn_down.png",
		"cell": 192, "type": "whip", "name": "Targhutai Kiriltugh", "boss": true, "flag": "targhutai",
		"hurt_size": Vector2(64, 110), "body_size": Vector2(44, 16), "hit_size": Vector2(100, 44), "walk": "bosses/boss_targhutai_walk_%s_6f.png"},
	Kind.CAPTAIN: {"hp": 16, "speed": 64.0, "aggro": 260.0, "range": 70.0, "windup": 0.55, "strike": 0.22, "recover": 0.8, "lunge": 260.0,
		"idle": "bosses/boss_captain_idle_3dir.png", "attack": "bosses/boss_captain_attack_down.png",
		"cell": 192, "type": "lunge", "name": "Guard captain", "boss": true, "flag": "captain", "taunt": "Captain: Back in the cangue, pup.",
		"hurt_size": Vector2(60, 110), "body_size": Vector2(40, 16), "hit_size": Vector2(80, 50), "walk": "bosses/boss_captain_walk_%s_6f.png",
		"fallback": {"idle": "bosses/boss_targhutai_idle_3dir.png", "attack": "bosses/boss_targhutai_whip_down.png"}},
	Kind.THIEF: {"hp": 2, "speed": 150.0, "aggro": 400.0, "range": 300.0, "windup": 0.5, "strike": 0.1, "recover": 3.0, "lunge": 0.0,
		"idle": "enemies/enemy_thief_mounted_idle_3dir.png", "attack": "enemies/enemy_thief_mounted_idle_3dir.png",
		"cell": 144, "type": "flee_shoot", "name": "Horse thief", "hurt_size": Vector2(40, 88), "body_size": Vector2(28, 14),
		"walk": "enemies/enemy_thief_mounted_gallop_%s_6f.png",
		"fallback": {"idle": "animals/animal_horse_bay_idle_3dir.png", "attack": "animals/animal_horse_bay_idle_3dir.png"}},
	Kind.THIEFLEADER: {"hp": 14, "speed": 160.0, "aggro": 300.0, "range": 260.0, "windup": 0.5, "strike": 0.45, "recover": 1.2, "lunge": 330.0,
		"idle": "bosses/boss_thiefleader_mounted_idle_3dir.png", "attack": "bosses/boss_thiefleader_mounted_bow_3dir.png",
		"cell": 144, "type": "charge_shoot", "name": "Thief leader", "boss": true, "flag": "thieves", "taunt": "Thief leader: Eight horses, and now a boy to sell.",
		"hurt_size": Vector2(44, 90), "body_size": Vector2(30, 14), "hit_size": Vector2(60, 50),
		"walk": "bosses/boss_thiefleader_mounted_gallop_%s_6f.png",
		"fallback": {"idle": "hero/hero_temujin_mounted_idle_3dir.png", "attack": "hero/hero_temujin_mounted_idle_3dir.png"}},
	Kind.MERKIT: {"hp": 3, "speed": 68.0, "aggro": 200.0, "range": 36.0, "windup": 0.38, "strike": 0.16, "recover": 0.7, "lunge": 180.0,
		"idle": "enemies/enemy_merkit_idle_3dir.png", "attack": "enemies/enemy_merkit_attack_3dir.png",
		"type": "lunge", "name": "Merkit raider", "slash": true, "walk": "enemies/enemy_merkit_walk_%s_6f.png",
		"fallback": {"idle": "enemies/enemy_tayichiud_sword_idle_3dir.png", "attack": "enemies/enemy_tayichiud_sword_attack_3dir.png"}},
	Kind.CHILGER: {"hp": 24, "speed": 60.0, "aggro": 240.0, "range": 80.0, "windup": 0.5, "strike": 0.3, "recover": 0.9, "lunge": 300.0,
		"idle": "bosses/boss_chilger_idle_3dir.png", "attack": "bosses/boss_chilger_attack_down.png", "horn": "bosses/boss_chilger_slam_down.png",
		"cell": 192, "type": "slam", "name": "Chilger Bökh", "boss": true, "flag": "chilger", "taunt": "Chilger: She is mine now, little bridegroom.",
		"hurt_size": Vector2(70, 110), "body_size": Vector2(44, 16), "hit_size": Vector2(80, 50), "walk": "bosses/boss_chilger_walk_%s_6f.png",
		"fallback": {"idle": "bosses/boss_targhutai_idle_3dir.png", "attack": "bosses/boss_targhutai_whip_down.png", "horn": "bosses/boss_targhutai_horn_down.png"}},
	Kind.TATAR: {"hp": 4, "speed": 64.0, "aggro": 200.0, "range": 44.0, "windup": 0.4, "strike": 0.18, "recover": 0.75, "lunge": 190.0,
		"idle": "enemies/enemy_tatar_idle_3dir.png", "attack": "enemies/enemy_tatar_attack_3dir.png",
		"type": "lunge", "name": "Tatar warrior", "walk": "enemies/enemy_tatar_walk_%s_6f.png", "drop": "arrows",
		"fallback": {"idle": "enemies/enemy_tayichiud_sword_idle_3dir.png", "attack": "enemies/enemy_tayichiud_sword_attack_3dir.png"}},
	Kind.TATARCHIEF: {"hp": 22, "speed": 70.0, "aggro": 240.0, "range": 84.0, "windup": 0.45, "strike": 0.28, "recover": 0.8, "lunge": 320.0,
		"idle": "bosses/boss_tatarchief_idle_3dir.png", "attack": "bosses/boss_tatarchief_attack_down.png", "horn": "bosses/boss_tatarchief_spin_down.png",
		"cell": 192, "type": "slam", "name": "The Tatar chief", "boss": true, "flag": "tatarchief", "taunt": "The chief: Yesügei's whelp. We poisoned the father; the son we will cut.",
		"hurt_size": Vector2(64, 110), "body_size": Vector2(44, 16), "hit_size": Vector2(90, 50), "walk": "bosses/boss_tatarchief_walk_%s_6f.png", "slash": true,
		"fallback": {"idle": "bosses/boss_targhutai_idle_3dir.png", "attack": "bosses/boss_targhutai_whip_down.png", "horn": "bosses/boss_targhutai_horn_down.png"}},
	Kind.KEREYIT: {"hp": 5, "speed": 56.0, "aggro": 200.0, "range": 40.0, "windup": 0.5, "strike": 0.2, "recover": 0.9, "lunge": 160.0,
		"idle": "enemies/enemy_kereyit_idle_3dir.png", "attack": "enemies/enemy_kereyit_attack_3dir.png",
		"type": "lunge", "name": "Kereyit heavy", "walk": "enemies/enemy_kereyit_walk_%s_6f.png", "hurt_size": Vector2(30, 56),
		"fallback": {"idle": "enemies/enemy_tayichiud_sword_idle_3dir.png", "attack": "enemies/enemy_tayichiud_sword_attack_3dir.png"}},
	Kind.SENGGUM: {"hp": 28, "speed": 66.0, "aggro": 240.0, "range": 90.0, "windup": 0.5, "strike": 0.3, "recover": 0.9, "lunge": 340.0,
		"idle": "bosses/boss_senggum_idle_3dir.png", "attack": "bosses/boss_senggum_attack_down.png", "horn": "bosses/boss_senggum_charge_down.png",
		"cell": 192, "type": "slam", "name": "Senggum", "boss": true, "flag": "senggum", "taunt": "Senggum: My father's dog has learned to bite. Heel.",
		"hurt_size": Vector2(64, 110), "body_size": Vector2(44, 16), "hit_size": Vector2(90, 50), "walk": "bosses/boss_senggum_walk_%s_6f.png",
		"fallback": {"idle": "bosses/boss_targhutai_idle_3dir.png", "attack": "bosses/boss_targhutai_whip_down.png", "horn": "bosses/boss_targhutai_horn_down.png"}},
	Kind.NAIMAN: {"hp": 4, "speed": 150.0, "aggro": 360.0, "range": 150.0, "windup": 0.45, "strike": 0.4, "recover": 1.4, "lunge": 330.0,
		"idle": "enemies/enemy_naiman_mounted_idle_3dir.png", "attack": "enemies/enemy_naiman_mounted_idle_3dir.png",
		"cell": 144, "type": "charge", "name": "Naiman lancer", "hurt_size": Vector2(40, 88), "body_size": Vector2(28, 14), "hit_size": Vector2(60, 46),
		"walk": "enemies/enemy_naiman_mounted_gallop_%s_6f.png",
		"fallback": {"idle": "enemies/enemy_thief_mounted_idle_3dir.png", "attack": "enemies/enemy_thief_mounted_idle_3dir.png"}},
	Kind.TAYANG: {"hp": 28, "dmg": 2, "speed": 50.0, "aggro": 240.0, "range": 92.0, "windup": 0.6, "strike": 0.3, "recover": 1.0, "lunge": 0.0,
		"idle": "bosses/boss_tayang_idle_3dir.png", "attack": "bosses/boss_tayang_attack_down.png", "horn": "bosses/boss_tayang_command_down.png",
		"cell": 192, "type": "whip", "name": "Tayang Khan", "boss": true, "flag": "tayang", "taunt": "Tayang Khan: Naiman! Ride the Mongols into the stones.",
		"hurt_size": Vector2(64, 110), "body_size": Vector2(44, 16), "hit_size": Vector2(100, 44), "walk": "bosses/boss_tayang_walk_%s_6f.png",
		"summon": ["naiman", "naiman"],
		"fallback": {"idle": "bosses/boss_targhutai_idle_3dir.png", "attack": "bosses/boss_targhutai_whip_down.png", "horn": "bosses/boss_targhutai_horn_down.png"}},
	Kind.JAMUKHA: {"hp": 24, "dmg": 2, "speed": 80.0, "aggro": 260.0, "range": 40.0, "windup": 0.32, "strike": 0.16, "recover": 0.55, "lunge": 220.0,
		"idle": "companions/comp_jamukha_idle_3dir.png", "attack": "companions/comp_jamukha_attack_3dir.png",
		"type": "lunge", "name": "Jamukha, anda", "boss": true, "flag": "jamukha", "slash": true, "tint": Color(0.75, 0.7, 0.8),
		"taunt": "Jamukha: Anda. One of us was always going to end like this.", "walk": "companions/comp_jamukha_walk_%s_6f.png",
		"fallback": {"idle": "enemies/enemy_tayichiud_sword_idle_3dir.png", "attack": "enemies/enemy_tayichiud_sword_attack_3dir.png"}},
}

const KIND_NAMES := {"sword": Kind.SWORD, "archer": Kind.ARCHER, "hunter": Kind.HUNTER, "dog": Kind.DOG, "begter": Kind.BEGTER,
	"targhutai": Kind.TARGHUTAI, "captain": Kind.CAPTAIN, "thief": Kind.THIEF, "thiefleader": Kind.THIEFLEADER,
	"merkit": Kind.MERKIT, "chilger": Kind.CHILGER, "tatar": Kind.TATAR, "tatarchief": Kind.TATARCHIEF, "kereyit": Kind.KEREYIT,
	"senggum": Kind.SENGGUM, "naiman": Kind.NAIMAN, "tayang": Kind.TAYANG, "jamukha": Kind.JAMUKHA}


static func kind_named(n: String) -> int:
	return KIND_NAMES.get(n, Kind.SWORD)

@export var kind: Kind = Kind.SWORD

var p := {}
var hp := 1
var max_hp := 1
var state := State.IDLE
var facing := "down"
var flip := false
var t := 0.0
var state_time := 0.0
var flash := 0.0
var hero: Node2D
var home := Vector2.ZERO
var wander_target := Vector2.ZERO
var wander_wait := 0.0
var shot_cooldown := 0.0
var attacks_done := 0
var horn_attack := false
var cell := 96
var idle_poses := {}
var attack_poses := {}
var horn_poses := {}
var walk := {}
var is_boss := false
var enraged := false
var recent_hits: Array = []
var aim := Vector2.DOWN

@onready var body: Sprite2D = $Body
@onready var body_shape: CollisionShape2D = $Shape
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurt_shape: CollisionShape2D = $Hurtbox/Shape
@onready var hitbox: Area2D = $Hitbox
@onready var hitshape: CollisionShape2D = $Hitbox/Shape


func _ready() -> void:
	p = PARAMS[kind].duplicate()
	# Art that has not been generated yet falls back to a stand-in sheet so the level still runs.
	if p.has("fallback"):
		for key in p.fallback:
			if not ResourceLoader.exists(Sheets.ROOT + p[key]):
				p[key] = p.fallback[key]
	hp = p.hp
	max_hp = hp
	is_boss = p.get("boss", false)
	cell = p.get("cell", 96)
	body.offset = Vector2(0, -cell / 2.0)
	idle_poses = _poses("idle")
	attack_poses = _poses("attack")
	if p.has("horn"):
		horn_poses = _poses("horn")
	if p.has("walk"):
		for d in ["down", "up", "side"]:
			var path: String = p.walk % d
			if ResourceLoader.exists(Sheets.ROOT + path):
				walk[d] = Sheets.cells(path, cell, cell)
	var hs: Vector2 = p.get("hurt_size", Vector2(26, 52))
	(hurt_shape.shape as RectangleShape2D).size = hs
	hurt_shape.position = Vector2(0, -hs.y / 2.0)
	var bs: Vector2 = p.get("body_size", Vector2(18, 10))
	(body_shape.shape as RectangleShape2D).size = bs
	body_shape.position = Vector2(0, -bs.y / 2.0)
	(hitshape.shape as RectangleShape2D).size = p.get("hit_size", Vector2(40, 36))
	add_to_group("enemy")
	if is_boss:
		add_to_group("boss")
		state = State.DORMANT
	home = position
	wander_target = position
	hurtbox.area_entered.connect(_on_hurt_area)
	# The hero's hurtbox only listens to this group; without it no blade here ever lands.
	hitbox.add_to_group("enemy_attack")
	hitbox.set_meta("damage", int(p.get("dmg", 1)))
	t = randf() * 10.0
	_apply_pose()


## Snares and heavy blows stop an enemy for a moment.
func stun(seconds: float) -> void:
	if state == State.DEAD or is_boss:
		return
	hitshape.set_deferred("disabled", true)
	_set_state(State.HURT)
	state_time = -seconds
	velocity = Vector2.ZERO
	flash = seconds


func _poses(which: String) -> Dictionary:
	if p.has("sheet"):
		var idx: Array = p.get(which + "_idx", p.idle_idx)
		return {"down": Sheets.cell(p.sheet, cell, idx[0], 4), "up": Sheets.cell(p.sheet, cell, idx[1], 4), "side": Sheets.cell(p.sheet, cell, idx[2], 4)}
	var path: String = p[which]
	if Sheets.tex(path).get_width() >= cell * 3:
		return Sheets.dir3(path, cell)
	var single := Sheets.cell(path, cell, 0, 1)
	return {"down": single, "up": single, "side": single}


func _physics_process(delta: float) -> void:
	t += delta
	state_time += delta
	flash = maxf(0.0, flash - delta)
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	if hero == null or not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero")
	var to_hero := Vector2.ZERO
	var dist := INF
	if hero != null:
		to_hero = hero.global_position - global_position
		dist = to_hero.length()
	match state:
		State.DORMANT:
			velocity = Vector2.ZERO
			if _should_wake(dist):
				_activate()
		State.IDLE:
			_idle(delta, dist)
		State.CHASE:
			_chase(to_hero, dist)
		State.WINDUP:
			velocity = Vector2.ZERO
			# The attacker tracks the hero for the first part of the wind-up, then commits, so a
			# sidestep in the last moment really gets out of the way.
			if state_time < p.windup * 0.55:
				_face(to_hero)
				if to_hero != Vector2.ZERO:
					aim = to_hero.normalized()
			if state_time >= (p.windup * (1.4 if horn_attack else 1.0)):
				_strike(aim)
		State.STRIKE:
			if p.type == "charge" or p.type == "charge_shoot":
				velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			if state_time >= p.strike:
				hitshape.disabled = true
				_set_state(State.RECOVER)
		State.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			if state_time >= p.recover:
				_set_state(State.CHASE)
		State.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			if state_time >= 0.25:
				_set_state(State.CHASE)
		State.DEAD:
			velocity = Vector2.ZERO
	move_and_slide()
	_apply_pose()
	_motion()


func _aggro() -> float:
	return float(p.aggro) * Game.level_aggro_scale


func _should_wake(dist: float) -> bool:
	if kind == Kind.BEGTER:
		return dist < _aggro() or (Game.inventory.get("fish", 0) >= 2 and dist < 560.0)
	return dist < _aggro()


func _set_state(s: State) -> void:
	state = s
	state_time = 0.0
	if s == State.WINDUP and hero != null:
		var v := hero.global_position - global_position
		if v != Vector2.ZERO:
			aim = v.normalized()


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


func _activate() -> void:
	_set_state(State.CHASE)
	if is_boss:
		Game.set_boss(self)
		Sfx.play("boss")
		var line: String = p.get("taunt", "Begter: That fish is mine, little brother." if kind == Kind.BEGTER else "Targhutai: Bring me the boy. Alive, or not.")
		Vfx.float_text(get_parent(), global_position, line, Color(1, 0.85, 0.7))


func _idle(delta: float, dist: float) -> void:
	if dist < _aggro():
		_set_state(State.CHASE)
		return
	wander_wait -= delta
	if wander_wait <= 0.0:
		wander_wait = randf_range(1.5, 3.5)
		wander_target = home + Vector2(randf_range(-48, 48), randf_range(-32, 32))
	var to_target := wander_target - global_position
	if to_target.length() > 4.0:
		velocity = to_target.normalized() * p.speed * 0.45
		_face(to_target)
	else:
		velocity = Vector2.ZERO


func _chase(to_hero: Vector2, dist: float) -> void:
	_face(to_hero)
	if p.type == "flee_shoot":
		# Riders keep ahead of the hero and turn in the saddle to shoot.
		if dist < 170.0:
			velocity = -to_hero.normalized() * p.speed
		elif dist > 330.0:
			velocity = to_hero.normalized() * p.speed * 0.8
		else:
			velocity = to_hero.orthogonal().normalized() * p.speed * 0.6 * (1.0 if int(t) % 2 == 0 else -1.0)
		if shot_cooldown <= 0.0 and dist <= p.range:
			_set_state(State.WINDUP)
		return
	if p.type == "charge":
		velocity = to_hero.normalized() * p.speed * (0.9 if dist > 200.0 else 1.0)
		if dist <= p.range and shot_cooldown <= 0.0:
			horn_attack = true
			_set_state(State.WINDUP)
		return
	if p.type == "charge_shoot":
		if dist > 140.0:
			velocity = to_hero.normalized() * p.speed * 0.9
			if shot_cooldown <= 0.0 and dist <= p.range:
				horn_attack = false
				_set_state(State.WINDUP)
		else:
			velocity = to_hero.normalized() * p.speed
			if dist <= 130.0 and shot_cooldown <= 0.0:
				horn_attack = true
				_set_state(State.WINDUP)
		return
	if p.type == "arrow":
		if dist < 90.0:
			velocity = -to_hero.normalized() * p.speed
		elif dist > 220.0:
			velocity = to_hero.normalized() * p.speed
		else:
			velocity = Vector2.ZERO
		if shot_cooldown <= 0.0 and dist <= p.range:
			_set_state(State.WINDUP)
		return
	velocity = to_hero.normalized() * p.speed
	if dist <= p.range:
		if not is_boss and _attackers() >= 2:
			# Two blades are already in. Circle at the edge of reach instead of piling on.
			var side := 1.0 if int(t) % 4 < 2 else -1.0
			velocity = to_hero.orthogonal().normalized() * p.speed * 0.6 * side
			if dist < p.range * 0.7:
				velocity -= to_hero.normalized() * p.speed * 0.5
			return
		horn_attack = (p.type == "whip" or p.type == "slam") and attacks_done > 0 and attacks_done % int(p.get("horn_every", 4)) == 0
		_set_state(State.WINDUP)


## How many other foot soldiers are mid-attack right now.
func _attackers() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e != self and e is Enemy and not e.is_boss and (e.state == State.WINDUP or e.state == State.STRIKE):
			n += 1
	return n


func _strike(direction: Vector2) -> void:
	_set_state(State.STRIKE)
	attacks_done += 1
	if is_boss:
		Game.debug("f%d %s strikes" % [Engine.get_physics_frames(), p.name])
	var fwd := direction.normalized() if direction != Vector2.ZERO else _facing_vector()
	match p.type:
		"arrow", "flee_shoot":
			# A rider shooting backwards from the saddle is not a marksman.
			var aim := fwd.rotated(randf_range(-0.22, 0.22)) if p.type == "flee_shoot" else fwd
			Arrow.spawn(get_parent(), global_position + fwd * 16.0 + Vector2(0, -cell / 3.0), aim, false)
			shot_cooldown = p.recover + 0.4
		"charge":
			velocity = fwd * p.lunge
			hitbox.position = fwd * 34.0 + Vector2(0, -44)
			hitshape.disabled = false
			Vfx.play(get_parent(), "hoof", global_position + Vector2(0, -4), 0.0, fwd.x < 0.0)
			shot_cooldown = p.recover
		"charge_shoot":
			if horn_attack:
				velocity = fwd * p.lunge
				hitbox.position = fwd * 30.0 + Vector2(0, -40)
				hitshape.disabled = false
				Vfx.play(get_parent(), "hoof", global_position + Vector2(0, -4), 0.0, fwd.x < 0.0)
				shot_cooldown = p.recover
			else:
				Arrow.spawn(get_parent(), global_position + fwd * 20.0 + Vector2(0, -50), fwd, false)
				shot_cooldown = p.recover
		"slam":
			if horn_attack:
				hitbox.position = Vector2(0, -30)
				(hitshape.shape as RectangleShape2D).size = Vector2(170, 90)
				hitshape.disabled = false
				if hero != null and hero.has_method("shake"):
					hero.shake(7.0)
				Vfx.play(get_parent(), "dust", global_position + Vector2(-50, -6))
				Vfx.play(get_parent(), "dust", global_position + Vector2(50, -6))
				Sfx.play("boss", -4.0)
			else:
				(hitshape.shape as RectangleShape2D).size = p.get("hit_size", Vector2(40, 36))
				velocity = fwd * p.lunge
				hitbox.position = fwd * 30.0 + Vector2(0, -40)
				hitshape.disabled = false
				Vfx.play(get_parent(), "dust", global_position + Vector2(0, -6))
		"whip":
			if horn_attack:
				horn_attack = false
				_summon()
				return
			hitbox.position = fwd * 56.0 + Vector2(0, -40)
			hitshape.disabled = false
			SlashArc.spawn(get_parent(), global_position + fwd * 30.0 + Vector2(0, -40), fwd.angle(), 1 if flip else -1, 70.0, Color(1.0, 0.6, 0.5))
			Sfx.play("swoosh", -1.0)
		_:
			velocity = fwd * p.lunge
			hitbox.position = fwd * 22.0 + Vector2(0, -cell / 4.0)
			hitshape.disabled = false
			Vfx.play(get_parent(), "dust", global_position + Vector2(0, -6))
			if p.get("slash", false):
				SlashArc.spawn(get_parent(), global_position + fwd * 8.0 + Vector2(0, -26), fwd.angle(), 1 if flip else -1, 30.0, Color(1.0, 0.6, 0.5))
			Sfx.play("swoosh", -3.0)


## A fast answer to a flurry: a shortened wind-up straight into the usual strike.
func _counter() -> void:
	horn_attack = false
	_set_state(State.WINDUP)
	state_time = float(p.windup) * 0.3
	Vfx.float_text(get_parent(), global_position, "%s turns on you" % p.name, Color(1, 0.7, 0.6))


## Half dead, a boss fights faster and shows it.
func _enrage() -> void:
	enraged = true
	Game.debug("%s enraged at hp %d" % [p.name, hp])
	p.speed = float(p.speed) * 1.3
	p.windup = float(p.windup) * 0.75
	p.recover = float(p.recover) * 0.7
	p["tint"] = Color(1.0, 0.72, 0.68)
	Sfx.play("boss", -2.0)
	Vfx.float_text(get_parent(), global_position, "%s fights like a cornered wolf" % p.name, Color(1, 0.7, 0.6))


## Targhutai blows the horn and hunters answer. Capped so the clearing never floods.
func _summon() -> void:
	Sfx.play("boss")
	Vfx.float_text(get_parent(), global_position, "Targhutai blows the horn", Color(1, 0.85, 0.7))
	var alive := get_tree().get_nodes_in_group("enemy").size() - 1
	if alive >= 3:
		return
	var scene: PackedScene = load("res://scenes/Enemy.tscn")
	var kinds: Array = p.get("summon", ["hunter", "dog"])
	for i in kinds.size():
		var e: Enemy = scene.instantiate()
		e.kind = kind_named(str(kinds[i]))
		e.position = global_position + Vector2(-70 + 140 * i, 30)
		get_parent().add_child(e)
		e.call_deferred("_set_state", State.CHASE)
		Vfx.play(get_parent(), "dust", e.position + Vector2(0, -6))


func _on_hurt_area(a: Area2D) -> void:
	if a.is_in_group("hero_attack"):
		take_hit(int(a.get_meta("damage", 1)), a.global_position)


func take_hit(dmg: int, from: Vector2) -> void:
	if state == State.DEAD:
		return
	hp -= dmg
	flash = 0.12
	Game.debug("%s takes %d, hp %d" % [p.name, dmg, hp])
	Vfx.play(get_parent(), "spark", global_position + Vector2(0, -cell / 3.0))
	Sfx.play("hit_boss" if is_boss else "hit", -2.0, 0.12)
	Game.hit_stop()
	if hero != null and hero.has_method("shake"):
		hero.shake(2.5)
	if state == State.DORMANT:
		_activate()
	if hp <= 0:
		_die()
		return
	if is_boss:
		if not enraged and hp * 2 <= max_hp:
			_enrage()
		# One full chain is fair play; a second chain on its heels is a sword wall, and the boss answers.
		recent_hits.append(t)
		while not recent_hits.is_empty() and t - float(recent_hits[0]) > 1.6:
			recent_hits.pop_front()
		if recent_hits.size() >= 4 and state != State.WINDUP and state != State.STRIKE:
			recent_hits.clear()
			_counter()
		return
	hitshape.set_deferred("disabled", true)
	_set_state(State.HURT)
	var away := global_position - from
	velocity = (away.normalized() if away.length() > 1.0 else Vector2.DOWN) * 140.0


func _die() -> void:
	_set_state(State.DEAD)
	hitshape.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0
	remove_from_group("enemy")
	Sfx.play("enemy_die")
	var tw := create_tween()
	tw.tween_property(body, "rotation", (PI / 2.0) * (1.0 if flip else -1.0), 0.35)
	tw.parallel().tween_property(body, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tw.tween_callback(queue_free)
	if is_boss:
		Game.set_boss(null)
		Game.set_flag(p.flag)
		Game.add_tail()
		Game.autosave()
		Vfx.float_text(get_parent(), global_position, "A white tail for the banner", Color(1, 0.92, 0.6))
		if hero != null and hero.has_method("shake"):
			hero.shake(6.0)
	else:
		var r := randf()
		if r < 0.35:
			Callable(Pickup, "spawn").call_deferred(get_parent(), global_position, "heart")
		elif r < 0.6 and p.has("drop"):
			Callable(Pickup, "spawn").call_deferred(get_parent(), global_position, str(p.drop))


func _apply_pose() -> void:
	if p.has("tint") and flash <= 0.0:
		body.self_modulate = p.tint
	var attacking := state == State.WINDUP or state == State.STRIKE
	var moving: bool = velocity.length() > 5.0 and (state == State.CHASE or state == State.IDLE or (state == State.STRIKE and str(p.type) == "charge_shoot"))
	if attacking and horn_attack and not horn_poses.is_empty():
		body.texture = horn_poses[facing]
	elif attacking and p.type == "charge_shoot" and horn_attack:
		body.texture = idle_poses[facing]
	elif attacking:
		body.texture = attack_poses[facing]
	elif moving and walk.has(facing):
		var frames: Array = walk[facing]
		var rate := 11.0 if kind != Kind.DOG else 14.0
		body.texture = frames[int(t * rate) % frames.size()]
	else:
		body.texture = idle_poses[facing]
	body.flip_h = flip and facing == "side"


func _motion() -> void:
	if state == State.DEAD:
		return
	var bob := 0.0
	var tilt := 0.0
	var sc := Vector2.ONE
	if velocity.length() > 5.0:
		var rate := 11.0 if kind != Kind.DOG else 18.0
		if walk.has(facing):
			bob = -absf(sin(t * rate * PI / 3.0)) * 1.0
		else:
			bob = -absf(sin(t * rate)) * 3.0
			tilt = sin(t * rate) * 0.05
	elif state == State.WINDUP:
		var k: float = state_time / float(p.windup)
		sc = Vector2(1.0 - 0.06 * k, 1.0 + 0.06 * k)
	else:
		sc = Vector2(1.0 + 0.01 * sin(t * 2.0), 1.0 - 0.01 * sin(t * 2.0))
	body.position = Vector2(0, roundf(bob))
	body.rotation = tilt
	body.scale = sc
	if flash > 0.0:
		body.modulate = Color(2.5, 2.5, 2.5)
	elif state == State.WINDUP and fmod(t, 0.12) < 0.06:
		body.modulate = Color(1.6, 1.2, 1.2)
	else:
		body.modulate = Color.WHITE
