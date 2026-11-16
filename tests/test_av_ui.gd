extends SceneTree
## Real main-scene integration with isolated, synthetic decoder fixtures.
## These tones are test inputs only, never game voices or acting previews.

var main: Control
var checks := 0
var failures := 0
var started: Array = []
var fixture_dir := "user://av-ui-test-fixtures"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if not ProjectSettings.globalize_path("user://").begins_with(project + "/work/"):
		printerr("AV_UI_TESTS_REFUSED: isolate XDG_DATA_HOME inside the repository work directory.")
		quit(2)
		return
	var scene: PackedScene = load("res://scenes/main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	main.state.settings = main.State.DEFAULT_SETTINGS.duplicate(true)
	# Test the missing-recording fallback explicitly even when real voices exist.
	var pending_catalog: Dictionary = main.voice_catalog.duplicate(true)
	for line in pending_catalog.lines.values():
		line.path = ""
		line.duration = 0.0
		line.subtitles = []
	main.voice_catalog = pending_catalog
	main.audio.configure(main.audio_catalog, pending_catalog, main.state.settings)
	main._apply_audio()
	main.state.new_game()
	main.playing = true
	main._show_location()
	var conversation: Dictionary = main.dialogue_data[0]
	main._conversation(conversation)
	await process_frame
	_expect(main.voice_replay.disabled and main.voice_skip.disabled, "unproduced conversation disables voice controls")
	_expect(main.voice_status.text.contains("unavailable") and not main.voice_progress.visible,
		"missing recordings have an honest message and no fictitious progress")
	_expect(not main.audio.is_voice_playing() and not main.character_stage.pose_snapshot().speaking,
		"missing recordings cannot animate a speaking character")
	_expect(_visible_text(main.overlay).contains(str(conversation.greeting)), "unvoiced greeting remains readable")
	# Exercise all source IDs through the real topic-panel construction.
	main.state.settings.auto_voice = false
	for exchange in main.dialogue_data:
		for index in exchange.topics.size():
			main._conversation(exchange, str(exchange.topics[index].reply), index)
			_expect(main.voice_ids == [str(exchange.id) + "_q%d" % index, str(exchange.id) + "_r%d" % index],
				"question/reply queue maps exact topic: " + str(exchange.id) + "/" + str(index))
			_expect(_visible_text(main.overlay).contains(str(exchange.topics[index].reply)), "complete written reply remains available")
	main._close_modal()
	await process_frame
	# Only the in-memory test catalogue is changed. Production manifests stay
	# untouched, and fixtures are created under ignored repository work storage.
	DirAccess.make_dir_recursive_absolute(fixture_dir)
	_fixture("question", 0.8, 330.0)
	_fixture("reply", 0.8, 440.0)
	var fixtures: Dictionary = main.voice_catalog.duplicate(true)
	for id in ["nadi_arrival_greeting", "nadi_arrival_q0", "nadi_arrival_r0"]:
		fixtures.lines[id].path = fixture_dir + ("/reply.wav" if id.ends_with("r0") else "/question.wav")
		fixtures.lines[id].duration = 0.8
	main.voice_catalog = fixtures
	main.audio.configure(main.audio_catalog, fixtures, main.state.settings)
	main.audio.voice_started.connect(func(id: String): started.append(id))
	main._conversation(conversation)
	await process_frame
	_expect(not main.voice_replay.disabled and main.voice_skip.disabled, "available recording enables replay while automatic playback is off")
	_expect(not main.audio.is_voice_playing(), "auto-voice preference prevents unsolicited playback")
	var topic: Dictionary = conversation.topics[0]
	var topic_button := _button(main.overlay, str(topic.question))
	_expect(topic_button != null, "real topic control is available")
	topic_button.pressed.emit()
	await process_frame
	_expect(main.voice_ids == ["nadi_arrival_q0", "nadi_arrival_r0"], "topic button selects question before reply")
	main.voice_replay.pressed.emit()
	await _wait_activity()
	_expect(main.audio.current_line_id() == "nadi_arrival_q0" and main.character_stage.character_id == "iona",
		"recorded player question shows Iona")
	_expect(main.character_stage.pose_snapshot().speaking and not main.voice_skip.disabled,
		"actual playback enables speaker movement and skip")
	_expect(main.subtitle_label.visible and main.subtitle_label.text == str(topic.question), "subtitle displays exact spoken question")
	main.state.settings.subtitles = false
	main._apply_audio()
	await create_timer(0.04).timeout
	_expect(not main.subtitle_label.visible and main.audio.is_voice_playing(), "subtitle toggle leaves voice playback independent")
	main.state.settings.subtitles = true
	main._apply_audio()
	await create_timer(0.04).timeout
	_expect(main.subtitle_label.visible, "subtitles can return during the same line")
	main.voice_skip.pressed.emit()
	await create_timer(0.13).timeout
	_expect(not main.audio.is_voice_playing() and main.audio.debug_state().voice_queue.is_empty(), "UI skip cancels the queued answer too")
	_expect(main.character_stage.character_id == "nadi" and not main.character_stage.pose_snapshot().speaking,
		"skip restores the silent witness after Iona's question")
	main.voice_replay.pressed.emit()
	await _wait_voice("nadi_arrival_r0")
	_expect(main.audio.current_line_id() == "nadi_arrival_r0" and main.character_stage.character_id == "nadi",
		"replay advances in order to the witness's own recording")
	_expect(main.character_stage.pose_snapshot().speaking and main.subtitle_label.text == str(topic.reply),
		"witness movement and subtitle follow the actual reply")
	await create_timer(0.95).timeout
	_expect(not main.audio.is_voice_playing() and not main.character_stage.pose_snapshot().speaking,
		"natural sequence completion stops speaking movement")
	_expect(started == ["nadi_arrival_q0", "nadi_arrival_q0", "nadi_arrival_r0"], "skip/replay does not leak or duplicate a stale queued reply")
	main.voice_replay.pressed.emit()
	await create_timer(0.1).timeout
	var stale_epoch: int = main.audio.debug_state().voice_epoch
	main._close_modal()
	main.audio._on_voice_finished(stale_epoch, "nadi_arrival_q0")
	await create_timer(0.15).timeout
	_expect(main.overlay == null and main.character_stage == null and not main.audio.is_voice_playing(), "closing dialogue cancels speech and releases the stage")
	_expect(main.audio.debug_state().voice_queue.is_empty(), "closed conversation cannot restart through a stale finished event")
	# A recording with no matching expression atlas must never move another
	# character's mouth. Rusk currently has no animated portrait in this batch.
	fixtures.lines.nadi_arrival_q0.speaker = "rusk"
	main.voice_catalog = fixtures
	main.state.settings.auto_voice = true
	main.audio.configure(main.audio_catalog, fixtures, main.state.settings)
	main._conversation(conversation, str(topic.reply), 0)
	await create_timer(0.12).timeout
	_expect(main.audio.is_voice_playing() and main.character_stage.character_id == "nadi"
		and not main.character_stage.pose_snapshot().speaking, "a missing speaker atlas cannot animate the wrong character")
	main._close_modal()
	fixtures.lines.nadi_arrival_q0.speaker = "iona"
	main.voice_catalog = fixtures
	main.audio.configure(main.audio_catalog, fixtures, main.state.settings)
	# Reduced motion still permits recorded dialogue, while freezing the portrait.
	main.state.settings.reduced_motion = true
	main.state.settings.auto_voice = true
	main._apply_audio()
	main._conversation(conversation, str(topic.reply), 0)
	await _wait_activity()
	var pose: Dictionary = main.character_stage.pose_snapshot()
	main.character_stage.set_visual_time(8.2)
	await create_timer(0.1).timeout
	var later: Dictionary = main.character_stage.pose_snapshot()
	_expect(main.audio.is_voice_playing() and pose.speaking, "reduced motion preserves actual voice playback")
	_expect(pose.reduced_motion and later.frame == pose.frame and later.time == pose.time,
		"reduced motion freezes character frame and animation clock")
	main._close_modal()
	_fixture("gated", 1.5, 330.0, true)
	fixtures.lines.nadi_arrival_q0.path = fixture_dir + "/gated.wav"
	for reduce in [false, true]:
		main.state.settings.reduced_motion = reduce
		main.audio.configure(main.audio_catalog, fixtures, main.state.settings)
		main._conversation(conversation, str(topic.reply), 0)
		await create_timer(0.18).timeout
		_expect(main.audio.is_voice_playing() and not main.character_stage.pose_snapshot().speaking,
			"portrait rests during recorded leading silence; reduced=" + str(reduce))
		var initial_pose: Dictionary = main.character_stage.pose_snapshot()
		await create_timer(0.32).timeout
		_expect(main.audio.is_voice_active() and main.character_stage.pose_snapshot().speaking,
			"actual decoded word energy drives portrait speaking state; reduced=" + str(reduce))
		if reduce:
			_expect(main.character_stage.pose_snapshot().frame == initial_pose.frame and main.character_stage.pose_snapshot().time == initial_pose.time,
				"audible speech respects reduced-motion frozen pose")
		await create_timer(0.65).timeout
		_expect(main.audio.is_voice_playing() and not main.character_stage.pose_snapshot().speaking,
			"untrimmed recorded tail keeps playback controls but rests mouth; reduced=" + str(reduce))
		main._close_modal()
	main._settings()
	await process_frame
	var sliders := _nodes(main.overlay, "HSlider")
	var toggles := _nodes(main.overlay, "CheckButton")
	_expect(sliders.size() == 4 and toggles.size() == 5, "settings exposes four volume controls and five accessibility/display toggles; old hotspot-label control is removed")
	for index in sliders.size():
		var key: String = ["music", "ambience", "voice", "sound"][index]
		sliders[index].value = 0.15 + index * 0.15
		_expect(is_equal_approx(float(main.state.settings[key]), float(sliders[index].value))
			and is_equal_approx(float(main.audio.debug_state().settings[key]), float(sliders[index].value)),
			"slider updates its independent preference and live mixer: " + key)
	for toggle in toggles:
		if toggle.text == "Spoken-line subtitles": toggle.button_pressed = false
		elif toggle.text == "Automatically play recorded voices": toggle.button_pressed = false
		elif toggle.text == "Reduce motion": toggle.button_pressed = false
	_expect(not main.state.settings.subtitles and not main.state.settings.auto_voice and not main.state.settings.reduced_motion,
		"subtitle, automatic voice and reduced-motion controls are wired")
	var saved: Dictionary = main.state.settings.duplicate(true)
	main.state.settings.voice = 0.0
	main.state.settings.subtitles = true
	main._load_preferences()
	_expect(main.state.settings == saved, "new volume and voice accessibility preferences persist")
	main._close_modal()
	main.stop_audio_for_exit()
	# Let the mixer release stopped streams before freeing their players.
	await create_timer(0.25).timeout
	main.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	if failures == 0:
		print("AV_UI_TESTS_OK: ", checks, " checks; all topic mappings, honest missing voices, real decoder/test-tone integration, skip/replay/close cancellation, speaker gating, subtitles, reduced motion and persistent controls; no acting-quality claim")
	else: printerr("AV_UI_TESTS_FAILED: ", failures, " / ", checks)
	quit(0 if failures == 0 else 1)


func _wait_voice(id: String) -> void:
	for _step in range(120):
		if main.audio.current_line_id() == id:
			await _wait_activity()
			return
		await create_timer(0.02).timeout


func _wait_activity() -> void:
	for _step in range(25):
		if main.audio.is_voice_active():
			await create_timer(0.02).timeout
			return
		await create_timer(0.02).timeout


func _fixture(name: String, duration: float, frequency: float, gated: bool = false) -> void:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var samples := int(duration * wave.mix_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for index in range(samples):
		var envelope := minf(1.0, minf(float(index) / 200.0, float(samples - index) / 200.0))
		if gated and (float(index) / wave.mix_rate < 0.3 or float(index) / wave.mix_rate >= 0.8): envelope = 0.0
		data.encode_s16(index * 2, int(sin(TAU * frequency * float(index) / wave.mix_rate) * 1600.0 * envelope))
	wave.data = data
	_expect(wave.save_to_wav(fixture_dir + "/" + name + ".wav") == OK, "test-only local decoder fixture created")


func _nodes(node: Node, type: String) -> Array:
	var result: Array = []
	if node.is_class(type): result.append(node)
	for child in node.get_children(): result.append_array(_nodes(child, type))
	return result


func _button(node: Node, text: String) -> Button:
	for candidate in _nodes(node, "Button"):
		if candidate.text == text: return candidate
	return null


func _visible_text(node: Node) -> String:
	var result := ""
	for label in _nodes(node, "Label"):
		if label.visible: result += label.text + "\n"
	return result


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("AV UI FAIL: ", message)
