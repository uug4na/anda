extends Node
## Sound and music. Autoloaded as "Sfx".
## Effects are recorded samples in assets/audio/sfx: name.ogg, or name_1.ogg, name_2.ogg ... picked at
## random for variety. Any name without a file falls back to a small synthesised sound.
## Music is one track per map in assets/audio/music/<map>.mp3 (or .ogg), crossfaded on change.

const RATE := 22050
const MUSIC_DB := -6.0
const QUIET_DB := -40.0

var streams := {}
var samples := {}
var players: Array = []
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var current: AudioStreamPlayer
var ambience: AudioStreamPlayer
var rng := RandomNumberGenerator.new()
var map_track := ""
var current_track := ""

## Maps that share a track with another map.
const MUSIC_FOR := {"sorkan": "camp"}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.seed = 7
	_make_buses()
	streams["swoosh"] = _wav(0.13, _gen_swoosh)
	streams["hit"] = _wav(0.14, _gen_hit)
	streams["arrow"] = _wav(0.16, _gen_arrow)
	streams["pickup"] = _wav(0.16, _gen_pickup)
	streams["hurt"] = _wav(0.2, _gen_hurt)
	streams["ui"] = _wav(0.06, _gen_ui)
	streams["dodge"] = _wav(0.14, _gen_dodge)
	streams["enemy_die"] = _wav(0.32, _gen_die)
	streams["boss"] = _wav(0.6, _gen_boss)
	streams["cook"] = _wav(0.35, _gen_cook)
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "Sfx"
		add_child(p)
		players.append(p)
	ambience = AudioStreamPlayer.new()
	ambience.bus = "Sfx"
	ambience.volume_db = -22.0
	add_child(ambience)
	var wind := _wav(4.0, _gen_wind)
	wind.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wind.loop_end = int(4.0 * RATE)
	ambience.stream = wind
	music_a = _music_player()
	music_b = _music_player()
	current = music_a
	Settings.apply()


func _make_buses() -> void:
	for bus_name in ["Music", "Sfx"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var i := AudioServer.bus_count
			AudioServer.add_bus(i)
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")


func _music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.volume_db = MUSIC_DB
	add_child(p)
	return p


# ---------------------------------------------------------------- effects

func play(name: String, volume_db := 0.0, pitch_jitter := 0.08) -> void:
	var stream := _sample(name)
	if stream == null:
		return
	for p in players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = 1.0 + rng.randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return


## All recorded takes of one effect, loaded once; a random one each time it plays.
func _sample(name: String) -> AudioStream:
	if not samples.has(name):
		var list: Array = []
		for ext in ["ogg", "wav", "mp3"]:
			var single := "res://assets/audio/sfx/%s.%s" % [name, ext]
			if ResourceLoader.exists(single):
				list.append(load(single))
			for i in range(1, 10):
				var path := "res://assets/audio/sfx/%s_%d.%s" % [name, i, ext]
				if ResourceLoader.exists(path):
					list.append(load(path))
		samples[name] = list
	var takes: Array = samples[name]
	if takes.is_empty():
		return streams.get(name)
	return takes[rng.randi_range(0, takes.size() - 1)]


# ---------------------------------------------------------------- music

## Called when a map starts: its own track, or the one it shares, else silence under the wind.
func start_map_audio(map_id: String) -> void:
	map_track = str(MUSIC_FOR.get(map_id, map_id))
	play_music(map_track)
	if not ambience.playing:
		ambience.play()


func _music_path(name: String) -> String:
	for ext in ["mp3", "ogg", "wav"]:
		var candidate := "res://assets/audio/music/%s.%s" % [name, ext]
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func play_music(name: String) -> void:
	if name == current_track and current.playing:
		return
	var path := _music_path(name)
	if path == "":
		_fade_out(current)
		current_track = ""
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var next := music_b if current == music_a else music_a
	var old := current
	next.stream = stream
	next.volume_db = QUIET_DB
	next.play()
	var tw := create_tween()
	tw.tween_property(next, "volume_db", MUSIC_DB, 1.2).set_trans(Tween.TRANS_SINE)
	_fade_out(old)
	current = next
	current_track = name


func _fade_out(p: AudioStreamPlayer) -> void:
	if p == null or not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", QUIET_DB, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		if p.volume_db <= QUIET_DB + 0.5:
			p.stop())


func restore_music() -> void:
	if map_track != "":
		play_music(map_track)


# ---------------------------------------------------------------- synthesised fallbacks

func _wav(seconds: float, gen: Callable) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var state := {"lp": 0.0, "noise": 0.0}
	for i in n:
		var k := float(i) / n
		var t := float(i) / RATE
		var v: float = clampf(gen.call(k, t, state), -1.0, 1.0)
		var s := int(v * 32767.0)
		bytes.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w


func _noise() -> float:
	return rng.randf_range(-1.0, 1.0)


func _lp(state: Dictionary, x: float, a: float) -> float:
	state.lp += a * (x - state.lp)
	return state.lp


func _gen_swoosh(k: float, _t: float, st: Dictionary) -> float:
	var a := 0.08 + 0.5 * sin(k * PI)
	return _lp(st, _noise(), a) * sin(k * PI) * 0.9


func _gen_hit(k: float, t: float, st: Dictionary) -> float:
	return _lp(st, _noise(), 0.5) * exp(-k * 14.0) * 0.8 + sin(TAU * 85.0 * t) * exp(-k * 9.0) * 0.7


func _gen_arrow(k: float, _t: float, st: Dictionary) -> float:
	return _lp(st, _noise(), 0.25 + 0.5 * k) * pow(1.0 - k, 2.0) * 0.6


func _gen_pickup(k: float, t: float, _st: Dictionary) -> float:
	var f := 660.0 if k < 0.5 else 990.0
	var env := exp(-fmod(k, 0.5) * 9.0)
	return sin(TAU * f * t) * env * 0.4


func _gen_hurt(k: float, t: float, _st: Dictionary) -> float:
	var sq := 1.0 if fmod(t * 110.0, 1.0) < 0.5 else -1.0
	return sq * exp(-k * 6.0) * 0.35 + sin(TAU * 55.0 * t) * exp(-k * 5.0) * 0.4


func _gen_ui(k: float, t: float, _st: Dictionary) -> float:
	return sin(TAU * 880.0 * t) * exp(-k * 12.0) * 0.3


func _gen_dodge(k: float, _t: float, st: Dictionary) -> float:
	return _lp(st, _noise(), 0.15) * sin(k * PI) * 0.5


func _gen_die(k: float, t: float, st: Dictionary) -> float:
	var f := 220.0 - 160.0 * k
	return sin(TAU * f * t) * exp(-k * 5.0) * 0.5 + _lp(st, _noise(), 0.3) * exp(-k * 8.0) * 0.4


func _gen_boss(k: float, t: float, st: Dictionary) -> float:
	return sin(TAU * 50.0 * t) * exp(-k * 4.0) * 0.8 + _lp(st, _noise(), 0.1) * exp(-k * 6.0) * 0.5


func _gen_cook(k: float, t: float, st: Dictionary) -> float:
	var crackle := _lp(st, _noise(), 0.6) * (0.3 if fmod(t * 37.0, 1.0) < 0.2 else 0.08)
	return crackle * (1.0 - k) + sin(TAU * 440.0 * t) * exp(-k * 10.0) * 0.2


func _gen_wind(k: float, t: float, st: Dictionary) -> float:
	var swell := 0.55 + 0.45 * sin(TAU * 0.25 * t + sin(TAU * 0.07 * t) * 2.0)
	var fade := minf(1.0, minf(k, 1.0 - k) * 10.0)
	return _lp(st, _noise(), 0.03) * swell * 0.9 * fade
