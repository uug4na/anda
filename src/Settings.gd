class_name Settings
extends RefCounted
## Player settings: volumes, fullscreen and key bindings. One JSON file in the user directory.

const PATH := "user://anda_settings.json"

## The actions a player may rebind, in the order the settings screen lists them.
const BINDABLE := [
	["move_up", "Move up"], ["move_down", "Move down"], ["move_left", "Move left"], ["move_right", "Move right"],
	["attack", "Sword"], ["bow", "Bow"], ["roll", "Roll"], ["interact", "Talk / use"],
	["ability", "Companion"], ["swap", "Switch companion"], ["pause", "Pause"],
]

static var music := 7
static var sound := 8
static var fullscreen := false
static var keys := {}
static var loaded := false
static var _names := {}


static func load_file() -> void:
	loaded = true
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return
	music = clampi(int(parsed.get("music", music)), 0, 10)
	sound = clampi(int(parsed.get("sound", sound)), 0, 10)
	fullscreen = bool(parsed.get("fullscreen", fullscreen))
	keys = {}
	for action in parsed.get("keys", {}):
		keys[str(action)] = int(parsed.keys[action])


static func save_file() -> void:
	Game.debug("settings saved: music %d sound %d fullscreen %s keys %s" % [music, sound, fullscreen, keys])
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"music": music, "sound": sound, "fullscreen": fullscreen, "keys": keys}, "\t"))
		f.close()


## Pushes the current values into the audio buses, the window and the input map.
static func apply() -> void:
	if not loaded:
		load_file()
	for pair in [["Music", music], ["Sfx", sound]]:
		var idx := AudioServer.get_bus_index(pair[0])
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx, linear_to_db(float(pair[1]) / 10.0) if pair[1] > 0 else -80.0)
			AudioServer.set_bus_mute(idx, pair[1] == 0)
	if OS.get_name() != "Web":
		var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen != is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	for action in keys:
		bind_key(str(action), int(keys[action]), false)


## Replaces the keyboard binding of one action. Pad buttons are left alone.
static func bind_key(action: String, physical_keycode: int, remember := true) -> void:
	if not InputMap.has_action(action):
		return
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	var ev := InputEventKey.new()
	ev.physical_keycode = physical_keycode
	InputMap.action_add_event(action, ev)
	_names.clear()
	if remember:
		keys[action] = physical_keycode


## The name of the key currently bound to an action, for hints on screen. Physical key names
## (US layout) are used on purpose: they need no display server, so they work headless and in browsers.
static func key_name(action: String) -> String:
	if _names.has(action):
		return _names[action]
	var label := "?"
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				var k: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
				var s := OS.get_keycode_string(k)
				if s != "":
					label = s
				break
	_names[action] = label
	return label
