class_name MysteryState
extends RefCounted
## Data-driven case progress. Invalid actions and failed loads never mutate it.

const SAVE_VERSION := 4
const DetectiveRules = preload("res://scripts/detective_rules.gd")
const SearchDefinition = preload("res://scripts/hidden_object_state.gd")
const GAME_ID := "the-quiet-meridian"
const DEFAULT_SETTINGS := {
	"music": 0.65, "sound": 0.8, "large_text": false,
	"reduced_motion": false, "hotspot_labels": false, "fullscreen": true,
	"voice": 0.9, "ambience": 0.5, "subtitles": true, "auto_voice": true
}
const LEGACY_SETTINGS := ["music", "sound", "large_text", "reduced_motion", "hotspot_labels", "fullscreen"]
const PUZZLE_TYPES := ["code", "choice", "deduction", "order", "sequence", "routing", "hidden", "assembly"]

var detective = DetectiveRules.new()
var data: Dictionary = {}
var location_id: String = ""
var solved: Array = []
var evidence: Array = []
var inventory: Array = []
var searches: Dictionary = {}
var search_progress: Dictionary = {}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var elapsed_seconds: float = 0.0
var last_error: String = ""
var _locations: Dictionary = {}
var _puzzles: Dictionary = {}
var _items: Dictionary = {}
var _hotspots: Dictionary = {}
var _hotspot_locations: Dictionary = {}


func load_content(path: String = "res://content/game.json") -> bool:
	if not FileAccess.file_exists(path):
		return _error("The case file is missing: " + path)
	var parsed: Variant = _parse_json(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return _error("The case file is not valid JSON.")
	var validation := _validate_content(parsed)
	if not validation.is_empty():
		return _error(validation)
	var pending_searches := {}
	if parsed.has("search_catalog"):
		if not parsed.search_catalog is String or not parsed.search_catalog.begins_with("res://content/"):
			return _error("The search catalogue path is invalid.")
		var catalogue: Variant = _parse_json(FileAccess.get_file_as_string(parsed.search_catalog))
		if not catalogue is Dictionary or catalogue.is_empty(): return _error("The search catalogue is missing or damaged.")
		if catalogue.size() != parsed.locations.size(): return _error("Every room needs a hidden-object search.")
		for location in catalogue:
			var known := false
			for room in parsed.locations:
				if room.id == location: known = true
			var definition := SearchDefinition.new()
			if not known or not catalogue[location] is Dictionary or catalogue[location].get("location") != location or not definition.configure(catalogue[location]):
				return _error("The search for " + str(location) + " is invalid.")
			pending_searches[location] = catalogue[location].duplicate(true)
	data = parsed
	searches = pending_searches
	_reindex()
	new_game()
	return true


func new_game() -> void:
	solved = []
	evidence = []
	inventory = []
	search_progress = {}
	detective.reset()
	elapsed_seconds = 0.0
	location_id = str(data.get("locations", [{}])[0].get("id", "")) if not data.get("locations", []).is_empty() else ""
	last_error = ""


func get_location(id: String) -> Dictionary:
	return _locations.get(id, {})


func get_puzzle(id: String) -> Dictionary:
	return _puzzles.get(id, {})


func get_item(id: String) -> Dictionary:
	return _items.get(id, {})


func get_hotspot(id: String) -> Dictionary:
	return _hotspots.get(id, {})


func chapter_unlocked(id: String) -> bool:
	return _chapter_unlocked_for(id, solved)


func can_solve(id: String) -> bool:
	var puzzle := get_puzzle(id)
	return not puzzle.is_empty() and id not in solved and chapter_unlocked(puzzle.chapter) and _contains_all(solved, puzzle.requires) and _contains_all(evidence, puzzle.clues) and _contains_all(inventory, puzzle.items) and _search_requirements_met(puzzle, search_progress)


func visit(id: String) -> bool:
	var location := get_location(id)
	if location.is_empty() or not chapter_unlocked(location.chapter):
		return _error("That part of the city is not available yet.")
	location_id = id
	last_error = ""
	return true


func examine(id: String) -> Dictionary:
	var hotspot := get_hotspot(id)
	if hotspot.is_empty() or _hotspot_locations.get(id, "") != location_id:
		return _failure("Travel to that location before examining its evidence.")
	if not chapter_unlocked(get_location(location_id).chapter):
		return _failure("That part of the city is not available yet.")
	if searches.has(location_id) and not search_complete(location_id):
		return _failure("Finish this room’s hidden-object search to recover its evidence.")
	if id not in evidence:
		evidence.append(id)
	var item: String = hotspot.get("item", "")
	if not item.is_empty() and item not in inventory:
		inventory.append(item)
	last_error = ""
	return {"ok": true, "text": hotspot.text, "item": item, "clue": id}


func try_solve(id: String, answer: Variant) -> Dictionary:
	var puzzle := get_puzzle(id)
	if puzzle.is_empty():
		return _failure("That investigation could not be found.")
	if id in solved:
		return _failure("This investigation is already resolved.")
	if puzzle.location != location_id:
		return _failure("Return to " + str(get_location(puzzle.location).get("title", "the investigation")) + " to work on this.")
	if not chapter_unlocked(puzzle.chapter) or not _contains_all(solved, puzzle.requires):
		return _failure("Resolve the related investigations first. The casebook lists the connections.")
	if not _search_requirements_met(puzzle, search_progress):
		return _failure("Complete the room searches needed for this investigation. The map shows any unfinished rooms.")
	if not _contains_all(evidence, puzzle.clues):
		return _failure("Some evidence is still missing. Inspect the clues listed in the casebook.")
	if not _contains_all(inventory, puzzle.items):
		return _failure("You still need an item for this. Inspect your inventory and try combining related objects.")
	if not _valid_submission(puzzle, answer):
		return _failure("Complete a valid answer before submitting it.")
	if puzzle.type != "hidden" and float(detective.puzzle_snapshot(id).submit_cooldown) > 0:
		return _failure("Review the evidence. You can submit again in %d seconds." % ceili(float(detective.puzzle_snapshot(id).submit_cooldown)))
	if not _answer_matches(puzzle, answer):
		if puzzle.type == "hidden": return _failure("That does not fit the evidence.")
		var signature := _normalize_code(str(answer)) if puzzle.type == "code" else JSON.stringify(answer)
		var rejected: Dictionary = detective.wrong_answer(id, signature)
		last_error = str(rejected.text)
		return rejected
	solved.append(id)
	for item in puzzle.rewards:
		if item not in inventory:
			inventory.append(item)
	_resolve_completed_search_tasks()
	last_error = ""
	var insight_awarded: int = detective.reward_puzzle(id) if puzzle.type != "hidden" else 0
	return {"ok": true, "text": puzzle.success, "puzzle": id, "insight_awarded":insight_awarded}


func combine(a: String, b: String) -> Dictionary:
	if a not in inventory or b not in inventory:
		return _failure("Both objects must be in your inventory.")
	for recipe in data.get("recipes", []):
		var ingredients: Array = recipe.ingredients
		if (ingredients[0] == a and ingredients[1] == b) or (ingredients[0] == b and ingredients[1] == a):
			if recipe.result in inventory:
				return _failure("You have already made " + str(get_item(recipe.result).get("name", "that object")) + ".")
			inventory.append(recipe.result)
			last_error = ""
			return {"ok": true, "text": recipe.text, "item": recipe.result}
	return _failure("Those objects do not fit together. Both remain in your inventory.")


func save_game(path: String = "user://autosave.json") -> bool:
	var record := _record()
	var validation := _validate_save(record)
	if not validation.is_empty():
		return _error("Progress could not be saved: " + validation)
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _error("Could not write the save file. Check the folder is writable.")
	file.store_string(JSON.stringify(record, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		return _error("The save could not be written completely. Your previous save is unchanged.")
	# Preserve the previous complete save before replacing it. Never rotate an
	# invalid primary over a valid recovery copy.
	if FileAccess.file_exists(path):
		var previous: Variant = _parse_json(FileAccess.get_file_as_string(path))
		if previous is Dictionary and _validate_save(previous).is_empty():
			if DirAccess.copy_absolute(path, path + ".bak") != OK:
				DirAccess.remove_absolute(temporary)
				return _error("Could not preserve the previous save. No progress file was replaced.")
	if DirAccess.rename_absolute(temporary, path) != OK:
		DirAccess.remove_absolute(temporary)
		return _error("Could not replace the save file. The previous save and backup are preserved.")
	last_error = ""
	return true


func load_game(path: String = "user://autosave.json") -> bool:
	if not FileAccess.file_exists(path):
		return _error("No save was found here.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 4000000:
		return _error("The save cannot be read or is unexpectedly large.")
	var parsed: Variant = _parse_json(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return _error("This save is damaged and could not be opened. No saved files have been changed.")
	var validation := _validate_save(parsed)
	if not validation.is_empty():
		return _error("This save could not be loaded: " + validation)
	# All validation occurs before the live case is changed.
	location_id = parsed.location
	solved = parsed.solved.duplicate()
	evidence = parsed.evidence.duplicate()
	inventory = parsed.inventory.duplicate()
	search_progress = parsed.get("search_progress", {}).duplicate(true) if int(parsed.version) >= 3 else {}
	if int(parsed.version) < 3:
		# Preserve old evidence and solved work. Previously examined rooms are
		# grandfathered complete; finish recording their already-accessible clues.
		for location in searches:
			var previously_seen := false
			for chapter in data.chapters:
				if chapter.id == get_location(location).chapter and chapter.final_puzzle in solved: previously_seen = true
			for spot in get_location(location).hotspots:
				if spot.id in evidence: previously_seen = true
			for puzzle_id in solved:
				if get_puzzle(puzzle_id).location == location: previously_seen = true
			if previously_seen:
				search_progress[location] = []
				for item in searches[location].items: search_progress[location].append(item.id)
				_award_search_evidence(location)
		_resolve_completed_search_tasks()
	if int(parsed.version) < SAVE_VERSION:
		# Existing work is claimed with zero payout. Untimed partial searches receive
		# a full first Detective attempt without losing any already-found objects.
		detective.migrate(searches, search_progress, _puzzles, solved)
	else:
		detective.restore(parsed.detective)
	# Version 1 predates the audiovisual mix controls. Validate its original
	# fields first, then add only new preference defaults without touching progress.
	settings = DEFAULT_SETTINGS.duplicate(true)
	for key in parsed.settings:
		settings[key] = parsed.settings[key]
	elapsed_seconds = float(parsed.elapsed_seconds)
	last_error = ""
	return true


func load_backup(path: String = "user://autosave.json") -> bool:
	return load_game(path + ".bak")


func _record() -> Dictionary:
	return {"version": SAVE_VERSION, "game": GAME_ID, "location": location_id,
		"solved": solved.duplicate(), "evidence": evidence.duplicate(),
		"inventory": inventory.duplicate(), "settings": settings.duplicate(true),
		"search_progress": search_progress.duplicate(true),
		"detective": detective.record(), "elapsed_seconds": elapsed_seconds}


func _validate_save(record: Dictionary) -> String:
	var version: Variant = record.get("version")
	if not (version is int or version is float) or float(version) not in [1.0, 2.0, 3.0, float(SAVE_VERSION)] or record.get("game") != GAME_ID:
		return "This save belongs to another game or an unsupported save version."
	if not record.get("location") is String or not _locations.has(record.location):
		return "The saved location is unknown."
	for pair in [["solved", _puzzles], ["evidence", _hotspots], ["inventory", _items]]:
		var values: Variant = record.get(pair[0])
		if not values is Array:
			return "The " + pair[0] + " list is damaged."
		var seen := {}
		for id in values:
			if not id is String or not pair[1].has(id) or seen.has(id):
				return "The " + pair[0] + " list contains an unknown or duplicate entry."
			seen[id] = true
	if not _chapter_unlocked_for(get_location(record.location).chapter, record.solved):
		return "The saved location is not reachable from this progress."
	if int(version) >= 3:
		var saved_searches: Variant = record.get("search_progress")
		if not saved_searches is Dictionary: return "The saved searches are missing."
		for location in saved_searches:
			if not location is String or not searches.has(location) or not saved_searches[location] is Array:
				return "The save contains an unknown search."
			if not _chapter_unlocked_for(get_location(location).chapter, record.solved): return "A saved search belongs to a locked chapter."
			var seen_targets := {}
			for id in saved_searches[location]:
				if not id is String or not _search_item_exists(location, id) or seen_targets.has(id): return "A saved search contains an unknown or repeated object."
				seen_targets[id] = true
			if _search_complete_in(location, saved_searches):
				for spot in get_location(location).hotspots:
					if spot.id not in record.evidence: return "A completed search is missing its evidence."
		for clue in record.evidence:
			var location: String = _hotspot_locations[clue]
			if searches.has(location) and not _search_complete_in(location, saved_searches): return "Evidence was awarded before its search was completed."
	for clue in record.evidence:
		if not _chapter_unlocked_for(get_location(_hotspot_locations[clue]).chapter, record.solved):
			return "The save contains evidence from a locked chapter."
	for id in record.solved:
		var puzzle := get_puzzle(id)
		if int(version) >= 3 and not _search_requirements_met(puzzle, record.search_progress): return "An investigation is missing a required completed search."
		if not _chapter_unlocked_for(puzzle.chapter, record.solved) or not _contains_all(record.solved, puzzle.requires) or not _contains_all(record.evidence, puzzle.clues) or not _contains_all(record.inventory, puzzle.items) or not _contains_all(record.inventory, puzzle.rewards):
			return "A completed investigation is missing its prerequisites or rewards."
	# Every inventory object needs an actual source, including complete recipe
	# ingredient provenance. Iterate to support multi-step combinations.
	var obtainable: Array = []
	for clue in record.evidence:
		var item: String = get_hotspot(clue).get("item", "")
		if not item.is_empty() and item not in obtainable:
			obtainable.append(item)
	for id in record.solved:
		for item in get_puzzle(id).rewards:
			if item not in obtainable:
				obtainable.append(item)
	for _pass in range(_items.size() + 1):
		var changed := false
		for recipe in data.get("recipes", []):
			if recipe.result not in obtainable and _contains_all(obtainable, recipe.ingredients) and _contains_all(record.inventory, recipe.ingredients):
				obtainable.append(recipe.result)
				changed = true
		if not changed:
			break
	if not _contains_all(obtainable, record.inventory):
		return "An inventory object has no discoverable source in this save."
	# Collection history keeps provenance even when incorporated or retired items leave the visible inventory.
	for clue in record.evidence:
		var item: String = get_hotspot(clue).get("item", "")
		if not item.is_empty() and item not in record.inventory:
			return "An examined collectible is missing from the inventory."
	var saved_settings: Variant = record.get("settings")
	if not saved_settings is Dictionary:
		return "Settings are missing."
	var required_settings: Array = LEGACY_SETTINGS if version == 1 else DEFAULT_SETTINGS.keys()
	for key in saved_settings:
		if key not in required_settings:
			return "An unknown setting is present for this save version."
	for key in required_settings:
		if not saved_settings.has(key):
			return "A setting is missing."
		if DEFAULT_SETTINGS[key] is bool:
			if not saved_settings[key] is bool:
				return "A display setting is invalid."
		elif not (saved_settings[key] is float or saved_settings[key] is int) or not is_finite(float(saved_settings[key])) or float(saved_settings[key]) < 0.0 or float(saved_settings[key]) > 1.0:
			return "An audio setting is invalid."
	var seconds: Variant = record.get("elapsed_seconds")
	if not (seconds is int or seconds is float) or not is_finite(float(seconds)) or float(seconds) < 0.0:
		return "The saved play duration is invalid."
	if int(version) == SAVE_VERSION:
		var detective_error := DetectiveRules.validate(record.get("detective"), searches, record.search_progress, _puzzles, record.solved)
		if not detective_error.is_empty(): return detective_error
		for location in record.detective.searches:
			if not _chapter_unlocked_for(get_location(location).chapter, record.solved): return "A Detective attempt belongs to a locked chapter."
		for id in record.detective.puzzles:
			var puzzle := get_puzzle(id)
			if not _chapter_unlocked_for(puzzle.chapter, record.solved) or not _contains_all(record.solved,puzzle.requires) or not _contains_all(record.evidence,puzzle.clues) or not _contains_all(record.inventory,puzzle.items) or not _search_requirements_met(puzzle,record.search_progress): return "An investigation attempt is missing its prerequisites."

	return ""


func _valid_submission(puzzle: Dictionary, answer: Variant) -> bool:
	if puzzle.type == "code": return answer is String and not _normalize_code(answer).is_empty() and answer.length() <= 1000
	if puzzle.type in ["choice", "deduction"]: return answer is String and answer in puzzle.options
	if puzzle.type in ["order", "sequence", "routing"]:
		if not answer is Array or answer.is_empty() or answer.size() > 100: return false
		if answer.size() != puzzle.solution.size(): return false
		var unique := {}
		for part in answer:
			if not part is String or part not in puzzle.options: return false
			if puzzle.type == "order" and unique.has(part): return false
			unique[part] = true
		return true
	return answer is String and answer == puzzle.solution


func _answer_matches(puzzle: Dictionary, answer: Variant) -> bool:
	var solution: Variant = puzzle.solution
	if puzzle.type == "code":
		return answer is String and _normalize_code(answer) == _normalize_code(str(solution))
	if solution is Array:
		if not answer is Array or answer.size() != solution.size():
			return false
		for i in range(solution.size()):
			if not answer[i] is String or answer[i] != solution[i]:
				return false
		return true
	return answer is String and answer == solution


func _normalize_code(value: String) -> String:
	return value.to_lower().replace(" ", "").replace("\t", "").replace("\n", "").replace("\r", "")


func _parse_json(value: String) -> Variant:
	# JSON.parse_string logs an engine error for damaged input. A player save
	# can be damaged legitimately, so handle that as a recoverable condition.
	var parser := JSON.new()
	return parser.data if parser.parse(value) == OK else null


func _contains_all(haystack: Array, needles: Array) -> bool:
	for value in needles:
		if value not in haystack:
			return false
	return true


func _chapter_unlocked_for(id: String, completed: Array) -> bool:
	var chapters: Array = data.get("chapters", [])
	for i in range(chapters.size()):
		if chapters[i].id == id:
			# Check every earlier gate, not just the nearest one.
			for j in range(i):
				if chapters[j].final_puzzle not in completed:
					return false
			return true
	return false


func _reindex() -> void:
	_locations.clear()
	_puzzles.clear()
	_items.clear()
	_hotspots.clear()
	_hotspot_locations.clear()
	for location in data.locations:
		_locations[location.id] = location
		for hotspot in location.hotspots:
			_hotspots[hotspot.id] = hotspot
			_hotspot_locations[hotspot.id] = location.id
	for puzzle in data.puzzles:
		_puzzles[puzzle.id] = puzzle
	for item in data.items:
		_items[item.id] = item


func _validate_content(content: Dictionary) -> String:
	for key in ["title", "subtitle", "intro", "ending"]:
		if not content.get(key) is String or content[key].is_empty():
			return "Case content is missing " + key + "."
	var indices := {}
	for key in ["chapters", "locations", "puzzles", "items", "characters", "recipes"]:
		if not content.get(key) is Array:
			return "Case content is missing the " + key + " collection."
		indices[key] = {}
		for row in content[key]:
			if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or indices[key].has(row.id):
				return "Duplicate or invalid ID in " + key + "."
			indices[key][row.id] = row
	if content.chapters.is_empty() or content.locations.is_empty() or content.puzzles.is_empty():
		return "The case has no chapters, locations or investigations."
	var hotspots := {}
	for location in content.locations:
		if not indices.chapters.has(location.get("chapter", "")) or not location.get("hotspots") is Array:
			return "Invalid chapter or hotspots in location " + location.id + "."
		for field in ["title", "description", "art"]:
			if not location.get(field) is String:
				return "Missing " + field + " in " + location.id + "."
		for hotspot in location.hotspots:
			if not hotspot is Dictionary or not hotspot.get("id") is String or hotspot.id.is_empty() or hotspots.has(hotspot.id):
				return "Invalid or duplicate hotspot in " + location.id + "."
			for field in ["label", "text"]:
				if not hotspot.get(field) is String:
					return "Missing hotspot " + field + "."
			for coordinate in ["x", "y"]:
				if not (hotspot.get(coordinate) is float or hotspot.get(coordinate) is int) or float(hotspot[coordinate]) < 0.0 or float(hotspot[coordinate]) > 1.0:
					return "Hotspot coordinates must be between zero and one."
			if hotspot.has("item") and not indices.items.has(hotspot.item):
				return "A hotspot rewards an unknown item."
			hotspots[hotspot.id] = hotspot
	for chapter in content.chapters:
		if not chapter.get("locations") is Array or chapter.locations.is_empty() or not indices.puzzles.has(chapter.get("final_puzzle", "")):
			return "Invalid chapter gate or locations."
		for field in ["title", "summary", "intro", "closing"]:
			if not chapter.get(field) is String:
				return "Missing chapter " + field + "."
		for id in chapter.locations:
			if not indices.locations.has(id) or indices.locations[id].chapter != chapter.id:
				return "A chapter references an unknown or mismatched location."
		var location_count := 0
		for location in content.locations:
			if location.chapter == chapter.id:
				location_count += 1
				if location.id not in chapter.locations:
					return "A chapter omits one of its locations."
		if location_count != chapter.locations.size():
			return "A chapter lists a location more than once."
		if indices.puzzles[chapter.final_puzzle].get("chapter", "") != chapter.id:
			return "A chapter finale belongs to another chapter."
	for item in content.items:
		if not item.get("name") is String or not item.get("description") is String:
			return "An item is missing its name or description."
	for puzzle in content.puzzles:
		if puzzle.get("type", "") not in PUZZLE_TYPES or not indices.locations.has(puzzle.get("location", "")) or indices.locations[puzzle.location].chapter != puzzle.get("chapter", ""):
			return "Invalid puzzle type or location for " + puzzle.id + "."
		for field in ["title", "prompt", "details", "success", "rationale"]:
			if not puzzle.get(field) is String:
				return "Missing puzzle " + field + " in " + puzzle.id + "."
		for pair in [["requires", indices.puzzles], ["clues", hotspots], ["items", indices.items], ["rewards", indices.items]]:
			if not puzzle.get(pair[0]) is Array:
				return "Missing " + pair[0] + " in " + puzzle.id + "."
			for id in puzzle[pair[0]]:
				if not id is String or not pair[1].has(id):
					return "Unknown " + pair[0] + " entry in " + puzzle.id + "."
		if not puzzle.get("hints") is Array or puzzle.hints.size() != 3:
			return "Every investigation needs three hints."
		for hint in puzzle.hints:
			if not hint is String or hint.is_empty():
				return "A puzzle hint is empty."
		if not puzzle.get("options") is Array:
			return "A puzzle option list is missing."
		for option in puzzle.options:
			if not option is String:
				return "Puzzle options must be text."
		if puzzle.type in ["order", "sequence", "routing"]:
			if not puzzle.get("solution") is Array or puzzle.solution.is_empty():
				return "An ordered puzzle needs a solution array."
			for part in puzzle.solution:
				if part not in puzzle.options:
					return "An ordered solution is absent from its options."
			if puzzle.type == "order" and (puzzle.solution.size() != puzzle.options.size() or not _contains_all(puzzle.solution, puzzle.options)):
				return "An ordering puzzle must use every option exactly once."
		elif not puzzle.get("solution") is String:
			return "A puzzle needs a text solution."
		elif puzzle.type in ["choice", "deduction"] and puzzle.solution not in puzzle.options:
			return "A deduction answer is absent from its options."
		elif puzzle.type == "hidden" and puzzle.solution != "found":
			return "A hidden-object solution must be found."
		elif puzzle.type == "assembly" and puzzle.solution != "assembled":
			return "An assembly solution must be assembled."
	for recipe in content.recipes:
		if not recipe.get("ingredients") is Array or recipe.ingredients.size() != 2 or not indices.items.has(recipe.get("result", "")) or not recipe.get("text") is String:
			return "A combination recipe is invalid."
		for item in recipe.ingredients:
			if not indices.items.has(item) or item == recipe.result:
				return "A recipe uses an unknown item or its own result."
	# Reachability includes chapter gates, physical evidence and item recipes,
	# not only explicit puzzle arrows. A key behind its own lock is invalid.
	var reachable: Array = []
	var available_clues: Array = []
	var available_items: Array = []
	for _pass in range(content.puzzles.size() + content.items.size() + 1):
		var changed := false
		var available_chapters: Array = []
		for chapter in content.chapters:
			available_chapters.append(chapter.id)
			if chapter.final_puzzle not in reachable:
				break
		for location in content.locations:
			if location.chapter not in available_chapters:
				continue
			for hotspot in location.hotspots:
				if hotspot.id not in available_clues:
					available_clues.append(hotspot.id)
					changed = true
				if hotspot.has("item") and hotspot.item not in available_items:
					available_items.append(hotspot.item)
					changed = true
		for recipe in content.recipes:
			if recipe.result not in available_items and _contains_all(available_items, recipe.ingredients):
				available_items.append(recipe.result)
				changed = true
		for puzzle in content.puzzles:
			if puzzle.id in reachable or puzzle.chapter not in available_chapters or not _contains_all(reachable, puzzle.requires) or not _contains_all(available_clues, puzzle.clues) or not _contains_all(available_items, puzzle.items):
				continue
			reachable.append(puzzle.id)
			for item in puzzle.rewards:
				if item not in available_items:
					available_items.append(item)
			changed = true
		if not changed:
			break
	if reachable.size() != content.puzzles.size():
		return "The investigation dependencies contain a cycle, an unreachable chapter, or an unobtainable clue or item."
	return ""


func search_complete(location: String) -> bool:
	return _search_complete_in(location, search_progress)


func _search_complete_in(location: String, progress: Dictionary) -> bool:
	return searches.has(location) and progress.get(location, []).size() == searches[location].items.size()


func _search_item_exists(location: String, id: String) -> bool:
	if not searches.has(location): return false
	for item in searches[location].items:
		if item.id == id: return true
	return false


func find_search_object(location: String, id: String) -> Dictionary:
	if location != location_id or not chapter_unlocked(get_location(location_id).chapter) or not _search_item_exists(location, id):
		return _failure("That object is not available in the current search.")
	if id in search_progress.get(location, []): return _failure("You have already found that object.")
	if float(detective.search_snapshot(location,_search_duration(location)).remaining) <= 0:
		return _failure("Time is up. Add an available time extension or restart this search.")
	detective.ensure_search(location,_search_duration(location))
	if not search_progress.has(location): search_progress[location] = []
	search_progress[location].append(id)
	var reward := {"clues":[], "items":[]}
	var insight_awarded := 0
	if search_complete(location):
		reward = _award_search_evidence(location)
		_resolve_completed_search_tasks()
		insight_awarded = detective.reward_search(location,_search_duration(location))
	last_error = ""
	return {"ok":true, "complete":search_complete(location), "clues":reward.clues, "items":reward.items, "insight_awarded":insight_awarded}


func _award_search_evidence(location: String) -> Dictionary:
	var reward := {"clues":[], "items":[]}
	for spot in get_location(location).hotspots:
		if spot.id not in evidence:
			evidence.append(spot.id)
			reward.clues.append(spot.id)
		var item: String = spot.get("item", "")
		if not item.is_empty() and item not in inventory:
			inventory.append(item)
			reward.items.append(item)
	return reward


func _search_requirements_met(puzzle: Dictionary, progress: Dictionary) -> bool:
	if searches.has(puzzle.location) and not _search_complete_in(puzzle.location, progress): return false
	for chapter in data.get("chapters", []):
		if chapter.final_puzzle == puzzle.id:
			for location in chapter.locations:
				if searches.has(location) and not _search_complete_in(location, progress): return false
	return true


func _resolve_completed_search_tasks() -> void:
	# Old 'hidden' tasks were confirmation buttons for three clue hotspots.
	# Actual picture searches now satisfy them; no extra confirmation is needed.
	for _pass in range(data.get("puzzles", []).size()):
		var changed := false
		for puzzle in data.get("puzzles", []):
			if puzzle.type == "hidden" and searches.has(puzzle.location) and can_solve(puzzle.id):
				solved.append(puzzle.id)
				for item in puzzle.rewards:
					if item not in inventory: inventory.append(item)
				changed = true
		if not changed: break


func insight_balance() -> int:
	return detective.insight

func _search_duration(location: String) -> float:
	return DetectiveRules.duration_for(searches[location].items.size())

func _current_search_available(location: String) -> bool:
	return location == location_id and searches.has(location) and chapter_unlocked(get_location(location).chapter) and not search_complete(location)

func search_status(location: String = "") -> Dictionary:
	if location.is_empty(): location = location_id
	if not searches.has(location): return {}
	var result: Dictionary = detective.search_snapshot(location,_search_duration(location))
	result.duration = _search_duration(location)
	result.complete = search_complete(location)
	result.expired = not result.complete and float(result.remaining) <= 0
	result.hint_cost = 0 if int(result.hints_used) == 0 else 1
	result.hints_left = 3 - int(result.hints_used)
	result.extensions_left = 2 - int(result.extensions)
	result.can_hint = _current_search_available(location) and not result.expired and result.hints_left > 0 and float(result.hint_cooldown) <= 0 and detective.insight >= int(result.hint_cost)
	result.can_extend = _current_search_available(location) and result.extensions_left > 0 and detective.insight >= 1
	return result

## Call only while the current search picture is visible and the application is active.
## State never consults wall time, so menus, focus loss and reload cannot consume time.
func advance_search(delta: float, location: String = "") -> bool:
	if location.is_empty(): location = location_id
	if not _current_search_available(location): return false
	return detective.advance_search(location,_search_duration(location),delta)

func register_search_miss(location: String = "") -> Dictionary:
	if location.is_empty(): location = location_id
	if not _current_search_available(location): return _failure("This search is not available.")
	if float(search_status(location).remaining) <= 0: return _failure("Time is up. Add time or restart this search.")
	return detective.search_miss(location,_search_duration(location))

func request_search_hint(location: String = "") -> Dictionary:
	if location.is_empty(): location = location_id
	if not _current_search_available(location): return _failure("This search is not available.")
	if float(search_status(location).remaining) <= 0: return _failure("Time is up. Add time or restart this search.")
	var result: Dictionary = detective.use_search_hint(location,_search_duration(location))
	if not result.ok: return _failure(str(result.text))
	for item in searches[location].items:
		if item.id not in search_progress.get(location,[]):
			result.id = item.id
			result.text = "Look for the " + str(item.name).to_lower() + "."
			last_error = ""
			return result
	return _failure("There are no remaining objects.")

func buy_search_time(location: String = "") -> Dictionary:
	if location.is_empty(): location = location_id
	if not _current_search_available(location): return _failure("This search is not available.")
	var result: Dictionary = detective.extend_search(location,_search_duration(location))
	last_error = "" if result.ok else str(result.text)
	return result

func retry_search(location: String = "") -> Dictionary:
	if location.is_empty(): location = location_id
	if not _current_search_available(location): return _failure("Only an unfinished current search can be restarted.")
	if not search_status(location).expired: return _failure("Only an expired search can be restarted.")
	var result: Dictionary = detective.restart_search(location,_search_duration(location))
	search_progress.erase(location)
	last_error = ""
	return result

func _puzzle_attempt_available(id: String) -> bool:
	var puzzle := get_puzzle(id)
	return not puzzle.is_empty() and puzzle.type != "hidden" and puzzle.location == location_id and can_solve(id)

func puzzle_status(id: String) -> Dictionary:
	if get_puzzle(id).is_empty(): return {}
	var result: Dictionary = detective.puzzle_snapshot(id)
	result.complete = id in solved
	result.hint_cost = 0 if int(result.hints_used) == 0 else 1
	result.hints_left = 3 - int(result.hints_used)
	result.can_hint = _puzzle_attempt_available(id) and result.hints_left > 0 and float(result.hint_cooldown) <= 0 and detective.insight >= int(result.hint_cost)
	result.can_submit = _puzzle_attempt_available(id) and float(result.submit_cooldown) <= 0
	return result

func advance_puzzle(id: String, delta: float) -> void:
	if _puzzle_attempt_available(id): detective.advance_puzzle(id,delta)

func request_puzzle_hint(id: String) -> Dictionary:
	if not _puzzle_attempt_available(id): return _failure("Gather the required evidence and return to this investigation first.")
	var result: Dictionary = detective.use_puzzle_hint(id)
	if not result.ok: return _failure(str(result.text))
	result.text = str(get_puzzle(id).hints[int(result.level)-1])
	last_error = ""
	return result

func active_inventory() -> Array:
	var visible: Array = []
	for id in inventory:
		var incorporated := false
		for recipe in data.get("recipes",[]):
			if id in recipe.ingredients and recipe.result in inventory: incorporated = true
		if incorporated: continue
		var needed := false
		for puzzle in data.get("puzzles",[]):
			if puzzle.id not in solved and id in puzzle.items: needed = true
		for recipe in data.get("recipes",[]):
			if recipe.result not in inventory and id in recipe.ingredients: needed = true
		if needed: visible.append(id)
	return visible

func archived_inventory() -> Array:
	var active := active_inventory()
	var history: Array = []
	for id in inventory:
		if id not in active: history.append(id)
	return history


func _error(message: String) -> bool:
	last_error = message
	return false


func _failure(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "text": message}
