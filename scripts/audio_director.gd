class_name AudioDirector
extends Node
## Offline mixer for authored music, field ambience, effects and recorded voices.
## No network access, system speech or fabricated speech fallback is used here.

signal voice_started(line_id: String)
signal voice_finished(line_id: String)
signal sequence_finished()

const CROSSFADE_SECONDS := 1.5
const VOICE_FADE_SECONDS := 0.055
const DEFAULT_VOLUMES := {"music": 0.65, "ambience": 0.5, "sound": 0.8, "voice": 0.9, "subtitles": true, "auto_voice": true}
const BASE_GAIN := {"music": 0.52, "ambience": 0.48, "sound": 0.7, "voice": 0.79}
const SILENCE_DB := -80.0
const VOICE_ACTIVITY_OPEN_DB := -43.0
const VOICE_ACTIVITY_CLOSE_DB := -49.0
const VOICE_ACTIVITY_HOLD_SECONDS := 0.13
const VOICE_METER_PREROLL_SECONDS := 0.10
const SFX_DIALOGUE_GAIN_DB := -4.0

var last_error := ""
var _catalog: Dictionary = {}
var _voices: Dictionary = {}
var _settings: Dictionary = DEFAULT_VOLUMES.duplicate()
var _groups: Dictionary = {}
var _voice_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_random := RandomNumberGenerator.new()
var _sfx_last_paths: Dictionary = {}
var _sfx_ready_at: Dictionary = {}
var _sfx_started := 0
var _sfx_last_event: Dictionary = {}
var _stream_cache: Dictionary = {}
var _voice_id := ""
var _voice_queue: Array = []
var _last_sequence: Array = []
var _voice_epoch := 0
var _voice_callback: Callable
var _voice_weight := 0.0
var _voice_target := 0.0
var _voice_entry_gain := 1.0
var _pending_voice_start := false
var _pending_voice_stop := false
var _duck := 1.0
var _mix_bus := ""
var _voice_bus := ""
var _voice_meter: AudioEffectCapture
var _voice_activity := false
var _voice_activity_hold := 0.0
var _voice_peak_db := SILENCE_DB
var _voice_meter_preroll := 0.0
var _configured := false


func _init() -> void:
	# Publish this frame's activity before the presentation reads it.
	process_priority = -10
	_sfx_random.randomize()


func configure(audio_catalog: Dictionary, voice_catalog: Dictionary, settings: Dictionary) -> void:
	_ensure_players()
	stop_all()
	_catalog = audio_catalog.duplicate(true)
	_voices = voice_catalog.get("lines", {}).duplicate(true)
	_sfx_last_paths.clear()
	_sfx_ready_at.clear()
	_sfx_started = 0
	_sfx_last_event.clear()
	set_volumes(settings)
	_configured = true
	last_error = ""


func _ensure_players() -> void:
	if is_instance_valid(_voice_player): return
	_mix_bus = "QuietMeridianMix_" + str(get_instance_id())
	AudioServer.add_bus()
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, _mix_bus)
	AudioServer.set_bus_send(bus_index, "Master")
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -0.8
	limiter.release = 0.12
	AudioServer.add_bus_effect(bus_index, limiter)
	# Meter speech before the final game mix: music, ambience and effects must
	# never move a character's mouth. The bus is transient and works for every
	# audio format decoded by Godot, without waveform sidecars or network calls.
	_voice_bus = "QuietMeridianVoice_" + str(get_instance_id())
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, _voice_bus)
	AudioServer.set_bus_send(AudioServer.bus_count - 1, _mix_bus)
	_voice_meter = AudioEffectCapture.new()
	_voice_meter.buffer_length = 0.25
	AudioServer.add_bus_effect(AudioServer.bus_count - 1, _voice_meter)
	for kind in ["music", "ambience"]:
		_groups[kind] = {"players": [_player(), _player()], "weights": [0.0, 0.0],
			"starts": [0.0, 0.0], "targets": [0.0, 0.0], "entry_gains": [1.0, 1.0],
			"active": -1, "cue": "", "playback_key": "", "playback_id": "", "pending": "", "fading": false, "elapsed": 0.0}
	_voice_player = _player()
	_voice_player.bus = _voice_bus
	for _i in range(8): _sfx_players.append(_player())


func _player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = SILENCE_DB
	player.bus = _mix_bus
	add_child(player)
	return player


func set_volumes(settings: Dictionary) -> void:
	for key in DEFAULT_VOLUMES:
		var value: Variant = settings.get(key, DEFAULT_VOLUMES[key])
		if DEFAULT_VOLUMES[key] is bool:
			_settings[key] = value if value is bool else DEFAULT_VOLUMES[key]
		else:
			_settings[key] = clampf(float(value), 0.0, 1.0) if (value is int or value is float) and is_finite(float(value)) else DEFAULT_VOLUMES[key]
	_apply_mix()
	if float(_settings.voice) <= 0.0001: _reset_voice_activity()


func play_music(cue: String) -> void:
	_switch_group("music", cue)


func set_ambience(cue: String) -> void:
	_switch_group("ambience", cue)


func _switch_group(kind: String, cue: String) -> void:
	if not _configured: return
	var group: Dictionary = _groups[kind]
	if cue == group.cue and _any_playing(group.players):
		group.pending = ""
		return
	var entry := _entry(kind, cue)
	if entry.is_empty() or _load_stream(str(entry.get("path", "")), bool(entry.get("loop", true))) == null:
		last_error = "Audio cue is unavailable: " + kind + "/" + cue
		return
	# An explicit shared identity keeps the same decoder running across title,
	# chapter and menu cues. Ordinary cues retain their existing crossfades even
	# when they happen to reference the same source file.
	if _playback_key(cue, entry) == group.playback_key and int(group.active) >= 0 and group.players[group.active].playing:
		group.cue = cue
		group.pending = ""
		group.entry_gains[group.active] = db_to_linear(clampf(float(entry.get("gain_db", 0.0)), -40.0, 6.0))
		last_error = ""
		return
	# A rapid room change replaces the pending destination, not an audible
	# player halfway through its fade. This avoids chopping a tail mid-sample.
	if group.fading:
		group.pending = cue
		return
	_start_group(kind, cue, entry)


func _playback_key(cue: String, entry: Dictionary) -> String:
	var shared: Variant = entry.get("playback_id", "")
	if shared is String and not shared.is_empty():
		# Reusing an ID for a different file or loop policy cannot silently keep
		# the wrong track playing.
		return JSON.stringify([shared, str(entry.get("path", "")), bool(entry.get("loop", true))])
	return "cue:" + cue


func _start_group(kind: String, cue: String, entry: Dictionary) -> void:
	var group: Dictionary = _groups[kind]
	var next: int = 0 if int(group.active) < 0 else 1 - int(group.active)
	var player: AudioStreamPlayer = group.players[next]
	player.stop()
	player.stream = _load_stream(str(entry.path), bool(entry.get("loop", true)))
	if player.stream == null: return
	group.entry_gains[next] = db_to_linear(clampf(float(entry.get("gain_db", 0.0)), -40.0, 6.0))
	group.starts = group.weights.duplicate()
	group.targets = [0.0, 0.0]
	group.targets[next] = 1.0
	group.elapsed = 0.0
	group.fading = true
	group.active = next
	group.cue = cue
	group.playback_key = _playback_key(cue, entry)
	group.playback_id = str(entry.get("playback_id", ""))
	group.pending = ""
	player.volume_db = SILENCE_DB
	player.play()
	last_error = ""


func play_sfx(cue: String) -> void:
	if not _configured: return
	var entry := _entry("sfx", cue)
	if entry.is_empty():
		last_error = "Sound effect is unavailable: " + cue
		return
	# Muted clicks are not queued to appear later when sound is enabled.
	if float(_settings.sound) <= 0.0001: return
	var now := Time.get_ticks_msec()
	if now < int(_sfx_ready_at.get(cue, 0)): return
	# A burst of UI activity never steals a dialogue or music player.
	for player in _sfx_players:
		if not player.playing:
			var selected := _select_sfx(cue, entry)
			if selected.is_empty():
				last_error = "Sound effect could not be loaded: " + cue
				return
			player.stream = selected.stream
			player.pitch_scale = _sfx_pitch(entry)
			var gain_db := clampf(_finite_number(entry.get("gain_db", 0.0), 0.0), -40.0, 0.0)
			var gain := db_to_linear(gain_db)
			player.set_meta("entry_gain", gain)
			player.set_meta("source_path", selected.path)
			player.volume_db = _db(float(_settings.sound) * float(BASE_GAIN.sound) * gain * _sfx_duck_gain())
			player.play()
			_sfx_last_paths[cue] = selected.path
			var cooldown := clampf(_finite_number(entry.get("cooldown_seconds", 0.0), 0.0), 0.0, 1.0)
			_sfx_ready_at[cue] = now + int(round(cooldown * 1000.0))
			_sfx_started += 1
			_sfx_last_event = {"cue": cue, "path": selected.path, "pitch": player.pitch_scale,
				"gain_db": gain_db, "started_msec": now}
			last_error = ""
			return
	# The finite pool deliberately drops excess effects instead of cutting a tail.
	# A dropped request consumes neither a cooldown nor a variation choice.


func _select_sfx(cue: String, entry: Dictionary) -> Dictionary:
	var paths: Array[String] = []
	var variants: Variant = entry.get("variants", [])
	if variants is Array:
		for value in variants:
			if value is String and not value.is_empty() and not value in paths:
				paths.append(value)
	var primary := str(entry.get("path", ""))
	if not primary.is_empty() and not primary in paths: paths.append(primary)
	var previous := str(_sfx_last_paths.get(cue, ""))
	var remaining: Array[String] = []
	for path in paths:
		if path != previous: remaining.append(path)
	while not remaining.is_empty():
		var index := _sfx_random.randi_range(0, remaining.size() - 1)
		var path: String = remaining[index]
		remaining.remove_at(index)
		var stream := _load_stream(path, false)
		if stream != null: return {"path": path, "stream": stream}
	# Single-file cues and a damaged variation set still have a safe fallback.
	if previous in paths:
		var stream := _load_stream(previous, false)
		if stream != null: return {"path": previous, "stream": stream}
	return {}


func _sfx_pitch(entry: Dictionary) -> float:
	var bounds: Variant = entry.get("pitch_range", [1.0, 1.0])
	if not bounds is Array or bounds.size() != 2: return 1.0
	var first := clampf(_finite_number(bounds[0], 1.0), 0.9, 1.1)
	var second := clampf(_finite_number(bounds[1], 1.0), 0.9, 1.1)
	return _sfx_random.randf_range(minf(first, second), maxf(first, second))


func _finite_number(value: Variant, fallback: float) -> float:
	return float(value) if (value is float or value is int) and is_finite(float(value)) else fallback


func _sfx_duck_gain() -> float:
	return lerpf(db_to_linear(SFX_DIALOGUE_GAIN_DB), 1.0, clampf((_duck - 0.25) / 0.75, 0.0, 1.0))


func has_voice(line_id: String) -> bool:
	if not _voices.has(line_id) or not _voices[line_id] is Dictionary: return false
	var path := str(_voices[line_id].get("path", ""))
	return not path.is_empty() and _load_stream(path, false) != null


func play_voice(line_id: String) -> bool:
	return play_sequence([line_id])


func play_sequence(ids: Array) -> bool:
	if not _configured or ids.is_empty():
		return false
	for id in ids:
		if not id is String or not has_voice(str(id)):
			stop_voice()
			last_error = "Recorded voice is not available for " + str(id) + ". The written dialogue remains available."
			return false
	stop_voice()
	_voice_queue = ids.duplicate()
	_last_sequence = ids.duplicate()
	if _voice_player.playing:
		_pending_voice_start = true
	else:
		_pending_voice_stop = false
		_next_voice()
	last_error = ""
	return true


func stop_voice() -> void:
	_reset_voice_activity()
	_voice_epoch += 1
	_disconnect_voice_finished()
	_voice_queue.clear()
	_pending_voice_start = false
	_pending_voice_stop = is_instance_valid(_voice_player) and _voice_player.playing
	_voice_target = 0.0
	var previous := _voice_id
	_voice_id = ""
	if not previous.is_empty(): voice_finished.emit(previous)


func replay_voice() -> bool:
	if _last_sequence.is_empty(): return false
	return play_sequence(_last_sequence.duplicate())


func _next_voice() -> void:
	_reset_voice_activity()
	if _voice_queue.is_empty():
		_voice_id = ""
		_voice_target = 0.0
		sequence_finished.emit()
		return
	var line_id := str(_voice_queue.pop_front())
	var entry: Dictionary = _voices[line_id]
	_voice_player.stream = _load_stream(str(entry.path), false)
	if _voice_player.stream == null:
		stop_voice()
		last_error = "A recorded line could not be opened: " + line_id
		return
	_voice_epoch += 1
	_voice_id = line_id
	_voice_weight = 0.0
	_voice_target = 1.0
	_voice_entry_gain = db_to_linear(clampf(float(entry.get("gain_db", 0.0)), -40.0, 6.0))
	_voice_callback = _on_voice_finished.bind(_voice_epoch, line_id)
	_voice_player.finished.connect(_voice_callback, CONNECT_ONE_SHOT)
	_voice_player.volume_db = SILENCE_DB
	_voice_player.play()
	# Discard the previous source's in-flight mix block after a skip/replay.
	# This short onset delay is animation gating, not phoneme lip synchronization.
	_voice_meter_preroll = VOICE_METER_PREROLL_SECONDS
	voice_started.emit(line_id)


func _on_voice_finished(epoch: int, line_id: String) -> void:
	if epoch != _voice_epoch or line_id != _voice_id: return
	_voice_id = ""
	_voice_weight = 0.0
	voice_finished.emit(line_id)
	if epoch != _voice_epoch: return
	_next_voice()


func _disconnect_voice_finished() -> void:
	if is_instance_valid(_voice_player) and _voice_callback.is_valid() and _voice_player.finished.is_connected(_voice_callback):
		_voice_player.finished.disconnect(_voice_callback)
	_voice_callback = Callable()


func is_voice_playing() -> bool:
	return not _voice_id.is_empty() and is_instance_valid(_voice_player) and _voice_player.playing


func is_voice_active() -> bool:
	# Playback/queue status is separate from audible word activity. Controls and
	# subtitles remain available during pauses and untrimmed recorded silence.
	return is_voice_playing() and _voice_activity and float(_settings.voice) > 0.0001


func _reset_voice_activity() -> void:
	_voice_activity = false
	_voice_activity_hold = 0.0
	_voice_peak_db = SILENCE_DB
	_voice_meter_preroll = 0.0
	if _voice_meter != null: _voice_meter.clear_buffer()


func _update_voice_activity(delta: float) -> void:
	var gain := float(_settings.voice) * float(BASE_GAIN.voice) * _voice_entry_gain * _voice_weight
	if not is_voice_playing() or gain <= 0.0001:
		_reset_voice_activity()
		return
	if _voice_meter == null:
		_reset_voice_activity()
		return
	if _voice_meter_preroll > 0.0:
		_voice_meter_preroll = maxf(0.0, _voice_meter_preroll - maxf(delta, 0.0))
		_voice_meter.clear_buffer()
		return
	# Compensate the adjustable playback gain so a quiet volume preference does
	# not change the source's activity threshold; muting still stops gestures.
	# Consume fresh PCM instead of the editor's peak display, whose decay can
	# retain the previous word after an interruption. Nothing is recorded to disk.
	var frames := _voice_meter.get_frames_available()
	var peak := 0.0
	if frames > 0:
		for sample in _voice_meter.get_buffer(frames):
			peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
	_voice_peak_db = _db(peak / gain)
	var threshold := VOICE_ACTIVITY_CLOSE_DB if _voice_activity else VOICE_ACTIVITY_OPEN_DB
	if _voice_peak_db >= threshold:
		_voice_activity_hold = VOICE_ACTIVITY_HOLD_SECONDS
	else:
		_voice_activity_hold = maxf(0.0, _voice_activity_hold - maxf(delta, 0.0))
	_voice_activity = _voice_activity_hold > 0.0


func current_line_id() -> String:
	return _voice_id


func get_voice_position() -> float:
	if not is_voice_playing(): return 0.0
	return clampf(_voice_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency(), 0.0, get_voice_duration())


func get_voice_duration() -> float:
	return _voice_player.stream.get_length() if is_instance_valid(_voice_player) and _voice_player.stream != null else 0.0


func get_subtitle() -> String:
	if not bool(_settings.subtitles) or _voice_id.is_empty(): return ""
	var entry: Dictionary = _voices.get(_voice_id, {})
	var position := get_voice_position()
	for subtitle in entry.get("subtitles", []):
		if position >= float(subtitle.get("start", 0.0)) and position < float(subtitle.get("end", 0.0)):
			return str(subtitle.get("text", ""))
	# A line without timed segments still has a complete verbatim transcript.
	return str(entry.get("text", "")) if entry.get("subtitles", []).is_empty() else ""


func _process(delta: float) -> void:
	if not _configured: return
	for kind in _groups:
		var group: Dictionary = _groups[kind]
		if group.fading:
			group.elapsed = minf(float(group.elapsed) + maxf(delta, 0.0), CROSSFADE_SECONDS)
			var fraction := smoothstep(0.0, 1.0, float(group.elapsed) / CROSSFADE_SECONDS)
			for i in range(2): group.weights[i] = lerpf(float(group.starts[i]), float(group.targets[i]), fraction)
			if group.elapsed >= CROSSFADE_SECONDS:
				group.fading = false
				for i in range(2):
					if float(group.targets[i]) <= 0.0:
						group.players[i].stop()
						group.players[i].stream = null
				var pending := str(group.pending)
				group.pending = ""
				if not pending.is_empty() and pending != group.cue:
					_start_group(kind, pending, _entry(kind, pending))
	_voice_weight = move_toward(_voice_weight, _voice_target, maxf(delta, 0.0) / VOICE_FADE_SECONDS)
	if _pending_voice_stop and _voice_weight <= 0.0:
		_voice_player.stop()
		_voice_player.stream = null
		_pending_voice_stop = false
		if _pending_voice_start:
			_pending_voice_start = false
			_next_voice()
	_update_voice_activity(delta)
	var audible_voice := is_voice_playing() and float(_settings.voice) > 0.0001
	var duck_target := 0.25 if audible_voice else 1.0
	_duck = move_toward(_duck, duck_target, maxf(delta, 0.0) / (0.20 if audible_voice else 0.75))
	_apply_mix()


func _apply_mix() -> void:
	for kind in _groups:
		var group: Dictionary = _groups[kind]
		# Ambience is lowered less than the score to preserve environmental space.
		var duck_gain := _duck if kind == "music" else lerpf(0.42, 1.0, (_duck - 0.25) / 0.75)
		for i in range(2):
			var gain: float = float(_settings[kind]) * float(BASE_GAIN[kind]) * float(group.weights[i]) * float(group.entry_gains[i]) * duck_gain
			group.players[i].volume_db = _db(gain)
	if is_instance_valid(_voice_player):
		_voice_player.volume_db = _db(float(_settings.voice) * float(BASE_GAIN.voice) * _voice_entry_gain * _voice_weight)
	for player in _sfx_players:
		player.volume_db = _db(float(_settings.sound) * float(BASE_GAIN.sound) * float(player.get_meta("entry_gain", 1.0)) * _sfx_duck_gain())


func stop_all() -> void:
	stop_voice()
	_pending_voice_start = false
	_pending_voice_stop = false
	_voice_weight = 0.0
	_duck = 1.0
	if is_instance_valid(_voice_player):
		_voice_player.stop()
		_voice_player.stream = null
	for kind in _groups:
		var group: Dictionary = _groups[kind]
		for player in group.players:
			player.stop()
			player.stream = null
		group.weights = [0.0, 0.0]
		group.starts = [0.0, 0.0]
		group.targets = [0.0, 0.0]
		group.active = -1
		group.cue = ""
		group.playback_key = ""
		group.playback_id = ""
		group.pending = ""
		group.fading = false
	for player in _sfx_players:
		player.stop()
		player.stream = null
	_sfx_ready_at.clear()


func debug_state() -> Dictionary:
	var groups := {}
	for kind in _groups:
		var group: Dictionary = _groups[kind]
		var actual_db: Array = []
		var playing: Array = []
		for player in group.players:
			actual_db.append(player.volume_db)
			playing.append(player.playing)
		groups[kind] = {"cue": group.cue, "playback_id": group.playback_id, "active": group.active, "pending": group.pending, "weights": group.weights.duplicate(), "playing": playing, "volume_db": actual_db, "crossfading": group.fading}
	var sfx_db: Array = []
	var sfx_active := 0
	for player in _sfx_players:
		sfx_db.append(player.volume_db)
		if player.playing: sfx_active += 1
	return {"groups": groups, "voice_id": _voice_id, "voice_playing": is_voice_playing(), "voice_queue": _voice_queue.duplicate(), "voice_epoch": _voice_epoch,
		"voice_active": is_voice_active(), "voice_peak_db": _voice_peak_db, "voice_activity_hold": _voice_activity_hold, "voice_bus": _voice_bus,
		"voice_weight": _voice_weight, "voice_position": get_voice_position(), "voice_duration": get_voice_duration(), "duck_gain": _duck,
		"voice_volume_db": _voice_player.volume_db if is_instance_valid(_voice_player) else SILENCE_DB,
		"settings": _settings.duplicate(), "limiter_bus": _mix_bus, "sfx_players": _sfx_players.size(), "sfx_active": sfx_active, "sfx_volume_db": sfx_db,
		"sfx_started": _sfx_started, "sfx_last_event": _sfx_last_event.duplicate(), "sfx_duck_gain": _sfx_duck_gain(), "last_error": last_error}


func _entry(kind: String, cue: String) -> Dictionary:
	var value: Variant = _catalog.get(kind, {}).get(cue, {})
	if value is String: return {"path": value}
	return value if value is Dictionary else {}


func _load_stream(path: String, loop: bool) -> AudioStream:
	if path.is_empty(): return null
	var key := path + ("#loop" if loop else "#once")
	if _stream_cache.has(key): return _stream_cache[key]
	var stream: AudioStream
	if ResourceLoader.exists(path):
		var resource := load(path)
		if resource is AudioStream: stream = resource.duplicate()
	elif FileAccess.file_exists(path):
		# Runtime loading supports local recorded lines and test fixtures before
		# editor import; packaged releases normally use imported resources above.
		match path.get_extension().to_lower():
			"wav": stream = AudioStreamWAV.load_from_file(path)
			"ogg": stream = AudioStreamOggVorbis.load_from_file(path)
			"mp3": stream = AudioStreamMP3.load_from_file(path)
	if stream == null: return null
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		if loop:
			stream.loop_begin = 0
			var bytes_per_sample := 1 if stream.format == AudioStreamWAV.FORMAT_8_BITS else 2
			stream.loop_end = stream.data.size() / (bytes_per_sample * (2 if stream.stereo else 1))
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop
	_stream_cache[key] = stream
	return stream


func _any_playing(players: Array) -> bool:
	for player in players:
		if player.playing: return true
	return false


func _db(gain: float) -> float:
	return maxf(SILENCE_DB, linear_to_db(gain)) if gain > 0.00001 else SILENCE_DB


func _exit_tree() -> void:
	stop_all()
	_stream_cache.clear()
	# Buses exist only in this running game process. No project-wide bus layout
	# or user/system configuration file is modified.
	var voice_index := AudioServer.get_bus_index(_voice_bus)
	if voice_index >= 0: AudioServer.remove_bus(voice_index)
	var index := AudioServer.get_bus_index(_mix_bus)
	if index >= 0: AudioServer.remove_bus(index)
