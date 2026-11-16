extends SceneTree
## Authored Foley routing plus real successful/invalid presentation callbacks.
## This is functional evidence; sound quality still needs listening review.

var main: Control
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if not ProjectSettings.globalize_path("user://").begins_with(project + "/work/"):
		printerr("INTERACTION_AUDIO_TESTS_REFUSED: isolate XDG_DATA_HOME inside repository work/; this test writes automatic saves.")
		quit(2)
		return
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.state.settings.music = 0.0
	main.state.settings.ambience = 0.0
	main.state.settings.sound = 0.8
	main.state.settings.voice = 0.0
	main.state.settings.auto_voice = false
	main.state.settings.reduced_motion = true
	main._apply_audio()
	main._new_game()
	main._close_modal()
	var mapping: Dictionary = main.interaction_audio
	_expect(mapping.get("version", 0) == 1, "authored action sound map loads")
	var expected := {"hotspots": [], "travel": [], "recipe_results": [], "puzzle_success": []}
	for location in main.state.data.locations:
		expected.travel.append(str(location.id))
		for spot in location.hotspots: expected.hotspots.append(str(spot.id))
	for recipe in main.state.data.recipes: expected.recipe_results.append(str(recipe.result))
	for puzzle in main.state.data.puzzles: expected.puzzle_success.append(str(puzzle.id))
	for group in expected:
		var entries: Dictionary = mapping.get(group, {})
		_expect(entries.size() == expected[group].size(), "complete action coverage without orphan mappings: " + group)
		for id in expected[group]:
			_expect(entries.has(id), "authored choice exists: " + group + "/" + id)
			var cue := str(entries.get(id, ""))
			_expect(main.audio_catalog.sfx.has(cue), "mapped sound is locally catalogued: " + group + "/" + id)
	_expect(mapping.hotspots.ch1_l1_b == "rope", "mooring rope has a fibre/rope interaction")
	_expect(mapping.hotspots.ch1_l2_b == "metal", "brass shutter plate has a metal interaction")
	_expect(mapping.hotspots.ch1_l4_a == "glass", "paste jar has a glass interaction")
	_expect(mapping.hotspots.ch1_l6_c == "book", "bound key register has a book interaction")
	_expect(mapping.hotspots.ch4_l5_a == "ui", "fixed memorial stones are not treated as struck props")
	_expect(mapping.hotspots.ch4_l6_c == "ui", "testimony uses quiet confirmation instead of arbitrary Foley")
	_expect(mapping.travel.ch4_l1 == "water", "reed jetty arrival uses a small landing splash")
	_expect(mapping.recipe_results.sealed_copies == "cloth", "oilcloth packaging is distinct from metal tools")
	_expect(mapping.puzzle_success.p12 == "paper", "route diagram does not sound like a machinery activation")
	_expect(mapping.puzzle_success.p13 == "campaign_mechanism", "disconnected valve training has mechanical feedback")
	for chapter in main.state.data.chapters:
		_expect(mapping.puzzle_success[chapter.final_puzzle] == "chapter", "chapter resolution retains its musical confirmation")
	_expect(main._interaction_sound("hotspots", "unknown", "paper") == "paper", "missing action safely falls back")
	main.interaction_audio["temporary_bad_group"] = "invalid"
	_expect(main._interaction_sound("temporary_bad_group", "unknown", "collect") == "collect", "malformed optional group safely falls back")
	main.interaction_audio.hotspots["temporary_bad_target"] = "not_in_catalog"
	_expect(main._interaction_sound("hotspots", "temporary_bad_target", "paper") == "paper", "unavailable material safely falls back")
	main.interaction_audio.erase("temporary_bad_group")
	main.interaction_audio.hotspots.erase("temporary_bad_target")
	# Exercise the actual UI callback with the real decoder/catalogue. Stopping
	# previous sounds avoids testing a deliberately full SFX pool or cooldown.
	for entry in [
		["ch1_l1", "ch1_l1_a", "wood"],
		["ch1_l1", "ch1_l1_b", "rope"],
		["ch1_l1", "ch1_l1_c", "paper"],
		["ch1_l2", "ch1_l2_b", "metal"],
		["ch1_l6", "ch1_l6_c", "book"],
		["ch1_l4", "ch1_l4_a", "glass"],
		["ch1_l3", "ch1_l3_c", "wood"],
		["ch1_l5", "ch1_l5_c", "rope"],
		["ch1_l6", "ch1_l6_a", "cloth"]
	]:
		_expect(main.state.visit(entry[0]), "representative evidence is reachable")
		if not main.state.search_complete(entry[0]):
			for item in main.state.searches[entry[0]].items: main.state.find_search_object(entry[0], item.id)
		main.audio.stop_all()
		var before: int = main.audio.debug_state().sfx_started
		main._examine(entry[1])
		_expect(main.state.evidence.has(entry[1]), "examination still records its clue: " + entry[1])
		_expect(main.audio.debug_state().sfx_started == before + 1, "one material effect per examination; no generic pickup layer")
		_expect(main.audio.debug_state().sfx_last_event.get("cue", "") == entry[2], "actual callback plays material: " + entry[2])
		main._close_modal()
		await process_frame
	main.audio.stop_all()
	var before: int = main.audio.debug_state().sfx_started
	main._examine("unknown")
	_expect(main.audio.debug_state().sfx_started == before, "invalid examination does not play success Foley")
	main._travel("ch1_l1")
	_expect(main.audio.debug_state().sfx_last_event.get("cue", "") == "campaign_steps_wet", "harbour travel plays wet arrival steps")
	main.audio.stop_all()
	main._travel("ch1_l2")
	_expect(main.audio.debug_state().sfx_last_event.get("cue", "") == "campaign_door", "office travel plays its entry door")
	before = main.audio.debug_state().sfx_started
	main._travel("ch6_l6")
	_expect(main.audio.debug_state().sfx_started == before and main.state.location_id == "ch1_l2", "locked travel does not play arrival Foley or move the player")
	for combination in [["tissue", "paste", "repair_kit", "paper"], ["bell_cord", "bell_hook", "bell_pull", "rope"]]:
		main.audio.stop_all()
		before = main.audio.debug_state().sfx_started
		main._combine(combination[0], combination[1])
		_expect(main.state.inventory.has(combination[2]), "material feedback preserves recipe result")
		_expect(main.audio.debug_state().sfx_started == before + 1 and main.audio.debug_state().sfx_last_event.get("cue", "") == combination[3], "recipe plays its own construction material")
		main._close_modal()
		main._combine(combination[0], combination[1])
		_expect(main.audio.debug_state().sfx_started == before + 1, "duplicate recipe does not play a fresh success effect")
		main._close_modal()
	main.state.visit("ch1_l1")
	main.audio.stop_all()
	before = main.audio.debug_state().sfx_started
	main.selected_puzzle = "p01"
	main._submit("found")
	_expect(main.state.solved.has("p01") and main.audio.debug_state().sfx_started == before, "completed picture search already resolved the first investigation; duplicate submission adds no success sound")
	main._close_modal()
	main.state.settings.sound = 0.0
	main._apply_audio()
	before = main.audio.debug_state().sfx_started
	main._examine("ch1_l1_b")
	_expect(main.audio.debug_state().sfx_started == before, "material effects respect sound-volume mute")
	main._close_modal()
	main.stop_audio_for_exit()
	await create_timer(0.25).timeout
	main.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	if failures == 0: print("INTERACTION_AUDIO_TESTS_OK: ", checks, " checks; authored actions and actual offline effect routing")
	else: printerr("INTERACTION_AUDIO_TESTS_FAILED: ", failures, " failures / ", checks)
	quit(0 if failures == 0 else 1)

func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("INTERACTION AUDIO FAIL: ", message)
