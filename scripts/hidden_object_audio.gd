extends Node
## Local opening-room mix. Only owner-selected recordings are used for its cues.
signal cue_played(id: String)
const CONFIG := "res://content/hidden-object-audio.json"
var cues := {}
var players := {}
var next_detail := {}
var scheduled: Array[Dictionary] = []
var music: AudioStreamPlayer
var muted := false
var music_enabled := true
var stopped := false
var ready_ok := false
var elapsed := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not data is Dictionary: return
	cues = data.cues
	for id in cues:
		var spec: Dictionary = cues[id]
		var player := AudioStreamPlayer.new()
		player.stream = load(str(spec.path))
		if player.stream == null or player.stream.get_length() <= 0:
			player.free()
			return
		# Resource-local copies keep loop flags independent of any other scene.
		player.stream = player.stream.duplicate()
		player.stream.loop = spec.kind == "loop"
		player.volume_db = float(spec.volume_db)
		add_child(player)
		players[id] = player
		if spec.kind == "periodic": next_detail[id] = _interval(spec)
	music = AudioStreamPlayer.new()
	music.stream = load(str(data.music.path))
	if music.stream == null: return
	music.stream = music.stream.duplicate()
	music.stream.loop = true
	music.volume_db = float(data.music.volume_db)
	add_child(music)
	ready_ok = true
	for id in cues:
		if cues[id].kind == "loop": players[id].play()
	music.play()

func _interval(spec: Dictionary) -> float:
	return rng.randf_range(float(spec.interval_min), float(spec.interval_max))

func _process(delta: float) -> void:
	if not ready_ok or stopped or muted: return
	elapsed += delta
	for id in next_detail:
		next_detail[id] -= delta
		if next_detail[id] <= 0:
			play_cue(id)
			# Never catch up missed ticks with a burst after a stall or mute.
			next_detail[id] = _interval(cues[id])
	if not scheduled.is_empty():
		scheduled[0].delay -= delta
		if scheduled[0].delay <= 0:
			play_cue(scheduled[0].id)
			scheduled.pop_front()

func play_cue(id: String) -> bool:
	if muted or stopped or not ready_ok or not players.has(id): return false
	var player: AudioStreamPlayer = players[id]
	# One voice per cue prevents rapid repeated clicking from stacking transients.
	if player.playing: return false
	player.play()
	cue_played.emit(id)
	return true

func finish_search(recorded := true) -> void:
	if muted or stopped or not ready_ok: return
	cancel_reward()
	play_cue("search_completed")
	scheduled = [{"id":"receipt_recovered", "delay":1.5}]
	if recorded: scheduled.append({"id":"journal_updated", "delay":0.6})

func cancel_reward() -> void:
	scheduled.clear()
	for id in ["search_completed", "receipt_recovered", "journal_updated"]:
		if players.has(id): players[id].stop()

func set_muted(value: bool) -> void:
	muted = value
	# Do not replay actions that happened while the listener muted the game.
	scheduled.clear()
	for id in players:
		if cues[id].kind == "loop": players[id].stream_paused = muted
		elif muted: players[id].stop()
	if is_instance_valid(music): music.stream_paused = muted or not music_enabled

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	if is_instance_valid(music): music.stream_paused = muted or not music_enabled

func stop_all() -> void:
	stopped = true
	scheduled.clear()
	for player in players.values():
		player.stop()
		player.stream = null
	if is_instance_valid(music):
		music.stop()
		music.stream = null

func _exit_tree() -> void:
	stop_all()
