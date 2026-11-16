extends Control
## Presentation only: every story, clue, dependency and answer is external data.

const State = preload("res://scripts/game_state.gd")
const RouteBoard = preload("res://scripts/investigation_board.gd")
const AudioDirector = preload("res://scripts/audio_director.gd")
const EnvironmentStage = preload("res://scripts/environment_stage.gd")
const CharacterStage = preload("res://scripts/character_stage.gd")
const CityMap = preload("res://scripts/city_map.gd")
const CaseGuide = preload("res://scripts/case_guide.gd")
const CampaignSearchRoom = preload("res://scripts/campaign_search_room.gd")
const BODY = preload("res://assets/fonts/body.ttf")
const DISPLAY = preload("res://assets/fonts/display.ttf")
const INK = Color("111e24")
const PANEL = Color("192a30")
const GOLD = Color("d8b574")
const PAPER = Color("eee5cf")
const MUTED = Color("a5b5b2")
var state = State.new()
var page: Control
var overlay: Control
var feedback: Label
var audio: Node
var environment_stage: Control
var character_stage: Control
var environment_profiles: Dictionary = {}
var audio_catalog: Dictionary = {}
var interaction_audio: Dictionary = {}
var voice_catalog: Dictionary = {}
var voice_ids: Array = []
var subtitle_label: Label
var voice_status: Label
var voice_skip: Button
var voice_replay: Button
var voice_progress: ProgressBar
var dialogue_character := ""
var playing := false
var selected_item := ""
var selected_puzzle := ""
var answer: Array = []
var answer_label: Label
var answer_entry: LineEdit
var hint_levels := {}
var puzzle_feedback: Label
var active_chapter := ""
var session_timer := 0.0
var toast_timer := 0.0
var status_text := ""
var image_cache := {}
var modal_name := ""
var dialogue_data: Array = []
var hotspot_layout: Dictionary = {}
var art_layout: Dictionary = {}
var board_data: Dictionary = {}
var active_board: Control
var shutting_down := false
var case_guide = CaseGuide.new()
var search_room: Control
var focus_cover: ColorRect
var puzzle_timer_id := ""
var puzzle_hint_button: Button
var puzzle_status_label: Label
var puzzle_submit_buttons: Array[Button] = []
var inventory_feedback: Label
var reward_audio_queue: Array[Dictionary] = []

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_make_theme()
	if not state.load_content():
		_fatal(state.last_error)
		return
	case_guide.configure(state, _read_dictionary("res://content/story-guide.json"))
	_load_preferences()
	var art_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/presentation.json"))
	if not art_data is Dictionary:
		_fatal("The illustration layout file could not be read.")
		return
	art_layout = art_data
	var boards: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/boards.json"))
	if not boards is Dictionary:
		_fatal("The investigation diagram file could not be read.")
		return
	board_data = boards
	if FileAccess.file_exists("res://content/dialogues.json"):
		var conversations: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/dialogues.json"))
		if conversations is Dictionary: dialogue_data = conversations.get("conversations", [])
		elif conversations is Array: dialogue_data = conversations
	if FileAccess.file_exists("res://content/hotspot-layout.json"):
		var positions: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/hotspot-layout.json"))
		if positions is Dictionary: hotspot_layout = positions
	environment_profiles = _read_dictionary("res://content/environment-effects.json")
	audio_catalog = _read_dictionary("res://content/audio-score.json")
	interaction_audio = _read_dictionary("res://content/interaction-audio.json")
	voice_catalog = _read_dictionary("res://content/voice-script.json")
	audio = AudioDirector.new()
	add_child(audio)
	audio.configure(audio_catalog, voice_catalog, state.settings)
	audio.voice_started.connect(_on_voice_started)
	audio.voice_finished.connect(_on_voice_finished)
	_apply_audio()
	if "--smoke-test" in OS.get_cmdline_user_args():
		# The packaging check runs this against exported builds; it lives outside gameplay code.
		await load("res://scripts/smoke_test.gd").new().run(self)
		return
	_show_title()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screenshot="):
			_new_game()
			await get_tree().process_frame
			_close_modal()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(argument.trim_prefix("--screenshot="))
			await _quit_game()

func _make_theme() -> void:
	var skin := Theme.new()
	skin.default_font = BODY
	skin.default_font_size = 20
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = PANEL if style_name != "hover" else Color("30444a")
		if style_name == "pressed": box.bg_color = Color("42504c")
		if style_name == "disabled": box.bg_color = Color("182329")
		box.border_color = GOLD if style_name == "focus" else Color("435250")
		box.set_border_width_all(2 if style_name == "focus" else 1)
		box.set_corner_radius_all(4)
		box.content_margin_left = 16
		box.content_margin_right = 16
		box.content_margin_top = 12
		box.content_margin_bottom = 12
		skin.set_stylebox(style_name, "Button", box)
		skin.set_stylebox(style_name, "LineEdit", box)
	skin.set_color("font_color", "Label", PAPER)
	skin.set_color("font_color", "Button", PAPER)
	skin.set_color("font_disabled_color", "Button", MUTED)
	skin.set_color("font_color", "LineEdit", PAPER)
	skin.set_color("font_placeholder_color", "LineEdit", MUTED)
	skin.set_color("font_color", "CheckButton", PAPER)
	theme = skin

func _process(delta: float) -> void:
	if playing and not is_instance_valid(focus_cover):
		if not is_instance_valid(overlay) and is_instance_valid(search_room):
			state.advance_search(delta)
			if state.search_status().expired: _search_expired()
		elif not puzzle_timer_id.is_empty():
			state.advance_puzzle(puzzle_timer_id, delta)
			_refresh_puzzle_controls()
	if not reward_audio_queue.is_empty() and not shutting_down:
		reward_audio_queue[0].delay -= delta
		if reward_audio_queue[0].delay <= 0:
			_search_sound(reward_audio_queue[0].cue, "paper")
			reward_audio_queue.pop_front()
	if is_instance_valid(audio) and is_instance_valid(voice_status):
		var speaking: bool = audio.is_voice_playing()
		voice_skip.disabled = not speaking
		voice_progress.max_value = maxf(audio.get_voice_duration(), 0.1)
		voice_progress.value = audio.get_voice_position()
		if speaking:
			var line: Dictionary = voice_catalog.get("lines", {}).get(audio.current_line_id(), {})
			voice_status.text = "Speaking · " + _character_name(str(line.get("speaker", "iona")))
		elif not voice_replay.disabled: voice_status.text = "Voice ready · replay to listen again"
		subtitle_label.text = audio.get_subtitle()
		subtitle_label.visible = bool(state.settings.get("subtitles", true)) and not subtitle_label.text.is_empty()
		if is_instance_valid(character_stage):
			var speaker := str(voice_catalog.get("lines", {}).get(audio.current_line_id(), {}).get("speaker", ""))
			character_stage.set_speaking(audio.is_voice_active() and character_stage.character_id == speaker)
	if playing:
		state.elapsed_seconds += delta
		session_timer += delta
		if session_timer > 45.0:
			session_timer = 0.0
			_autosave()
	if toast_timer > 0:
		toast_timer -= delta
		if toast_timer <= 0 and is_instance_valid(feedback):
			feedback.text = status_text

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and playing: _set_focus_cover(true)
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN: _set_focus_cover(false)
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if playing: _autosave()
		_save_preferences()
		_quit_game()

func stop_audio_for_exit() -> void:
	shutting_down = true
	reward_audio_queue.clear()
	if is_instance_valid(audio): audio.stop_all()

func _quit_game() -> void:
	stop_audio_for_exit()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _exit_tree() -> void:
	if is_instance_valid(audio): audio.stop_all()
	image_cache.clear()

func _read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(focus_cover): return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE:
		if is_instance_valid(overlay): _close_modal()
		elif playing: _pause()
		get_viewport().set_input_as_handled()
		return
	if not playing or is_instance_valid(overlay): return
	match event.keycode:
		KEY_C: _casebook()
		KEY_J: _casebook()
		KEY_M: _map()
		KEY_I: _inventory()
		KEY_F11:
			state.settings.fullscreen = not state.settings.fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if state.settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
			_save_preferences()
		KEY_F1:
			if is_instance_valid(search_room): search_room.request_hint()
		_: return
	get_viewport().set_input_as_handled()

func _clear_page() -> void:
	reward_audio_queue.clear()
	search_room = null
	_close_modal()
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	page = Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	var bg := ColorRect.new()
	bg.color = INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(bg)

func _margin(parent: Node, edges: int = 24) -> MarginContainer:
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, edges)
	parent.add_child(margin)
	return margin

func _label(parent: Node, value: String, font_size: int = 20, color: Color = PAPER, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size + (3 if state.settings.large_text else 0))
	if serif: label.add_theme_font_override("font", DISPLAY)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, callback: Callable, min_width: float = 0) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(min_width, 48)
	button.add_theme_font_size_override("font_size", 19 + (2 if state.settings.large_text else 0))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func(): _click_sound(); callback.call())
	parent.add_child(button)
	return button

func _vbox(parent: Node, separation: int = 14) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	return box

func _hbox(parent: Node, separation: int = 12) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	return box

func _rule(parent: Node) -> void:
	var rule := HSeparator.new()
	parent.add_child(rule)

func _scroll(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	return _vbox(scroll)

func _texture(path: String) -> Texture2D:
	if image_cache.has(path): return image_cache[path]
	if ResourceLoader.exists(path):
		var result = load(path)
		image_cache[path] = result
		return result
	return null

func _illustration(parent: Node, path: String) -> TextureRect:
	var art := TextureRect.new()
	art.texture = _texture(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	return art

func _show_title() -> void:
	playing = false
	_set_focus_cover(false)
	_clear_page()
	_add_environment(page, "ch1_l1", "res://assets/art/locations/ch1_l1.png")
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.055, 0.07, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(shade)
	var margin := _margin(page, 92)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := _hbox(margin, 80)
	var story := _vbox(row, 24)
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(story, "A HIDDEN-OBJECT MYSTERY", 16, GOLD)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	story.add_child(spacer)
	_label(story, "The Quiet\nMeridian", 70, PAPER, true)
	_label(story, str(case_guide.data.title_intro), 23, PAPER)
	var menu := _vbox(row, 14)
	menu.custom_minimum_size.x = 390
	menu.size_flags_horizontal = Control.SIZE_SHRINK_END
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_label(menu, "OPEN THE CASE", 16, GOLD)
	var cont := _button(menu, "Continue investigation", func(): _load_slot("user://autosave.json"), 390)
	cont.disabled = not FileAccess.file_exists("user://autosave.json")
	var begin := _button(menu, "Begin a new investigation", _confirm_new, 390)
	_button(menu, "Settings & accessibility", _settings, 390)
	_button(menu, "Quit", _quit_game, 390)
	audio.play_music("title")
	audio.set_ambience(audio_catalog.location_ambience.get("ch1_l1", "harbor"))
	if not cont.disabled: cont.grab_focus()
	else: begin.grab_focus()

func _confirm_new() -> void:
	if not FileAccess.file_exists("user://autosave.json"):
		_new_game()
		return
	var box := _modal("Begin a new case")
	_label(box, "Starting a new investigation replaces your current case and its automatic progress. Choose Continue investigation to keep playing your existing case.", 23)
	_button(box, "Begin new investigation", _new_game)

func _new_game() -> void:
	state.new_game()
	playing = true
	selected_item = ""
	hint_levels.clear()
	_show_location()
	_autosave()
	_story("A letter without a return address", str(state.data.intro), true)

func _load_slot(path: String) -> void:
	if not state.load_game(path):
		_story("The save could not be opened", state.last_error)
		return
	playing = true
	selected_item = ""
	_apply_audio()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if state.settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	_show_location()
	_toast("Investigation restored.")

func _chapter(id: String) -> Dictionary:
	for chapter in state.data.chapters:
		if chapter.id == id: return chapter
	return {}

func _show_location() -> void:
	_clear_page()
	if state.searches.has(state.location_id):
		_show_search_location()
		return
	var location: Dictionary = state.get_location(state.location_id)
	var chapter: Dictionary = _chapter(location.chapter)
	var margin := _margin(page, 26)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layout := _vbox(margin, 18)
	var nav := _hbox(layout)
	_label(nav, "THE QUIET MERIDIAN", 22, GOLD, true)
	_button(nav, "Map  M", _map)
	_button(nav, "Casebook  J", _casebook)
	_button(nav, "Inventory  I  ·  %d" % state.inventory.size(), _inventory)
	_button(nav, "Pause", _pause)
	_rule(layout)
	var row := _hbox(layout, 26)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scene_column := _vbox(row, 14)
	scene_column.size_flags_stretch_ratio = 3.1
	var title_row := _hbox(scene_column)
	_label(title_row, str(location.title), 36, PAPER, true)
	_label(scene_column, str(chapter.title).to_upper(), 15, GOLD)
	var aspect := AspectRatioContainer.new()
	aspect.ratio = 16.0 / 9.0
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	scene_column.add_child(aspect)
	var scene := Control.new()
	aspect.add_child(scene)
	_add_environment(scene, state.location_id, str(location.art))
	# Each spot remains keyboard accessible; the named labels are an accessibility option.
	for spot in location.hotspots:
		var marker := Button.new()
		var seen: bool = spot.id in state.evidence
		marker.set_meta("hotspot_id", str(spot.id))
		marker.set_meta("hotspot_seen", seen)
		for style_name in ["normal", "hover", "pressed", "focus"]:
			marker.add_theme_stylebox_override(style_name, _hotspot_style(style_name, bool(state.settings.hotspot_labels)))
		marker.text = ("✓ " if seen else "") + str(spot.label) if state.settings.hotspot_labels else ""
		marker.tooltip_text = str(spot.label)
		marker.accessibility_name = str(spot.label)
		var position_override: Array = hotspot_layout.get(spot.id, [spot.x, spot.y])
		marker.anchor_left = float(position_override[0])
		marker.anchor_top = float(position_override[1])
		marker.anchor_right = float(position_override[0])
		marker.anchor_bottom = float(position_override[1])
		marker.offset_left = -22
		marker.offset_top = -22
		marker.offset_right = 22
		marker.offset_bottom = 22
		if float(position_override[0]) > 0.65: marker.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		var evidence_icon := _evidence_index(str(spot.id))
		if evidence_icon >= 0 and not seen:
			marker.icon = _atlas("res://assets/art/evidence-atlas.png", evidence_icon, 3, 5)
			if art_layout.evidence_portraits.has(spot.id):
				marker.icon = _atlas("res://assets/art/portraits/cast.png", art_layout.portraits.find(art_layout.evidence_portraits[spot.id]), 3, 3)
			marker.expand_icon = true
			marker.add_theme_constant_override("icon_max_width", 52)
			marker.custom_minimum_size = Vector2(60, 60)
		marker.add_theme_font_size_override("font_size", 18)
		marker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		scene.add_child(marker)
		marker.pressed.connect(_examine.bind(str(spot.id)))
		marker.mouse_entered.connect(_show_hotspot_hint.bind(marker))
		marker.focus_entered.connect(_show_hotspot_hint.bind(marker))
		marker.mouse_exited.connect(_leave_hotspot_hint.bind(marker))
		marker.focus_exited.connect(_leave_hotspot_hint.bind(marker))
	_label(scene_column, str(location.description), 20, MUTED)
	var travel := _hbox(scene_column)
	_button(travel, "Explore the city", _map)
	_button(travel, "Show / hide points of interest  F1", func():
		state.settings.hotspot_labels = not state.settings.hotspot_labels
		_save_preferences()
		_show_location())
	var side := _vbox(row, 14)
	side.custom_minimum_size.x = 350
	side.size_flags_stretch_ratio = 1.0
	_label(side, "FIELD NOTES", 16, GOLD)
	_label(side, "Investigations here", 28, PAPER, true)
	var tasks := _scroll(side)
	for conversation in dialogue_data:
		if conversation.location == state.location_id and _requirements_met(conversation.get("requires", [])):
			_button(tasks, "Talk · " + _character_name(str(conversation.character)), _conversation.bind(conversation))
	var count := 0
	for puzzle in state.data.puzzles:
		if puzzle.location != state.location_id: continue
		count += 1
		var done: bool = puzzle.id in state.solved
		_label(tasks, ("RESOLVED" if done else ("READY TO WORK" if state.can_solve(puzzle.id) else "GATHER EVIDENCE")), 13, GOLD if done else MUTED)
		var button := _button(tasks, str(puzzle.title), _open_puzzle.bind(str(puzzle.id)))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label(tasks, str(puzzle.success) if done else str(puzzle.prompt), 18, MUTED)
		_rule(tasks)
	if count == 0: _label(tasks, "Inspect the room and record what you find.", 20, MUTED)
	var found := 0
	for spot in location.hotspots:
		if spot.id in state.evidence: found += 1
	_label(side, "%d / %d points examined" % [found, location.hotspots.size()], 17, MUTED)
	_label(side, "%d / %d investigations resolved" % [state.solved.size(), state.data.puzzles.size()], 17, GOLD)
	_rule(layout)
	status_text = "Select a point of interest to inspect it. Tab and Enter work throughout."
	if not selected_item.is_empty(): status_text = "In hand: " + str(state.get_item(selected_item).name) + ". Inspect an object or open its investigation to use your evidence."
	feedback = _label(layout, status_text, 18, MUTED)
	active_chapter = location.chapter
	_play_ambience(active_chapter)

func _show_search_location() -> void:
	var location: Dictionary = state.get_location(state.location_id)
	search_room = CampaignSearchRoom.new()
	search_room.campaign = state
	search_room.location_id = state.location_id
	search_room.objective = case_guide.room_goal(state.location_id) if not state.search_complete(state.location_id) else "Evidence recovered. Open the Casebook to follow this lead."
	search_room.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	search_room.object_requested.connect(_find_room_object)
	search_room.menu_used.connect(_click_sound)
	search_room.hint_used.connect(func(): _search_sound("search_hint", "paper"))
	search_room.navigation_requested.connect(_search_navigation)
	search_room.progress_changed.connect(_autosave)
	search_room.time_expired.connect(_search_expired)
	page.add_child(search_room)
	feedback = search_room.message
	status_text = feedback.text
	toast_timer = 0
	active_chapter = location.chapter
	_play_ambience(active_chapter)

func _search_navigation(action: String) -> void:
	match action:
		"map": _map()
		"notebook": _casebook()
		"bag": _inventory()
		"menu": _pause()



func _add_next_step(box: Control) -> void:
	var step: Dictionary = case_guide.next_step()
	_rule(box)
	_label(box, "NEXT STEP", 15, GOLD)
	_label(box, str(step.detail), 22)
	_button(box, str(step.title), _follow_case_step.bind(step))

func _follow_case_step(step: Dictionary) -> void:
	match str(step.action):
		"search": _travel(str(step.location))
		"puzzle":
			_travel(str(step.location))
			_open_puzzle(str(step.id))
		"inventory": _inventory()
		"ending": _story("The record belongs to everyone", str(state.data.ending))
		_: _casebook()

func _find_room_object(id: String) -> void:
	if is_instance_valid(overlay) or not is_instance_valid(search_room): return
	var item: Dictionary = search_room.search.object_by_id(id)
	var result: Dictionary = state.find_search_object(state.location_id, id)
	if not result.ok: _toast(result.text); return
	var saved: bool = state.save_game("user://autosave.json")
	search_room.sync_progress()
	if result.complete:
		_show_location()
		_search_reward()
		_search_sound("search_complete", "success")
		reward_audio_queue = [{"cue":"search_receipt", "delay":1.5}]
		if saved: reward_audio_queue.append({"cue":"search_journal", "delay":.6})
	else:
		_search_sound("search_symbol" if not str(item.get("found_note", "")).is_empty() else "search_found", "collect")
		_toast("Found: " + str(item.name) + str(item.get("found_note", "")))
	if not saved: _toast("Progress could not be saved: " + state.last_error)

func _search_sound(cue: String, fallback: String) -> void:
	if not is_instance_valid(audio): return
	audio.play_sfx(cue if audio_catalog.get("sfx", {}).has(cue) else fallback)

func _search_reward() -> void:
	if not state.search_complete(state.location_id): return
	var definition: Dictionary = state.searches[state.location_id]
	var box := _modal(str(definition.reward_title))
	_label(box, "SEARCH COMPLETE · DISCOVERY RECORDED", 15, GOLD)
	_label(box, case_guide.discovery(state.location_id), 26, PAPER, true)
	_label(box, "Insight available: %d" % state.insight_balance(), 20, GOLD)
	_add_next_step(box)
	_button(box, "Review this room’s evidence", _room_investigations)
	_button(box, "Return to the picture", _close_modal)

func _room_investigations() -> void:
	_casebook("room")

func _hotspot_style(style_name: String, reveal: bool) -> StyleBox:
	# Normal exploration exposes the painting, including after evidence has been
	# recorded. Named tags are opt-in; keyboard focus stays visibly discoverable.
	if not reveal and style_name in ["normal", "hover"]: return StyleBoxEmpty.new()
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(4)
	box.bg_color = Color(0.07, 0.13, 0.16, 0.92 if reveal else 0.18)
	box.border_color = GOLD
	box.set_border_width_all(2 if style_name == "focus" else 1)
	if style_name == "focus": box.draw_center = false
	elif style_name == "hover": box.bg_color = Color(0.16, 0.25, 0.28, 0.96)
	if reveal:
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 7
		box.content_margin_bottom = 7
	return box

func _show_hotspot_hint(marker: Button) -> void:
	if not is_instance_valid(marker) or not is_instance_valid(feedback): return
	toast_timer = 0.0
	var action := "Review" if bool(marker.get_meta("hotspot_seen", false)) else "Examine"
	feedback.text = action + " · " + marker.accessibility_name
	if marker.has_focus(): feedback.text += " · Enter or Space"

func _leave_hotspot_hint(marker: Button) -> void:
	if not is_instance_valid(marker) or not is_instance_valid(feedback): return
	if marker.has_focus() or marker.get_global_rect().has_point(get_global_mouse_position()):
		_show_hotspot_hint(marker)
	else:
		feedback.text = status_text

func _examine(id: String) -> void:
	var result: Dictionary = state.examine(id)
	if not result.ok: _toast(result.text); return
	var fallback := "collect" if not str(result.get("item", "")).is_empty() else "paper"
	audio.play_sfx(_interaction_sound("hotspots", id, fallback))
	_autosave()
	var spot: Dictionary = state.get_hotspot(id)
	_show_location()
	var coordinates: Array = hotspot_layout.get(id, [spot.x, spot.y])
	if is_instance_valid(environment_stage): environment_stage.pulse_at(Vector2(float(coordinates[0]), float(coordinates[1])))
	var box := _modal(str(spot.label))
	var evidence_icon := _evidence_index(id)
	if evidence_icon >= 0:
		var icon := TextureRect.new()
		icon.texture = _atlas("res://assets/art/evidence-atlas.png", evidence_icon, 3, 5)
		if art_layout.evidence_portraits.has(id):
			icon.texture = _atlas("res://assets/art/portraits/cast.png", art_layout.portraits.find(art_layout.evidence_portraits[id]), 3, 3)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(140, 140)
		box.add_child(icon)
	_label(box, "EVIDENCE RECORDED", 14, GOLD)
	_label(box, str(result.text), 24)
	if not str(result.get("item", "")).is_empty():
		_rule(box)
		var item: Dictionary = state.get_item(result.item)
		_inventory_icon(box, str(result.item), 120)
		_label(box, "Added to inventory · " + str(item.name), 22, GOLD)
		_label(box, str(item.description), 20, MUTED)
	if not selected_item.is_empty():
		_label(box, "Carrying " + str(state.get_item(selected_item).name) + ". Required tools are checked when you work on an investigation; objects stay available for later use.", 18, MUTED)
	_button(box, "Return to the scene", _close_modal)

func _modal(title: String) -> VBoxContainer:
	_close_modal()
	if is_instance_valid(page): page.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.03, 1.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var margin := _margin(overlay, 62)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layout := _vbox(margin, 20)
	var head := _hbox(layout)
	_label(head, title, 37, PAPER, true)
	var close := _button(head, "Close  Esc", _close_modal)
	close.grab_focus()
	_rule(layout)
	modal_name = title
	return _scroll(layout)

func _close_modal() -> void:
	puzzle_timer_id = ""
	puzzle_hint_button = null
	puzzle_status_label = null
	puzzle_submit_buttons.clear()
	if is_instance_valid(audio): audio.stop_voice()
	voice_ids.clear()
	character_stage = null
	dialogue_character = ""
	voice_status = null
	subtitle_label = null
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
	overlay = null
	modal_name = ""
	if is_instance_valid(page): page.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	if is_instance_valid(audio):
		audio.play_music(active_chapter if playing and not active_chapter.is_empty() else "title")

func _story(title: String, prose: String, chapter_after: bool = false) -> void:
	var box := _modal(title)
	var is_briefing := chapter_after
	if chapter_after:
		_label(box, case_guide.data.title, 32, GOLD, true)
		_label(box, case_guide.data.premise, 25)
		_label(box, "YOUR TASK", 15, GOLD)
		_label(box, case_guide.data.mission, 25)
		_label(box, case_guide.data.search_explanation, 21, MUTED)
	else:
		for chapter in state.data.chapters:
			if prose == str(chapter.intro):
				is_briefing = true
				var brief: Dictionary = case_guide.data.chapters[chapter.id]
				_label(box, brief.question, 31, GOLD, true)
				_label(box, brief.mission, 25)
				_label(box, "Your Casebook (J or C) holds this room’s evidence and opens your next investigation directly.", 21, MUTED)
	var voice_parent: Control = box
	var line_id := _narration_id(prose)
	if is_briefing:
		var original := _vbox(box)
		voice_parent = original
		_label(original, prose, 23)
		original.visible = false
		_button(box, "Read the letter" if chapter_after else "Read the chapter scene", func():
			original.visible = not original.visible
			if original.visible and not line_id.is_empty() and bool(state.settings.auto_voice): audio.play_sequence([line_id])
			elif not original.visible: audio.stop_voice())
	else: _label(box, prose, 25)
	if not line_id.is_empty(): _voice_controls(voice_parent, [line_id], not is_briefing)
	_button(box, "Continue", func():
		_close_modal()
		if chapter_after:
			var chapter: Dictionary = _chapter(state.get_location(state.location_id).chapter)
			_story(str(chapter.title), str(chapter.intro)))

func _open_puzzle(id: String) -> void:
	selected_puzzle = id
	active_board = null
	answer = []
	var puzzle: Dictionary = state.get_puzzle(id)
	var box := _modal(str(puzzle.title))
	puzzle_timer_id = id if id not in state.solved else ""
	if id not in state.solved and (puzzle.type == "routing" or id == _chapter(puzzle.chapter).final_puzzle): audio.play_music("tension")
	_label(box, str(state.get_location(puzzle.location).title).to_upper() + "  /  " + str(puzzle.type).to_upper(), 14, GOLD)
	_label(box, str(puzzle.prompt), 26, PAPER, true)
	_label(box, str(puzzle.details), 22)
	if id in state.solved:
		_label(box, "RESOLVED\n" + str(puzzle.success), 24, GOLD)
		if id == state.data.chapters[-1].final_puzzle:
			_button(box, "Read the conclusion again", func(): _story("The record belongs to everyone", str(state.data.ending)))
		_button(box, "Return to the scene", _close_modal)
		return
	_rule(box)
	var columns := _hbox(box, 32)
	var clues := _vbox(columns, 12)
	clues.custom_minimum_size.x = 600
	_label(clues, "EVIDENCE & CONNECTIONS", 15, GOLD)
	for clue_id in puzzle.clues:
		var spot: Dictionary = state.get_hotspot(clue_id)
		if clue_id in state.evidence:
			_label(clues, str(spot.label), 20, GOLD)
			_label(clues, str(spot.text), 20, MUTED)
		else:
			_label(clues, "Missing · " + str(spot.label) + " — " + _clue_location(clue_id), 20, MUTED)
	for required in puzzle.requires:
		_label(clues, ("✓ " if required in state.solved else "Needs resolution · ") + str(state.get_puzzle(required).title), 18, MUTED)
	for item_id in puzzle.items:
		_label(clues, ("✓ In inventory · " if item_id in state.inventory else "Needed object · ") + str(state.get_item(item_id).name), 18, GOLD)
	var work := _vbox(columns, 14)
	work.custom_minimum_size.x = 520
	_label(work, "WORKING THEORY", 15, GOLD)
	if puzzle.location != state.location_id:
		_label(work, "Return to the investigation's location to work on it.", 22)
		_button(work, "Travel to " + str(state.get_location(puzzle.location).title), _travel.bind(str(puzzle.location)))
	elif not state.can_solve(id):
		_label(work, "Follow the connections and gather the missing evidence listed here. You can review everything already recorded without leaving this page.", 23)
		_button(work, "Open city map", _map)
		_button(work, "Inspect inventory / combine", _inventory)
	else:
		match str(puzzle.type):
			"code":
				answer_entry = LineEdit.new()
				answer_entry.placeholder_text = "Enter your answer"
				answer_entry.custom_minimum_size.y = 58
				answer_entry.max_length = 100
				answer_entry.add_theme_font_size_override("font_size", 24)
				work.add_child(answer_entry)
				answer_entry.text_submitted.connect(func(value: String): _submit(value))
				puzzle_submit_buttons.append(_button(work, "Test the answer", func(): _submit(answer_entry.text)))
				answer_entry.grab_focus()
			"choice", "deduction":
				for option in puzzle.options:
					var button := _button(work, str(option), _submit.bind(str(option)))
					puzzle_submit_buttons.append(button)
					button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			"order", "sequence", "routing":
				_label(work, "Select in order. Use Undo or Clear to revise your sequence.", 19, MUTED)
				answer_label = _label(work, "No steps selected", 22, GOLD)
				if board_data.has(id):
					active_board = RouteBoard.new()
					work.add_child(active_board)
					active_board.configure(board_data[id], _append_answer)
				for option in puzzle.options:
					var button := _button(work, str(option), _append_answer.bind(str(option)))
					button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				var actions := _hbox(work)
				_button(actions, "Undo", func():
					if not answer.is_empty(): answer.pop_back()
					_refresh_answer())
				_button(actions, "Clear", func(): answer.clear(); _refresh_answer())
				puzzle_submit_buttons.append(_button(work, "Test the sequence", func(): _submit(answer.duplicate())))
			"hidden":
				_label(work, "All listed objects have been located in the illustrated scenes. Their details are preserved in your evidence.", 22)
				puzzle_submit_buttons.append(_button(work, "Compare the recovered evidence", _submit.bind("found")))
			"assembly":
				_label(work, "The necessary tools are in your inventory. Fit the prepared components according to the instructions above.", 22)
				puzzle_submit_buttons.append(_button(work, "Apply the prepared assembly", _submit.bind("assembled")))
	puzzle_feedback = _label(work, "", 20, GOLD)
	_rule(work)
	puzzle_status_label = _label(work, "", 18, MUTED)
	puzzle_hint_button = _button(work, "Ask for a hint", _hint.bind(id))
	_refresh_puzzle_controls()
	var level: int = int(state.puzzle_status(id).hints_used)
	hint_levels[id] = level
	if level > 0: _show_hint_text(puzzle, level)

func _clue_location(id: String) -> String:
	for location in state.data.locations:
		for spot in location.hotspots:
			if spot.id == id: return str(location.title)
	return "Unknown location"

func _append_answer(value: String) -> void:
	var puzzle: Dictionary = state.get_puzzle(selected_puzzle)
	if puzzle.type == "order" and value in answer:
		puzzle_feedback.text = "That step is already in the sequence. Undo or clear to move it."
		return
	if answer.size() >= 24: return
	answer.append(value)
	_refresh_answer()

func _refresh_answer() -> void:
	answer_label.text = " → ".join(answer) if not answer.is_empty() else "No steps selected"
	if is_instance_valid(active_board): active_board.set_path(answer)

func _hint(id: String) -> void:
	var result: Dictionary = state.request_puzzle_hint(id)
	if result.ok:
		hint_levels[id] = int(result.level)
		_show_hint_text(state.get_puzzle(id), int(result.level))
		_autosave()
	elif is_instance_valid(puzzle_feedback): puzzle_feedback.text = str(result.text)
	_refresh_puzzle_controls()

func _refresh_puzzle_controls() -> void:
	if puzzle_timer_id.is_empty() or not is_instance_valid(puzzle_hint_button): return
	var status: Dictionary = state.puzzle_status(puzzle_timer_id)
	puzzle_hint_button.disabled = not status.can_hint
	puzzle_hint_button.text = "Hint · free" if int(status.hint_cost) == 0 else "Hint · 1 Insight"
	if int(status.hints_used) >= 3: puzzle_hint_button.text = "All 3 hints used"
	elif float(status.hint_cooldown) > 0: puzzle_hint_button.text = "Hint ready in %ds" % ceili(float(status.hint_cooldown))
	puzzle_status_label.text = "Hints %d / 3 · Insight %d" % [int(status.hints_used), state.insight_balance()]
	if float(status.submit_cooldown) > 0: puzzle_status_label.text += " · Try again in %ds" % ceili(float(status.submit_cooldown))
	for button in puzzle_submit_buttons:
		if is_instance_valid(button): button.disabled = float(status.submit_cooldown) > 0

func _show_hint_text(puzzle: Dictionary, level: int) -> void:
	if is_instance_valid(puzzle_feedback):
		puzzle_feedback.text = "Hint %d / %d\n%s" % [level, puzzle.hints.size(), str(puzzle.hints[level - 1])]

func _submit(value: Variant) -> void:
	if selected_puzzle in state.solved:
		_toast("This investigation is already resolved.")
		return
	var puzzle: Dictionary = state.get_puzzle(selected_puzzle)
	var result: Dictionary = state.try_solve(selected_puzzle, value)
	if not result.ok:
		_autosave()
		_refresh_puzzle_controls()
		if is_instance_valid(puzzle_feedback): puzzle_feedback.text = str(result.text)
		else: _toast(str(result.text))
		audio.play_sfx("error")
		return
	_autosave()
	var chapter: Dictionary = _chapter(puzzle.chapter)
	var fallback := "chapter" if puzzle.id == chapter.final_puzzle else "success"
	audio.play_sfx(_interaction_sound("puzzle_success", str(puzzle.id), fallback))
	_show_location()
	if puzzle.id == chapter.final_puzzle:
		audio.play_music("resolution")
		if puzzle.chapter == state.data.chapters[-1].id:
			var box := _modal("The record belongs to everyone")
			_label(box, str(puzzle.success), 25, GOLD)
			_label(box, str(chapter.closing), 24, MUTED)
			_label(box, str(state.data.ending), 25)
			_voice_controls(box, [str(chapter.id) + "_closing", "narration_ending"])
			audio.play_music("resolution")
			_label(box, "All %d investigations resolved. You may revisit the city and reread the casebook." % state.solved.size(), 20, MUTED)
			_button(box, "Return to Leth", _close_modal)
		else:
			var next_index: int = state.data.chapters.find(chapter) + 1
			var next: Dictionary = state.data.chapters[next_index]
			var box := _modal(str(chapter.title) + " · complete")
			_label(box, str(puzzle.success), 25, GOLD)
			_label(box, str(chapter.closing), 24)
			_voice_controls(box, [str(chapter.id) + "_closing"])
			audio.play_music("resolution")
			_button(box, "Continue · " + str(next.title), func():
				_travel(str(next.locations[0]))
				_story(str(next.title), str(next.intro)))
			_button(box, "Stay and review the evidence", _close_modal)
	else:
		_story("A connection made", str(result.text))

func _travel(id: String) -> void:
	if state.visit(id):
		audio.play_sfx(_interaction_sound("travel", id, "travel"))
		_show_location()
		_autosave()
	else: _toast(state.last_error)

func _map() -> void:
	var box := _modal("A city built around the tide")
	var map := CityMap.new()
	map.campaign = state
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.travel_requested.connect(_travel)
	box.add_child(map)

func _casebook(section: String = "room") -> void:
	var location: Dictionary = state.get_location(state.location_id)
	var chapter: Dictionary = _chapter(location.chapter)
	var box := _modal("Casebook · " + str(location.title))
	var tabs := _hbox(box)
	_button(tabs, "This room", _casebook.bind("room"))
	_button(tabs, "This chapter", _casebook.bind("chapter"))
	_button(tabs, "Story so far", _casebook.bind("story"))
	if section == "room":
		_label(box, case_guide.room_goal(state.location_id), 25, GOLD, true)
		var discovery: String = case_guide.discovery(state.location_id)
		if not discovery.is_empty(): _label(box, discovery, 23)
		_add_next_step(box)
		var step: Dictionary = case_guide.next_step()
		for puzzle in state.data.puzzles:
			if puzzle.location != state.location_id or puzzle.id in state.solved or puzzle.id == step.get("id", ""): continue
			_button(box, str(puzzle.title), _open_case_investigation.bind(str(puzzle.id)))
			_label(box, "Ready to investigate" if state.can_solve(puzzle.id) else "More evidence or another connection is needed.", 18, MUTED)
		for conversation in dialogue_data:
			if conversation.location == state.location_id and _requirements_met(conversation.get("requires", [])):
				_button(box, "Talk · " + _character_name(str(conversation.character)), _conversation.bind(conversation))
		var evidence := _vbox(box)
		for spot in location.hotspots:
			if spot.id in state.evidence:
				_button(evidence, str(spot.label), _examine.bind(str(spot.id)))
		if evidence.get_child_count() > 0:
			evidence.visible = false
			_button(box, "Evidence from this room", func(): evidence.visible = not evidence.visible)
	elif section == "chapter":
		_label(box, str(chapter.title), 29, GOLD, true)
		_label(box, str(case_guide.data.chapters[chapter.id].question), 25)
		_add_next_step(box)
		for puzzle in state.data.puzzles:
			if puzzle.chapter != chapter.id: continue
			var done: bool = puzzle.id in state.solved
			_button(box, ("✓ " if done else "○ ") + str(puzzle.title), _open_case_investigation.bind(str(puzzle.id)))
			_label(box, str(state.get_location(puzzle.location).title) + " · " + ("Resolved" if done else ("Ready to investigate" if state.can_solve(puzzle.id) else "Follow the evidence")), 18, MUTED)
		_button(box, "Collected evidence", _journal)
	else:
		_label(box, case_guide.title(), 30, GOLD, true)
		_label(box, case_guide.mission(), 24)
		_label(box, str(case_guide.data.premise), 22, MUTED)
		for previous in state.data.chapters:
			if previous.final_puzzle not in state.solved: continue
			_rule(box)
			_label(box, "RESOLVED · " + str(previous.title), 23, GOLD)
			_label(box, str(case_guide.data.chapters[previous.id].recap), 22)
		_button(box, "People of Leth", _people)
		_button(box, "Collected evidence", _journal)
		_button(box, "Objects in the case history", _inventory_history)

func _journal() -> void:
	var box := _modal("Collected evidence")
	_button(box, "Back to investigations", _casebook)
	if state.evidence.is_empty(): _label(box, "Your notebook is empty. Inspect the landing to begin.", 23)
	for location in state.data.locations:
		var entries: Array = []
		for spot in location.hotspots:
			if spot.id in state.evidence: entries.append(spot)
		if entries.is_empty(): continue
		_label(box, str(location.title), 29, GOLD, true)
		for spot in entries:
			_label(box, str(spot.label), 22, GOLD)
			_label(box, str(spot.text), 22)
		_rule(box)

func _people() -> void:
	var box := _modal("People of Leth")
	_button(box, "Back to investigations", _casebook)
	for character in state.data.characters:
		var row := _hbox(box, 26)
		_portrait(row, str(character.id), 160)
		var description := _vbox(row)
		_label(description, str(character.name) + "  ·  " + str(character.role), 28, GOLD, true)
		_label(description, str(character.description), 23)
		_rule(box)

func _inventory() -> void:
	var active: Array = state.active_inventory()
	if selected_item not in active: selected_item = ""
	var box := _modal("Objects carried forward")
	_label(box, "%d useful objects · combined components and finished tools are kept in your case history." % active.size(), 21, MUTED)
	var row := _hbox(box, 30)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 18)
	row.add_child(grid)
	for id in active:
		var item: Dictionary = state.get_item(id)
		var card := _vbox(grid, 5)
		card.custom_minimum_size.x = 160
		var choose := _button(card, "", _select_inventory_item.bind(str(id)))
		choose.custom_minimum_size = Vector2(160, 104)
		choose.icon = _atlas("res://assets/art/inventory-atlas.png", art_layout.inventory.find(id), 6, 6)
		choose.expand_icon = true
		choose.add_theme_constant_override("icon_max_width", 80)
		choose.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choose.tooltip_text = str(item.name)
		choose.accessibility_name = str(item.name)
		var name_label := _label(card, str(item.name), 18, GOLD if id == selected_item else PAPER)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.custom_minimum_size.y = 48
	var detail := _vbox(row, 14)
	detail.custom_minimum_size.x = 420
	if not selected_item.is_empty():
		var item: Dictionary = state.get_item(selected_item)
		_inventory_icon(detail, selected_item, 120)
		_label(detail, str(item.name), 28, GOLD, true)
		_label(detail, str(item.description), 22)
		if active.size() > 1:
			_label(detail, "COMBINE WITH", 15, GOLD)
			for other in active:
				if other != selected_item: _button(detail, str(state.get_item(other).name), _combine.bind(selected_item, str(other)))
	else:
		_label(detail, "Select an object to inspect it or combine it with another.", 24, GOLD)
	if active.is_empty(): _label(detail, "Your useful objects have all been recorded or put to use. Search another room to follow the case.", 23)
	inventory_feedback = _label(detail, "", 20, GOLD)
	_button(box, "Case history · used objects and components", _inventory_history)

func _select_inventory_item(id: String) -> void:
	selected_item = id
	_inventory()

func _inventory_history() -> void:
	var box := _modal("Objects in the case history")
	var active: Array = state.active_inventory()
	var recorded := 0
	for id in state.inventory:
		if id in active: continue
		recorded += 1
		var item: Dictionary = state.get_item(id)
		_label(box, str(item.name), 24, GOLD, true)
		_label(box, str(item.description), 21)
		for recipe in state.data.recipes:
			if id in recipe.ingredients and recipe.result in state.inventory:
				_label(box, "Incorporated into " + str(state.get_item(recipe.result).name), 18, MUTED)
		_rule(box)
	if recorded == 0: _label(box, "Objects appear here once they have been incorporated into something else or their work is complete.", 23)
	_button(box, "Return to your inventory", _inventory)

func _combine(a: String, b: String) -> void:
	var result: Dictionary = state.combine(a, b)
	if result.ok:
		selected_item = result.get("item", "")
		_autosave()
		audio.play_sfx(_interaction_sound("recipe_results", str(result.get("item", "")), "combine"))
		_inventory()
	if is_instance_valid(inventory_feedback): inventory_feedback.text = str(result.text)

func _pause() -> void:
	var box := _modal("Set the case down")
	_label(box, "Your search clock is paused. Progress is saved automatically after discoveries, deductions and travel, and when you leave the game.", 23)
	_button(box, "Return to investigation", _close_modal)
	_button(box, "Settings & accessibility", _settings)
	_button(box, "Save and return to title", _save_and_return_to_title)
	_button(box, "Save and quit", _save_and_quit)

func _save_and_return_to_title() -> void:
	if _autosave(): _show_title()
	else: _story("Your progress could not be saved", state.last_error)

func _save_and_quit() -> void:
	if _autosave(): _quit_game()
	else: _story("Your progress could not be saved", state.last_error)



func _settings() -> void:
	var box := _modal("Settings & accessibility")
	for setting in [["music", "Music"], ["ambience", "Environmental ambience"], ["voice", "Character voices & narration"], ["sound", "Interaction sounds"]]:
		_label(box, setting[1], 23, GOLD)
		if setting[0] == "music": _label(box, "Sonder · Purrple Cat · CC BY-SA 3.0", 17, MUTED)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = state.settings[setting[0]]
		slider.custom_minimum_size.y = 48
		slider.accessibility_name = setting[1]
		box.add_child(slider)
		slider.value_changed.connect(func(value: float): state.settings[setting[0]] = value; _apply_audio(); _save_preferences())
	for setting in [["large_text", "Larger reading text"], ["reduced_motion", "Reduce motion"], ["subtitles", "Spoken-line subtitles"], ["auto_voice", "Automatically play recorded voices"], ["fullscreen", "Fullscreen display"]]:
		var toggle := CheckButton.new()
		toggle.text = setting[1]
		toggle.button_pressed = state.settings[setting[0]]
		toggle.custom_minimum_size.y = 56
		box.add_child(toggle)
		toggle.toggled.connect(func(value: bool):
			state.settings[setting[0]] = value
			_apply_audio()
			if setting[0] == "reduced_motion" and is_instance_valid(environment_stage): environment_stage.set_reduced_motion(value)
			_save_preferences()
			if setting[0] == "fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED))
	_label(box, "Detective searches are timed, and the clock tightens in later chapters. Five rapid misses in three seconds cost ten seconds. A first clear earns 1 Insight, plus 1 for a clean clear: no rapid-click penalty, no paid hint and no restart. A deduction solved without a paid hint earns 1 Insight. Each search or deduction allows three hints: the first is free, the next two cost one Insight each, with a 30-second cooldown. Choose a name in the search list to aim your next hint at it. One Insight buys 30 seconds, at most twice per clock. Restarting an expired search keeps your finds and starts a shorter clock. Searches pause while covered by a panel or when the game loses focus. Three wrong deduction answers within a minute impose a ten-second submission cooldown. Tab moves focus and Enter activates. J or C opens the Casebook; M opens the map; I opens inventory; F1 requests a search hint; F11 toggles fullscreen. Scroll or +/− zooms, right-drag pans. Focus the picture and use arrows and Enter to search by keyboard. Larger text applies when a panel is reopened.", 22, MUTED)
	_button(box, "Apply and return", func():
		if playing: _show_location()
		else: _show_title())



func _autosave() -> bool:
	if not playing: return true
	var ok: bool = state.save_game("user://autosave.json")
	if not ok: _toast("Automatic save failed: " + state.last_error)
	return ok

func _save_preferences() -> void:
	var config := ConfigFile.new()
	for key in state.settings: config.set_value("settings", key, state.settings[key])
	config.save("user://preferences.cfg")

func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load("user://preferences.cfg") == OK:
		for key in state.settings:
			var value: Variant = config.get_value("settings", key, state.settings[key])
			if key in ["music", "sound", "voice", "ambience"] and (value is float or value is int):
				state.settings[key] = clampf(float(value), 0, 1)
			elif value is bool and key not in ["music", "sound", "voice", "ambience"]: state.settings[key] = value
	if state.settings.fullscreen: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _apply_audio() -> void:
	if is_instance_valid(audio): audio.set_volumes(state.settings)

func _play_ambience(chapter: String) -> void:
	if not is_instance_valid(audio): return
	audio.play_music(chapter)
	audio.set_ambience(str(audio_catalog.get("location_ambience", {}).get(state.location_id, "interior")))

func _interaction_sound(group: String, id: String, fallback: String) -> String:
	# An authored action selects its material independently of narrative wording.
	# Keep older catalogues functional if optional presentation data is missing.
	var entries: Variant = interaction_audio.get(group, {})
	if entries is Dictionary:
		var cue := str(entries.get(id, ""))
		if audio_catalog.get("sfx", {}).has(cue): return cue
	return fallback

func _click_sound() -> void:
	if is_instance_valid(audio): _search_sound("search_menu", "ui")

func _chime() -> void:
	if is_instance_valid(audio): audio.play_sfx("success")

func _toast(value: String) -> void:
	if is_instance_valid(feedback):
		feedback.text = value
		toast_timer = 9

func _fatal(value: String) -> void:
	_clear_page()
	var margin := _margin(page, 80)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label(margin, "The Quiet Meridian could not open its case file.\n\n" + value, 26)
	if "--smoke-test" in OS.get_cmdline_user_args():
		push_error(value)
		get_tree().quit(1)

func _atlas(path: String, index: int, columns: int, rows: int) -> AtlasTexture:
	var texture := _texture(path)
	if texture == null: return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	var cell := Vector2(float(texture.get_width()) / columns, float(texture.get_height()) / rows)
	atlas.region = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	atlas.filter_clip = true
	return atlas

func _evidence_index(id: String) -> int:
	return int(art_layout.get("evidence", {}).get(id, -1))

func _portrait(parent: Node, id: String, side: float) -> void:
	var index: int = art_layout.portraits.find(id)
	if index < 0: return
	var image := TextureRect.new()
	image.texture = _atlas("res://assets/art/portraits/cast.png", index, 3, 3)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(side, side)
	parent.add_child(image)

func _inventory_icon(parent: Node, id: String, side: float) -> void:
	var index: int = art_layout.inventory.find(id)
	if index < 0: return
	var image := TextureRect.new()
	image.texture = _atlas("res://assets/art/inventory-atlas.png", index, 6, 6)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(side, side)
	parent.add_child(image)

func _requirements_met(requirements: Array) -> bool:
	for id in requirements:
		if id not in state.solved: return false
	return true

func _character_name(id: String) -> String:
	for character in state.data.characters:
		if character.id == id: return str(character.name)
	return id

func _conversation(conversation: Dictionary, reply: String = "", topic_index: int = -1) -> void:
	var box := _modal(_character_name(str(conversation.character)))
	var row := _hbox(box, 35)
	dialogue_character = str(conversation.character)
	_add_character(row, dialogue_character, 310)
	var dialogue := _vbox(row, 24)
	_label(dialogue, str(conversation.get("greeting", "")) if reply.is_empty() else reply, 25)
	var ids: Array = [str(conversation.id) + "_greeting"]
	if topic_index < 0 and not reply.is_empty():
		for index in conversation.topics.size():
			if str(conversation.topics[index].reply) == reply: topic_index = index
	if topic_index >= 0:
		ids = [str(conversation.id) + "_q%d" % topic_index, str(conversation.id) + "_r%d" % topic_index]
		if is_instance_valid(character_stage): character_stage.set_emotion("concern" if topic_index == 2 else "explain")
	_voice_controls(dialogue, ids)
	_label(dialogue, "IONA", 15, GOLD)
	for index in conversation.topics.size():
		var topic: Dictionary = conversation.topics[index]
		if not _requirements_met(topic.get("requires", [])): continue
		var button := _button(dialogue, str(topic.question), func():
			var evidence_id: String = topic.get("evidence", "")
			if not evidence_id.is_empty():
				state.examine(evidence_id)
				_autosave()
			_conversation(conversation, str(topic.reply), index))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(dialogue, "We will speak again.", _close_modal)

func _add_environment(parent: Node, id: String, path: String) -> void:
	environment_stage = EnvironmentStage.new()
	parent.add_child(environment_stage)
	environment_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	environment_stage.configure(_texture(path), environment_profiles.get(id, {}), bool(state.settings.reduced_motion))

func _add_character(parent: Node, id: String, side: float) -> void:
	var path := "res://assets/art/characters/" + id + "-expressions.png"
	if not ResourceLoader.exists(path):
		_portrait(parent, id, side)
		return
	character_stage = CharacterStage.new()
	character_stage.custom_minimum_size = Vector2(side, side)
	character_stage.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	parent.add_child(character_stage)
	character_stage.configure(id, _texture(path), bool(state.settings.reduced_motion))

func _narration_id(prose: String) -> String:
	for id in voice_catalog.get("lines", {}):
		var line: Dictionary = voice_catalog.lines[id]
		if str(line.text) == prose: return str(id)
	return ""

func _voice_controls(parent: Node, ids: Array, autoplay: bool = true) -> void:
	voice_ids = ids.duplicate()
	var ready := not ids.is_empty()
	for id in ids: ready = ready and audio.has_voice(str(id))
	var controls := _hbox(parent, 10)
	voice_replay = _button(controls, "Replay voice", func(): audio.play_sequence(voice_ids))
	voice_replay.disabled = not ready
	voice_skip = _button(controls, "Skip voice", func(): audio.stop_voice(); audio.play_sfx("voice_skip"))
	voice_skip.disabled = true
	voice_status = _label(parent, "Voice ready" if ready else "Voice recording unavailable in this build · full text above", 16, MUTED)
	voice_progress = ProgressBar.new()
	voice_progress.show_percentage = false
	voice_progress.custom_minimum_size.y = 3
	voice_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(voice_progress)
	voice_progress.visible = ready
	subtitle_label = _label(parent, "", 21, GOLD)
	subtitle_label.visible = false
	if ready and autoplay and bool(state.settings.get("auto_voice", true)): audio.play_sequence(ids)

func _on_voice_started(line_id: String) -> void:
	if not is_instance_valid(audio) or line_id not in voice_ids or audio.current_line_id() != line_id or not audio.is_voice_playing(): return
	var line: Dictionary = voice_catalog.get("lines", {}).get(line_id, {})
	var speaker := str(line.get("speaker", ""))
	if is_instance_valid(character_stage):
		# Show Iona while she asks; return to the witness for their reply.
		var path := "res://assets/art/characters/" + speaker + "-expressions.png"
		if ResourceLoader.exists(path): character_stage.configure(speaker, _texture(path), bool(state.settings.reduced_motion))
		character_stage.set_speaking(audio.is_voice_active() and character_stage.character_id == speaker)

func _on_voice_finished(_line_id: String) -> void:
	if is_instance_valid(character_stage):
		character_stage.set_speaking(false)
		# Skipping during Iona's question returns the conversation to its witness.
		if not dialogue_character.is_empty() and character_stage.character_id != dialogue_character:
			var path := "res://assets/art/characters/" + dialogue_character + "-expressions.png"
			if ResourceLoader.exists(path): character_stage.configure(dialogue_character, _texture(path), bool(state.settings.reduced_motion))

func _set_focus_cover(covered: bool) -> void:
	if covered and not is_instance_valid(focus_cover):
		focus_cover = ColorRect.new()
		focus_cover.color = INK
		focus_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(focus_cover)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		focus_cover.add_child(center)
		_label(center, "Paused · return to the game to continue", 28, PAPER)
	elif not covered and is_instance_valid(focus_cover):
		remove_child(focus_cover)
		focus_cover.queue_free()
		focus_cover = null

func _search_expired() -> void:
	if is_instance_valid(overlay) or not playing: return
	var status: Dictionary = state.search_status()
	if not status.expired or status.complete: return
	_autosave()
	var box := _modal("Time has run out")
	_label(box, "This search is paused. Your earlier discoveries and completed rooms are safe.", 25, PAPER, true)
	_label(box, "Insight available: %d · Time extensions used: %d / 2" % [state.insight_balance(), int(status.extensions)], 22, GOLD)
	if status.can_extend: _button(box, "Add 30 seconds · 1 Insight", _extend_search)
	_button(box, "Restart the clock", _restart_search)
	_label(box, "Restarting keeps every object you have found and starts a shorter clock for the ones that remain. Insight already spent is not refunded, and the room no longer earns its clean-search bonus.", 21, MUTED)
	_button(box, "Choose another location", _map)
	_button(box, "Save and return to title", _save_and_return_to_title)

func _extend_search() -> void:
	var result: Dictionary = state.buy_search_time()
	if result.ok:
		_autosave()
		_close_modal()
	else: _toast(str(result.text))

func _restart_search() -> void:
	var result: Dictionary = state.retry_search()
	if result.ok:
		_autosave()
		_show_location()
		_toast(str(result.text))
	else: _toast(str(result.text))

func _open_case_investigation(id: String) -> void:
	var puzzle: Dictionary = state.get_puzzle(id)
	if puzzle.location != state.location_id:
		if not state.chapter_unlocked(puzzle.chapter): return
		_travel(str(puzzle.location))
	_open_puzzle(id)
