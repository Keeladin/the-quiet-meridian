extends SceneTree
## Staged capture of the real game UI. No input/save files or voice placeholders.
## Run through tools/render_av_preview.py to isolate all generated state.

const FPS := 12
const OUT := "res://builds/previews/"
var game: Control
var caption: Label
var frames := 0
var stages: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.state.new_game()
	game.state.settings.reduced_motion = false
	game.state.settings.fullscreen = false
	game.state.settings.auto_voice = false
	game.state.settings.music = 0.85
	game.state.settings.ambience = 0.65
	game._apply_audio()
	# Forty seconds cannot reach the 45-second autosave timer. The wrapper also
	# isolates XDG data to work/av-preview-data; this never reads player saves.
	game.playing = true
	game.session_timer = 0.0
	_make_caption()
	game.state.location_id = "ch1_l1"
	game._show_location()
	_stage("Ferry Landing · water, drifting fog and warm light", "ferry", 8.0)
	await _hold(8.0)
	game.state.location_id = "ch2_l3"
	game._show_location()
	game.audio.play_sfx("mechanism")
	_stage("Machine Room · piston, flywheel light and steam", "machinery", 8.0)
	await _hold(8.0)
	game.state.location_id = "ch1_l1"
	game._show_location()
	var conversation: Dictionary = {}
	for entry in game.dialogue_data:
		if str(entry.id) == "nadi_arrival": conversation = entry; break
	assert(not conversation.is_empty(), "Nadi arrival conversation is required")
	game._conversation(conversation)
	_stage("Nadi · original expression artwork and natural blinking", "nadi_greeting", 4.0)
	await _hold(4.0)
	game._conversation(conversation, str(conversation.topics[1].reply), 1)
	game.audio.play_sfx("paper")
	_stage("Nadi · silent topic gesture; written dialogue remains complete", "nadi_gesture", 6.0)
	await _hold(6.0)
	game._close_modal()
	game.state.settings.reduced_motion = true
	game.state.location_id = "ch2_l3"
	game._show_location()
	_stage("Reduced motion ON · still environment, music and ambience continue", "reduced_motion", 6.0)
	await _hold(6.0)
	game.state.settings.reduced_motion = false
	game.state.location_id = "ch6_l6"
	game._show_location()
	game._story("The record belongs to everyone", str(game.state.data.ending))
	game.audio.play_music("resolution")
	game.audio.play_sfx("chapter")
	_stage("Resolution · original finale theme and final narrative (spoiler)", "resolution", 8.0)
	await _hold(8.0)
	game.stop_audio_for_exit()
	await create_timer(0.2).timeout
	var report := {
		"capture": "Native Godot Movie Maker rendering of scenes/main.tscn",
		"engine": Engine.get_version_info().string,
		"fps": FPS, "target_resolution": [1280, 800], "staged_frames": frames,
		"stages": stages,
		"audio": "Actual AudioDirector mix: original Ogg chapter/resolution cues, separate ambience and effects. No dubbed replacement soundtrack.",
		"voice": "No voice recordings produced. Voice controls visibly unavailable; no fake speech or speaking animation.",
		"state": "Locations staged in memory. No gameplay completion or manual playthrough claimed. Isolated XDG directories supplied by render_av_preview.py.",
		"motion": "Native environment effects and character stage. Reduced-motion stage freezes the scene. Nadi topic gesture is a text-response expression, not lip-synced speech.",
		"limits": ["Preview does not establish 6–10 hour pacing, release readiness or native Windows sound quality", "Synthesized chamber score remains subject to listening and mix review", "Final eight seconds contain ending text"]
	}
	var file := FileAccess.open(OUT + "capture-manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("AV_PREVIEW_CAPTURE_OK: ", frames, " staged frames; no recorded voice")
	quit(0)

func _make_caption() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	root.add_child(layer)
	var backing := ColorRect.new()
	backing.color = Color(0.025, 0.045, 0.055, 0.97)
	backing.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	backing.offset_top = -25
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(backing)
	caption = Label.new()
	caption.add_theme_font_override("font", load("res://assets/fonts/body.ttf"))
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", Color("eee5cf"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backing.add_child(caption)

func _stage(title: String, id: String, seconds: float) -> void:
	caption.text = "DEVELOPMENT PREVIEW · Voice recordings pending  |  " + title
	stages.append({"id": id, "start_seconds": frames / float(FPS), "duration_seconds": seconds, "description": title, "character_frames": [], "environment_start": game.environment_stage.effect_snapshot()})
	print("PREVIEW_STAGE: ", id)

func _hold(seconds: float) -> void:
	for index in int(round(seconds * FPS)):
		await process_frame
		frames += 1
		if is_instance_valid(game.character_stage):
			var pose: Dictionary = game.character_stage.pose_snapshot()
			assert(not pose.speaking, "Unproduced voice must not trigger speaking motion")
			if not pose.frame in stages[-1].character_frames: stages[-1].character_frames.append(pose.frame)
		if index == (8 if str(stages[-1].id) == "nadi_gesture" else 24):
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png(OUT + str(stages[-1].id) + ".png")
	stages[-1].environment_end = game.environment_stage.effect_snapshot()
	if str(stages[-1].id) == "reduced_motion":
		assert(stages[-1].environment_start.time == stages[-1].environment_end.time, "Reduced motion must freeze environment time")
