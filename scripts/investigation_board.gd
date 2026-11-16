class_name InvestigationBoard
extends Control
## Functional diagram renderer. Geometry, links and labels are authored data;
## this view never reads a puzzle solution or changes game progression.

const INK := Color("14262c")
const LINE := Color("708883")
const GOLD := Color("e1bd79")
const PAPER := Color("eee5cf")
const CORAL := Color("d99b89")
const NODE_SIZE := Vector2(116, 54)

var board_data: Dictionary = {}
var selected_path: Array = []
var _on_select: Callable
var _buttons: Dictionary = {}
var _nodes: Dictionary = {}
var _option_ids: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(520, 390)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_layout_nodes)


func configure(value: Dictionary, callback: Callable) -> void:
	board_data = value.duplicate(true)
	_on_select = callback
	selected_path = []
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_buttons.clear()
	_nodes.clear()
	_option_ids.clear()
	custom_minimum_size.y = float(board_data.get("height", 390))
	for entry in board_data.get("nodes", []):
		var id := str(entry.get("id", ""))
		var option := str(entry.get("option", entry.get("label", id)))
		_nodes[id] = entry
		_option_ids[option] = id
		var button := Button.new()
		button.text = str(entry.get("label", id))
		if not str(entry.get("detail", "")).is_empty():
			button.text += "\n" + str(entry.detail)
		button.tooltip_text = str(entry.get("description", option)) + " · select as the next route step"
		button.accessibility_name = option + (", " + str(entry.detail) if entry.has("detail") else "")
		button.set_meta("route_option", option)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_select.bind(option))
		add_child(button)
		_buttons[id] = button
	_layout_nodes()
	_update_styles()


func set_path(answer: Array) -> void:
	selected_path = answer.duplicate()
	_update_styles()
	queue_redraw()


func _select(option: String) -> void:
	if _on_select.is_valid():
		_on_select.call(option)


func _point(id: String) -> Vector2:
	var node: Dictionary = _nodes.get(id, {})
	# Normalized graph positions reserve room for the heading and legend.
	var plot_size := Vector2(maxf(size.x, 520), maxf(size.y, custom_minimum_size.y) - 88)
	return Vector2(float(node.get("x", 0.5)) * plot_size.x, 35 + float(node.get("y", 0.5)) * plot_size.y)


func _layout_nodes() -> void:
	for id in _buttons:
		var button: Button = _buttons[id]
		button.position = _point(str(id)) - NODE_SIZE / 2
		button.size = NODE_SIZE
	queue_redraw()


func _style(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(5)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _update_styles() -> void:
	var selected_ids: Array = []
	for option in selected_path:
		if _option_ids.has(option):
			selected_ids.append(_option_ids[option])
	for id in _buttons:
		var button: Button = _buttons[id]
		var hazard: bool = _nodes[id].get("hazard", false)
		var border := CORAL if hazard else LINE
		var fill := Color("352a2a") if hazard else Color("223b40")
		if id in selected_ids:
			border = GOLD
			fill = Color("494432")
		button.add_theme_stylebox_override("normal", _style(fill, border, 2 if id in selected_ids else 1))
		button.add_theme_stylebox_override("hover", _style(Color("3d5353"), GOLD, 2))
		button.add_theme_stylebox_override("pressed", _style(Color("5b5039"), GOLD, 2))
		button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), PAPER, 3))


func _has_edge(a: String, b: String) -> bool:
	for edge in board_data.get("edges", []):
		if edge[0] == a and edge[1] == b:
			return true
		if not board_data.get("directed", true) and edge[0] == b and edge[1] == a:
			return true
	return false


func _edge_endpoints(a: String, b: String) -> Array:
	var origin := _point(a)
	var destination := _point(b)
	var delta := destination - origin
	if delta.length_squared() < 1:
		return [origin, destination]
	# Trim links at the rectangular buttons, rather than letting arrows run
	# underneath labels. No gameplay rule is inferred from this geometry.
	var half := NODE_SIZE / 2 + Vector2(4, 4)
	var fraction := 1.0 / maxf(absf(delta.x) / half.x, absf(delta.y) / half.y)
	return [origin + delta * fraction, destination - delta * fraction]


func _draw_edge(a: String, b: String, color: Color, width: float, directed: bool, dashed: bool = false) -> void:
	if not _nodes.has(a) or not _nodes.has(b) or a == b:
		return
	var ends := _edge_endpoints(a, b)
	var origin: Vector2 = ends[0]
	var destination: Vector2 = ends[1]
	if dashed:
		draw_dashed_line(origin, destination, color, width, 5, true, true)
	else:
		draw_line(origin, destination, color, width, true)
	if directed:
		var direction := (destination - origin).normalized()
		var side := Vector2(-direction.y, direction.x)
		draw_colored_polygon(PackedVector2Array([destination, destination - direction * 9 + side * 4, destination - direction * 9 - side * 4]), color)


func _draw() -> void:
	if board_data.is_empty():
		return
	var bounds := Rect2(Vector2.ZERO, size)
	draw_style_box(_style(INK, Color("38514f")), bounds)
	var font := get_theme_default_font()
	draw_string(font, Vector2(12, 23), str(board_data.get("title", "INVESTIGATION BOARD")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, GOLD)
	var directed: bool = board_data.get("directed", true)
	for edge in board_data.get("edges", []):
		_draw_edge(str(edge[0]), str(edge[1]), LINE, 2, directed)
	for i in range(selected_path.size() - 1):
		var a: String = _option_ids.get(selected_path[i], "")
		var b: String = _option_ids.get(selected_path[i + 1], "")
		var connected := _has_edge(a, b)
		_draw_edge(a, b, GOLD if connected else CORAL, 4, directed, not connected)
	# Loss numbers and equipment requirements remain visible over selected paths.
	for edge in board_data.get("edges", []):
		var key := str(edge[0]) + ">" + str(edge[1])
		var label := str(board_data.get("edge_labels", {}).get(key, ""))
		if label.is_empty():
			continue
		var midpoint := (_point(str(edge[0])) + _point(str(edge[1]))) / 2
		var extent := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
		var box := Rect2(midpoint - extent / 2 - Vector2(4, 2), extent + Vector2(8, 4))
		draw_style_box(_style(INK, LINE), box)
		draw_string(font, midpoint + Vector2(-extent.x / 2, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PAPER)
	draw_string(font, Vector2(12, size.y - 30), str(board_data.get("legend", "Select nodes to add route steps. Existing options below remain available.")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 13, PAPER)
	draw_string(font, Vector2(12, size.y - 12), "Gold: chosen links · dashed coral: no charted link · Undo/Clear below", HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 12, LINE)
