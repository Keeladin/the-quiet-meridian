extends RefCounted
## Packaged-build smoke check, started by `--smoke-test` (tools/verify.py runs it against
## extracted Linux and Windows archives). Exercises real presentation paths without using
## or overwriting player saves. Kept out of main.gd so gameplay code carries no test logic.

func run(main: Node) -> void:
	# Exercises real presentation paths without using or overwriting player saves.
	var probe: String = "user://package-smoke-probe.json"
	if not main.state.save_game(probe) or not main.state.save_game(probe) or not main.state.load_game(probe) or not main.state.load_game(probe + ".bak"):
		push_error("Packaged save roundtrip failed: " + main.state.last_error)
		main.get_tree().quit(1)
		return
	DirAccess.remove_absolute(probe)
	DirAccess.remove_absolute(probe + ".bak")
	for path in ["res://assets/art/portraits/cast.png", "res://assets/art/inventory-atlas.png", "res://assets/art/evidence-atlas.png"]:
		if main._texture(path) == null:
			push_error("Missing packaged atlas: " + path)
			main.get_tree().quit(1)
			return
	for category in ["music", "ambience", "sfx"]:
		if main.audio_catalog.get(category, {}).is_empty():
			push_error("Missing audio catalog category: " + category)
			main.get_tree().quit(1)
			return
		for cue in main.audio_catalog[category].values():
			var path: String = str(cue.path)
			if not ResourceLoader.exists(path) or not load(path) is AudioStream:
				push_error("Missing packaged audio: " + path)
				main.get_tree().quit(1)
				return
	for id in ["iona", "mara", "rowan", "nadi", "sera", "elian", "ada"]:
		if main._texture("res://assets/art/characters/" + id + "-expressions.png") == null:
			push_error("Missing packaged expression atlas: " + id)
			main.get_tree().quit(1)
			return
	var packaged_voices := 0
	for id in main.voice_catalog.get("lines", {}):
		var entry: Dictionary = main.voice_catalog.lines[id]
		var voice_path := str(entry.get("path", ""))
		if voice_path.is_empty(): continue
		var stream := load(voice_path) as AudioStream
		if stream == null or not main.audio.has_voice(str(id)) or stream.get_length() <= 0.0 or absf(stream.get_length() - float(entry.duration)) > 0.1:
			push_error("Missing or invalid packaged voice: " + str(id))
			main.get_tree().quit(1)
			return
		packaged_voices += 1
	for location in main.state.data.locations:
		var art: Texture2D = main._texture(str(location.art))
		if art == null or art.get_width() < 1:
			push_error("Missing packaged illustration: " + str(location.art))
			main.get_tree().quit(1)
			return
	for definition in main.state.searches.values():
		if not ResourceLoader.exists(str(definition.art)) or main._texture(str(definition.art)) == null:
			push_error("Missing packaged search painting: " + str(definition.art))
			main.get_tree().quit(1)
			return
	main._show_title()
	await main.get_tree().process_frame
	main.playing = true
	main._show_location()
	await main.get_tree().process_frame
	main._map()
	await main.get_tree().process_frame
	main._casebook()
	await main.get_tree().process_frame
	main._casebook("story")
	await main.get_tree().process_frame
	main._journal()
	await main.get_tree().process_frame
	main._inventory()
	await main.get_tree().process_frame
	main._settings()
	await main.get_tree().process_frame
	main._close_modal()
	print("QUIET_MERIDIAN_SMOKE_OK: 36 hidden-object rooms, authored target lists and room audio, expression atlases, save roundtrip, title, map, casebook, inventory and settings; %d packaged voices decoded" % packaged_voices)
	await main._quit_game()
