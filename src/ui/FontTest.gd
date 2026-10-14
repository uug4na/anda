extends Control
## Renders sample text in each candidate pixel font at a few sizes. Dev only.

const FONTS := ["DotGothic16-Regular.ttf", "VT323-Regular.ttf", "PixelifySans[wght].ttf", "Silkscreen-Regular.ttf"]
const SAMPLE := "Temüjin: Take your bow. 0123 / 9 Hoelun"


func _ready() -> void:
	size = Vector2(640, 360)
	var back := ColorRect.new()
	back.color = Color(0.23, 0.16, 0.1)
	back.size = size
	add_child(back)
	var y := 6
	for f in FONTS:
		var font: Font = load("res://assets/fonts/" + f)
		for s in [8, 10, 12, 16]:
			var l := Label.new()
			var ls := LabelSettings.new()
			ls.font = font
			ls.font_size = s
			ls.outline_size = 2
			ls.outline_color = Color(0.1, 0.08, 0.14)
			l.label_settings = ls
			l.text = "%s %d  %s" % [f.get_basename().substr(0, 10), s, SAMPLE]
			l.position = Vector2(6, y)
			add_child(l)
			y += s + 6
		y += 4
