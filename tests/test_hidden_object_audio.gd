extends SceneTree
const OpeningAudio = preload("res://scripts/hidden_object_audio.gd")
var checks := 0
var failures := 0
var events: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func expect(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", description)

func _run() -> void:
	var audio := OpeningAudio.new()
	root.add_child(audio)
	audio.set_process(false)
	audio.cue_played.connect(func(id): events.append(id))
	expect(audio.ready_ok and audio.players.size() == 13, "all thirteen chosen recordings load")
	for id in audio.players:
		var player: AudioStreamPlayer = audio.players[id]
		expect(player.stream.get_length() > .05, "audible-length packaged resource: " + str(id))
		expect(player.stream.loop == (audio.cues[id].kind == "loop"), "only ambience beds loop: " + str(id))
	for id in ["harbour_water", "rain_on_the_office", "office_room_tone"]:
		expect(audio.players[id].playing, "background layer starts: " + id)
	audio.set_music_enabled(false)
	expect(audio.music.stream_paused and not audio.players.harbour_water.stream_paused, "music switch leaves room atmosphere playing")
	expect(audio.play_cue("object_found"), "discovery starts")
	expect(not audio.play_cue("object_found"), "repeated discovery cannot stack the same sound")
	audio.finish_search()
	expect(audio.scheduled.size() == 2 and events.back() == "search_completed", "completion starts before receipt and writing")
	audio._process(1.51)
	expect(events.back() == "receipt_recovered" and audio.scheduled.size() == 1, "receipt plays after completion")
	audio._process(.61)
	expect(events.back() == "journal_updated" and audio.scheduled.is_empty(), "writing follows receipt")
	audio.finish_search()
	audio.set_muted(true)
	expect(audio.scheduled.is_empty(), "muting cancels pending reward sounds")
	for id in audio.players:
		var player: AudioStreamPlayer = audio.players[id]
		expect(player.stream_paused if audio.cues[id].kind == "loop" else not player.playing, "mute silences " + str(id))
	var event_count := events.size()
	audio._process(50)
	expect(not audio.play_cue("hint_revealed") and events.size() == event_count, "muted actions and time do not trigger sound")
	audio.set_muted(false)
	expect(audio.music.stream_paused and not audio.players.harbour_water.stream_paused, "unmute preserves separate music setting")
	audio._process(50)
	expect(events.count("moored_boat_and_ropes") == 1 and events.count("building_movement") == 1, "occasional details do not burst to catch up")
	expect(audio.scheduled.is_empty(), "unmute does not replay old completion sounds")
	audio.set_music_enabled(true)
	expect(not audio.music.stream_paused, "score can resume")
	audio.finish_search()
	audio.cancel_reward()
	expect(audio.scheduled.is_empty() and not audio.players.search_completed.playing, "restart cancels the reward sequence")
	audio.finish_search(false)
	expect(audio.scheduled.size() == 1 and audio.scheduled[0].id == "receipt_recovered", "failed save does not announce a journal update")
	audio.stop_all()
	expect(not audio.play_cue("menu_interaction"), "exit prevents new cues")
	for player in audio.players.values(): expect(player.stream == null and not player.playing, "exit releases the audio stream")
	await create_timer(.25).timeout
	audio.queue_free()
	await process_frame
	if failures: printerr("HIDDEN_AUDIO_TESTS_FAILED: ", failures, "/", checks)
	else: print("HIDDEN_AUDIO_TESTS_OK: ", checks)
	quit(1 if failures else 0)
