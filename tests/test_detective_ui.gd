extends SceneTree
## Main-scene integration: timer ownership, real controls, persistence and Casebook flow.
## Requires XDG_DATA_HOME inside the repository work directory; never uses player saves.
var main: Control
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("DETECTIVE UI FAIL: ", message)

func _button(node: Node, title: String) -> Button:
	if node is Button and node.text == title: return node
	for child in node.get_children():
		var found := _button(child,title)
		if found != null: return found
	return null

func _press(title: String) -> void:
	var button := _button(main.overlay if is_instance_valid(main.overlay) else main.page,title)
	expect(button != null, "control exists: " + title)
	if button != null:
		expect(not button.disabled, "control is available: " + title)
		if not button.disabled: button.pressed.emit()

func _press_puzzle(id: String) -> void:
	var step: Dictionary = main.case_guide.next_step()
	var title: String = str(step.title) if step.get("id", "") == id else str(main.state.get_puzzle(id).title)
	_press(title)

func _tick(delta: float) -> void:
	# Disable automatic main processing so tests can supply deterministic active
	# time through the same main-scene path used by rendered frames.
	main._process(delta)
	if is_instance_valid(main.search_room): main.search_room._process(0)

func _saved_detective() -> Dictionary:
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://autosave.json"))
	return saved.get("detective",{}) if saved is Dictionary else {}

func _run() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if not ProjectSettings.globalize_path("user://").begins_with(project + "/work/"):
		printerr("DETECTIVE_UI_REFUSED: isolate XDG_DATA_HOME inside the repository work directory.")
		quit(2)
		return
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	await process_frame
	expect(not main.state.data.is_empty(), "real main scene loads the campaign")
	if main.state.data.is_empty(): await _finish(); return
	main.state.settings.auto_voice = false
	main.state.settings.fullscreen = false
	for bus in ["music","sound","ambience","voice"]: main.state.settings[bus] = 0.0
	main._apply_audio()
	main._new_game()
	main._set_focus_cover(false)
	await process_frame
	expect(is_instance_valid(main.overlay), "opening story starts in a modal")
	_tick(80)
	expect(main.state.search_status().remaining == 600, "opening exposition never consumes search time")
	main._close_modal()
	_tick(1)
	expect(main.state.search_status().remaining == 599, "visible active picture consumes supplied time")
	_test_keyboard_penalties()
	await _test_search_hints_and_pause()
	await _test_expiry_and_retry()
	await _test_casebook_and_deduction()
	await _finish()

func _test_keyboard_penalties() -> void:
	var canvas: Control = main.search_room.canvas
	var empty := Vector2(-1,-1)
	for y in range(1,10):
		for x in range(1,10):
			var candidate := Vector2(x/10.0,y/10.0)
			if main.search_room.search.hit_at(candidate).is_empty(): empty = candidate; break
		if empty.x >= 0: break
	expect(empty.x >= 0 and canvas.picture_rect().has_area(), "real canvas has a visible empty test point")
	if empty.x < 0: return
	canvas.keyboard_point = empty
	var key := InputEventKey.new(); key.keycode = KEY_ENTER; key.pressed = true
	canvas._gui_input(key)
	var before: Dictionary = main.state.search_status()
	key.echo = true
	for i in range(8): canvas._gui_input(key)
	expect(main.state.search_status() == before, "holding Enter produces no extra misses or automatic penalties")
	key.echo = false
	for i in range(4): canvas._gui_input(key)
	expect(main.state.search_status().penalties == 1 and main.state.search_status().remaining == before.remaining-10, "five distinct presses at empty space apply exactly one ten-second penalty")
	var saved := _saved_detective()
	expect(saved.searches.ch1_l1.penalties == 1, "real empty-picture signals autosave the rapid-click penalty")

func _test_search_hints_and_pause() -> void:
	var aimed: String = main.state.searches.ch1_l1.items[4].id
	var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true
	main.search_room.item_labels[aimed].gui_input.emit(click)
	expect(main.search_room.hint_target == aimed and main.search_room.item_labels[aimed].text.contains("▸"), "choosing a list name marks it as the hint target without spending anything")
	expect(main.state.search_status().hints_used == 0 and main.state.insight_balance() == 4, "choosing a hint target is free")
	main.search_room.hint_button.pressed.emit()
	expect(main.search_room.canvas.hinted == aimed, "the hint highlights the chosen object, not the first in the list")
	expect(main.state.search_status().hints_used == 1 and main.state.insight_balance() == 4, "search hint button grants the free first hint")
	expect(not main.search_room.canvas.hinted.is_empty(), "successful hint reaches the actual picture highlight")
	expect(main.search_room.hint_button.disabled and main.search_room.hint_button.text == "30", "rail displays and disables the active cooldown")
	var frozen: Dictionary = main.state.search_status()
	main.search_room.navigation_buttons.map.pressed.emit()
	expect(is_instance_valid(main.overlay) and main.overlay.get_child(0) is ColorRect and main.overlay.get_child(0).color.a == 1.0, "map modal is opaque so a paused clock cannot expose the picture")
	_tick(70)
	expect(main.state.search_status() == frozen, "map pauses both search time and hint cooldown")
	main._close_modal()
	main._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	expect(is_instance_valid(main.focus_cover) and main.focus_cover.color.a == 1.0, "focus loss installs an opaque pause cover")
	_tick(70)
	var covered_key := InputEventKey.new(); covered_key.keycode = KEY_F1; covered_key.pressed = true
	main._unhandled_key_input(covered_key)
	expect(main.state.search_status() == frozen, "focus loss freezes search time, cooldown and covered keyboard hints")
	main._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	_tick(30)
	expect(not is_instance_valid(main.focus_cover) and not main.search_room.hint_button.disabled, "focus return resumes active countdown and makes recharged hint available")
	main.search_room.hint_button.pressed.emit()
	expect(main.state.search_status().hints_used == 2 and main.state.insight_balance() == 3, "second search hint button spends one Insight")
	_tick(30)
	main.search_room.hint_button.pressed.emit()
	expect(main.state.search_status().hints_used == 3 and main.state.insight_balance() == 2, "third search hint button spends one Insight")
	_tick(30)
	expect(main.search_room.hint_button.disabled and main.search_room.hint_button.tooltip_text.contains("All 3 hints used"), "rail clearly disables the exhausted hint allowance")
	var key := InputEventKey.new(); key.keycode = KEY_F1; key.pressed = true
	main._unhandled_key_input(key)
	expect(main.state.search_status().hints_used == 3 and main.state.insight_balance() == 2, "keyboard hint cannot bypass cap or charge a fourth hint")
	var before: Dictionary = main.state.search_status()
	main._pause(); _press("Save and return to title")
	expect(not main.playing and main.overlay == null, "pause save returns to title")
	var saved := _saved_detective()
	expect(saved.insight == 2 and saved.searches.ch1_l1.hints_used == 3, "paid hints are persisted by real UI actions")
	_tick(50)
	main.state.new_game()
	_press("Continue investigation")
	expect(main.playing and main.state.search_status() == before and main.state.insight_balance() == 2, "title Continue restores exact active timer, hint cap and spending")
	await process_frame

func _test_expiry_and_retry() -> void:
	_tick(1000)
	expect(main.state.search_status().expired and main.modal_name == "Time has run out", "frame expiry automatically opens recovery choices")
	expect(main.overlay.get_child(0).color.a == 1.0, "expired search is fully covered")
	var target: String = main.state.searches.ch1_l1.items[0].id
	main._find_room_object(target)
	expect(main.state.search_progress.get("ch1_l1",[]).is_empty(), "object callback behind expired modal cannot record a find")
	main._close_modal(); _tick(0)
	expect(main.modal_name == "Time has run out", "closing expiry modal cannot continue a zero-time search")
	_press("Add 30 seconds · 1 Insight")
	expect(main.overlay == null and main.state.search_status().remaining == 30 and main.state.insight_balance() == 1, "rescue control buys time and returns directly to the picture")
	main._find_room_object(target)
	expect(target in main.state.search_progress.ch1_l1 and target in main.search_room.search.found, "rescued search accepts finds and synchronizes the visible list")
	main.search_room.time_button.pressed.emit()
	expect(main.state.search_status().remaining == 60 and main.state.insight_balance() == 0 and main.search_room.time_button.disabled, "rail buys the second extension and then disables further purchases")
	_tick(70)
	expect(_button(main.overlay,"Add 30 seconds · 1 Insight") == null, "expiry recovery omits exhausted extension purchase")
	_press("Restart the clock")
	expect(main.overlay == null and main.state.search_status().remaining == 565, "restart rebuilds the picture with a clock for the 16 remaining objects")
	expect(main.state.insight_balance() == 0 and main.state.search_status().hints_used == 3 and main.state.search_status().extensions == 0, "restart refunds nothing, keeps the hint cap and reopens extensions")
	expect(target in main.search_room.search.found and main.search_room.count_label.text.contains("FIND 1/17"), "restart keeps found marks in both state and visible rail")
	var saved := _saved_detective()
	expect(saved.insight == 0 and saved.searches.ch1_l1.restarts == 1 and saved.searches.ch1_l1.remaining == 565, "restart is immediately autosaved")
	await process_frame

func _test_casebook_and_deduction() -> void:
	main._travel("ch1_l2")
	await process_frame
	for item in main.state.searches.ch1_l2.items: main._find_room_object(str(item.id))
	expect(main.state.search_complete("ch1_l2") and is_instance_valid(main.overlay), "finishing a real search presents its discovery")
	main._close_modal()
	main.search_room.navigation_buttons.notebook.pressed.emit()
	expect(main.modal_name == "Casebook · Tide Office", "single notebook icon opens the current room Casebook")
	_press_puzzle("p02")
	expect(main.modal_name == main.state.get_puzzle("p02").title and main.selected_puzzle == "p02" and is_instance_valid(main.answer_entry), "one local Casebook selection opens the ready investigation directly")
	var search_before: Dictionary = main.state.search_status()
	_tick(12)
	expect(main.state.puzzle_status("p02").active_seconds == 12 and main.state.search_status() == search_before, "active puzzle advances its own clock without advancing the covered picture")
	main.puzzle_hint_button.pressed.emit()
	expect(main.state.puzzle_status("p02").hints_used == 1 and main.puzzle_hint_button.disabled, "puzzle hint control uses its independent allowance and cooldown")
	var frozen: Dictionary = main.state.puzzle_status("p02")
	main._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT); _tick(80)
	expect(main.state.puzzle_status("p02") == frozen, "focus cover also freezes deduction cooldowns")
	main._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	main._casebook(); _tick(80)
	expect(main.state.puzzle_status("p02").hint_cooldown == 30, "returning to Casebook does not recharge a covered puzzle")
	_press_puzzle("p02"); _tick(30)
	var bank: int = main.state.insight_balance()
	main.puzzle_hint_button.pressed.emit(); _tick(30); main.puzzle_hint_button.pressed.emit(); _tick(30)
	expect(main.state.insight_balance() == bank-2 and main.puzzle_hint_button.disabled and main.puzzle_hint_button.text == "All 3 hints used", "deduction controls charge for exactly two extra hints and show the hard cap")
	for value in ["0000","0001","0002"]:
		main.answer_entry.text = value
		main.answer_entry.text_submitted.emit(value)
	expect(main.puzzle_submit_buttons[0].disabled and main.state.puzzle_status("p02").submit_cooldown == 10, "wrong submissions disable the actual answer button")
	main.answer_entry.text_submitted.emit("0050")
	expect("p02" not in main.state.solved, "Enter key cannot bypass the disabled submit cooldown")
	_tick(10)
	expect(not main.puzzle_submit_buttons[0].disabled, "answer button re-enables when active cooldown finishes")
	main.answer_entry.text = "0050"; main.answer_entry.text_submitted.emit("0050")
	expect("p02" in main.state.solved and main.puzzle_timer_id.is_empty(), "correct answer completes investigation and stops its timer")
	main._close_modal(); main._casebook()
	var next: Dictionary = main.case_guide.next_step()
	expect(next.get("id", "") == "p07" and _button(main.overlay,str(next.title)) != null, "Casebook exposes the next local available investigation after completion")
	await process_frame

func _finish() -> void:
	if is_instance_valid(main): main.stop_audio_for_exit()
	await create_timer(0.2).timeout
	if is_instance_valid(main): main.queue_free()
	await process_frame
	print("DETECTIVE_UI_" + ("OK" if failures == 0 else "FAILED") + ": %d checks; active/covered clocks, real hint and recovery controls, saved spending, direct Casebook flow" % checks)
	quit(0 if failures == 0 else 1)
