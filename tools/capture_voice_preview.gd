extends SceneTree
## Local, unapproved Mara audition staged in memory in the real game UI/mixer.
## No production voice manifest, source audio or saved progress is modified.

const FPS := 24
const OUT := "res://builds/previews/voice-audition/"
const SOURCE := "res://assets/audio/auditions/2026-11-14/mara_refuge_r0-56e17e6bda42440c93a80b5508e108e5/candidate.wav"
const LINE := "mara_refuge_r0"
var game: Control
var caption: Label
var samples: Array = []
var stages: Array = []
var frames := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	assert(ProjectSettings.globalize_path("user://").begins_with(project + "/work/"), "Preview must use isolated work storage")
	root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.state.new_game()
	game.state.settings.merge({"reduced_motion": false, "fullscreen": false, "auto_voice": false,
		"subtitles": true, "music": 0.75, "ambience": 0.55, "voice": 0.95}, true)
	var audition: Dictionary = game.voice_catalog.duplicate(true)
	audition.lines[LINE].path = ProjectSettings.globalize_path(SOURCE)
	audition.lines[LINE].gain_db = 6.0
	var subtitle_preview: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://work/voice-preview/audition-subtitles.json"))
	audition.lines[LINE].subtitles = subtitle_preview.cues
	game.voice_catalog = audition
	game.audio.configure(game.audio_catalog, audition, game.state.settings)
	game.playing = true
	game.session_timer = 0.0
	var conversation: Dictionary = {}
	for entry in game.dialogue_data:
		if entry.id == "mara_refuge": conversation = entry; break
	assert(not conversation.is_empty(), "Mara scene is required")
	game.state.location_id = conversation.location
	game._show_location()
	_make_caption()
	_make_panel()
	game.audio.play_music("ch4")
	_stage("Music and ambience · silent portrait", 2.0)
	await _hold(2.0, "ready")
	game.voice_replay.pressed.emit()
	_stage("Full local Mara take · voice bus controls mouth activity", 32.0)
	await _hold(32.0, "full-take")
	_stage("After speech · music recovers smoothly", 2.0)
	await _hold(2.0, "recovery")
	game.state.settings.reduced_motion = true
	game.character_stage.set_reduced_motion(true)
	game.environment_stage.set_reduced_motion(true)
	game._apply_audio()
	game.voice_replay.pressed.emit()
	_stage("Reduced motion ON · short audition replay", 4.0)
	await _hold(4.0, "reduced-motion")
	game.audio.stop_voice()
	await _hold(0.25, "fade")
	game.stop_audio_for_exit()
	var report := {"status": "UNAPPROVED AUDITION — not a production voice or approved performance",
		"capture": "Native Godot Movie Maker; actual main.gd, AudioDirector, CharacterStage and chapter-four mix",
		"line_id": LINE, "source": SOURCE, "source_gain_db": 6.0, "source_modified": false,
		"settings": game.state.settings, "engine": Engine.get_version_info().string, "fps": FPS,
		"resolution": [1280,800], "stages": stages, "samples": samples,
		"scope": "Only the in-memory catalogue points at the local audition. Production voice paths remain empty. No provider request or spending.",
		"limits": ["Not acting or listening approval", "Amplitude activity and preset speaking frames are not phoneme lip sync", "Full take retains original leading and trailing silence", "Sentence captions use approximate independent-ASR timestamps in memory only; timing is unreviewed"]}
	var output := FileAccess.open(OUT + "capture-manifest.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t") + "\n")
	print("VOICE_PREVIEW_CAPTURE_OK: ", frames, " frames; local unapproved Mara audition only")
	quit(0)

func _make_panel() -> void:
	var box: VBoxContainer = game._modal("Mara Venn · local voice audition")
	var row: HBoxContainer = game._hbox(box, 35)
	game.dialogue_character = "mara"
	game._add_character(row, "mara", 310)
	var dialogue: VBoxContainer = game._vbox(row, 24)
	game._label(dialogue, str(game.voice_catalog.lines[LINE].text), 25)
	game._voice_controls(dialogue, [LINE])
	game._button(dialogue, "Close audition", game._close_modal)

func _make_caption() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	root.add_child(layer)
	var backing := ColorRect.new()
	backing.color = Color(0.18, 0.055, 0.025, 0.98)
	backing.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	backing.offset_top = -34
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(backing)
	caption = Label.new()
	caption.add_theme_font_override("font", load("res://assets/fonts/body.ttf"))
	caption.add_theme_font_size_override("font_size", 16)
	caption.add_theme_color_override("font_color", Color("fff1d2"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backing.add_child(caption)

func _stage(title: String, duration: float) -> void:
	caption.text = "UNAPPROVED AUDITION · Mara  |  " + title
	stages.append({"title": title, "start": frames / float(FPS), "duration": duration})

func _hold(seconds: float, section: String) -> void:
	for index in int(round(seconds * FPS)):
		await process_frame
		frames += 1
		# Rendering runs the actual controller before capture; no animated pose is
		# injected to simulate a voice. Collect evidence of the mixer/portrait state.
		var mix: Dictionary = game.audio.debug_state()
		var pose: Dictionary = game.character_stage.pose_snapshot()
		samples.append({"t": frames / float(FPS), "section": section, "voice_position": mix.voice_position,
			"playing": mix.voice_playing, "active": mix.voice_active, "peak_db": mix.voice_peak_db,
			"duck": mix.duck_gain, "pose": pose, "subtitle": game.subtitle_label.text})
		if (section == "full-take" and index in [48, 648]) or (section == "reduced-motion" and index == 72):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT + section + "-" + str(index) + ".png")
