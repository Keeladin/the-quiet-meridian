extends HBoxContainer
signal object_requested(id: String)
signal hint_used
signal menu_used
signal navigation_requested(action: String)
signal progress_changed
signal time_expired
const SearchState = preload("res://scripts/hidden_object_state.gd")
const SearchCanvas = preload("res://scripts/hidden_object_canvas.gd")
var campaign: RefCounted
var location_id := ""
var objective := ""
var search := SearchState.new()
var canvas: Control
var rail: PanelContainer
var count_label: Label
var time_label: Label
var time_button: Button
var hint_button: Button
var item_labels := {}
## Unfound object the next hint should point at; empty means the first unfound one.
var hint_target := ""
var message: Label
var objective_label: Label
var navigation_buttons := {}

func _ready() -> void:
	search.configure(campaign.searches[location_id])
	add_theme_constant_override("separation", 0)
	canvas = SearchCanvas.new()
	canvas.search = search
	canvas.painting = load(str(search.definition.art))
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2(200, 260)
	add_child(canvas)
	canvas.object_selected.connect(func(id): object_requested.emit(id))
	canvas.empty_selected.connect(_miss)
	rail = PanelContainer.new()
	rail.custom_minimum_size.x = 276 if not campaign.settings.large_text else 310
	rail.size_flags_horizontal = Control.SIZE_SHRINK_END
	var style := StyleBoxFlat.new()
	style.bg_color = Color("14262b")
	style.border_color = Color("435750")
	style.border_width_left = 1
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	rail.add_theme_stylebox_override("panel", style)
	add_child(rail)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	rail.add_child(list)
	var title := _label(list, str(search.definition.title), 24)
	title.add_theme_font_override("font", load("res://assets/fonts/display.ttf"))
	title.modulate = Color("eee5cf")
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	list.add_child(nav)
	for pair in [["map", "Map · M"], ["notebook", "Casebook · J / C"], ["bag", "Inventory · I"], ["menu", "Pause & settings · Esc"]]:
		var action: String = pair[0]
		navigation_buttons[action] = _icon_button(nav, action, pair[1], func(): navigation_requested.emit(action))
	var budget := HBoxContainer.new()
	budget.add_theme_constant_override("separation", 6)
	list.add_child(budget)
	time_label = _label(budget, "", 17)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	time_label.tooltip_text = "Search time remaining and spendable Insight"
	time_button = Button.new()
	time_button.text = "+30s"
	time_button.add_theme_font_size_override("font_size", 16)
	time_button.tooltip_text = "Buy 30 seconds for 1 Insight. Maximum two extensions per search."
	time_button.accessibility_name = time_button.tooltip_text
	time_button.pressed.connect(_buy_time)
	budget.add_child(time_button)
	var lead_title := _label(list, "YOUR LEAD", 13)
	lead_title.modulate = Color("d8b574")
	objective_label = _label(list, objective, 18)
	objective_label.modulate = Color("c8d0c3")
	list.add_child(HSeparator.new())
	count_label = _label(list, "", 15)
	count_label.modulate = Color("d8b574")
	var items := VBoxContainer.new()
	items.add_theme_constant_override("separation", 0)
	list.add_child(items)
	for item in search.definition.items:
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		# Choosing a name aims the next hint at that object. Choosing costs nothing.
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.focus_mode = Control.FOCUS_ALL
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		label.tooltip_text = "Choose this object for your next hint"
		label.gui_input.connect(_on_item_input.bind(str(item.id)))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size.y = 25 if not campaign.settings.large_text else 28
		label.add_theme_font_size_override("normal_font_size", 21 if not campaign.settings.large_text else 24)
		label.add_theme_font_size_override("italics_font_size", 20 if not campaign.settings.large_text else 23)
		items.add_child(label)
		item_labels[item.id] = label
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_child(space)
	message = _label(list, "", 16)
	message.custom_minimum_size.y = 36
	message.modulate = Color("9cb5aa")
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	list.add_child(controls)
	_icon_button(controls, "zoom_out", "Zoom out · −", func(): canvas.set_zoom(canvas.zoom / 1.25))
	_icon_button(controls, "zoom_in", "Zoom in · + / mouse wheel", func(): canvas.set_zoom(canvas.zoom * 1.25))
	_icon_button(controls, "fit", "Fit the whole picture; right-drag to pan when zoomed", func(): canvas.set_zoom(1))
	hint_button = _icon_button(controls, "hint", "Hint · F1", request_hint)
	sync_progress()

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _icon_button(parent: Node, icon: String, description: String, action: Callable) -> Button:
	var button := Button.new()
	button.icon = load("res://assets/ui/" + icon + ".svg")
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 25)
	button.custom_minimum_size = Vector2(44, 44)
	button.tooltip_text = description
	button.accessibility_name = description
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("20383d") if state in ["hover", "pressed"] else Color("14262b")
		style.set_content_margin_all(8)
		style.set_corner_radius_all(5)
		if state == "focus":
			style.border_color = Color("d8b574")
			style.set_border_width_all(2)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(func(): menu_used.emit(); action.call())
	parent.add_child(button)
	return button

func sync_progress() -> void:
	search.found.assign(campaign.search_progress.get(location_id, []))
	for item in search.definition.items:
		var found: bool = item.id in search.found
		var chosen: bool = item.id == hint_target and not found
		var shown := search.list_text(item).replace("[", "[lb]")
		var riddle: bool = item.has("clue") and not found
		if found: item_labels[item.id].text = "[color=#829e91]✓ [s]" + shown + "[/s][/color]"
		elif chosen: item_labels[item.id].text = "[color=#d8b574]▸ " + ("[i]" + shown + "[/i]" if riddle else shown) + "[/color]"
		elif riddle: item_labels[item.id].text = "·  [i]" + shown + "[/i]"
		else: item_labels[item.id].text = "·  " + shown
		item_labels[item.id].accessibility_name = (("Riddle: " if riddle else "") + search.list_text(item)) + (", found" if found else (", chosen for the next hint" if chosen else ", still hidden; press Enter to choose it for the next hint"))
	if hint_target in search.found: hint_target = ""
	if search.complete(): message.text = "Evidence recovered. Open the Casebook to follow it."
	_refresh_hint()
	canvas.queue_redraw()

func _miss() -> void:
	var result: Dictionary = campaign.register_search_miss(location_id)
	if result.get("warning", false) or result.get("penalty", false): message.text = str(result.text)
	else: message.text = "Look for objects, symbols and familiar shapes."
	progress_changed.emit()
	if result.get("expired", false): time_expired.emit()

func _on_item_input(event: InputEvent, id: String) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept")
	if not pressed or id in search.found: return
	hint_target = "" if hint_target == id else id
	var item := search.object_by_id(id)
	# Choosing is free, so it must not solve a riddle: name the riddle, not its answer.
	var label := ("“" + str(item.clue) + "”") if item.has("clue") else "the " + str(item.name).to_lower()
	message.text = ("Your next hint will point to " + label + ".") if not hint_target.is_empty() else "Your next hint will point to the first object still hidden."
	sync_progress()
	item_labels[id].accept_event()

func request_hint() -> void:
	var result: Dictionary = campaign.request_search_hint(location_id, hint_target)
	if not result.ok:
		message.text = str(result.text)
		return
	canvas.reveal(str(result.id))
	message.text = "Look for the " + str(search.object_by_id(str(result.id)).name).to_lower() + "."
	hint_used.emit()
	progress_changed.emit()
	_refresh_hint()

func _buy_time() -> void:
	var result: Dictionary = campaign.buy_search_time(location_id)
	message.text = str(result.text)
	if result.ok:
		menu_used.emit()
		progress_changed.emit()
	_refresh_hint()

func _refresh_hint() -> void:
	var status: Dictionary = campaign.search_status(location_id)
	var seconds := ceili(float(status.remaining))
	time_label.text = ("Complete" if status.complete else "%02d:%02d" % [seconds / 60, seconds % 60]) + " · %d Insight" % campaign.insight_balance()
	time_label.modulate = Color("e9aa7c") if seconds <= 30 and not status.complete else Color("d8b574")
	time_button.disabled = not status.can_extend
	count_label.text = "FIND %d/%d · HINTS %d/3" % [search.found.size(), search.definition.items.size(), int(status.hints_used)]
	var remaining := float(status.hint_cooldown)
	hint_button.text = "%d" % ceili(remaining) if remaining > 0 and not status.complete else ""
	hint_button.disabled = not status.can_hint
	var description := "All 3 hints used" if int(status.hints_used) >= 3 else ("Hint · free" if int(status.hint_cost) == 0 else "Hint · costs 1 Insight")
	if status.complete: description = "Search complete"
	elif remaining > 0: description += " · ready in %d seconds" % ceili(remaining)
	hint_button.accessibility_name = description
	hint_button.tooltip_text = description + " · F1"

func _process(_delta: float) -> void:
	if is_instance_valid(hint_button): _refresh_hint()
