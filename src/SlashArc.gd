class_name SlashArc
extends Node2D
## A procedural sword sweep: an arc that grows around the attacker in the facing direction.
## direction +1 sweeps clockwise on screen, -1 anticlockwise, so consecutive attacks alternate.

var radius := 30.0
var start := 0.0
var sweep := 2.2
var dur := 0.13
var t := 0.0
var width := 5.0
var tint := Color(1.0, 0.95, 0.8)


static func spawn(parent: Node, pos: Vector2, centre_angle: float, direction: int, radius_px := 30.0, color := Color(1.0, 0.95, 0.8)) -> SlashArc:
	var s := SlashArc.new()
	s.position = pos
	s.radius = radius_px
	s.sweep = 2.3 * float(direction)
	s.start = centre_angle - s.sweep / 2.0
	s.tint = color
	s.z_index = 5
	parent.add_child(s)
	return s


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t > dur + 0.1:
		queue_free()


func _draw() -> void:
	var k := clampf(t / dur, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - k, 2.0)
	var a_end := start + sweep * eased
	var fade := 1.0 - clampf((t - dur) / 0.1, 0.0, 1.0)
	var a_trail := start + sweep * maxf(0.0, eased - 0.6)
	if absf(a_end - a_trail) < 0.01:
		return
	draw_arc(Vector2.ZERO, radius, a_trail, a_end, 18, Color(tint, 0.5 * fade), width * 1.8, false)
	draw_arc(Vector2.ZERO, radius + 1.0, a_trail + (a_end - a_trail) * 0.45, a_end, 12, Color(1, 1, 1, fade), width * 0.7, false)
