extends SceneTree
## Automated presentation traversal using authored answers, NOT a human playtest.
## XDG_DATA_HOME="$PWD/work/user-data" godot --headless --path . --script tests/test_ui.gd
## Omit --headless and append -- --screenshots=/absolute/repository/work/ui-review
## to capture the live Compatibility renderer at chapter/puzzle/ending boundaries.

var main: Control
var checks := 0
var failures := 0
var screenshot_dir := ""
var captured: Dictionary = {}
var conversations_seen: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var user_directory := ProjectSettings.globalize_path("user://")
	if not user_directory.begins_with(project + "/work/"):
		printerr("UI_TESTS_REFUSED: this traversal creates automatic saves. Set XDG_DATA_HOME to the repository's work/user-data directory to isolate test data.")
		quit(2)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screenshots="):
			screenshot_dir = argument.trim_prefix("--screenshots=")
			if not screenshot_dir.begins_with(project + "/work/"):
				printerr("UI_TESTS_REFUSED: screenshots must stay inside the repository work directory.")
				quit(2)
				return
			DirAccess.make_dir_recursive_absolute(screenshot_dir)
	var scene: PackedScene = load("res://scenes/main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_expect(not main.state.data.is_empty(), "main scene loads the complete case")
	if main.state.data.is_empty():
		await _finish()
		return
	_expect(not main.playing, "title opens before a case begins")
	_expect_title_menu()
	_expect(_visible_text(main.page).contains(str(main.case_guide.data.title_intro)), "title introduces what happened and what the player must solve")
	_expect(not _visible_text(main.page).contains("DEVELOPMENT BUILD"), "title omits development-build status")
	await _capture("00-title")
	main._new_game()
	await process_frame
	_expect(main.playing and main.state.location_id == "ch1_l1", "new game begins at the ferry landing")
	_expect(main.modal_name == "A letter without a return address", "opening story is presented")
	_press("Continue")
	await process_frame
	_expect(main.modal_name == main.state.data.chapters[0].title, "opening continues into chapter introduction")
	_press("Continue")
	await process_frame
	_expect(main.overlay == null, "chapter introduction can be dismissed")
	await _exercise_panels()
	# The content solver remains in the presentation layer: travel, examination,
	# combination and solution submission all go through main.gd callbacks.
	for _pass in range(main.state.data.puzzles.size() + 1):
		var before_count: int = main.state.solved.size()
		for location in main.state.data.locations:
			if not main.state.chapter_unlocked(location.chapter):
				continue
			var unseen := false
			for hotspot in location.hotspots:
				if hotspot.id not in main.state.evidence:
					unseen = true
			if unseen:
				main._travel(str(location.id))
				await process_frame
				_expect(main.state.location_id == location.id, "UI travel reaches " + location.id)
				_expect(main._texture(str(location.art)) != null, "room painting loads: " + location.id)
				if str(location.id).ends_with("_l1"):
					await _capture(str(location.chapter) + "-arrival")
				if main.state.searches.has(location.id):
					for item in main.state.searches[location.id].items:
						main._find_room_object(str(item.id))
						await process_frame
						_expect(item.id in main.state.search_progress.get(location.id, []), "UI search records " + location.id + "/" + item.id)
					main._close_modal()
					await process_frame
				for hotspot in location.hotspots:
					main._examine(str(hotspot.id))
					await process_frame
					_expect(hotspot.id in main.state.evidence, "UI examination records " + hotspot.id)
					_expect(main.modal_name == hotspot.label, "evidence panel uses its authored title")
					_expect(_visible_text(main.overlay).contains(str(hotspot.text)), "evidence prose is displayed")
					main._close_modal()
					await process_frame
		for _craft in range(main.state.data.recipes.size() + 1):
			var crafted := false
			for recipe in main.state.data.recipes:
				if recipe.result not in main.state.inventory and recipe.ingredients[0] in main.state.inventory and recipe.ingredients[1] in main.state.inventory:
					main._inventory()
					main._combine(str(recipe.ingredients[1]), str(recipe.ingredients[0]))
					await process_frame
					_expect(recipe.result in main.state.inventory, "UI combination produces " + recipe.result)
					_expect(recipe.ingredients[0] in main.state.inventory and recipe.ingredients[1] in main.state.inventory, "collection history retains both component records")
					var active_items: Array = main.state.active_inventory()
					_expect(recipe.ingredients[0] not in active_items and recipe.ingredients[1] not in active_items and recipe.result in active_items, "active satchel replaces components with the useful assembled object")
					_expect(main.modal_name == "Objects carried forward", "combination stays in the inventory without an intermediate screen")
					main._close_modal()
					if not captured.has("panel-inventory-populated"):
						main._inventory()
						await process_frame
						await _capture("panel-inventory-populated")
						main._close_modal()
					crafted = true
			if not crafted:
				break
		await _exercise_dialogues()
		for puzzle in main.state.data.puzzles:
			if not main.state.can_solve(puzzle.id):
				continue
			main._travel(str(puzzle.location))
			main._open_puzzle(str(puzzle.id))
			await process_frame
			_expect(main.selected_puzzle == puzzle.id and main.modal_name == puzzle.title, "investigation panel opens: " + puzzle.id)
			_expect(is_instance_valid(main.puzzle_feedback), "investigation feedback exists: " + puzzle.id)
			var previous := _progress()
			main._submit(_wrong_answer(puzzle))
			_expect(_progress() == previous, "realistic wrong answer preserves progression: " + puzzle.id)
			_expect(not main.puzzle_feedback.text.is_empty(), "wrong answer gets visible feedback: " + puzzle.id)
			# This traversal exercises every hint level, which a scarce economy cannot fund
			# for 55 puzzles. Fund it consistently: the saved ledger stays valid.
			if main.state.insight_balance() < 2:
				main.state.detective.starting_insight += 2
				main.state.detective.insight += 2
			for hint_index in range(3):
				if hint_index > 0: main.state.advance_puzzle(str(puzzle.id), 30.0)
				main._hint(str(puzzle.id))
			_expect(main.hint_levels[puzzle.id] == 3, "three earned and purchased hint levels are recorded: " + puzzle.id)
			_expect(main.puzzle_feedback.text.contains(str(puzzle.hints[2])), "final hint displays: " + puzzle.id)
			var hint_balance: int = main.state.insight_balance()
			main.state.advance_puzzle(str(puzzle.id), 30.0)
			main._hint(str(puzzle.id))
			_expect(main.state.puzzle_status(str(puzzle.id)).hints_used == 3 and main.state.insight_balance() == hint_balance, "fourth puzzle hint is blocked without a charge: " + puzzle.id)
			if not captured.has("puzzle-" + str(puzzle.type)):
				await _capture("puzzle-" + str(puzzle.type))
			if puzzle.type == "routing":
				await _capture("board-" + str(puzzle.id))
			if puzzle.type in ["code", "order"] and not captured.has("puzzle-" + str(puzzle.type) + "-large-text"):
				main.state.settings.large_text = true
				main._open_puzzle(str(puzzle.id))
				await process_frame
				await _capture("puzzle-" + str(puzzle.type) + "-large-text")
				main.state.settings.large_text = false
				main._open_puzzle(str(puzzle.id))
				await process_frame
			await _submit_through_widgets(puzzle)
			_expect(puzzle.id in main.state.solved, "UI accepts authored solution: " + puzzle.id)
			_expect(main.overlay != null, "solution consequence is presented: " + puzzle.id)
			var chapter: Dictionary = main._chapter(str(puzzle.chapter))
			if puzzle.id == chapter.final_puzzle:
				var expected_voice: Array = [str(chapter.id) + "_closing"]
				if chapter.id == main.state.data.chapters[-1].id: expected_voice.append("narration_ending")
				_expect(main.voice_ids == expected_voice, "chapter consequence queues exact narration: " + str(chapter.id))
				await _capture(str(chapter.id) + "-conclusion")
				await _checkpoint(str(puzzle.id))
			main._close_modal()
			await process_frame
		if main.state.solved.size() == main.state.data.puzzles.size():
			break
		if main.state.solved.size() == before_count:
			_expect(false, "UI traversal stalled without solving another investigation")
			break
	_expect(main.state.solved.size() == 60, "all sixty investigations completed through UI callbacks")
	await _exercise_dialogues()
	_expect(conversations_seen.size() == 36, "all 36 authored dialogue topics were exercised")
	main._travel(str(main.state.data.puzzles[-1].location))
	main._open_puzzle(str(main.state.data.puzzles[-1].id))
	await process_frame
	_expect(_find_button(main.overlay, "Read the conclusion again") != null, "resolved final case offers ending replay")
	_press("Read the conclusion again")
	await process_frame
	_expect(main.modal_name == "The record belongs to everyone", "ending can be replayed after completion")
	_expect(_visible_text(main.overlay).contains(str(main.state.data.ending)), "complete ending prose is displayed")
	await _capture("ending-replay")
	main._close_modal()
	await _exercise_panels()
	await _finish()


func _exercise_panels() -> void:
	var casebook_title := "Casebook · " + str(main.state.get_location(main.state.location_id).title)
	for pair in [[KEY_M, "A city built around the tide"], [KEY_J, casebook_title], [KEY_C, casebook_title], [KEY_I, "Objects carried forward"]]:
		main._close_modal()
		var key := InputEventKey.new()
		key.pressed = true
		key.keycode = pair[0]
		main._unhandled_key_input(key)
		await process_frame
		_expect(main.modal_name == pair[1], "keyboard shortcut opens " + pair[1])
		_expect(main.page.focus_behavior_recursive == Control.FOCUS_BEHAVIOR_DISABLED, "modal prevents focus moving behind it")
		var escape := InputEventKey.new()
		escape.pressed = true
		escape.keycode = KEY_ESCAPE
		main._unhandled_key_input(escape)
		_expect(main.overlay == null and main.page.focus_behavior_recursive == Control.FOCUS_BEHAVIOR_INHERITED, "Escape closes modal and restores scene focus")
	for method in ["_map", "_casebook", "_journal", "_people", "_inventory", "_pause"]:
		main.call(method)
		await process_frame
		_expect(is_instance_valid(main.overlay), "panel renders: " + method)
		if method == "_pause": _expect_pause_menu()
		await _capture("panel" + method)
		main._close_modal()
	main._settings()
	await process_frame
	var sliders := _nodes_of_type(main.overlay, "HSlider")
	_expect(sliders.size() == 4, "four independent audio settings have sliders")
	if sliders.size() == 4:
		sliders[0].value = 0.35
		sliders[3].value = 0.4
		_expect(is_equal_approx(float(main.state.settings.music), 0.35), "music slider changes preference")
		_expect(is_equal_approx(float(main.state.settings.sound), 0.4), "sound slider changes preference")
	var toggles := _nodes_of_type(main.overlay, "CheckButton")
	_expect(toggles.size() == 5, "five accessibility/display toggles are available")
	for toggle in toggles:
		if toggle.text == "Larger reading text":
			toggle.button_pressed = true
			_expect(main.state.settings.large_text, "larger text toggle is wired")
		elif toggle.text == "Always label points of interest":
			toggle.button_pressed = true
			_expect(main.state.settings.hotspot_labels, "labels toggle is wired")
		elif toggle.text == "Reduce motion":
			toggle.button_pressed = true
			_expect(main.state.settings.reduced_motion, "reduced motion toggle is wired")
	await _capture("panel-settings")
	_press("Apply and return")
	await process_frame
	_expect(main.overlay == null, "settings apply returns to scene")
	# Verify preferences are persisted by the controls, without relaunching the app.
	var saved_settings: Dictionary = main.state.settings.duplicate(true)
	main.state.settings.music = 1.0
	main._load_preferences()
	_expect(main.state.settings == saved_settings, "settings persist and restore")
	# Return text and labels to default after capturing the accessibility case.
	main.state.settings.large_text = false
	main.state.settings.hotspot_labels = false
	main._save_preferences()
	main._show_location()


func _exercise_dialogues() -> void:
	for conversation in main.dialogue_data:
		if not main._requirements_met(conversation.get("requires", [])):
			continue
		var location: Dictionary = main.state.get_location(str(conversation.location))
		if not main.state.chapter_unlocked(str(location.chapter)):
			continue
		for topic in conversation.topics:
			var key: String = str(conversation.location) + "/" + str(conversation.character) + "/" + str(topic.question)
			if conversations_seen.has(key) or not main._requirements_met(topic.get("requires", [])):
				continue
			main._travel(str(conversation.location))
			main._conversation(conversation)
			await process_frame
			_expect(_find_button(main.overlay, str(topic.question)) != null, "unlocked dialogue topic is visible")
			_press(str(topic.question))
			await process_frame
			_expect(_visible_text(main.overlay).contains(str(topic.reply)), "dialogue reply appears")
			if not str(topic.get("evidence", "")).is_empty():
				_expect(topic.evidence in main.state.evidence, "dialogue records its associated evidence")
			conversations_seen[key] = true
			if not captured.has("dialogue-" + str(conversation.character)):
				await _capture("dialogue-" + str(conversation.character))
			main._close_modal()


func _submit_through_widgets(puzzle: Dictionary) -> void:
	if puzzle.solution is Array:
		main._append_answer(str(puzzle.options[0]))
		_press("Undo")
		_expect(main.answer.is_empty(), "Undo removes a sequence entry")
		main._append_answer(str(puzzle.options[0]))
		_press("Clear")
		_expect(main.answer.is_empty(), "Clear resets sequence")
		if puzzle.type == "routing":
			var board: Variant = main.get("active_board")
			_expect(board is Control, "routing investigation has an interactive diagram")
			if board is Control:
				_expect(board.selected_path.is_empty(), "Clear resets the diagram path")
				for value in puzzle.solution:
					var found := false
					for node_button in _nodes_of_type(board, "Button"):
						if node_button.get_meta("route_option", "") == value:
							node_button.pressed.emit()
							found = true
							break
					_expect(found, "diagram button maps to answer option " + str(value))
				_expect(board.selected_path == puzzle.solution, "selected diagram path follows node button clicks")
		else:
			for value in puzzle.solution:
				main._append_answer(str(value))
		_expect(main.answer == puzzle.solution, "sequence widget preserves authored order")
		_press("Test the sequence")
	elif puzzle.type == "code":
		main.answer_entry.text = str(puzzle.solution)
		main.answer_entry.text_submitted.emit(main.answer_entry.text)
	elif puzzle.type in ["choice", "deduction"]:
		_press(str(puzzle.solution))
	elif puzzle.type == "hidden":
		_press("Compare the recovered evidence")
	elif puzzle.type == "assembly":
		_press("Apply the prepared assembly")
	await process_frame


func _checkpoint(id: String) -> void:
	var snapshot := _progress()
	main._pause()
	_expect_pause_menu()
	_press("Save and return to title")
	await process_frame
	_expect(not main.playing and main.overlay == null, "save and return reaches the title at " + id)
	_expect(FileAccess.file_exists("user://autosave.json"), "automatic checkpoint exists at " + id)
	_expect_title_menu()
	# Discard only the in-memory state, so Continue must actually restore the
	# saved chapter boundary, inventory and every completed picture search.
	main.state.new_game()
	_press("Continue investigation")
	await process_frame
	_expect(main.playing and _progress() == snapshot, "title Continue preserves complete chapter progress at " + id)


func _expect_title_menu() -> void:
	var labels := _button_labels(main.page)
	_expect(labels == ["Continue investigation", "Begin a new investigation", "Settings & accessibility", "Quit"], "title has exactly the four requested actions in order")


func _expect_pause_menu() -> void:
	var labels := _button_labels(main.overlay)
	labels.erase("Close  Esc")
	_expect(labels == ["Return to investigation", "Settings & accessibility", "Save and return to title", "Save and quit"], "pause has exactly the four requested actions in order")


func _button_labels(node: Node) -> Array:
	var labels: Array = []
	for button in _nodes_of_type(node, "Button"):
		if button.is_visible_in_tree(): labels.append(str(button.text))
	return labels


func _wrong_answer(puzzle: Dictionary) -> Variant:
	if puzzle.solution is Array:
		var wrong: Array = puzzle.solution.duplicate()
		for i in range(wrong.size()):
			for j in range(i + 1, wrong.size()):
				if wrong[i] != wrong[j]:
					var first: Variant = wrong[i]
					wrong[i] = wrong[j]
					wrong[j] = first
					return wrong
		wrong.append(str(puzzle.options[0]))
		return wrong
	for option in puzzle.options:
		if option != puzzle.solution:
			return str(option)
	return "not-" + str(puzzle.solution)


func _progress() -> Dictionary:
	return {"location": main.state.location_id, "solved": main.state.solved.duplicate(), "evidence": main.state.evidence.duplicate(), "inventory": main.state.inventory.duplicate(), "search_progress": main.state.search_progress.duplicate(true)}


func _find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result := _find_button(child, text)
		if result != null:
			return result
	return null


func _press(text: String) -> void:
	var button := _find_button(main.overlay if is_instance_valid(main.overlay) else main, text)
	_expect(button != null, "button exists: " + text)
	if button != null:
		_expect(not button.disabled, "button enabled: " + text)
		button.pressed.emit()


func _visible_text(node: Node) -> String:
	var result := str(node.text) if node is Label else ""
	for child in node.get_children():
		result += "\n" + _visible_text(child)
	return result


func _nodes_of_type(node: Node, type_name: String) -> Array:
	var result: Array = []
	if node.is_class(type_name):
		result.append(node)
	for child in node.get_children():
		result.append_array(_nodes_of_type(child, type_name))
	return result


func _capture(name: String) -> void:
	if captured.has(name):
		return
	captured[name] = true
	if screenshot_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	_expect(picture.save_png(screenshot_dir.path_join(name + ".png")) == OK, "rendered screenshot saved: " + name)


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("UI FAIL: ", message)


func _finish() -> void:
	if is_instance_valid(main):
		main.stop_audio_for_exit()
	await create_timer(0.2).timeout
	if failures == 0:
		print("UI_TESTS_OK: ", checks, " assertions; 60 authored-answer UI submissions; full chapter traversal; realistic wrong answers; hints; autosave/title Continue; four-action menus; map/casebook/inventory/settings; ", conversations_seen.size(), " dialogue topics; ending replay. This is not a human playthrough, duration measurement, or native Windows test.")
	else:
		printerr("UI_TESTS_FAILED: ", failures, " of ", checks, " assertions")
	quit(0 if failures == 0 else 1)
