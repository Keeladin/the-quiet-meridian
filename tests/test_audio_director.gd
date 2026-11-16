extends SceneTree
## Known synthetic test signals verify mixer behavior, not voice or music quality.
## These fixtures are created only in repository-isolated user storage.

const Director = preload("res://scripts/audio_director.gd")
var director: Node
var checks := 0
var failures := 0
var started: Array = []
var finished: Array = []
var completed := 0
var test_folder := "user://audio-director-tests"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if not ProjectSettings.globalize_path("user://").begins_with(project + "/work/"):
		printerr("AUDIO_TESTS_REFUSED: isolate XDG_DATA_HOME inside the repository work directory.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(test_folder)
	_fixture("music", 2.0, 220.0)
	_fixture("ambience", 2.0, 110.0)
	_fixture("effect", 0.35, 660.0)
	_fixture("effect_alt", 0.35, 770.0)
	_fixture("effect_long", 2.0, 660.0)
	_fixture("a", 0.45, 330.0)
	_fixture("b", 0.45, 440.0)
	_activity_fixture()
	var catalog := {
		"music": {"title": {"path": _path("music"), "loop": true}, "ch1": {"path": _path("music"), "loop": true, "gain_db": -2.0}, "tension": {"path": _path("music"), "loop": true}},
		"ambience": {"harbor": {"path": _path("ambience"), "loop": true}},
		"sfx": {
			"paper": {"path": _path("effect"), "gain_db": -3.0},
			"varied": {"path": _path("effect"), "variants": [_path("effect"), _path("effect_alt"), _path("effect_alt")], "pitch_range": [0.98, 1.02]},
			"cooldown": {"path": _path("effect"), "variants": [_path("effect"), _path("effect_alt")], "cooldown_seconds": 0.12},
			"fallback": {"path": _path("effect"), "variants": [_path("not-present"), 42, ""]},
			"invalid": {"path": _path("not-present"), "variants": [_path("also-missing")]},
			"guarded": {"path": _path("effect"), "gain_db": 99.0, "pitch_range": [9.0, -1.0]},
			"malformed": {"path": _path("effect"), "gain_db": "bad", "pitch_range": ["bad", 1.0]},
			"long": {"path": _path("effect_long"), "gain_db": -6.0}
		}
	}
	var voices := {"lines": {
		"a": {"speaker": "test-a", "text": "Test sentence A.", "path": _path("a"), "duration": 0.001, "subtitles": [{"start": 0, "end": 0.22, "text": "A first"}, {"start": 0.22, "end": 0.45, "text": "A second"}]},
		"b": {"speaker": "test-b", "text": "Test sentence B.", "path": _path("b"), "duration": 0.45, "subtitles": []},
		"gated_wav": {"speaker": "test-a", "text": "Synthetic gated decoder fixture.", "path": _path("gated"), "subtitles": []},
		"gated_ogg": {"speaker": "test-a", "text": "Synthetic gated decoder fixture.", "path": test_folder + "/gated.ogg", "subtitles": []},
		"pending": {"speaker": "nadi", "text": "Not produced.", "path": "", "duration": 0.0, "subtitles": []},
		"missing": {"speaker": "nadi", "text": "Missing file.", "path": test_folder + "/not-present.wav", "duration": 1.0, "subtitles": []}
	}}
	director = Director.new()
	root.add_child(director)
	director.configure(catalog, voices, {"music": 0.6, "ambience": 0.5, "sound": 0.4, "voice": 0.8, "subtitles": true, "auto_voice": true})
	director.voice_started.connect(func(id: String): started.append(id))
	director.voice_finished.connect(func(id: String): finished.append(id))
	director.sequence_finished.connect(func(): completed += 1)
	var initial_bus_count := AudioServer.bus_count
	var mix_bus: String = director.debug_state().limiter_bus
	var voice_bus: String = director.debug_state().voice_bus
	_expect(AudioServer.get_bus_index(mix_bus) > 0, "isolated game mix bus exists")
	_expect(AudioServer.get_bus_send(AudioServer.get_bus_index(voice_bus)) == mix_bus, "voice-only meter feeds the limited game mix")
	_expect(AudioServer.get_bus_effect(AudioServer.get_bus_index(mix_bus), 0) is AudioEffectHardLimiter, "master has bounded output limiter")
	_expect(not director.has_voice("pending") and not director.has_voice("missing") and not director.has_voice("unknown"), "absent recorded voices stay unavailable")
	_expect(not director.play_voice("pending"), "unproduced line cannot claim playback")
	_expect(started.is_empty() and director.current_line_id().is_empty(), "no synthetic speech or false voice-start event")
	_expect(not director.last_error.is_empty(), "unavailable recording has an explicit diagnostic")
	director.play_music("title")
	director.set_ambience("harbor")
	await create_timer(0.25).timeout
	var mix: Dictionary = director.debug_state()
	_expect(mix.groups.music.crossfading and mix.groups.music.weights[0] > 0.0 and mix.groups.music.weights[0] < 1.0, "music starts with a gradual fade")
	_expect(mix.groups.ambience.crossfading, "ambience has an independent gradual fade")
	await create_timer(1.4).timeout
	mix = director.debug_state()
	_expect(not mix.groups.music.crossfading and is_equal_approx(float(mix.groups.music.weights[0]), 1.0), "music reaches its sustained level")
	_expect(mix.groups.music.playing[0], "music loops in the decoder beyond the test start")
	director.play_music("ch1")
	await create_timer(0.55).timeout
	mix = director.debug_state()
	_expect(mix.groups.music.playing[0] and mix.groups.music.playing[1], "new cue overlaps the previous cue during transition")
	_expect(mix.groups.music.weights[0] > 0.0 and mix.groups.music.weights[1] > 0.0, "both cue gains take part in crossfade")
	director.play_music("tension")
	_expect(director.debug_state().groups.music.pending == "tension", "rapid travel queues latest cue instead of cutting an audible tail")
	await create_timer(1.0).timeout
	_expect(director.debug_state().groups.music.cue == "tension", "queued destination starts after the existing transition")
	await create_timer(1.6).timeout
	mix = director.debug_state()
	_expect(not mix.groups.music.crossfading and mix.groups.music.pending.is_empty(), "latest transition settles completely")
	director.play_music("tension")
	_expect(not director.debug_state().groups.music.crossfading, "same active cue does not restart on scene refresh")
	director.play_music("unknown")
	_expect(director.debug_state().groups.music.cue == "tension", "missing cue preserves current music")
	_expect(not director.is_voice_active(), "music and ambience cannot activate the isolated speech meter")
	_expect(director.has_voice("a"), "local recorded file loads without network access")
	_expect(director.play_sequence(["a", "b"]), "recorded sequence starts")
	_expect(director.current_line_id() == "a" and started == ["a"], "first line event identifies its actual recording")
	_expect(absf(director.get_voice_duration() - 0.45) < 0.01, "caption duration comes from actual audio, not unchecked manifest duration")
	await create_timer(0.12).timeout
	mix = director.debug_state()
	_expect(mix.voice_playing and mix.voice_weight > 0.99, "voice fades in quickly and plays")
	_expect(mix.duck_gain < 0.8, "audible voice smoothly ducks music and ambience")
	# Decoder time can advance beyond the first segment on a busy machine.
	var caption_time: float = director.get_voice_position()
	_expect(director.current_line_id() == "a" and director.get_subtitle() == ("A first" if caption_time < 0.22 else "A second"), "subtitle segment follows actual decoder time")
	director.set_volumes({"voice": 0.0, "subtitles": false})
	_expect(director.debug_state().voice_volume_db <= -79.9 and director.get_subtitle().is_empty(), "voice mute and subtitles are independent controls")
	var previous_duck: float = director.debug_state().duck_gain
	await create_timer(0.1).timeout
	_expect(director.debug_state().duck_gain > previous_duck, "muted dialogue no longer suppresses the score")
	director.set_volumes({"voice": 0.8, "subtitles": true})
	await create_timer(0.85).timeout
	_expect(started == ["a", "b"] and finished == ["a", "b"], "natural playback advances through exactly both lines")
	_expect(completed == 1 and not director.is_voice_playing(), "natural queue completion emits once")
	await create_timer(0.6).timeout
	_expect(is_equal_approx(float(director.debug_state().duck_gain), 1.0), "music recovers smoothly after speech")
	_expect(director.replay_voice(), "complete exchange can be replayed")
	await create_timer(0.1).timeout
	var stale_epoch: int = director.debug_state().voice_epoch
	director.stop_voice()
	director._on_voice_finished(stale_epoch, "a")
	await create_timer(0.12).timeout
	_expect(not director.is_voice_playing() and director.debug_state().voice_queue.is_empty(), "skip cancels both current line and queued reply")
	_expect(completed == 1, "skip does not falsely emit natural sequence completion")
	_expect(started == ["a", "b", "a"], "stale finished signal cannot start a skipped reply")
	_expect(director.play_voice("a"), "single line starts after interruption")
	await create_timer(0.08).timeout
	stale_epoch = director.debug_state().voice_epoch
	_expect(director.play_voice("b"), "a new line can replace an active line")
	await create_timer(0.1).timeout
	director._on_voice_finished(stale_epoch, "a")
	_expect(director.current_line_id() == "b", "old-generation completion cannot affect replacement speech")
	director.play_sfx("paper")
	_expect(director.debug_state().sfx_active > 0 and director.current_line_id() == "b", "effects use separate players and never steal speech")
	director.set_volumes({"music": 0.0, "ambience": 0.0, "voice": 0.0, "sound": 0.0})
	mix = director.debug_state()
	_expect(mix.groups.music.volume_db[0] <= -79.9 and mix.groups.music.volume_db[1] <= -79.9, "music can be muted during playback")
	_expect(mix.groups.ambience.volume_db[0] <= -79.9 and mix.groups.ambience.volume_db[1] <= -79.9, "ambience can be muted independently")
	_expect(mix.voice_volume_db <= -79.9 and float(mix.sfx_volume_db[0]) <= -79.9, "voice and effects respect their own mute controls")
	director.stop_voice()
	await create_timer(0.12).timeout
	director.set_volumes({"music": 0.6, "ambience": 0.5, "voice": 0.8})
	for format in ["wav", "ogg"]:
		director.play_voice("gated_" + format)
		await create_timer(0.2).timeout
		_expect(director.is_voice_playing() and not director.is_voice_active(), format + " leading silence keeps mouth at rest")
		await create_timer(0.35).timeout
		_expect(director.is_voice_active(), format + " decoded word energy opens speaking gate")
		var held_duck: float = director.debug_state().duck_gain
		director.set_volumes({"voice": 0.0})
		_expect(not director.is_voice_active(), format + " muted speech stops mouth activity immediately")
		director.set_volumes({"voice": 0.8})
		await create_timer(0.6).timeout
		_expect(director.is_voice_playing() and not director.is_voice_active(), format + " sentence pause closes the gate after short hold")
		_expect(absf(float(director.debug_state().duck_gain) - held_duck) < 0.01, format + " sentence pause retains stable music ducking")
		await create_timer(0.35).timeout
		_expect(director.is_voice_active(), format + " speech resumes after the pause")
		await create_timer(0.6).timeout
		_expect(director.is_voice_playing() and not director.is_voice_active(), format + " trailing silence rests portrait while playback remains skippable")
		director.stop_voice()
		_expect(not director.is_voice_active(), format + " skip clears held activity immediately")
		await create_timer(0.12).timeout
	await _check_sfx()
	await _check_shared_music(catalog, voices)
	await _check_main_music_continuity()
	director.stop_all()
	mix = director.debug_state()
	_expect(not mix.voice_playing and not mix.groups.music.playing[0] and not mix.groups.music.playing[1] and mix.sfx_active == 0, "shutdown stops every channel")
	await create_timer(0.2).timeout
	director.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	_expect(AudioServer.get_bus_index(mix_bus) == -1 and AudioServer.get_bus_index(voice_bus) == -1
		and AudioServer.bus_count == initial_bus_count - 2, "owned runtime buses are removed without modifying other buses")
	if failures == 0:
		print("AUDIO_DIRECTOR_TESTS_OK: ", checks, " checks; real decoder playback, shared-track continuity across gameplay/title cues, crossfades, ducking, SFX variations/cooldown/pool/priority, separate volume/mute, missing voice honesty, subtitle timing, skip/replay, stale callbacks, limiter and cleanup")
	else: printerr("AUDIO_DIRECTOR_TESTS_FAILED: ", failures, " / ", checks)
	quit(0 if failures == 0 else 1)


func _check_sfx() -> void:
	director.stop_all()
	director.set_volumes({"music": 0.6, "ambience": 0.5, "voice": 0.8, "sound": 0.4})
	director.play_sfx("paper")
	var state: Dictionary = director.debug_state()
	_expect(state.sfx_last_event.path == _path("effect") and is_equal_approx(float(state.sfx_last_event.pitch), 1.0), "legacy single-file effects retain original pitch")
	_expect(absf(float(state.sfx_volume_db[0]) - linear_to_db(0.4 * 0.7) + 3.0) < 0.01, "effect volume combines independent slider, conservative base gain and cue trim")
	await create_timer(0.4).timeout
	var count: int = director.debug_state().sfx_started
	var previous := ""
	var varied_ok := true
	var pitch_ok := true
	for index in 6:
		director.play_sfx("varied")
		state = director.debug_state()
		var event: Dictionary = state.sfx_last_event
		var path: String = event.path
		varied_ok = varied_ok and path != previous and path in [_path("effect"), _path("effect_alt")]
		pitch_ok = pitch_ok and float(event.pitch) >= 0.98 and float(event.pitch) <= 1.02
		previous = path
		await create_timer(0.08).timeout
	_expect(int(state.sfx_started) == count + 6, "separated Foley interactions all start real decoder playback")
	_expect(varied_ok, "two-file variation pool never immediately repeats a path despite duplicate catalog entries")
	_expect(pitch_ok, "Foley pitch variation stays inside its declared subtle range")
	await create_timer(0.4).timeout
	director.play_sfx("fallback")
	count = director.debug_state().sfx_started
	director.play_sfx("fallback")
	state = director.debug_state()
	_expect(state.sfx_started == count + 1 and state.sfx_last_event.path == _path("effect"), "invalid variants fall back to the valid primary, including a single available recording")
	count = state.sfx_started
	director.play_sfx("invalid")
	_expect(director.debug_state().sfx_started == count and not director.last_error.is_empty(), "unloadable effect has an explicit diagnostic and never reports playback")
	director.play_sfx("guarded")
	state = director.debug_state()
	_expect(float(state.sfx_last_event.gain_db) == 0.0 and float(state.sfx_last_event.pitch) >= 0.9 and float(state.sfx_last_event.pitch) <= 1.1, "bad authored gain cannot amplify effects and extreme reversed pitch bounds are constrained")
	director.play_sfx("malformed")
	state = director.debug_state()
	_expect(float(state.sfx_last_event.gain_db) == 0.0 and is_equal_approx(float(state.sfx_last_event.pitch), 1.0), "malformed optional gain and pitch values fall back safely")
	await create_timer(0.45).timeout
	director.play_sfx("cooldown")
	state = director.debug_state()
	count = state.sfx_started
	previous = state.sfx_last_event.path
	director.play_sfx("cooldown")
	_expect(director.debug_state().sfx_started == count, "rapid repeated cue is suppressed during its cooldown")
	director.play_sfx("paper")
	_expect(director.debug_state().sfx_started == count + 1, "cue cooldown does not suppress a different interaction")
	await create_timer(0.16).timeout
	director.play_sfx("cooldown")
	state = director.debug_state()
	_expect(state.sfx_started == count + 2 and state.sfx_last_event.path != previous, "cooldown expires and suppressed requests do not consume the next variation")
	director.set_volumes({"sound": 0.0})
	count = state.sfx_started
	director.play_sfx("varied")
	state = director.debug_state()
	var all_muted := true
	for value in state.sfx_volume_db: all_muted = all_muted and float(value) <= -79.9
	_expect(state.sfx_started == count and all_muted, "sound mute silences existing effects and does not queue new effects")
	await create_timer(0.45).timeout
	director.set_volumes({"sound": 0.4})
	_expect(director.debug_state().sfx_active == 0 and director.debug_state().sfx_started == count, "unmuting cannot replay interactions made while muted")

	director.stop_all()
	director.set_volumes({"music": 0.6, "ambience": 0.5, "voice": 0.8, "sound": 0.4})
	director.play_music("title")
	director.set_ambience("harbor")
	director.play_sfx("long")
	var unvoiced_db: float = director.debug_state().sfx_volume_db[0]
	_expect(not director.is_voice_active(), "Foley alone cannot trigger the speech activity meter")
	director.play_voice("gated_wav")
	await create_timer(0.08).timeout
	state = director.debug_state()
	_expect(float(state.sfx_duck_gain) < 1.0 and float(state.sfx_duck_gain) > db_to_linear(-4.0), "voice priority eases effect gain down instead of stepping abruptly")
	await create_timer(0.2).timeout
	state = director.debug_state()
	_expect(absf(float(state.sfx_volume_db[0]) - unvoiced_db + 4.0) < 0.05, "dialogue ducks ongoing Foley by four decibels without additional amplification")
	count = state.sfx_started
	for index in 7: director.play_sfx("paper")
	state = director.debug_state()
	_expect(state.sfx_players == 8 and state.sfx_active == 8 and state.sfx_started == count + 7, "sound effects use the bounded eight-player pool")
	director.play_sfx("cooldown")
	state = director.debug_state()
	_expect(state.sfx_started == count + 7 and state.voice_id == "gated_wav" and state.voice_playing, "ninth overlapping effect is dropped without stealing or restarting speech")
	_expect(state.groups.music.cue == "title" and state.groups.music.playing[0] and state.groups.ambience.playing[0], "busy Foley pool leaves music and ambience playback intact")
	await create_timer(0.45).timeout
	director.play_sfx("cooldown")
	_expect(director.debug_state().sfx_started == count + 8, "effect pool accepts a new interaction once a playback slot is free")
	director.stop_voice()
	await create_timer(0.2).timeout
	state = director.debug_state()
	_expect(float(state.sfx_duck_gain) > db_to_linear(-4.0) and float(state.sfx_duck_gain) < 1.0, "Foley gains recover gradually after dialogue skip")
	await create_timer(0.65).timeout
	state = director.debug_state()
	_expect(is_equal_approx(float(state.sfx_duck_gain), 1.0) and absf(float(state.sfx_volume_db[0]) - unvoiced_db) < 0.01, "Foley returns to its authored level after the dialogue release")
	director.play_sfx("cooldown")
	count = director.debug_state().sfx_started
	director.stop_all()
	director.play_sfx("cooldown")
	_expect(director.debug_state().sfx_started == count + 1, "explicit shutdown clears cooldown for a fresh gameplay session")


func _path(name: String) -> String:
	return test_folder + "/" + name + ".wav"


func _fixture(name: String, duration: float, frequency: float) -> void:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var samples := int(duration * wave.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var envelope := minf(1.0, minf(float(i) / 200.0, float(samples - i) / 200.0))
		var sample := int(sin(TAU * frequency * float(i) / wave.mix_rate) * 1600.0 * envelope)
		bytes.encode_s16(i * 2, sample)
	wave.data = bytes
	_expect(wave.save_to_wav(_path(name)) == OK, "test-only local PCM fixture written: " + name)


func _activity_fixture() -> void:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(int(2.4 * wave.mix_rate) * 2)
	for index in data.size() / 2:
		var seconds := float(index) / wave.mix_rate
		var envelope := 0.0
		for interval in [Vector2(0.35, 0.9), Vector2(1.25, 1.8)]:
			if seconds >= interval.x and seconds < interval.y:
				envelope = minf(1.0, minf((seconds - interval.x) / 0.015, (interval.y - seconds) / 0.015))
		data.encode_s16(index * 2, int(sin(TAU * 330.0 * seconds) * 1600.0 * envelope))
	wave.data = data
	_expect(wave.save_to_wav(_path("gated")) == OK, "test-only leading/pause/trailing silence PCM fixture")
	# This base64 source is the same artificial waveform, encoded once with
	# libvorbis q3. Materialize it only in ignored work storage, never game assets.
	var encoded := FileAccess.get_file_as_string("res://tests/fixtures/voice-activity.ogg.b64").strip_edges()
	var output := FileAccess.open(test_folder + "/gated.ogg", FileAccess.WRITE)
	output.store_buffer(Marshalls.base64_to_raw(encoded))
	output.close()


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("AUDIO FAIL: ", message)


func _check_shared_music(catalog: Dictionary, voices: Dictionary) -> void:
	_fixture("continuous_music", 8.0, 220.0)
	var shared := catalog.duplicate(true)
	for cue in ["title", "ch1", "ch2", "tension", "resolution"]:
		shared.music[cue] = {"path":_path("continuous_music"), "loop":true, "gain_db":-9.0, "playback_id":"shared-theme"}
	shared.music["collision"] = {"path":_path("music"), "loop":true, "playback_id":"shared-theme"}
	director.configure(shared,voices,{"music":0.6,"ambience":0.5,"voice":0.8})
	director.play_music("title")
	await create_timer(0.1).timeout
	var active: int = director.debug_state().groups.music.active
	var player: AudioStreamPlayer = director._groups.music.players[active]
	director.play_music("ch1"); director.play_music("tension")
	var state: Dictionary = director.debug_state()
	_expect(state.groups.music.active == active and state.groups.music.pending.is_empty() and state.groups.music.cue == "tension", "shared aliases during the initial fade keep one decoder and do not queue another start")
	await create_timer(1.5).timeout
	var position := player.get_playback_position()
	_expect(position > 1.0 and not director.debug_state().groups.music.crossfading, "shared cue aliases preserve elapsed playback through the initial fade")
	for cue in ["resolution","ch2","title","ch1"]: director.play_music(cue)
	await create_timer(0.1).timeout
	state = director.debug_state()
	_expect(state.groups.music.active == active and not state.groups.music.crossfading and player.get_playback_position() > position, "chapter, tension, resolution and title cues continue the same track without rewind or crossfade")
	director.set_ambience("harbor")
	director.set_volumes({"music":0.0,"ambience":0.5,"voice":0.8})
	position = player.get_playback_position()
	await create_timer(0.1).timeout
	state = director.debug_state()
	_expect(player.playing and player.get_playback_position() > position and player.volume_db <= -79.9, "muting continuous music silences it without losing playback position")
	_expect(state.groups.ambience.playing[0], "continuous music keeps the ambience decoder independent")
	director.set_volumes({"music":0.25,"ambience":0.5,"voice":0.8})
	await process_frame
	_expect(absf(player.volume_db - (linear_to_db(0.25*0.52)-9.0)) < 0.02, "continuous music retains the slider, base level and conservative cue trim")
	director.play_voice("a")
	await create_timer(0.15).timeout
	_expect(director.debug_state().duck_gain < 0.8 and director.debug_state().groups.music.active == active and player.playing, "dialogue ducks the continuous track without replacing its decoder")
	director.stop_voice()
	player.seek(7.95)
	await create_timer(0.2).timeout
	_expect(player.playing and player.get_playback_position() < 0.5, "shared background track loops in the decoder at its actual end")
	director.play_music("collision")
	_expect(director.debug_state().groups.music.active != active and director.debug_state().groups.music.crossfading, "an accidentally reused shared ID cannot retain a different source file")


func _check_main_music_continuity() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Control = scene.instantiate()
	root.add_child(main)
	main.set_process(false)
	main.state.settings.auto_voice = false
	main.state.settings.fullscreen = false
	main.state.settings.music = 0.2
	main._apply_audio()
	await create_timer(0.12).timeout
	var active: int = main.audio.debug_state().groups.music.active
	_expect(active >= 0, "real main title starts the selected background track")
	if active < 0:
		main.stop_audio_for_exit(); main.queue_free(); await process_frame
		return
	var player: AudioStreamPlayer = main.audio._groups.music.players[active]
	_expect(player.stream is AudioStreamMP3 and absf(player.stream.get_length()-189.25346875) < 0.1, "real main decodes the unchanged user-selected MP3 with its actual duration")
	var position := player.get_playback_position()
	main._new_game(); main._close_modal(); main._travel("ch1_l2")
	main._pause(); main._close_modal(); main._casebook(); main._close_modal()
	main._save_and_return_to_title()
	await create_timer(0.15).timeout
	var state: Dictionary = main.audio.debug_state()
	_expect(state.groups.music.active == active and state.groups.music.playback_id == "sonder" and state.groups.music.pending.is_empty(), "real new-game, travel, pause, Casebook and title callbacks all retain the selected music decoder")
	_expect(player.playing and player.get_playback_position() > position, "real screen transitions advance selected MP3 playback instead of restarting it")
	player.seek(player.stream.get_length()-0.15)
	await create_timer(0.5).timeout
	_expect(player.playing and player.get_playback_position() < 1.0, "the actual selected MP3 repeats across its end without stopping the background soundtrack")
	main.stop_audio_for_exit(); main.queue_free(); await process_frame
