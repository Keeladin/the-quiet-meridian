extends SceneTree
const SearchState = preload("res://scripts/hidden_object_state.gd")
const Canvas = preload("res://scripts/hidden_object_canvas.gd")
var failures := 0
var checks := 0
var scene: Control
var samples: Array[Vector2] = []

func _initialize() -> void:
	call_deferred("_run")

func expect(ok: bool, explanation: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", explanation)

func _run() -> void:
	var root_dir := ProjectSettings.globalize_path("res://")
	expect(ProjectSettings.globalize_path("user://").begins_with(root_dir + "work/"), "test save directory is isolated")
	if failures: quit(2); return
	var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/hidden-object-dispatch.json"))
	var observations: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/hidden_object_observations.json"))
	for item in definition.items:
		var point: Array = observations.interiors[item.id]
		samples.append(Vector2(point[0], point[1]))
	var state := SearchState.new()
	expect(state.configure(definition), "definition validates")
	expect(not state.complete() and not state.find_object("missing"), "unknown objects cannot complete a search")
	for i in range(samples.size()): expect(state.hit_at(samples[i]) == definition.items[i].id, "visible interior matches " + str(definition.items[i].name))
	expect(state.hit_at(Vector2(.9,.15)).is_empty(), "unlisted window is not a target")
	var gap: Array = observations.horseshoe_gap
	expect(state.hit_at(Vector2(gap[0], gap[1])).is_empty(), "empty centre of horseshoe is not its silhouette")
	for id in observations.alternatives:
		for point in observations.alternatives[id]:
			var match_id := state.hit_at(Vector2(point[0], point[1]))
			expect(match_id == id, "a visible alternative satisfies " + str(id))
			var already_found: bool = id in state.found
			expect(state.find_object(match_id) == not already_found, "a valid alternative is awarded exactly once")
			expect(not state.find_object(id), "another matching shape cannot duplicate its reward")
	state.found.clear()
	var invalid := definition.duplicate(true)
	invalid.items[0]["alternatives"] = [[[0.1,0.1],[2.0,0.2],[0.2,0.3]]]
	expect(not state.configure(invalid) and state.definition == definition, "invalid alternate hit regions cannot replace working content")
	state.find_object("bottle")
	expect(not state.find_object("bottle") and state.found.size() == 1, "repeat clicks cannot duplicate an object")
	var path := "user://hidden-object-state-test.json"
	expect(state.save_progress(path), "partial search saves")
	var restored := SearchState.new()
	restored.configure(definition)
	expect(restored.load_progress(path) and restored.found == state.found, "partial search reloads")
	var bad := FileAccess.open(path, FileAccess.WRITE)
	bad.store_string(JSON.stringify({"version":1,"scene":definition.id,"found":["key","key"]}))
	bad.close()
	expect(not restored.load_progress(path) and restored.found == state.found, "invalid save cannot partially mutate live progress")
	for item in definition.items: state.find_object(str(item.id))
	expect(state.complete() and state.found.size() == definition.items.size(), "all listed clues finish the search")
	expect(state.save_progress(path) and restored.load_progress(path) and restored.complete(), "completed search reloads")
	DirAccess.remove_absolute(path)
	# Preview uses its own independent save, which must not leak between test runs.
	DirAccess.remove_absolute("user://dispatch-search-review-v2.json")
	scene = load("res://scenes/hidden_object_preview.tscn").instantiate()
	root.add_child(scene)
	await _settle()
	scene._toggle_sound()
	expect(scene.item_labels.size() == definition.items.size(), "all targets have checklist entries")
	for dimensions in [Vector2i(960,600), Vector2i(1280,800), Vector2i(1920,1080)]:
		root.size = dimensions
		await _settle()
		var picture: Rect2 = scene.canvas.picture_rect()
		expect(picture.size.x > 0 and picture.size.y > 0, "picture fits " + str(dimensions))
		for point in samples:
			var projected: Vector2 = scene.canvas.to_screen(point)
			expect(scene.canvas.to_image(projected).distance_to(point) < 0.0001, "pointer alignment survives resize")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(root_dir + "work/search-review/opening-%dx%d.png" % [dimensions.x, dimensions.y])
	root.size = Vector2i(1280,800)
	await _settle()
	var heard: Array[String] = []
	scene.audio.cue_played.connect(func(id): heard.append(id))
	scene._toggle_sound()
	scene._hint()
	expect(scene.hint_cooldown > 0 and scene.canvas.hinted == "mitten" and scene.search.found.is_empty(), "hint reveals but does not award an object")
	expect(heard.count("hint_revealed") == 1, "accepted hint plays the selected sound")
	scene._hint()
	expect(heard.count("hint_revealed") == 1, "cooldown click cannot replay the hint sound")
	scene.canvas.hint_remaining = 0
	scene.canvas.set_zoom(2, scene.canvas.to_screen(samples[2]))
	await _settle()
	var image_point: Vector2 = scene.canvas.to_image(scene.canvas.to_screen(samples[2]))
	expect(image_point.distance_to(samples[2]) < .0001, "zoom retains the actual object hit position")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = scene.canvas.to_screen(samples[2])
	scene.canvas._gui_input(click)
	expect("bottle" in scene.search.found and "[s]" in scene.item_labels.bottle.text, "actual picture click crosses off the matching name")
	expect(heard.count("object_found") == 1, "picture discovery uses the owner-selected recognition sound")
	scene.canvas._gui_input(click)
	expect(heard.count("object_found") == 1, "already-found object does not repeat its sound")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(root_dir + "work/search-review/zoom.png")
	scene.canvas.set_zoom(1)
	for point in samples: scene.canvas.select_point(scene.canvas.to_screen(point))
	await _settle()
	expect(scene.search.complete() and is_instance_valid(scene.complete_panel), "all actual picture clicks award the receipt")
	expect("symbol_understood" in heard and heard.count("search_completed") == 1, "symbol meaning and final search have distinct selected sounds")
	expect(scene.hint_button.disabled, "completed searches do not offer meaningless hints")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(root_dir + "work/search-review/complete.png")
	var again := SearchState.new()
	again.configure(definition)
	expect(again.load_progress("user://dispatch-search-review-v2.json") and again.complete(), "UI completion is saved")
	var resumed: Control = load("res://scenes/hidden_object_preview.tscn").instantiate()
	root.add_child(resumed)
	expect(is_instance_valid(resumed.complete_panel) and resumed.audio.scheduled.is_empty() and not resumed.audio.players.search_completed.playing, "loading a completed search does not replay reward sounds")
	resumed.stop_audio_for_exit()
	await create_timer(.25).timeout
	resumed.queue_free()
	DirAccess.remove_absolute("user://dispatch-search-review-v2.json")
	scene.stop_audio_for_exit()
	await create_timer(0.25).timeout
	scene.queue_free()
	await _settle()
	if failures: printerr("HIDDEN_OBJECT_TESTS_FAILED: ", failures, "/", checks)
	else: print("HIDDEN_OBJECT_TESTS_OK: ", checks)
	quit(1 if failures else 0)

func _settle() -> void:
	for _frame in range(4): await process_frame
