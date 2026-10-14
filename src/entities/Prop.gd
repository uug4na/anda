class_name Prop
extends StaticBody2D
## Static scenery built from a config table. The node position is the feet (bottom centre),
## which is what the world's y-sort uses.

const CONFIG := {
	"larch": {"tex": "props/prop_larch_trees_3.png", "cell": 128, "cols": 3, "idx": [0, 1, 2], "col": Rect2(-8, -10, 16, 10)},
	"pine": {"tex": "props/prop_pine_trees_2.png", "cell": 128, "cols": 2, "idx": [0, 1], "col": Rect2(-8, -10, 16, 10)},
	"boulder": {"tex": "props/prop_boulders_3.png", "cell": 96, "cols": 3, "idx": [0, 1, 2],
		"col_by_variant": [Rect2(-10, -12, 20, 12), Rect2(-18, -20, 36, 20), Rect2(-26, -26, 52, 26)]},
	"bush": {"tex": "props/prop_bush_grass_grid.png", "cell": 48, "cols": 4, "idx": [0, 1, 2]},
	"tallgrass": {"tex": "props/prop_bush_grass_grid.png", "cell": 48, "cols": 4, "idx": [4], "anim": [4, 5], "fps": 2.0},
	"ger": {"tex": "props/prop_ger_medium.png", "col": Rect2(-70, -66, 140, 66)},
	"ger_small": {"tex": "props/prop_ger_small.png", "col": Rect2(-54, -52, 108, 52)},
	"ger_enemy": {"tex": "props/prop_ger_enemy.png", "col": Rect2(-68, -66, 136, 66)},
	"campfire": {"tex": "props/prop_small_grid01.png", "cell": 64, "cols": 4, "idx": [0], "anim": [0, 1, 2, 3], "fps": 8.0, "col": Rect2(-14, -12, 28, 12)},
	"haystack": {"tex": "props/prop_haystack.png", "col": Rect2(-26, -28, 52, 28)},
	"hitching": {"tex": "props/prop_hitching_line.png", "col": Rect2(-56, -8, 112, 8)},
	"ovoo": {"tex": "props/prop_ovoo.png", "col": Rect2(-22, -22, 44, 22)},
	"banner": {"tex": "props/prop_banner_10states.png", "cell": 128, "cols": 5, "idx": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], "col": Rect2(-6, -8, 12, 8)},
	"cart": {"tex": "props/prop_oxcart.png", "col": Rect2(-40, -22, 80, 22)},
	"torch": {"tex": "props/prop_torch_4f.png", "cell": 64, "cols": 4, "idx": [0], "anim": [0, 1, 2, 3], "fps": 8.0, "col": Rect2(-4, -6, 8, 6)},
	"fence_h": {"tex": "props/prop_fence_pieces.png", "cell": 48, "cols": 4, "idx": [0], "col": Rect2(-24, -10, 48, 10)},
	"fence_v": {"tex": "props/prop_fence_pieces.png", "cell": 48, "cols": 4, "idx": [1], "col": Rect2(-6, -44, 12, 44)},
	"sheep": {"tex": "animals/animal_small_grid01.png", "cell": 48, "cols": 4, "idx": [4, 6, 7], "col": Rect2(-14, -10, 28, 10)},
	"horse": {"tex": "animals/animal_horse_bay_idle_3dir.png", "cell": 144, "cols": 3, "idx": [0, 2], "col": Rect2(-28, -14, 56, 14)},
	"wool_cart": {"tex": "props/prop_wool_cart.png", "col": Rect2(-40, -22, 80, 22), "fallback": "cart"},
	"palisade_h": {"tex": "props/prop_palisade_grid.png", "cell": 48, "cols": 4, "idx": [0], "col": Rect2(-24, -12, 48, 12), "fallback": "fence_h"},
	"palisade_v": {"tex": "props/prop_palisade_grid.png", "cell": 48, "cols": 4, "idx": [1], "col": Rect2(-8, -44, 16, 44), "fallback": "fence_v"},
	"merkit_standard": {"tex": "props/prop_merkit_standard.png", "col": Rect2(-6, -8, 12, 8), "fallback": "banner"},
	"cauldron": {"tex": "props/prop_cauldron_4f.png", "cell": 64, "cols": 4, "idx": [0], "anim": [0, 1, 2, 3], "fps": 6.0, "col": Rect2(-20, -16, 40, 16), "fallback": "campfire"},
	"golden_tent": {"tex": "props/prop_golden_tent.png", "col": Rect2(-72, -70, 144, 70), "fallback": "ger"},
}

var kind := ""
var cfg := {}
var sprite: Node2D
var hero_ref: Node2D


func _ready() -> void:
	set_process(kind == "larch" or kind == "pine")


## Trees turn see-through while the hero walks behind them, so the woods never hide the way.
func _process(delta: float) -> void:
	if hero_ref == null or not is_instance_valid(hero_ref):
		hero_ref = get_tree().get_first_node_in_group("hero")
		if hero_ref == null:
			return
	var d := hero_ref.global_position - global_position
	var behind := d.y < 2.0 and d.y > -118.0 and absf(d.x) < 52.0
	sprite.modulate.a = move_toward(sprite.modulate.a, 0.4 if behind else 1.0, delta * 5.0)


static func make(kind_name: String, variant: int = -1) -> Prop:
	var cfg_try: Dictionary = CONFIG[kind_name]
	if cfg_try.has("fallback") and not ResourceLoader.exists(Sheets.ROOT + cfg_try.tex):
		return make(cfg_try.fallback, variant)
	var p := Prop.new()
	p.kind = kind_name
	p.cfg = CONFIG[kind_name]
	p.collision_layer = 1
	p.collision_mask = 0
	var height: int
	if p.cfg.has("anim"):
		var a := AnimatedSprite2D.new()
		a.sprite_frames = Sheets.anim(p.cfg.tex, p.cfg.cell, p.cfg.cell, p.cfg.fps, true, p.cfg.anim)
		a.play("default")
		a.frame = randi() % p.cfg.anim.size()
		p.sprite = a
		height = p.cfg.cell
	elif p.cfg.has("cell"):
		var s := Sprite2D.new()
		p.sprite = s
		height = p.cfg.cell
		p.set_variant(variant)
	else:
		var s := Sprite2D.new()
		s.texture = Sheets.tex(p.cfg.tex)
		p.sprite = s
		height = s.texture.get_height()
	p.sprite.position = Vector2(0, -height / 2.0)
	p.add_child(p.sprite)
	var col = p.cfg.get("col")
	if p.cfg.has("col_by_variant"):
		col = p.cfg.col_by_variant[clampi(variant, 0, p.cfg.col_by_variant.size() - 1)]
	if col != null:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = col.size
		shape.shape = rect
		shape.position = col.position + col.size / 2.0
		p.add_child(shape)
	if kind_name == "campfire":
		var reach := Area2D.new()
		reach.collision_layer = 1 << 8
		reach.collision_mask = 0
		var rs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 34.0
		rs.shape = circle
		rs.position = Vector2(0, -12)
		reach.add_child(rs)
		p.add_child(reach)
	return p


## Cooking at the campfire turns foraged food into health.
func interact(_hero: Node) -> void:
	if kind != "campfire":
		return
	var where: Node = get_parent()
	if Game.hp >= Game.max_hp():
		Vfx.float_text(where, global_position, "Warm. Nothing hurts right now.")
		return
	if Game.inventory.get("fish", 0) > 0:
		Game.add_item("fish", -1)
		Game.heal_hero(Game.max_hp())
		Vfx.float_text(where, global_position, "Grilled fish. Fully healed.", Color(1, 0.9, 0.7))
		Sfx.play("cook")
	elif Game.inventory.get("roots", 0) > 0:
		Game.add_item("roots", -1)
		Game.heal_hero(3)
		Vfx.float_text(where, global_position, "Roasted roots. Healed.", Color(1, 0.9, 0.7))
		Sfx.play("cook")
	else:
		Vfx.float_text(where, global_position, "Nothing to cook.")


func set_variant(variant: int) -> void:
	if not cfg.has("cell") or sprite is AnimatedSprite2D:
		return
	var idxs: Array = cfg.idx
	var i: int
	if variant >= 0:
		i = idxs[clampi(variant, 0, idxs.size() - 1)]
	else:
		i = idxs[randi() % idxs.size()]
	(sprite as Sprite2D).texture = Sheets.cell(cfg.tex, cfg.cell, i, cfg.cols)
