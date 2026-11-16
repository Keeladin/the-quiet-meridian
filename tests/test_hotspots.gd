extends SceneTree
## Campaign presentation: actual image clicks, no hover targets, persistence and hints.
var main: Control
var checks := 0
var failures := 0
var screenshot_dir := ""
func _initialize() -> void: call_deferred("run_checks")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("SEARCH UI FAIL: ", message)
func settle() -> void:
	await process_frame; await process_frame; await process_frame
func run_checks() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if not ProjectSettings.globalize_path("user://").begins_with(project + "/work/"):
		printerr("SEARCH_UI_REFUSED: isolate test saves inside repository work/"); quit(2); return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			screenshot_dir = arg.trim_prefix("--screenshots=").simplify_path()
			if not screenshot_dir.begins_with(project + "/work/") or DisplayServer.get_name() == "headless": quit(2); return
			DirAccess.make_dir_recursive_absolute(screenshot_dir)
	main = load("res://scenes/main.tscn").instantiate(); root.add_child(main); await settle()
	main.state.settings.auto_voice = false
	for bus in ["music", "sound", "ambience", "voice"]: main.state.settings[bus] = 0.0
	main._apply_audio(); main._new_game(); main._close_modal(); await settle()
	var observations: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/campaign_search_observations.json"))
	for location in main.state.data.locations:
		main.state.location_id = location.id; main._show_location(); await settle()
		expect(is_instance_valid(main.search_room), "search UI exists: " + location.id)
		var room: Control = main.search_room
		expect(room.search.definition.location == location.id and room.canvas.painting != null, "correct actual picture loaded: " + location.id)
		expect(room.item_labels.size() == room.search.definition.items.size(), "complete visible item list: " + location.id)
		expect(room.canvas.get_child_count() == 0 and room.canvas.tooltip_text.is_empty(), "painting has no revealing hover controls: " + location.id)
		for id in observations[location.id].interiors:
			var p: Array = observations[location.id].interiors[id]
			var normalized := Vector2(p[0],p[1])
			expect(room.canvas.to_image(room.canvas.to_screen(normalized)).distance_to(normalized)<.0001, "actual viewport click transform: " + location.id + "/" + id)
			expect(room.search.hit_at(normalized)==id, "visible picture target maps: " + location.id + "/" + id)
		if not screenshot_dir.is_empty() and location.id in ["ch1_l1","ch1_l3","ch2_l3","ch3_l6","ch4_l3","ch5_l4","ch6_l6"]:
			await capture(location.id)
	main.state.new_game(); main._show_location(); await settle()
	var first: String = main.search_room.search.definition.items[0].id
	var p: Array = observations.ch1_l1.interiors[first]
	main.search_room.canvas.select_point(main.search_room.canvas.to_screen(Vector2(p[0],p[1])))
	await settle()
	expect(main.state.search_progress.ch1_l1 == [first], "real picture click records the target")
	expect(main.search_room.item_labels[first].text.contains("[s]"), "found label is crossed off")
	var before: Dictionary = main.state._record()
	main.search_room.canvas.select_point(main.search_room.canvas.to_screen(Vector2(p[0],p[1])))
	await settle()
	expect(main.state.search_progress.ch1_l1 == [first] and main.state.inventory.is_empty(), "repeat click gives no new reward")
	main.search_room.request_hint()
	var hinted: String = main.search_room.canvas.hinted
	expect(not hinted.is_empty() and hinted != first and main.search_room.hint_button.disabled, "hint reveals one unfound target and recharges")
	var hint_status: Dictionary = main.state.search_status("ch1_l1")
	var balance: int = main.state.insight_balance()
	expect(hint_status.hints_used == 1 and hint_status.hint_cooldown > 0, "first hint is counted and begins its cooldown")
	main.search_room.request_hint()
	expect(main.state.search_status("ch1_l1").hints_used == 1 and main.state.insight_balance() == balance, "cooldown blocks repeated hint requests without spending Insight")
	main._travel("ch1_l2"); main._travel("ch1_l1"); await settle()
	expect(main.search_room.search.found == [first] and main.search_room.hint_button.disabled, "travel preserves progress and hint cooldown")
	expect(main.state.search_status("ch1_l1").hint_cooldown <= hint_status.hint_cooldown, "travel does not refill the hint timer")
	main._pause(); await settle()
	var paused_status: Dictionary = main.state.search_status("ch1_l1")
	await create_timer(.15).timeout; await settle()
	expect(is_equal_approx(main.state.search_status("ch1_l1").remaining, paused_status.remaining), "pause freezes the search clock")
	expect(is_equal_approx(main.state.search_status("ch1_l1").hint_cooldown, paused_status.hint_cooldown), "pause does not recharge hints")
	main._close_modal(); await settle()
	for _purchase in range(2):
		main.state.advance_search(45.0, "ch1_l1")
		main.search_room.request_hint(); await settle()
	expect(main.state.search_status("ch1_l1").hints_used == 3 and main.state.insight_balance() == balance - 2, "two additional hints cost one Insight each")
	main.state.advance_search(45.0, "ch1_l1")
	main.search_room.request_hint(); await settle()
	expect(main.state.search_status("ch1_l1").hints_used == 3 and main.state.insight_balance() == balance - 2 and main.search_room.hint_button.disabled, "fourth hint is refused even after recharging")
	main.search_room.canvas.set_zoom(2)
	var second: String = main.search_room.search.definition.items[1].id
	p = observations.ch1_l1.interiors[second]
	main.search_room.canvas.centre = Vector2(p[0],p[1]); main.search_room.canvas._clamp_centre()
	main.search_room.canvas.keyboard_point = Vector2(p[0],p[1])
	var enter := InputEventKey.new(); enter.keycode=KEY_ENTER; enter.pressed=true
	main.search_room.canvas._gui_input(enter); await settle()
	expect(second in main.state.search_progress.ch1_l1, "zoomed keyboard activation finds visible target")
	main.search_room.canvas.set_zoom(1)
	for item in main.state.searches.ch1_l1.items:
		if item.id in main.state.search_progress.ch1_l1: continue
		p = observations.ch1_l1.interiors[item.id]
		main.search_room.canvas.select_point(main.search_room.canvas.to_screen(Vector2(p[0],p[1])))
		await settle()
	expect(main.state.search_complete("ch1_l1") and main.state.evidence.size()==3, "all picture clicks award room evidence")
	expect(is_instance_valid(main.overlay) and main.modal_name==main.state.searches.ch1_l1.reward_title, "completion presents the room's story discovery")
	main._close_modal(); await settle()
	expect(main.search_room.hint_button.disabled and main.search_room.search.complete(), "completed room stays crossed off with no unused hint")
	expect(main.state.load_game("user://autosave.json") and main.state.search_complete("ch1_l1"), "actual UI autosave restores completed search")
	main._show_location(); await settle(); main._room_investigations(); await settle()
	expect(main.overlay!=null, "discoveries lead to the chapter investigations")
	main._close_modal()
	if not screenshot_dir.is_empty():
		for dimensions in [Vector2i(960,600),Vector2i(1280,800),Vector2i(1920,1080)]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(dimensions)
			await create_timer(.25).timeout; await settle()
			var rect: Rect2 = main.search_room.canvas.get_global_rect()
			expect(rect.size.x>0 and rect.size.y>=260 and main.get_global_rect().encloses(rect), "picture fits at "+str(dimensions))
			await capture("completed-%dx%d"%[dimensions.x,dimensions.y])
		main.state.settings.large_text=true; main._show_location(); await settle(); await capture("larger-text")
	main.stop_audio_for_exit(); await create_timer(.25).timeout
	main.queue_free(); await settle(); main=null
	print("HOTSPOT_TESTS_"+("OK" if failures==0 else "FAILED")+": %d assertions; 36 actual search pictures, 507 target transforms, clicks, keyboard zoom, hints, rewards and saves"%checks)
	quit(0 if failures==0 else 1)
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(screenshot_dir.path_join(label+".png"))
