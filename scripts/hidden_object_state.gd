class_name HiddenObjectState
extends RefCounted
## Reusable search state. Saves are isolated from the adventure's existing slots.
var definition: Dictionary = {}
var found: Array[String] = []
var last_error := ""

func configure(value: Dictionary) -> bool:
	if not value.get("id") is String or not value.get("items") is Array or value.items.is_empty():
		return _error("The search definition is incomplete.")
	var ids := {}
	for item in value.items:
		if not item is Dictionary or not item.get("id") is String or not item.get("name") is String or ids.has(item.id):
			return _error("Search objects need unique names and identifiers.")
		var alternatives: Variant = item.get("alternatives", [])
		if not alternatives is Array: return _error("Alternative matches must be a list of shapes.")
		var regions: Array = [item.get("polygon")]
		regions.append_array(alternatives)
		for points in regions:
			if not points is Array or points.size() < 3: return _error("An object has no usable shape.")
			for point in points:
				if not point is Array or point.size() != 2: return _error("An object shape is invalid.")
				for number in point:
					if not (number is float or number is int) or not is_finite(float(number)) or float(number) < 0 or float(number) > 1:
						return _error("An object shape leaves the picture.")
		ids[item.id] = true
	definition = value.duplicate(true)
	found.clear()
	last_error = ""
	return true

func find_object(id: String) -> bool:
	if id in found or object_by_id(id).is_empty(): return false
	found.append(id)
	return true

func object_by_id(id: String) -> Dictionary:
	for item in definition.get("items", []):
		if item.id == id: return item
	return {}

func hit_at(point: Vector2) -> String:
	for item in definition.get("items", []):
		var regions: Array = [item.polygon]
		regions.append_array(item.get("alternatives", []))
		for region in regions:
			var polygon := PackedVector2Array()
			for vertex in region: polygon.append(Vector2(vertex[0], vertex[1]))
			if Geometry2D.is_point_in_polygon(point, polygon): return str(item.id)
	return ""

func complete() -> bool:
	return not definition.is_empty() and found.size() == definition.items.size()

func save_progress(path: String) -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return _error("Search progress could not be saved.")
	file.store_string(JSON.stringify({"version": 1, "scene": definition.id, "found": found}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return _error("Search progress could not be written completely.")
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: return _error("Search progress could not be replaced.")
	last_error = ""
	return true

func load_progress(path: String) -> bool:
	if not FileAccess.file_exists(path): return _error("No search progress was found.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 65536: return _error("Search progress cannot be read.")
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return _error("Search progress is damaged.")
	var record: Variant = parser.data
	if not record is Dictionary or record.get("version") != 1 or record.get("scene") != definition.id or not record.get("found") is Array:
		return _error("Search progress belongs to a different scene or version.")
	var pending: Array[String] = []
	for id in record.found:
		if not id is String or object_by_id(id).is_empty() or id in pending: return _error("Search progress contains invalid objects.")
		pending.append(id)
	found = pending
	last_error = ""
	return true

func _error(message: String) -> bool:
	last_error = message
	return false
