extends SceneTree
## Real layout regression: visible vertical lists, accessible compact navigation,
## unclipped artwork and spoiler-aware briefings. Optional native screenshots.
var main: Control
var checks := 0
var failures := 0
var screenshot_dir := ""
var metrics: Array = []
func _initialize() -> void: call_deferred("run_checks")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("SEARCH LAYOUT FAIL: ", message)
func settle() -> void:
	for i in range(12): await process_frame
func visible_text(node: Node) -> String:
	var result := ""
	if node is Control and not node.is_visible_in_tree(): return result
	if node is Label or node is Button or node is RichTextLabel: result += node.text + "\n"
	for child in node.get_children(): result += visible_text(child)
	return result
func run_checks() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if not ProjectSettings.globalize_path("user://").begins_with(project + "/work/"): quit(2); return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			screenshot_dir = arg.trim_prefix("--screenshots=").simplify_path()
			if not screenshot_dir.begins_with(project + "/work/") or DisplayServer.get_name() == "headless": quit(2); return
			DirAccess.make_dir_recursive_absolute(screenshot_dir)
	main = load("res://scenes/main.tscn").instantiate(); root.add_child(main); await settle()
	main.state.settings.auto_voice = false
	for bus in ["music", "sound", "ambience", "voice"]: main.state.settings[bus] = 0.0
	main._apply_audio(); main._new_game(); await settle()
	var text := visible_text(main.overlay)
	expect(text.contains("You are Iona Vale") and text.contains("Your father") and text.contains("then vanished"), "opening explains player, stakes and missing friend")
	expect(text.contains(main.case_guide.data.mission), "opening states the task directly")
	await capture("opening-briefing")
	main._close_modal()
	for dimensions in [Vector2i(960,600),Vector2i(1280,800),Vector2i(1920,1080)]:
		root.mode = Window.MODE_WINDOWED
		root.size = dimensions
		await create_timer(.25).timeout
		for large in [false,true]:
			main.state.settings.large_text = large
			for location in main.state.data.locations:
				main.state.location_id = location.id; main._show_location(); await settle()
				var room: Control = main.search_room
				var viewport := main.get_global_rect()
				var rail: Rect2 = room.rail.get_global_rect()
				var rect: Rect2 = room.canvas.get_global_rect()
				var context: String = location.id + " " + str(dimensions) + " large=" + str(large)
				expect(viewport.grow(1).encloses(rail) and viewport.grow(1).encloses(rect), "rail and picture fit: " + context)
				expect(rect.end.x <= rail.position.x + 1, "rail never overlays picture: " + context)
				expect(rail.grow(1).encloses(room.hint_button.get_global_rect()), "bottom controls remain on screen: " + context)
				var bottom := -1.0
				for label in room.item_labels.values():
					var item_rect: Rect2 = label.get_global_rect()
					expect(rail.encloses(item_rect) and item_rect.position.y >= bottom, "list is vertical and fully visible: " + context)
					bottom = item_rect.end.y
				var picture: Rect2 = room.canvas.picture_rect()
				var fraction: float = picture.get_area() / viewport.get_area()
				if location.id in ["ch1_l1", "ch1_l3"]: print("LAYOUT: ", context, " viewport=", viewport, " picture=",picture," rail=",rail," hint=",room.hint_button.get_global_rect())
				expect(fraction > (0.57 if location.id == "ch1_l1" else 0.68), "picture occupies most of screen: " + context)
				if location.id in ["ch1_l1", "ch1_l3"]:
					metrics.append({"room":location.id,"requested_window":str(dimensions),"actual_window":str(root.size),"logical_viewport":str(viewport.size),"large_text":large,"picture_fraction":fraction,"rail":str(rail),"hint":str(room.hint_button.get_global_rect())})
					await capture(location.id + "-%dx%d" % [dimensions.x,dimensions.y] + ("-large" if large else ""))
	main.state.settings.large_text=false; main.state.new_game(); main.state.visit("ch1_l3"); main._show_location(); await settle()
	main.search_room.request_hint(); await settle()
	expect(main.search_room.rail.get_global_rect().encloses(main.search_room.hint_button.get_global_rect()), "hint countdown fits the rail")
	expect(main.search_room.navigation_buttons.keys() == ["map", "notebook", "bag", "menu"], "one Casebook replaces duplicate notebook and compass navigation")
	for action in main.search_room.navigation_buttons:
		var button: Button = main.search_room.navigation_buttons[action]
		expect(not button.tooltip_text.is_empty() and not button.accessibility_name.is_empty(), "icon has explanatory tooltip and accessible name")
		button.pressed.emit(); await settle()
		expect(main.overlay != null, "navigation icon opens its panel: " + action)
		if action == "notebook":
			text = visible_text(main.overlay)
			expect(text.contains(main.case_guide.room_goal("ch1_l3")), "Casebook states the current room lead")
			expect(not text.contains(main.case_guide.data.rooms.ch1_l3.discovery), "Casebook hides unearned room discovery")
			await capture("casebook")
		main._close_modal(); await settle()
	if not screenshot_dir.is_empty():
		var file := FileAccess.open(screenshot_dir.path_join("layout-metrics.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(metrics,"  ")); file.close()
	main.stop_audio_for_exit(); await create_timer(.25).timeout
	main.queue_free(); await settle(); main=null
	print("SEARCH_LAYOUT_" + ("OK" if failures == 0 else "FAILED") + ": %d checks" % checks)
	quit(0 if failures == 0 else 1)
func capture(label: String) -> void:
	if screenshot_dir.is_empty(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(screenshot_dir.path_join(label+".png"))
