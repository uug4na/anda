class_name Bot
extends Node
## An automated player for checking the whole game: it reads the guide target, walks there on the
## level's walk grid, fights whatever comes close, rolls away from wind-ups, talks, and clicks
## through cutscenes. Started with ANDA_BOT=1; prints a log the test harness can read.

var clock := 0.0
var tick := 0.0
var status_at := 0.0
var path: PackedVector2Array = []
var path_at := -10.0
var path_goal := Vector2.ZERO
var attack_at := -10.0
var roll_at := -10.0
var dismount_at := -10.0
var last_objective := ""
var last_map := ""
var progress_at := 0.0
var stalls := 0
var deaths := 0
var hp_seen := 0
var grid_level: Node = null
var no_path_logged := false
var bow_release := -1.0
var chase_target: Node = null
var chase_since := 0.0
var ignored := {}
var at_goal_since := -1.0
var nudge_until := -1.0
var nudge_dir := Vector2.ZERO
var hit_target: Node = null
var hit_target_hp := 0
var hit_since := 0.0
var last_pos := Vector2.ZERO
var moved_at := 0.0
var unstick_until := -1.0
var unstick_dir := Vector2.ZERO
var last_threat_note := ""
var ability_at := -10.0


func to_threat_dir(threat: Node, pos: Vector2) -> Vector2:
	return threat.global_position - pos


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hp_seen = Game.hp
	print("[bot] start")


func _physics_process(delta: float) -> void:
	clock += delta
	tick -= delta
	var scene := get_tree().current_scene
	if scene == null:
		return
	if Game.hp < hp_seen and Game.hp == 0:
		deaths += 1
		print("[bot] t=%.0f DEATH #%d on %s (%s)" % [clock, deaths, Game.current_map, Game.objective_text()])
	hp_seen = Game.hp
	if Game.flags.get("finished", false):
		print("[bot] t=%.0f FINISHED: deaths %d, tails %d" % [clock, deaths, Game.tails])
		get_tree().quit()
		return
	if deaths > 25:
		print("[bot] t=%.0f ABORT: too many deaths" % clock)
		get_tree().quit()
		return
	if scene.name == "Title" or scene.name == "Cutscene":
		if tick <= 0.0:
			tick = 0.45
			_press("ui_accept")
		return
	if not scene.has_method("guide_target"):
		return
	_play_level(scene, delta)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event.call_deferred(up)


func _play_level(level: Node, delta: float) -> void:
	var hero: Node = get_tree().get_first_node_in_group("hero")
	if hero == null:
		return
	if level != grid_level:
		grid_level = level
		path = []
		no_path_logged = false
	var objective := Game.objective_text()
	if objective != last_objective or Game.current_map != last_map:
		print("[bot] t=%.0f %s | %s | hp %d tails %d" % [clock, Game.current_map, objective, Game.hp, Game.tails])
		last_objective = objective
		last_map = Game.current_map
		progress_at = clock
		stalls = 0
	# Stall watch, before any branch can return: no change of objective or map for a long while.
	if clock - progress_at > 150.0:
		progress_at = clock
		stalls += 1
		print("[bot] t=%.0f STALL #%d on %s: %s | pos %s hp %d state %s dir %s busy %s paused %s scale %.2f %s" % [clock, stalls, Game.current_map, objective, hero.global_position.round(), Game.hp, hero.state, hero.bot_dir, Game.ui_busy, get_tree().paused, Engine.time_scale, last_threat_note])
		path = []
		if stalls >= 4:
			print("[bot] ABORT: stuck")
			get_tree().quit()
			return
	if clock - status_at > 20.0:
		status_at = clock
		print("[bot] t=%.0f status: %s pos %s hp %d stamina %.0f arrows %d fish %d roots %d" % [clock, Game.current_map, hero.global_position.round(), Game.hp, Game.stamina, Game.arrows, Game.inventory.get("fish", 0), Game.inventory.get("roots", 0)])
	# Anti-stuck: wanting to move but not moving for five seconds means something is in the way
	# that the plan does not know about. Drop the current enemy and walk off at an angle.
	if hero.global_position.distance_to(last_pos) > 3.0:
		last_pos = hero.global_position
		moved_at = clock
	elif hero.bot_dir != Vector2.ZERO and clock - moved_at > 5.0 and clock >= unstick_until:
		unstick_until = clock + 1.2
		unstick_dir = Vector2.RIGHT.rotated(float(int(clock * 13.0) % 8) * PI / 4.0)
		if chase_target != null and is_instance_valid(chase_target):
			ignored[chase_target] = clock + 15.0
		path = []
		print("[bot] t=%.0f unstick at %s (%s)" % [clock, hero.global_position.round(), last_threat_note])
		moved_at = clock
	hero.bot_dir = Vector2.ZERO
	hero.bot_cmd = ""
	if clock < unstick_until:
		hero.bot_dir = unstick_dir
		return
	if bow_release > 0.0 and clock >= bow_release:
		hero.bot_hold_bow = false
		bow_release = -1.0
	# Dialog: keep pressing on.
	var box: Node = get_tree().get_first_node_in_group("dialog")
	if box != null and box.visible:
		if tick <= 0.0:
			tick = 0.3
			box.call("_advance")
		progress_at = clock
		return
	if Game.ui_busy:
		return
	var pos: Vector2 = hero.global_position
	# Enemies nearby decide the fight.
	var threat: Node = null
	var threat_d := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Enemy) or e.state == Enemy.State.DEAD:
			continue
		if ignored.has(e) and float(ignored[e]) > clock:
			continue
		var d: float = pos.distance_to(e.global_position)
		if d < threat_d:
			threat_d = d
			threat = e
	last_threat_note = ("threat %s at %.0f px state %s" % [threat.p.name, threat_d, threat.state]) if threat != null else "no threat"
	# An enemy that never comes within reach is behind something; leave it alone for a while.
	if threat != null and threat_d > 42.0 and threat_d < 170.0 and not threat.is_boss:
		if threat != chase_target:
			chase_target = threat
			chase_since = clock
		elif clock - chase_since > 6.0:
			ignored[threat] = clock + 12.0
			print("[bot] t=%.0f ignoring %s at %.0f px" % [clock, threat.p.name, threat_d])
			chase_target = null
			threat = null
			threat_d = INF
	else:
		chase_target = null
	var cangue: bool = hero.cangue
	var mounted: bool = hero.mounted
	# An arrow on its way here: roll off its line, or at least step aside.
	for a in get_tree().get_nodes_in_group("enemy_attack"):
		if a is Arrow and is_instance_valid(a):
			var rel: Vector2 = pos + Vector2(0, -24) - a.global_position
			if rel.length() < 100.0 and rel.normalized().dot(a.dir) > 0.8:
				var side: Vector2 = a.dir.orthogonal() * (1.0 if int(clock * 7.0) % 2 == 0 else -1.0)
				hero.bot_dir = side
				if Game.stamina >= Game.ROLL_COST and clock - roll_at > 0.5:
					roll_at = clock
					hero.bot_cmd = "roll"
				return
	if mounted and threat != null and threat_d < 260.0 and Game.companion() == "boorchu" and clock - dismount_at > 3.0:
		dismount_at = clock
		hero.bot_cmd = "ability"
		return
	# Companions earn their keep: Jelme binds a bad wound, the archers shoot a boss from a distance.
	var comp := Game.companion()
	if Game.ability_cooldown <= 0.0 and clock - ability_at > 1.0:
		if comp == "jelme" and Game.hp <= 4 and not Game.jelme_used:
			ability_at = clock
			hero.bot_cmd = "ability"
			return
		if (comp == "qasar" or comp == "jebe") and threat != null and threat.is_boss and threat_d > 60.0 and threat_d < 220.0 and Game.arrows > 0:
			var axis_x: bool = absf(to_threat_dir(threat, pos).x) > absf(to_threat_dir(threat, pos).y)
			var off: float = to_threat_dir(threat, pos).y if axis_x else to_threat_dir(threat, pos).x
			if absf(off) < 14.0:
				ability_at = clock
				hero.bot_dir = (Vector2(signf(to_threat_dir(threat, pos).x), 0) if axis_x else Vector2(0, signf(to_threat_dir(threat, pos).y)))
				hero.bot_cmd = "ability"
				return
		if comp == "subutai" and threat != null and threat.is_boss and threat_d < 90.0:
			ability_at = clock
			hero.bot_cmd = "ability"
			return
	if threat != null and threat_d < 170.0:
		var to_threat: Vector2 = threat.global_position - pos
		# Roll late, on the blow itself: the roll's grace must cover the strike, not the wind-up.
		var late_windup: bool = threat.state == Enemy.State.WINDUP and threat.state_time >= float(threat.p.windup) * (0.6 if threat.horn_attack else 0.45)
		var winding: bool = late_windup or threat.state == Enemy.State.STRIKE
		# A foot soldier winding up in reach is best hit first: the blow staggers it and the swing is lost.
		if not mounted and not cangue and not threat.is_boss and threat.state == Enemy.State.WINDUP and threat_d < 56.0 and clock - attack_at > 0.2 and hero.combo_rest <= 0.0:
			attack_at = clock
			hero.bot_dir = to_threat.normalized() * 0.3
			hero.bot_cmd = "attack"
			return
		if winding and threat_d < 110.0 and Game.stamina >= Game.ROLL_COST and clock - roll_at > 0.6:
			# A diagonal retreat: out of the committed line and out of reach, close enough to punish.
			roll_at = clock
			var roll_dir: Vector2 = (-to_threat).normalized().rotated(0.9 if int(clock) % 2 == 0 else -0.9)
			# Never roll out through an exit; take the other diagonal, or go sideways.
			for digit in level.exit_info:
				if (pos + roll_dir * 80.0).distance_to(level.exit_info[digit].pos) < 56.0:
					roll_dir = (-to_threat).normalized().rotated(-0.9 if int(clock) % 2 == 0 else 0.9)
					if (pos + roll_dir * 80.0).distance_to(level.exit_info[digit].pos) < 56.0:
						roll_dir = to_threat.orthogonal().normalized()
					break
			hero.bot_dir = roll_dir
			hero.bot_cmd = "roll"
			return
		if cangue:
			# Unarmed: only a guard already on the chase is worth running from; the rest are walked past.
			var chasing: bool = threat.state == Enemy.State.CHASE or winding
			if chasing and threat_d < 130.0:
				_walk(level, hero, pos, delta, -to_threat.normalized())
				return
		if not mounted:
			if threat_d <= 48.0:
				# Swinging at something whose health never drops means a trunk is between us: let it go.
				if threat != hit_target or threat.hp < hit_target_hp:
					hit_target = threat
					hit_target_hp = threat.hp
					hit_since = clock
				elif clock - hit_since > 4.0 and not threat.is_boss:
					ignored[threat] = clock + 12.0
					print("[bot] t=%.0f ignoring %s: swings do not land" % [clock, threat.p.name])
					hit_target = null
					return
				hero.bot_dir = to_threat.normalized() * 0.3
				# Against a boss keep a roll in reserve, unless it is recovering and the swing is free.
				var can_afford: bool = Game.stamina >= Game.ROLL_COST + 4.0 or (not threat.is_boss and Game.stamina >= 12.0)
				if clock - attack_at > 0.2 and hero.combo_rest <= 0.0 and can_afford:
					attack_at = clock
					hero.bot_cmd = "attack"
				return
			if threat.is_boss:
				_go_to(level, hero, pos, threat.global_position)
				return
			if threat_d < 70.0:
				hero.bot_dir = to_threat.normalized()
				return
		else:
			# In the saddle: shoot when lined up with the enemy, else line up.
			var axis_x: bool = absf(to_threat.x) > absf(to_threat.y)
			var off: float = to_threat.y if axis_x else to_threat.x
			if absf(off) > 12.0:
				hero.bot_dir = Vector2(0, signf(off)) if axis_x else Vector2(signf(off), 0)
				return
			if Game.arrows > 0 and clock - attack_at > 0.6 and threat_d < 280.0:
				attack_at = clock
				hero.bot_dir = (Vector2(signf(to_threat.x), 0) if axis_x else Vector2(0, signf(to_threat.y)))
				hero.bot_cmd = "bow"
				hero.bot_hold_bow = true
				bow_release = clock + 0.2
				return
	# Low health at the camp with something to cook: eat first.
	var target = level.guide_target()
	var obj: Dictionary = Game.objective()
	if Game.hp <= 3 and Game.current_map == "camp" and obj.map != "riverbank" and (Game.inventory.get("fish", 0) > 0 or Game.inventory.get("roots", 0) > 0):
		for prop in level.get_node("World").get_children():
			if prop is Prop and prop.kind == "campfire":
				target = prop.global_position
				if pos.distance_to(target) < 34.0:
					hero.bot_cmd = "interact"
					return
				break
	if target == null:
		# Nothing to reach: hold ground near the middle of the map, away from the nearest enemy.
		var centre := Vector2(level.map_w * 16.0, level.map_h * 16.0)
		var to_centre := (centre - pos)
		if threat != null and threat_d < 200.0:
			var away: Vector2 = (pos - threat.global_position).normalized()
			var dir: Vector2 = (away * 0.6 + to_centre.normalized() * 0.4).normalized()
			# Never back onto an exit while holding out: that leaves the map.
			for digit in level.exit_info:
				if (pos + dir * 40.0).distance_to(level.exit_info[digit].pos) < 56.0:
					dir = to_centre.normalized()
					break
			_walk(level, hero, pos, delta, dir)
		elif to_centre.length() > 120.0:
			_go_to(level, hero, pos, centre)
		return
	var goal: Vector2 = target
	var d_goal := pos.distance_to(goal)
	if obj.kind == "npc" and obj.map == Game.current_map and d_goal < 44.0:
		if tick <= 0.0:
			tick = 0.5
			hero.bot_cmd = "interact"
		return
	if obj.kind == "boss" and d_goal < 60.0:
		hero.bot_dir = (goal - pos).normalized()
		return
	_go_to(level, hero, pos, goal)


## Walk toward a goal along the grid path, recomputing now and then.
func _go_to(level: Node, hero: Node, pos: Vector2, goal: Vector2) -> void:
	if clock - path_at > 0.6 or goal.distance_to(path_goal) > 24.0 or path.is_empty():
		path_at = clock
		path_goal = goal
		var g: AStarGrid2D = level.walk_grid()
		var from: Vector2i = level.free_cell_near(pos)
		var to: Vector2i = level.free_cell_near(goal)
		path = g.get_point_path(from, to)
		if path.is_empty() and not no_path_logged:
			no_path_logged = true
			print("[bot] t=%.0f no path on %s from %s to %s" % [clock, Game.current_map, pos.round(), goal.round()])
	while path.size() > 1 and pos.distance_to(path[0]) < 10.0:
		path.remove_at(0)
	var next: Vector2 = goal
	if not path.is_empty():
		next = path[0]
		if path.size() == 1:
			next = goal
	hero.bot_dir = (next - pos).normalized() if pos.distance_to(next) > 2.0 else Vector2.ZERO
	# Standing on the goal with nothing happening (an exit that did not fire): step off and back.
	if pos.distance_to(goal) < 14.0:
		if at_goal_since < 0.0:
			at_goal_since = clock
		elif clock - at_goal_since > 2.0:
			at_goal_since = -1.0
			nudge_until = clock + 0.7
			nudge_dir = (Vector2(level.map_w * 16.0, level.map_h * 16.0) - pos).normalized()
	else:
		at_goal_since = -1.0
	if clock < nudge_until:
		hero.bot_dir = nudge_dir
	if OS.get_environment("ANDA_BOT") == "2" and tick <= 0.0:
		tick = 1.0
		var g2: AStarGrid2D = level.walk_grid()
		print("[bot] nav pos %s cell %s solid %s next %s dir %s path %d first %s" % [pos.round(), level.grid_cell(pos), g2.is_point_solid(level.grid_cell(pos)), next.round(), hero.bot_dir, path.size(), Array(path.slice(0, 4))])


func _walk(level: Node, hero: Node, pos: Vector2, _delta: float, dir: Vector2) -> void:
	# A short step in a direction that keeps to standable ground.
	var g: AStarGrid2D = level.walk_grid()
	var ahead := pos + dir * 24.0
	if g.is_point_solid(level.grid_cell(ahead)):
		dir = dir.rotated(PI / 2.0)
	hero.bot_dir = dir
