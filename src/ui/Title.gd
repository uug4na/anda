extends Control
## Title screen: background painting, logo, menu.

const INTRO_IMAGE := "cutscenes/cutscene_02_abandoned_camp.png"
const INTRO_LINES := [
	"Spring, 1171. The Onon river.",
	"Yesügei is dead, poisoned at a Tatar feast. The Tayichiud took the herds and rode away.",
	"They left Hoelun with five children, a river, and a single white tail on a pole.",
	"Temüjin is nine. He has a mother, a bow, and a brother who takes what is his.",
]

var menu: Menu
var confirm: Menu
var settings: SettingsMenu
var controls: Label
var started := false


func _ready() -> void:
	Game.ui_busy = false
	get_tree().paused = false
	size = Vector2(640, 360)
	var back := ColorRect.new()
	back.color = Color(0.1, 0.08, 0.14)
	back.size = size
	add_child(back)
	var bg := TextureRect.new()
	bg.texture = Sheets.tex("ui/ui_title_background.png")
	bg.scale = Vector2(2, 2)
	bg.position = Vector2(-64, -76)
	add_child(bg)
	var logo := TextureRect.new()
	logo.texture = Sheets.tex("ui/ui_title_logo.png")
	logo.position = Vector2(120, 14)
	add_child(logo)
	var items := []
	if Save.exists():
		items.append({"id": "continue", "label": "Continue"})
	items.append({"id": "new", "label": "New game"})
	items.append({"id": "settings", "label": "Settings"})
	if OS.get_name() != "Web":
		items.append({"id": "quit", "label": "Quit"})
	menu = Menu.new()
	add_child(menu)
	menu.setup(items, "", 200)
	menu.position = Vector2(roundf((640 - menu.size.x) / 2.0), 236 - roundf(menu.size.y / 2.0))
	menu.chosen.connect(_on_chosen)
	settings = SettingsMenu.new()
	settings.visible = false
	settings.closed.connect(_on_settings_closed)
	add_child(settings)
	# Starting over with a saved game asks first.
	confirm = Menu.new()
	confirm.visible = false
	add_child(confirm)
	confirm.setup([{"id": "keep", "label": "Keep my saved game"}, {"id": "over", "label": "Start over"}], "The saved game will be lost", 300)
	confirm.position = Vector2(roundf((640 - confirm.size.x) / 2.0), 236 - roundf(confirm.size.y / 2.0))
	confirm.chosen.connect(_on_confirm)
	controls = Label.new()
	controls.label_settings = Game.label_settings(Color(0.85, 0.8, 0.7), 2)
	controls.position = Vector2(0, 336)
	controls.size = Vector2(640, 20)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(controls)
	_refresh_controls()
	var credit := Label.new()
	credit.text = "Music by Kevin MacLeod (CC BY 4.0)   Sounds by Kenney (CC0)"
	var ls := Game.label_settings(Color(0.85, 0.8, 0.7), 2)
	ls.font_size = 13
	credit.label_settings = ls
	credit.position = Vector2(0, 318)
	credit.size = Vector2(640, 18)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(credit)
	var version := Label.new()
	version.text = "Nine Tails  v1.0.0"
	version.label_settings = Game.label_settings(Color(0.85, 0.8, 0.7), 2)
	version.position = Vector2(8, 6)
	add_child(version)
	Sfx.start_map_audio("title")
	Game.debug("title ready")


func _start_new() -> void:
	started = true
	Game.new_game()
	Game.play_cutscene(INTRO_IMAGE, INTRO_LINES, "camp")


func _on_confirm(id: String) -> void:
	confirm.visible = false
	if id == "over":
		_start_new()
	else:
		menu.visible = true
		menu.guard = 0.25


## The controls line follows the current key bindings.
func _refresh_controls() -> void:
	var move := "%s%s%s%s" % [Settings.key_name("move_up"), Settings.key_name("move_left"), Settings.key_name("move_down"), Settings.key_name("move_right")]
	controls.text = "%s move   %s sword   %s bow   %s roll   %s talk   %s menu" % [move, Settings.key_name("attack"), Settings.key_name("bow"), Settings.key_name("roll"), Settings.key_name("interact"), Settings.key_name("pause")]


func _on_settings_closed() -> void:
	menu.visible = true
	menu.guard = 0.25
	_refresh_controls()


func _on_chosen(id: String) -> void:
	Game.debug("title chose " + id)
	if started:
		return
	match id:
		"settings":
			menu.visible = false
			settings.open()
		"continue":
			started = true
			Game.load_save()
		"new":
			if Save.exists():
				menu.visible = false
				confirm.visible = true
				confirm.index = 0
				confirm._highlight()
				confirm.guard = 0.25
				return
			_start_new()
		"quit":
			get_tree().quit()
