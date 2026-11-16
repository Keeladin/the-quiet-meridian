extends Control
const SearchState = preload("res://scripts/hidden_object_state.gd")
const SearchCanvas = preload("res://scripts/hidden_object_canvas.gd")
const SearchAudio = preload("res://scripts/hidden_object_audio.gd")
const BODY = preload("res://assets/fonts/body.ttf")
const DISPLAY = preload("res://assets/fonts/display.ttf")
const SAVE := "user://dispatch-search-review-v2.json"
const GOLD := Color("d8b574")
const PAPER := Color("eee5cf")
var search := SearchState.new()
var canvas: Control
var count_label: Label
var message: Label
var checklist: GridContainer
var hint_button: Button
var sound_button: Button
var music_button: Button
var item_labels := {}
var hint_cooldown := 0.0
var audio: Node
var complete_panel: PanelContainer
var closing := false
var muted := false
var saved_ok := true

func _ready() -> void:
	get_tree().auto_accept_quit = false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/hidden-object-dispatch.json"))
	if not data is Dictionary or not search.configure(data):
		push_error("Hidden object scene could not load.")
		get_tree().quit(1)
		return
	var load_error := ""
	if FileAccess.file_exists(SAVE) and not search.load_progress(SAVE): load_error = search.last_error + " Your previous file has been preserved."
	var skin := Theme.new()
	skin.default_font = BODY
	skin.default_font_size = 21
	skin.set_color("font_color", "Label", PAPER)
	skin.set_color("font_color", "Button", PAPER)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("243b40") if state != "hover" else Color("365055")
		style.border_color = GOLD if state == "focus" else Color("52625b")
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(5)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		skin.set_stylebox(state, "Button", style)
	theme = skin
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("0c191e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 20)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	layout.add_child(top)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	_label(heading, str(search.definition.title), 30, true)
	_label(heading, "FERRY LANDING · HIDDEN-OBJECT SEARCH", 14).modulate = GOLD
	count_label = _label(top, "", 22)
	count_label.custom_minimum_size.x = 130
	_button(top, "−", func(): canvas.set_zoom(canvas.zoom / 1.25)).tooltip_text = "Zoom out"
	_button(top, "+", func(): canvas.set_zoom(canvas.zoom * 1.25)).tooltip_text = "Zoom in; right-drag the picture to pan"
	_button(top, "Fit", func(): canvas.set_zoom(1)).tooltip_text = "Show the whole picture"
	sound_button = _button(top, "Sound on", _toggle_sound)
	music_button = _button(top, "Music on", _toggle_music)
	_button(top, "Fullscreen", _fullscreen).tooltip_text = "F11 also toggles fullscreen"
	_button(top, "Exit", _quit_preview)
	canvas = SearchCanvas.new()
	canvas.search = search
	canvas.painting = load(str(search.definition.art))
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size.y = 220
	layout.add_child(canvas)
	canvas.object_selected.connect(_find)
	canvas.empty_selected.connect(func(): message.text = "A word may describe an object, a symbol or a shape in the scenery. Try another interpretation.")
	var list_panel := PanelContainer.new()
	var list_style := StyleBoxFlat.new()
	list_style.bg_color = Color("182b30")
	list_style.border_color = Color("52625b")
	list_style.border_width_top = 1
	list_style.content_margin_left = 24
	list_style.content_margin_right = 24
	list_style.content_margin_top = 13
	list_style.content_margin_bottom = 13
	list_panel.add_theme_stylebox_override("panel", list_style)
	layout.add_child(list_panel)
	var list_layout := VBoxContainer.new()
	list_layout.add_theme_constant_override("separation", 8)
	list_panel.add_child(list_layout)
	var list_title := HBoxContainer.new()
	list_layout.add_child(list_title)
	var caption := _label(list_title, "FIND IN THE PICTURE", 16)
	caption.modulate = GOLD
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_button = _button(list_title, "Hint", _hint)
	hint_button.tooltip_text = "Reveal one remaining object; recharges in 20 seconds"
	_button(list_title, "Start again", _confirm_restart)
	checklist = GridContainer.new()
	checklist.columns = 6
	checklist.add_theme_constant_override("h_separation", 24)
	checklist.add_theme_constant_override("v_separation", 5)
	list_layout.add_child(checklist)
	for item in search.definition.items:
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("normal_font_size", 21)
		label.custom_minimum_size.y = 28
		checklist.add_child(label)
		item_labels[item.id] = label
	message = _label(layout, "Find %d hidden things. A word may describe an object, symbol or pattern. Scroll to zoom; F11: fullscreen." % search.definition.items.size(), 17)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 24
	message.modulate = Color("b0c1bc")
	audio = SearchAudio.new()
	add_child(audio)
	if not audio.ready_ok:
		push_error("Opening sound collection could not load.")
	_refresh()
	if not load_error.is_empty(): message.text = load_error
	elif search.complete(): _show_reward()
	if "--search-smoke-test" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		if canvas.painting == null or item_labels.size() != search.definition.items.size() or not audio.ready_ok or audio.players.size() != 13:
			get_tree().quit(1)
		else:
			print("HIDDEN_SEARCH_SMOKE_OK")
			await _quit_preview()

func _label(parent: Node, text: String, font_size: int, serif := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if serif: label.add_theme_font_override("font", DISPLAY)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(func():
		if is_instance_valid(audio): audio.play_cue("menu_interaction")
		action.call())
	parent.add_child(button)
	return button

func _refresh() -> void:
	count_label.text = "%d / %d found" % [search.found.size(), search.definition.items.size()]
	for item in search.definition.items:
		var found: bool = item.id in search.found
		item_labels[item.id].text = ("[color=#8ca99a]✓ [s]" + str(item.name) + "[/s][/color]") if found else str(item.name)
		item_labels[item.id].accessibility_name = str(item.name) + (", found" if found else ", still hidden")
	hint_button.disabled = search.complete() or hint_cooldown > 0

func _find(id: String) -> void:
	if not search.find_object(id):
		message.text = "You already found the " + str(search.object_by_id(id).name).to_lower() + "."
		return
	saved_ok = search.save_progress(SAVE)
	message.text = "Found: " + str(search.object_by_id(id).name) + str(search.object_by_id(id).get("found_note", "")) + (" · progress saved" if saved_ok else " · " + search.last_error)
	_refresh()
	if search.complete():
		_show_reward()
		audio.finish_search(saved_ok)
	else:
		audio.play_cue("symbol_understood" if id in ["club", "knight"] else "object_found")

func _hint() -> void:
	if hint_cooldown > 0 or search.complete(): return
	for item in search.definition.items:
		if item.id not in search.found:
			canvas.reveal(str(item.id))
			message.text = "Look for the " + str(item.name).to_lower() + " in the highlighted area."
			hint_cooldown = 20
			audio.play_cue("hint_revealed")
			_refresh()
			return

func _process(delta: float) -> void:
	if hint_cooldown > 0:
		hint_cooldown = maxf(0, hint_cooldown - delta)
		hint_button.text = "Hint · %ds" % ceili(hint_cooldown) if hint_cooldown > 0 else "Hint"
		hint_button.disabled = hint_cooldown > 0 or search.complete()

func _fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _toggle_sound() -> void:
	muted = not muted
	sound_button.text = "Sound off" if muted else "Sound on"
	audio.set_muted(muted)

func _toggle_music() -> void:
	audio.set_music_enabled(not audio.music_enabled)
	music_button.text = "Music on" if audio.music_enabled else "Music off"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			_fullscreen()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			get_viewport().set_input_as_handled()

func _show_reward() -> void:
	if is_instance_valid(complete_panel): return
	complete_panel = PanelContainer.new()
	complete_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	complete_panel.offset_left = -360
	complete_panel.offset_right = 360
	complete_panel.offset_top = -150
	complete_panel.offset_bottom = 150
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172a30")
	style.border_color = GOLD
	style.set_border_width_all(2)
	for edge in ["left", "right", "top", "bottom"]: style.set("content_margin_" + edge, 28)
	complete_panel.add_theme_stylebox_override("panel", style)
	add_child(complete_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	complete_panel.add_child(box)
	_label(box, "SEARCH COMPLETE", 16).modulate = GOLD
	_label(box, str(search.definition.reward_title), 30, true)
	var prose := _label(box, str(search.definition.reward_text), 22)
	prose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prose.custom_minimum_size.x = 610
	_label(box, "Opening search preview · the wider game conversion is still pending.", 16).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(box, "Receipt recorded in this preview’s saved search progress." if saved_ok else "Receipt found, but progress could not be saved.", 16).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(box, "Return to the picture", func(): complete_panel.queue_free())
	message.text = "All %d clues found · dispatch receipt recovered." % search.definition.items.size() + ("" if saved_ok else " Progress could not be saved.")

func _confirm_restart() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Search again"
	dialog.dialog_text = "Clear only this preview’s found-object list and start again?\nYour main game progress is unaffected."
	dialog.confirmed.connect(func():
		audio.cancel_reward()
		search.found.clear()
		saved_ok = search.save_progress(SAVE)
		canvas.set_zoom(1)
		canvas.hint_remaining = 0
		canvas.flash_remaining = 0
		hint_cooldown = 0
		hint_button.text = "Hint"
		if is_instance_valid(complete_panel): complete_panel.queue_free()
		_refresh()
		message.text = "Find all %d hidden things to recover Mara’s receipt." % search.definition.items.size() if saved_ok else search.last_error
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(560, 170))

func stop_audio_for_exit() -> void:
	if is_instance_valid(audio): audio.stop_all()

func _quit_preview() -> void:
	if closing: return
	closing = true
	stop_audio_for_exit()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _quit_preview()

func _exit_tree() -> void:
	stop_audio_for_exit()
