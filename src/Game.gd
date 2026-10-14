extends Node
## Global game state, scene routing, fades, input, theme, saving and test hooks. Autoloaded as "Game".

signal hp_changed
signal inventory_changed
signal tails_changed
signal flags_changed
signal boss_changed(boss)

const MAX_HP := 6
const LEVEL_SCENE := "res://scenes/Level.tscn"
const CUTSCENE_SCENE := "res://scenes/Cutscene.tscn"
const TITLE_SCENE := "res://scenes/Title.tscn"
static var font_path := "res://assets/fonts/Alegreya[wght].ttf"
static var font_size := 17
static var font_spacing := 0
static var font_weight := 500
static var _font: Font
const STAMINA_MAX := 100.0
const ROLL_COST := 30.0

var hp: int = MAX_HP
var stamina: float = STAMINA_MAX
var arrows: int = 12
var tails: int = 1
var inventory := {"fish": 0, "roots": 0}
var flags := {}
var ui_busy := false

var current_map := ""
var pending_map := "camp"
var pending_spawn := "@"
var pending_position = null
var pending_cutscene := {}
var active_boss: Node = null

var _fade: ColorRect
var _busy_fade := false
var bot := false
var base_time_scale := 1.0
var level_aggro_scale := 1.0
var survive_left := 0.0
var ability_cooldown := 0.0
var jelme_used := false
var companion_pick := ""

const COMPANIONS := {
	"boorchu": {"name": "Bo'orchu", "ability": "whistle the horse", "portrait": "portraits/portrait_boorchu_neutral.png"},
	"qasar": {"name": "Qasar", "ability": "arrow volley", "portrait": "portraits/portrait_qasar_neutral.png"},
	"jelme": {"name": "Jelme", "ability": "field dressing", "portrait": "portraits/portrait_jelme_neutral.png"},
	"jebe": {"name": "Jebe", "ability": "piercing shot", "portrait": "portraits/portrait_jebe_neutral.png"},
	"subutai": {"name": "Subutai", "ability": "snare", "portrait": "portraits/portrait_subutai_neutral.png"},
}

const CUTSCENES := {
	"captured": {"image": "cutscenes/cutscene_15_captured.png", "flags": ["captured", "cangue"], "lines": [
		"Summer. The Tayichiud came at dawn with twenty riders.",
		"They took Temüjin alive. Targhutai had a cangue made for him: a wooden board locked around the neck, the hands bound to its edge.",
		"A prisoner in a cangue cannot eat by himself, cannot lie down, and cannot fight. He can only wait for a careless guard.",
	]},
	"cangue_river": {"image": "cutscenes/cutscene_05_cangue_river.png", "flags": ["cangue_river"], "next": "sorkan", "lines": [
		"On the night of the summer feast the guard was drunk, and the boy swung the cangue into his head.",
		"He ran for the river and lay in the shallows with only his face above the water, the board floating on the current.",
		"One searcher saw him. Sorkan-Shira of the Suldus looked straight at the boy in the water, and said nothing.",
	]},
	"wedding": {"image": "cutscenes/cutscene_08_wedding_sable.png", "flags": ["wedded", "borte_home"], "next": "camp", "lines": [
		"Temüjin rode to the Onggirat, to the girl his father had chosen when they were both children.",
		"Börte came back with him to the Onon, with a black sable coat from her mother as her dowry.",
		"Hoelun looked at the coat for a long time and said: that is not a coat. That is an army.",
	]},
	"merkit_raid": {"image": "cutscenes/cutscene_09_merkit_raid.png", "flags": ["borte_taken"], "unset": ["borte_home"], "next": "camp", "lines": [
		"The Merkits came before dawn. Three hundred riders, for a debt twenty years old: Hoelun had been a Merkit bride once, stolen by Yesügei.",
		"Everyone with a horse rode for Burkhan Khaldun. There was one horse too few.",
		"They took Börte in a cart, and gave her to a Merkit named Chilger.",
	]},
	"borte_found": {"image": "cutscenes/cutscene_10_borte_found.png", "flags": ["borte_back"], "unset": ["borte_taken"], "next": "camp", "lines": [
		"The camp was burning when he found her. He called her name in the dark, and she climbed down from the cart and came.",
		"Jamukha and Ong Khan took their share of the Merkit herds and rode home. Temüjin took only Börte.",
		"Nine months later she bore a son, Jochi. Temüjin never once asked whose.",
	]},
	"balzhut": {"image": "cutscenes/cutscene_11_cauldrons.png", "flags": ["balzhut", "anda_broken"], "next": "camp", "lines": [
		"At Dalan Balzhut the two andas met with thirteen thousand riders each, and Jamukha won.",
		"He boiled seventy of the Chinos prisoners alive in cauldrons, and hung a chief's head from his horse's tail.",
		"Temüjin lost the field and won the steppe. Clans that had followed Jamukha began, quietly, to ride the other way.",
	]},
	"tatar_end": {"image": "cutscenes/cutscene_01_poisoned_feast.png", "flags": ["tatar_done"], "next": "camp", "lines": [
		"The Tatars had poisoned Yesügei. Temüjin did not forget it, and after the battle he did not forgive it.",
		"In the wreck of the camp his men found a small boy with a gold earring and a sable-lined cap, and brought him to Hoelun.",
		"She named him Shigi Qutuqu and raised him as her own. He would write the laws of the empire.",
	]},
	"baljuna": {"image": "cutscenes/cutscene_12_baljuna.png", "flags": ["baljuna"], "next": "kereyit", "lines": [
		"Ong Khan's son Senggum turned the old man against his father's anda. The Kereyit struck at dawn.",
		"Temüjin escaped with nineteen men to the muddy lake at Baljuna. They drank the water and swore an oath on it.",
		"Every one of the nineteen would be a lord. And the Kereyit camp would be found by night, feasting.",
	]},
	"jamukha_end": {"image": "cutscenes/cutscene_13_jamukha_end.png", "flags": ["jamukha_done"], "next": "camp", "lines": [
		"Jamukha's own men brought him in bound, hoping for a reward. Temüjin had them executed for betraying their lord.",
		"Then he offered his anda his life. Jamukha refused it: one sun in the sky, one lord on the steppe.",
		"He asked only to die without his blood being spilled. He was wrapped in a felt rug, and it was done.",
	]},
	"kurultai": {"image": "cutscenes/cutscene_14_kurultai.png", "flags": ["kurultai", "finished"], "next": "credits", "lines": [
		"Spring, 1206. At the source of the Onon the clans raised the nine-tailed white banner.",
		"The boy who had foraged roots on this river was named Chinggis Khan, lord of all who live in felt tents.",
		"Hoelun was there. Börte was there. Bo'orchu, Jelme, Jebe, Subutai, Qasar, and Shigi Qutuqu with his writing brush.",
		"Nine tails. The steppe is wide.",
	]},
	"credits": {"image": "cutscenes/cutscene_14_kurultai.png", "flags": [], "next": "title", "lines": [
		"Anda. A game about the boy who became Chinggis Khan.",
		"Made with Godot 4.7. The pixel art was generated with image models and cleaned by hand to a palette of thirty-five colours.",
		"Music by Kevin MacLeod (incompetech.com), Creative Commons Attribution 4.0. Sound effects by Kenney (kenney.nl), CC0.",
		"Type set in Alegreya and Alegreya Sans, SIL Open Font License.",
		"Every name, every place and most of the lines come from the Secret History of the Mongols.",
		"Thank you for playing. The steppe is wide, and the camp is yours to ride from.",
	]},
	"wool_cart": {"image": "cutscenes/cutscene_06_wool_cart.png", "flags": ["cangue_off"], "unset": ["cangue"], "next": "sorkan", "lines": [
		"Sorkan-Shira's sons struck off the cangue and burned it. They hid Temüjin in a cart of wool.",
		"When the searchers came and began to pull the fleece aside, Sorkan-Shira asked who would lie under wool in that heat.",
		"They left. The captain did not.",
	]},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_environment("ANDA_FONT") != "":
		font_path = OS.get_environment("ANDA_FONT")
	if OS.get_environment("ANDA_FONT_SIZE") != "":
		font_size = int(OS.get_environment("ANDA_FONT_SIZE"))
	if OS.get_environment("ANDA_FONT_SPACING") != "":
		font_spacing = int(OS.get_environment("ANDA_FONT_SPACING"))
	if OS.get_environment("ANDA_FONT_WEIGHT") != "":
		font_weight = int(OS.get_environment("ANDA_FONT_WEIGHT"))
	_setup_input()
	Settings.apply()
	_setup_theme()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.1, 0.08, 0.14, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	if OS.has_environment("ANDA_TAILS"):
		tails = int(OS.get_environment("ANDA_TAILS"))
	if OS.has_environment("ANDA_FISH"):
		inventory["fish"] = int(OS.get_environment("ANDA_FISH"))
	if OS.has_environment("ANDA_FLAGS"):
		for f in OS.get_environment("ANDA_FLAGS").split(","):
			flags[f] = true
	if OS.get_environment("ANDA_POS").contains(","):
		var xy := OS.get_environment("ANDA_POS").split(",")
		pending_position = Vector2(float(xy[0]), float(xy[1]))
	var jump := OS.get_environment("ANDA_MAP")
	if jump != "":
		pending_map = jump
		call_deferred("_jump")
	if OS.get_environment("ANDA_SHOT") != "" or OS.get_environment("ANDA_AUTO") != "":
		_screenshot_and_quit.call_deferred()
	if OS.get_environment("ANDA_SPEED") != "":
		base_time_scale = float(OS.get_environment("ANDA_SPEED"))
		Engine.time_scale = base_time_scale
	if OS.has_environment("ANDA_BOT"):
		bot = true
		add_child(Bot.new())


func _process(delta: float) -> void:
	ability_cooldown = maxf(0.0, ability_cooldown - delta)
	if Input.is_action_just_pressed("swap"):
		cycle_companion()
	if Input.is_action_just_pressed("fullscreen"):
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		Settings.fullscreen = not full
		Settings.save_file()


# ---------------------------------------------------------------- routing

## Every second tail on the banner adds a heart: six health at the start, twelve at the end.
func max_hp() -> int:
	return mini(12, 6 + 2 * int((tails - 1) / 2))


func new_game() -> void:
	hp = MAX_HP
	stamina = STAMINA_MAX
	arrows = 12
	tails = 1
	inventory = {"fish": 0, "roots": 0}
	flags = {}
	pending_position = null
	Save.clear()
	hp_changed.emit()
	inventory_changed.emit()
	tails_changed.emit()


func goto_map(map_id: String, spawn: String = "@") -> void:
	if _busy_fade:
		return
	_busy_fade = true
	pending_map = map_id
	pending_spawn = spawn
	pending_position = null
	active_boss = null
	stamina = STAMINA_MAX
	ui_busy = true
	await fade_out()
	get_tree().change_scene_to_file(LEVEL_SCENE)
	await get_tree().process_frame
	await fade_in()
	_busy_fade = false


## An exit target is either a map id or {"map": id, "cutscene": id}.
func take_exit(target, digit: String) -> void:
	if target is Dictionary:
		if target.has("cutscene"):
			run_cutscene(str(target.cutscene), str(target.map))
		else:
			goto_map(str(target.map), digit)
	else:
		goto_map(str(target), digit)


func run_cutscene(id: String, next_map := "") -> void:
	var c: Dictionary = CUTSCENES[id]
	for f in c.get("flags", []):
		flags[f] = true
	for f in c.get("unset", []):
		flags.erase(f)
	flags_changed.emit()
	autosave()
	play_cutscene(str(c.get("image", "")), c.lines, next_map if next_map != "" else str(c.get("next", "camp")))


## Story trigger areas in maps call this with their id.
func story_trigger(id: String) -> void:
	debug("story trigger " + id)
	match id:
		"cangue_river":
			if not flags.get("cangue_river", false):
				run_cutscene("cangue_river")
		"balzhut_end":
			if not flags.get("balzhut", false):
				run_cutscene("balzhut")
		"baljuna_oath":
			if not flags.get("baljuna", false):
				run_cutscene("baljuna")


const OPEN_MAPS := ["overworld", "thieves", "ongkhan", "balzhut"]


func on_level_ready(map_id: String) -> void:
	var m := Maps.get_map(map_id)
	if m.get("mounted", false):
		flags["mounted"] = true
	elif not (map_id in OPEN_MAPS):
		flags["mounted"] = false


## Called once the level is on screen: story beats that fire on arrival.
func on_level_shown(map_id: String) -> void:
	if map_id == "camp" and flags.get("sable", false) and flags.get("ongkhan_met", false) and not flags.get("borte_taken", false) and not flags.get("borte_back", false):
		call_deferred("run_cutscene", "merkit_raid")
	jelme_used = false
	if map_id == "camp" and flags.get("jamukha_done", false) and not flags.get("kurultai", false):
		call_deferred("run_cutscene", "kurultai")
	elif map_id == "naqu" and flags.get("jamukha", false) and not flags.get("jamukha_done", false):
		call_deferred("run_cutscene", "jamukha_end")


## The active companion: the chosen one if still valid, else the most recently recruited.
func companion() -> String:
	if companion_pick != "" and flags.get(companion_pick, false):
		return companion_pick
	for c in ["subutai", "jebe", "jelme", "qasar", "boorchu"]:
		if flags.get(c, false):
			return c
	return ""


func cycle_companion() -> void:
	var have := []
	for c in ["boorchu", "qasar", "jelme", "jebe", "subutai"]:
		if flags.get(c, false):
			have.append(c)
	if have.size() < 2:
		return
	var i := have.find(companion())
	companion_pick = have[(i + 1) % have.size()]


## Companion abilities on Q. Each companion has one.
func use_ability(hero: Node) -> void:
	var world: Node = hero.get_parent()
	var pos: Vector2 = hero.global_position
	var comp := companion()
	if comp == "":
		Vfx.float_text(world, pos, "No companion yet", Color(1, 0.8, 0.6))
		return
	if ability_cooldown > 0.0:
		return
	match comp:
		"boorchu":
			if current_map in OPEN_MAPS and not flags.get("cangue", false):
				var on: bool = not flags.get("mounted", false)
				hero.set_mounted(on)
				Vfx.play(world, "hoof", pos + Vector2(0, -4))
				Vfx.float_text(world, pos, "Bo'orchu whistles the bay" if on else "Dismounted", Color(0.8, 0.95, 1.0))
			else:
				Vfx.float_text(world, pos, "No room to ride here", Color(1, 0.8, 0.6))
		"qasar":
			if not use_arrow():
				Vfx.float_text(world, pos, "No arrows", Color(1, 0.8, 0.6))
				return
			var fwd: Vector2 = hero.call("_facing_vector")
			for a in [-0.35, 0.0, 0.35]:
				Arrow.spawn(world, pos + fwd * 14.0 + Vector2(0, -30), fwd.rotated(a), true)
			Sfx.play("arrow")
			Vfx.float_text(world, pos, "Qasar looses a volley", Color(0.8, 0.95, 1.0))
			ability_cooldown = 2.5
		"jelme":
			if jelme_used:
				Vfx.float_text(world, pos, "Jelme has nothing left to bind with", Color(1, 0.8, 0.6))
				return
			jelme_used = true
			heal_hero(4)
			Sfx.play("cook")
			Vfx.float_text(world, pos, "Jelme binds the wound", Color(0.8, 1.0, 0.8))
		"jebe":
			if not use_arrow():
				Vfx.float_text(world, pos, "No arrows", Color(1, 0.8, 0.6))
				return
			var fwd2: Vector2 = hero.call("_facing_vector")
			var arrow := Arrow.spawn(world, pos + fwd2 * 14.0 + Vector2(0, -30), fwd2, true)
			arrow.pierce = true
			arrow.speed = 420.0
			arrow.set_meta("damage", 3)
			Sfx.play("arrow")
			Vfx.float_text(world, pos, "Jebe's arrow", Color(0.8, 0.95, 1.0))
			ability_cooldown = 3.0
		"subutai":
			Snare.spawn(world, pos)
			Vfx.float_text(world, pos, "Subutai sets a snare", Color(0.8, 0.95, 1.0))
			ability_cooldown = 4.0


func play_cutscene(image: String, lines: Array, next_map: String) -> void:
	pending_cutscene = {"image": image, "lines": lines, "next": next_map}
	# Nothing may start a dialog or an exit while the screen is fading to another scene.
	ui_busy = true
	await fade_out()
	get_tree().change_scene_to_file(CUTSCENE_SCENE)
	await get_tree().process_frame
	await fade_in()


func to_title() -> void:
	get_tree().paused = false
	ui_busy = true
	active_boss = null
	await fade_out()
	get_tree().change_scene_to_file(TITLE_SCENE)
	await get_tree().process_frame
	await fade_in()


func fade_out(t := 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, t)
	await tw.finished


func fade_in(t := 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, t)
	await tw.finished


func respawn() -> void:
	hp = max_hp()
	stamina = STAMINA_MAX
	hp_changed.emit()
	if current_map == "balzhut" and not flags.get("balzhut", false):
		run_cutscene("balzhut")
		return
	if flags.get("cangue", false):
		await goto_map("tayichiud", "@")
	elif current_map == "sorkan" and not flags.get("captain", false):
		# The ger has no road from the steppe; the captain must be faced where he found you.
		await goto_map("sorkan", "@")
	else:
		await goto_map("camp", "@")


# ---------------------------------------------------------------- saving

## Writes the checkpoint. Never from between scenes: without a hero on the map there is nothing
## true to write, and a save at (0, 0) would put the next Continue inside the map border.
func autosave() -> void:
	if current_map == "":
		return
	var hero := get_tree().get_first_node_in_group("hero")
	if hero == null or not hero.is_inside_tree():
		debug("autosave skipped: no hero on " + current_map)
		return
	Save.write(current_map, hero.global_position)


func load_save() -> bool:
	var d := Save.read()
	if d.is_empty():
		return false
	tails = int(d.get("tails", 1))
	hp = int(d.get("hp", max_hp()))
	arrows = int(d.get("arrows", 12))
	tails = int(d.get("tails", 1))
	inventory = d.get("inventory", {"fish": 0, "roots": 0})
	flags = d.get("flags", {})
	pending_map = str(d.get("map", "camp"))
	pending_spawn = "@"
	pending_position = Vector2(float(d.get("x", 0)), float(d.get("y", 0)))
	hp_changed.emit()
	inventory_changed.emit()
	tails_changed.emit()
	_busy_fade = true
	ui_busy = true
	await fade_out()
	get_tree().change_scene_to_file(LEVEL_SCENE)
	await get_tree().process_frame
	await fade_in()
	_busy_fade = false
	return true


# ---------------------------------------------------------------- state

func damage_hero(amount: int) -> void:
	hp = max(0, hp - amount)
	hp_changed.emit()


func heal_hero(amount: int) -> void:
	hp = min(max_hp(), hp + amount)
	hp_changed.emit()


func add_item(item: String, n: int = 1) -> void:
	inventory[item] = max(0, inventory.get(item, 0) + n)
	inventory_changed.emit()


func use_arrow() -> bool:
	if arrows <= 0:
		return false
	arrows -= 1
	inventory_changed.emit()
	return true


func add_arrows(n: int) -> void:
	arrows += n
	inventory_changed.emit()


func add_tail() -> void:
	tails = min(9, tails + 1)
	tails_changed.emit()
	# A new heart arrives full.
	hp = min(max_hp(), hp + 2)
	hp_changed.emit()


func set_flag(name: String, value := true) -> void:
	flags[name] = value
	flags_changed.emit()
	if name == "jamukha" and value and current_map == "naqu" and not flags.get("jamukha_done", false):
		call_deferred("run_cutscene", "jamukha_end")


func set_boss(boss: Node) -> void:
	active_boss = boss
	boss_changed.emit(boss)
	if boss != null:
		Sfx.play_music("boss")
	else:
		Sfx.restore_music()


## Short freeze on a solid hit. Real-time timer so the freeze itself is not slowed.
func hit_stop(duration := 0.06, scale := 0.08) -> void:
	if Engine.time_scale < base_time_scale:
		return
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = base_time_scale


## What the player should be doing right now, for the HUD.
func objective_text() -> String:
	return str(objective().text)


## The current objective: the HUD line plus where it is, so the level can point at it.
## kind is npc, boss, pickup, trigger, exit, survive or done; who names the npc, pickup kinds or trigger.
func objective() -> Dictionary:
	var fish: int = inventory.get("fish", 0)
	var roots: int = inventory.get("roots", 0)
	var f := flags
	var here := current_map
	if not f.get("begter", false):
		if fish >= 2:
			return _obj("Begter is coming for the fish" if here == "riverbank" else "Begter waits at the river", "riverbank", "boss")
		var need := []
		if roots < 3:
			need.append("roots")
		if fish < 2:
			need.append("fish")
		return _obj("River: gather roots %d/3 and fish %d/2" % [mini(roots, 3), mini(fish, 2)], "riverbank", "pickup", ",".join(need))
	if not f.get("thanked", false):
		return _obj("Return to Hoelun at the camp", "camp", "npc", "hoelun")
	if not f.get("targhutai", false):
		return _obj("The Tayichiud hunt in the forest to the east", "burkhan", "boss")
	if not f.get("thanked2", false):
		return _obj("Tell Hoelun about Targhutai", "camp", "npc", "hoelun")
	if not f.get("captured", false):
		return _obj("Scout the Tayichiud camp to the north-east", "tayichiud", "exit")
	if f.get("cangue", false) and not f.get("cangue_river", false):
		return _obj("Slip past the guards to the river", "tayichiud", "trigger", "cangue_river")
	if not f.get("cangue_off", false):
		return _obj("Find Sorkan-Shira in his ger", "sorkan", "npc", "sorkanshira")
	if not f.get("captain", false):
		return _obj("The captain has found you", "sorkan", "boss")
	if not f.get("thanked3", false):
		return _obj("Return to Hoelun at the camp", "camp", "npc", "hoelun")
	if not f.get("thieves", false):
		var txt := "Follow the horse thieves' tracks east" if here != "thieves" else "Ride down the thieves and take back the geldings"
		return _obj(txt, "thieves", "boss" if f.get("boorchu", false) else "npc", "boorchu")
	if not f.get("thanked4", false):
		return _obj("Ride home with the eight geldings", "camp", "npc", "hoelun")
	if not f.get("wedded", false):
		return _obj("Talk to Hoelun about Börte", "camp", "npc", "hoelun")
	if not f.get("sable", false):
		return _obj("Talk to Börte", "camp", "npc", "borte")
	if not f.get("ongkhan_met", false):
		return _obj("Take the sable coat to Ong Khan, south of the steppe", "ongkhan", "npc", "ongkhan")
	if not f.get("borte_taken", false) and not f.get("borte_back", false):
		return _obj("Ride home", "camp", "exit")
	if not f.get("allies_pledged", false):
		return _obj("Ask Ong Khan and Jamukha for riders", "ongkhan", "npc", "jamukha")
	if not f.get("chilger", false):
		return _obj("Raid the Merkit camp at night, east of the steppe" if here != "merkit" else "Find Börte. Kill Chilger.", "merkit", "boss")
	if not f.get("borte_back", false):
		return _obj("Find Börte in the Merkit camp", "merkit", "npc", "borte")
	if not f.get("thanked5", false):
		return _obj("Return to Hoelun", "camp", "npc", "hoelun")
	if not f.get("balzhut", false):
		return _obj("Jamukha's riders gather at Dalan Balzhut, south-west" if here != "balzhut" else "Hold the line", "balzhut", "survive")
	if not f.get("qasar", false):
		return _obj("Talk to Qasar at the camp", "camp", "npc", "qasar")
	if not f.get("tatarchief", false):
		return _obj("The Tatar camp lies to the south. Your father's killers." if here != "tatar" else "Kill the Tatar chief", "tatar", "boss")
	if not f.get("tatar_done", false):
		return _obj("Find the boy with the gold earring", "tatar", "npc", "shigi")
	if not f.get("baljuna", false):
		return _obj("Ong Khan has turned. Ride to the muddy lake, south-east" if here != "baljuna" else "Hold out with the nineteen", "baljuna", "survive")
	if not f.get("senggum", false):
		return _obj("Take the Kereyit camp by night", "kereyit", "boss")
	if not f.get("jebe", false):
		return _obj("An enemy archer asks to speak", "kereyit", "npc", "jebe")
	if not f.get("subutai", false):
		return _obj("Talk to Subutai at the camp", "camp", "npc", "subutai")
	if not f.get("tayang", false):
		return _obj("The Naiman wait at Mount Naqu, far to the west" if here != "naqu" else "Break the Naiman. Kill Tayang Khan.", "naqu", "boss")
	if not f.get("jamukha", false):
		return _obj("Jamukha waits on the mountain", "naqu", "boss")
	if not f.get("kurultai", false):
		return _obj("Ride home to the Onon", "camp", "exit")
	return _obj("Chinggis Khan. The steppe is yours.", "", "done")


static func _obj(text: String, map: String, kind: String, who := "") -> Dictionary:
	return {"text": text, "map": map, "kind": kind, "who": who}


## Only the camp, the steppe and the place the story is at right now can be entered.
## Once the banner has nine tails the whole steppe is open to ride.
func exit_open(dest: String) -> bool:
	if dest == "camp" or dest == "overworld" or flags.get("finished", false):
		return true
	return dest == str(objective().map)


## Splits text into pages that fit a box of the given width and line count, breaking between
## words and, where it can, after a sentence so a page does not end mid-thought.
static func paginate(text: String, width: float, max_lines: int) -> Array:
	var font: Font = font()
	var limit := font.get_height(font_size) * max_lines + 1.0
	var pages: Array = []
	var page := ""
	for w in text.split(" ", false):
		var trial := w if page == "" else page + " " + w
		if page != "" and font.get_multiline_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y > limit:
			var cut := -1
			for mark in [". ", "! ", "? "]:
				cut = maxi(cut, page.rfind(mark))
			if cut > page.length() / 2:
				pages.append(page.substr(0, cut + 1))
				page = page.substr(cut + 2) + " " + w
			else:
				pages.append(page)
				page = w
		else:
			page = trial
	if page != "":
		pages.append(page)
	return pages


# ---------------------------------------------------------------- theme

func _setup_theme() -> void:
	var theme := Theme.new()
	theme.default_font = font()
	theme.default_font_size = font_size
	get_tree().root.theme = theme


## The game font: a medium weight so it holds up on dark panels, lining numerals for the counters,
## and optional letter spacing for faces that set their glyphs tight.
static func font() -> Font:
	if _font == null:
		var ts := TextServerManager.get_primary_interface()
		var fv := FontVariation.new()
		fv.base_font = load(font_path)
		fv.variation_opentype = {ts.name_to_tag("weight"): font_weight}
		fv.opentype_features = {ts.name_to_tag("lnum"): 1}
		fv.spacing_glyph = font_spacing
		fv.spacing_space = font_spacing
		_font = fv
	return _font


## Height of one text line in the game font, for sizing boxes.
static func line_height() -> float:
	return font().get_height(font_size)


## LabelSettings in the game font. Outline 0 for text on panels, 2 for text over the world.
static func label_settings(color := Color(0.95, 0.91, 0.82), outline := 2) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = font()
	ls.font_size = font_size
	ls.font_color = color
	ls.outline_size = outline
	ls.outline_color = Color(0.1, 0.08, 0.14)
	return ls


# ---------------------------------------------------------------- input

func _setup_input() -> void:
	_action("move_left", [KEY_A, KEY_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_action("move_right", [KEY_D, KEY_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_action("move_up", [KEY_W, KEY_UP], JOY_AXIS_LEFT_Y, -1.0)
	_action("move_down", [KEY_S, KEY_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_action("attack", [KEY_J, KEY_Z], -1, 0.0, JOY_BUTTON_X)
	_action("bow", [KEY_K, KEY_X], -1, 0.0, JOY_BUTTON_Y)
	_action("roll", [KEY_SPACE, KEY_L, KEY_SHIFT], -1, 0.0, JOY_BUTTON_A)
	_action("interact", [KEY_E, KEY_ENTER], -1, 0.0, JOY_BUTTON_B)
	_action("pause", [KEY_ESCAPE], -1, 0.0, JOY_BUTTON_START)
	_action("fullscreen", [KEY_F11, KEY_F], -1, 0.0)
	_action("ability", [KEY_Q, KEY_C], -1, 0.0, JOY_BUTTON_RIGHT_SHOULDER)
	_action("swap", [KEY_TAB], -1, 0.0, JOY_BUTTON_LEFT_SHOULDER)


func _action(name: String, keys: Array, axis: int, axis_value: float, button: int = -1) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.4)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(name, ev)
	if axis >= 0:
		var m := InputEventJoypadMotion.new()
		m.axis = axis
		m.axis_value = axis_value
		InputMap.action_add_event(name, m)
	if button >= 0:
		var b := InputEventJoypadButton.new()
		b.button_index = button
		InputMap.action_add_event(name, b)


# ---------------------------------------------------------------- test hooks

func _jump() -> void:
	debug("jump to level " + pending_map)
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _screenshot_and_quit() -> void:
	for i in 50:
		await get_tree().process_frame
	if OS.get_environment("ANDA_AUTO") != "":
		await _autoplay(OS.get_environment("ANDA_AUTO"))
	if OS.get_environment("ANDA_SHOT") != "":
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(OS.get_environment("ANDA_SHOT"))
		print("screenshot saved")
	get_tree().quit()


## Scripted input for automated checks: "left:1.0,attack,wait:0.3,bow:0.4,roll,interact".
func _autoplay(script: String) -> void:
	for step in script.split(","):
		var parts := step.split(":")
		var action := parts[0]
		var dur := float(parts[1]) if parts.size() > 1 else 0.0
		if action == "wait":
			await get_tree().create_timer(dur, true).timeout
			continue
		if action == "killboss":
			var boss := get_tree().get_first_node_in_group("boss")
			if boss != null:
				boss.call("_die")
			continue
		var name := "move_" + action if action in ["left", "right", "up", "down"] else action
		debug("auto " + name)
		var ev := InputEventAction.new()
		ev.action = name
		ev.pressed = true
		ev.strength = 1.0
		Input.parse_input_event(ev)
		await get_tree().create_timer(maxf(dur, 0.06), true).timeout
		var up := InputEventAction.new()
		up.action = name
		up.pressed = false
		Input.parse_input_event(up)
		await get_tree().process_frame


static func debug(msg: String) -> void:
	if OS.has_environment("ANDA_DEBUG"):
		print("[anda] ", msg)
