class_name Save
extends RefCounted
## One JSON save slot in the user directory.

const PATH := "user://anda_save.json"


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func write(map_id: String, pos: Vector2) -> void:
	Game.debug("save write: map %s pos %s pending_map %s hero_in_tree %s" % [map_id, pos, Game.pending_map, Game.get_tree().get_first_node_in_group("hero") != null])
	var data := {
		"version": 1,
		"hp": Game.hp, "arrows": Game.arrows, "tails": Game.tails,
		"inventory": Game.inventory, "flags": Game.flags,
		"map": map_id, "x": pos.x, "y": pos.y,
		"saved_at": Time.get_datetime_string_from_system(),
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


static func read() -> Dictionary:
	if not exists():
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


static func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
