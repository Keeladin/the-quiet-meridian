extends SceneTree
## Staged first-chapter actions through the real UI and audio mixer.
const OUT := "res://builds/previews/sfx-game/"
var game: Control
var caption: Label
var events: Array = []
var frames := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	assert(ProjectSettings.globalize_path("user://").begins_with(project + "/work/"), "Isolated preview storage required")
	root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.state.new_game()
	game.state.settings.merge({"reduced_motion": false, "fullscreen": false, "hotspot_labels": false,
		"music": 0.6, "ambience": 0.6, "sound": 0.8, "voice": 0.9}, true)
	game._apply_audio()
	game.playing = true
	game._show_location()
	var layer := CanvasLayer.new()
	layer.layer = 90
	root.add_child(layer)
	var backing := ColorRect.new()
	backing.color = Color(0.035, 0.065, 0.08, 0.96)
	backing.position = Vector2(0, 763)
	backing.size = Vector2(1280, 37)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(backing)
	caption = Label.new()
	caption.position = Vector2(20, 768)
	caption.add_theme_font_size_override("font_size", 17)
	layer.add_child(caption)
	await _hold("Native game capture · material Foley + chapter music and harbour ambience", 2)
	for id in ["ch1_l1_a", "ch1_l1_b", "ch1_l1_c"]:
		game._examine(id)
		_record("examine", id)
		var material := {"ch1_l1_a": "wooden dispatch box", "ch1_l1_b": "mooring rope", "ch1_l1_c": "receipt paper"}
		await _hold("Examining the receipt scraps · " + str(material[id]) + " handling", 2)
		game._close_modal()
		await _hold("Recorded evidence stays available without circles", 0.5)
	await _hold("All three recorded · clear illustration, no persistent target circles", 3)
	game.state.settings.hotspot_labels = true
	game._show_location()
	await _hold("Optional F1 reveal · named evidence tags with recorded checkmarks", 3)
	game.state.settings.hotspot_labels = false
	game._show_location()
	game._travel("ch1_l2")
	_record("travel", "ch1_l2")
	await _hold("Enter the Tide Office · door Foley, smooth ambience transition", 3)
	game._examine("ch1_l2_b")
	_record("examine", "ch1_l2_b")
	await _hold("Brass shutter plate · material-specific interaction", 3)
	game._close_modal()
	game._travel("ch1_l1")
	_record("travel", "ch1_l1")
	await _hold("Return to the wet landing · surface-specific footsteps", 3)
	game.stop_audio_for_exit()
	var report := {"status": "Development alpha preview; staged opening actions, not a playthrough",
		"capture": "Native Godot Movie Maker; real main.gd callbacks and AudioDirector mix",
		"engine": Engine.get_version_info().string, "fps": 24, "frames": frames,
		"settings": game.state.settings, "events": events, "scope": "Opening clues only; no ending spoilers or production voices. Isolated save data."}
	var file := FileAccess.open(OUT + "capture-manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("SFX_PREVIEW_CAPTURE_OK: ", frames, " frames")
	quit(0)

func _record(action: String, id: String) -> void:
	var audio: Dictionary = game.audio.debug_state()
	assert(str(audio.last_error).is_empty(), "Audio failed during preview")
	events.append({"time": frames / 24.0, "action": action, "id": id, "sound": audio.sfx_last_event})

func _hold(text: String, seconds: float) -> void:
	caption.text = text
	for i in range(int(round(seconds * 24))):
		await process_frame
		frames += 1
