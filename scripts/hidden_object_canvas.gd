class_name HiddenObjectCanvas
extends Control
signal object_selected(id: String)
signal empty_selected
const CLICK_TOLERANCE_PIXELS := 7.0
var search: HiddenObjectState
var painting: Texture2D
var zoom := 1.0
var centre := Vector2(0.5, 0.5)
var hinted := ""
var hint_remaining := 0.0
var flash_position := Vector2.ZERO
var flash_remaining := 0.0
var keyboard_point := Vector2(0.5, 0.5)
var keyboard_active := false
var dragging := false

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	clip_contents = true
	accessibility_name = "Hidden object picture. Arrow keys move the search cursor; Enter finds an object. Plus and minus zoom."

func picture_rect() -> Rect2:
	if painting == null: return Rect2()
	var image_size := painting.get_size()
	var ratio := minf(size.x / image_size.x, size.y / image_size.y)
	var fitted := image_size * ratio
	return Rect2((size - fitted) / 2.0, fitted)

func view_rect() -> Rect2:
	return Rect2(centre - Vector2.ONE / (2.0 * zoom), Vector2.ONE / zoom)

func to_image(point: Vector2) -> Vector2:
	var rect := picture_rect()
	return view_rect().position + (point - rect.position) / rect.size / zoom

func to_screen(point: Vector2) -> Vector2:
	var rect := picture_rect()
	return rect.position + (point - view_rect().position) * zoom * rect.size

func set_zoom(value: float, anchor: Vector2 = Vector2(-1, -1)) -> void:
	var rect := picture_rect()
	if rect.size.x <= 0: return
	if anchor.x < 0: anchor = rect.get_center()
	var before := to_image(anchor)
	zoom = clampf(value, 1.0, 2.5)
	centre = before - ((anchor - rect.position) / rect.size - Vector2(0.5, 0.5)) / zoom
	_clamp_centre()
	queue_redraw()

func _clamp_centre() -> void:
	var edge := 0.5 / zoom
	centre = centre.clamp(Vector2.ONE * edge, Vector2.ONE * (1.0 - edge))

func select_point(point: Vector2) -> void:
	if not picture_rect().has_point(point) or search == null: return
	var normalized := to_image(point)
	# Forgive near-misses of a few screen pixels, independent of zoom and window size.
	var tolerance := Vector2(CLICK_TOLERANCE_PIXELS, CLICK_TOLERANCE_PIXELS) / (picture_rect().size * zoom)
	var id := search.hit_at(normalized, tolerance)
	if id.is_empty():
		empty_selected.emit()
		return
	if id not in search.found:
		flash_position = normalized
		flash_remaining = 0.55
	object_selected.emit(id)
	queue_redraw()

func reveal(id: String) -> void:
	hinted = id
	hint_remaining = 4.0
	var item := search.object_by_id(id)
	if not item.is_empty():
		var middle := Vector2.ZERO
		for vertex in item.polygon: middle += Vector2(vertex[0], vertex[1])
		centre = middle / item.polygon.size()
		_clamp_centre()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			grab_focus()
			keyboard_active = false
			select_point(event.position)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			set_zoom(zoom * (1.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2), event.position)
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		centre -= event.relative / picture_rect().size / zoom
		_clamp_centre()
		queue_redraw()
		accept_event()
	elif event is InputEventKey and event.pressed:
		# Holding a search key is one deliberate selection, not rapid guessing.
		if event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]: return
		var direction := Vector2.ZERO
		match event.keycode:
			KEY_LEFT: direction.x = -1
			KEY_RIGHT: direction.x = 1
			KEY_UP: direction.y = -1
			KEY_DOWN: direction.y = 1
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				keyboard_active = true
				select_point(to_screen(keyboard_point))
			KEY_PLUS, KEY_EQUAL: set_zoom(zoom * 1.2)
			KEY_MINUS: set_zoom(zoom / 1.2)
			_: return
		if direction != Vector2.ZERO:
			keyboard_active = true
			keyboard_point = (keyboard_point + direction * (0.03 if event.shift_pressed else 0.008) / zoom).clamp(Vector2.ZERO, Vector2.ONE)
			if not view_rect().has_point(keyboard_point):
				centre = keyboard_point
				_clamp_centre()
		queue_redraw()
		accept_event()

func _process(delta: float) -> void:
	if hint_remaining > 0 or flash_remaining > 0:
		hint_remaining = maxf(0, hint_remaining - delta)
		flash_remaining = maxf(0, flash_remaining - delta)
		queue_redraw()

func _draw() -> void:
	if painting == null: return
	var rect := picture_rect()
	var view := view_rect()
	draw_texture_rect_region(painting, rect, Rect2(view.position * painting.get_size(), view.size * painting.get_size()))
	if hint_remaining > 0 and not hinted.is_empty():
		var polygon := PackedVector2Array()
		for vertex in search.object_by_id(hinted).polygon: polygon.append(to_screen(Vector2(vertex[0], vertex[1])))
		polygon.append(polygon[0])
		draw_polyline(polygon, Color(1, 0.84, 0.44, 0.7 + 0.25 * sin(hint_remaining * 6)), 3, true)
	if flash_remaining > 0:
		draw_arc(to_screen(flash_position), 15 + (0.55 - flash_remaining) * 45, 0, TAU, 48, Color(1, 0.87, 0.58, flash_remaining / 0.55), 2, true)
	if keyboard_active and has_focus():
		var point := to_screen(keyboard_point)
		draw_line(point - Vector2(10, 0), point + Vector2(10, 0), Color.WHITE, 2, true)
		draw_line(point - Vector2(0, 10), point + Vector2(0, 10), Color.WHITE, 2, true)
