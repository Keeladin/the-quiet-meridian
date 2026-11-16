extends SceneTree
## Headless progression, item, and persistence regression tests.
## Run: godot --headless --path . --script tests/test_state.gd

const State = preload("res://scripts/game_state.gd")
const TEST_DIR := "user://state-tests"
var checks := 0
var failures := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_test_fixture()
	_test_av_save_migration()
	_test_content()
	if failures == 0:
		print("STATE_TESTS_OK: ", checks, " assertions; progression, wrong actions, recipes, transactional saves, backup recovery, two full content traversals")
		quit(0)
	else:
		printerr("STATE_TESTS_FAILED: ", failures, " of ", checks, " assertions")
		quit(1)


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _snapshot(state: RefCounted) -> Dictionary:
	return {"location": state.location_id, "solved": state.solved.duplicate(), "evidence": state.evidence.duplicate(), "inventory": state.inventory.duplicate(), "settings": state.settings.duplicate(true), "elapsed": state.elapsed_seconds, "search_progress": state.search_progress.duplicate(true)}


func _write(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "test file opens: " + path)
	if file != null:
		file.store_string(value if value is String else JSON.stringify(value))
		file.close()


func _fixture() -> Dictionary:
	var chapters := [
		{"id": "ch1", "title": "First", "summary": "First case", "intro": "Begin", "closing": "Continue", "locations": ["room", "store"], "final_puzzle": "assembly"},
		{"id": "ch2", "title": "Second", "summary": "Last case", "intro": "Continue", "closing": "End", "locations": ["vault"], "final_puzzle": "deduction"}
	]
	var locations := [
		{"id": "room", "chapter": "ch1", "title": "Room", "description": "A desk", "art": "res://assets/art/setup-key.png", "hotspots": [{"id": "card", "label": "Card", "x": 0.25, "y": 0.5, "text": "The card says A B then A. A route enters A before B. The code is NIGHT FALL.", "item": "paper"}]},
		{"id": "store", "chapter": "ch1", "title": "Store", "description": "A shelf", "art": "res://assets/art/setup-key.png", "hotspots": [{"id": "paste", "label": "Paste", "x": 0.5, "y": 0.5, "text": "Paste binds the paper.", "item": "glue"}]},
		{"id": "vault", "chapter": "ch2", "title": "Vault", "description": "The answer", "art": "res://assets/art/setup-key.png", "hotspots": [{"id": "testimony", "label": "Testimony", "x": 0.5, "y": 0.5, "text": "A is true."}]}
	]
	var items := [{"id": "paper", "name": "Paper", "description": "Combine with glue."}, {"id": "glue", "name": "Glue", "description": "Combine with paper."}, {"id": "bound", "name": "Bound card", "description": "Complete."}, {"id": "token", "name": "Token", "description": "Hidden reward."}]
	var puzzles: Array = []
	var definitions := [
		["hidden", "found", []], ["code", "Night Fall", []],
		["choice", "A", ["A", "B"]], ["order", ["A", "B"], ["B", "A"]],
		["sequence", ["A", "B", "A"], ["A", "B"]],
		["routing", ["A", "B"], ["A", "B", "C"]],
		["assembly", "assembled", []], ["deduction", "A", ["A", "B"]]
	]
	for i in range(definitions.size()):
		var definition: Array = definitions[i]
		var id: String = definition[0]
		var previous: Array = [] if i == 0 else [definitions[i - 1][0]]
		puzzles.append({"id": id, "chapter": "ch2" if id == "deduction" else "ch1", "location": "vault" if id == "deduction" else "room", "title": id.capitalize(), "type": id, "requires": previous, "clues": ["testimony"] if id == "deduction" else ["card"], "items": ["bound"] if id == "assembly" else [], "prompt": "Solve " + id, "details": "Read the card.", "options": definition[2], "solution": definition[1], "rewards": ["token"] if id == "hidden" else [], "success": "Solved.", "hints": ["Read.", "Consider the card.", "Use its answer."], "rationale": "The card supplies the answer."})
	return {"title": "Fixture", "subtitle": "Tests", "intro": "Begin", "ending": "End", "chapters": chapters, "locations": locations, "puzzles": puzzles, "items": items, "characters": [], "recipes": [{"id": "bind", "ingredients": ["paper", "glue"], "result": "bound", "text": "The card is bound."}]}


func _test_fixture() -> void:
	var fixture_path := TEST_DIR + "/fixture.json"
	var save_path := TEST_DIR + "/fixture-save.json"
	_write(fixture_path, _fixture())
	var state := State.new()
	_expect(state.load_content(fixture_path), "fixture content loads: " + state.last_error)
	if state.data.is_empty():
		return
	_expect(state.location_id == "room", "new game starts in first location")
	_expect(not state.chapter_unlocked("ch2"), "second chapter starts locked")
	var before := _snapshot(state)
	_expect(not state.visit("vault"), "cannot visit locked chapter")
	_expect(not state.visit("missing"), "cannot visit unknown location")
	_expect(not state.examine("paste").ok, "cannot collect from another room")
	_expect(not state.examine("testimony").ok, "cannot collect from locked chapter")
	_expect(not state.examine("unknown").ok, "unknown hotspot rejected")
	_expect(not state.try_solve("hidden", "found").ok, "hidden-object task cannot finish without evidence")
	_expect(not state.try_solve("missing", "answer").ok, "unknown puzzle rejected")
	_expect(not state.combine("paper", "glue").ok, "unowned ingredient rejected")
	_expect(before == _snapshot(state), "invalid actions leave every state field unchanged")
	_expect(state.examine("card").ok, "examining hotspot succeeds")
	_expect(state.examine("card").ok, "evidence can be re-read")
	_expect(state.evidence.count("card") == 1 and state.inventory.count("paper") == 1, "re-reading never duplicates evidence or inventory")
	_expect(not state.try_solve("code", "Night Fall").ok, "dependencies enforced even for correct answer")
	_expect(state.try_solve("hidden", "found").ok, "collected hidden-object set can be submitted")
	_expect("token" in state.inventory, "puzzle reward added")
	before = _snapshot(state)
	_expect(not state.try_solve("hidden", "found").ok, "solved puzzle cannot reward again")
	_expect(not state.try_solve("code", 123).ok, "wrong answer type rejected")
	_expect(not state.try_solve("code", "wrong").ok, "wrong code rejected")
	_expect(before == _snapshot(state), "retries and wrong answers preserve state")
	_expect(state.try_solve("code", "  niGHT\t FaLL\n").ok, "codes normalize case and whitespace")
	_expect(state.try_solve("choice", "A").ok, "choice answer works")
	_expect(not state.try_solve("order", ["A"]).ok, "partial order rejected")
	_expect(not state.try_solve("order", ["B", "A"]).ok, "wrong order rejected")
	_expect(state.try_solve("order", ["A", "B"]).ok, "full correct order accepted")
	_expect(state.try_solve("sequence", ["A", "B", "A"]).ok, "sequence allows repeated options")
	_expect(state.try_solve("routing", ["A", "B"]).ok, "route accepts a proper subset")
	_expect(not state.try_solve("assembly", "assembled").ok, "assembly requires crafted item")
	_expect(state.visit("store"), "travel to another unlocked scene")
	_expect(state.examine("paste").ok, "collect second ingredient")
	before = _snapshot(state)
	_expect(not state.combine("paper", "token").ok, "unrelated inventory combination rejected")
	_expect(before == _snapshot(state), "failed recipe consumes nothing")
	_expect(state.combine("glue", "paper").ok, "recipe accepts swapped ingredient order")
	_expect("paper" in state.inventory and "glue" in state.inventory and "bound" in state.inventory, "recipe never destroys source objects")
	_expect(not state.combine("paper", "glue").ok, "duplicate recipe result is prevented")
	_expect(not state.try_solve("assembly", "assembled").ok, "investigations require travel to their scene")
	_expect(state.visit("room") and state.try_solve("assembly", "assembled").ok, "assembled object completes puzzle")
	_expect(state.chapter_unlocked("ch2"), "chapter finale opens next chapter")
	_expect(state.save_game(save_path), "save writes complete progress: " + state.last_error)
	var first_save := _snapshot(state)
	_expect(state.visit("vault") and state.examine("testimony").ok and state.try_solve("deduction", "A").ok, "second chapter through ending")
	state.elapsed_seconds = 812.5
	state.settings.music = 0.25
	state.settings.large_text = true
	_expect(state.save_game(save_path), "second save atomically replaces first")
	var restored := State.new()
	_expect(restored.load_content(fixture_path) and restored.load_game(save_path), "save loads into fresh state")
	_expect(_snapshot(restored) == _snapshot(state), "all progression/settings/playtime roundtrip exactly")
	_expect(restored.load_backup(save_path), "previous complete save is recoverable")
	_expect(_snapshot(restored) == first_save, "backup contains previous checkpoint")
	_expect(restored.load_game(save_path), "main save is not changed by recovery")
	var valid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	var invalid_path := TEST_DIR + "/invalid.json"
	for field in ["unknown_id", "duplicate_id", "missing_prereq", "missing_clue", "missing_item", "bad_settings", "bad_elapsed", "future_version", "locked_location", "unearned_item"]:
		var bad: Dictionary = valid.duplicate(true)
		match field:
			"unknown_id": bad.solved.append("unknown")
			"duplicate_id": bad.evidence.append("card")
			"missing_prereq": bad.solved.erase("hidden")
			"missing_clue": bad.evidence.erase("card")
			"missing_item": bad.inventory.erase("bound")
			"bad_settings": bad.settings.music = "loud"
			"bad_elapsed": bad.elapsed_seconds = -1
			"future_version": bad.version = 999
			"locked_location":
				bad.solved = []
				bad.evidence = []
				bad.inventory = []
			"unearned_item":
				bad.location = "room"
				bad.solved = []
				bad.evidence = []
				bad.inventory = ["bound"]
		_write(invalid_path, bad)
		before = _snapshot(restored)
		_expect(not restored.load_game(invalid_path), "invalid save rejected: " + field)
		_expect(before == _snapshot(restored), "failed load transactional: " + field)
	_write(invalid_path, "{truncated")
	before = _snapshot(restored)
	_expect(not restored.load_game(invalid_path) and before == _snapshot(restored), "truncated JSON rejected transactionally")
	_expect(not restored.load_game(TEST_DIR + "/not-present.json") and before == _snapshot(restored), "missing save leaves live progress unchanged")
	# Content loading also must be transactional, including cycle detection.
	var invalid_content := _fixture()
	invalid_content.puzzles[0].requires = ["deduction"]
	_write(invalid_path, invalid_content)
	_expect(not restored.load_content(invalid_path) and before == _snapshot(restored), "chapter dependency cycle rejected without replacing live game")
	invalid_content = _fixture()
	invalid_content.locations[0].hotspots[0].item = "unknown"
	_write(invalid_path, invalid_content)
	_expect(not restored.load_content(invalid_path), "content rejects unknown collectible ID")
	invalid_content = _fixture()
	invalid_content.puzzles[0].items = ["token"]
	_write(invalid_path, invalid_content)
	_expect(not restored.load_content(invalid_path), "content rejects a puzzle requiring its own reward")
	invalid_content = _fixture()
	invalid_content.puzzles[0].clues = ["testimony"]
	_write(invalid_path, invalid_content)
	_expect(not restored.load_content(invalid_path), "content rejects an early clue locked behind a later chapter")
	# A corrupt primary must not replace the good backup during a new save.
	_write(save_path, "{interrupted write")
	_expect(state.save_game(save_path), "valid live state can replace a corrupt primary")
	_expect(restored.load_backup(save_path) and _snapshot(restored) == first_save, "corrupt primary never overwrites a valid recovery copy")


func _test_content() -> void:
	if not FileAccess.file_exists("res://content/game.json"):
		_expect(false, "full narrative content is present")
		return
	for reverse in [false, true]:
		var state := State.new()
		_expect(state.load_content(), "production case content validates: " + state.last_error)
		if state.data.is_empty():
			return
		_expect(state.data.chapters.size() >= 6, "at least six chapters authored")
		_expect(state.data.locations.size() >= 36, "at least 36 locations authored")
		_expect(state.data.puzzles.size() >= 60, "at least 60 investigations authored")
		var puzzles: Array = state.data.puzzles.duplicate()
		var locations: Array = state.data.locations.duplicate()
		if reverse:
			puzzles.reverse()
			locations.reverse()
		var completed := true
		var saves := 0
		for _pass in range(puzzles.size() + 1):
			var previous_count: int = state.solved.size()
			for location in locations:
				if state.chapter_unlocked(location.chapter):
					_expect(state.visit(location.id), "reachable location: " + location.id)
					if state.searches.has(location.id) and not state.search_complete(location.id):
						for item in state.searches[location.id].items:
							_expect(state.find_search_object(location.id, item.id).ok, "reachable hidden object: " + location.id + "/" + item.id)
						var search_save := TEST_DIR + "/room-boundary.json"
						_expect(state.save_game(search_save) and state.load_game(search_save), "completed room save roundtrip: " + location.id)
					for hotspot in location.hotspots:
						_expect(state.examine(hotspot.id).ok, "reachable evidence: " + hotspot.id)
			for _craft_pass in range(state.data.recipes.size() + 1):
				var crafted := false
				for recipe in state.data.recipes:
					if recipe.result not in state.inventory and recipe.ingredients[0] in state.inventory and recipe.ingredients[1] in state.inventory:
						_expect(state.combine(recipe.ingredients[1], recipe.ingredients[0]).ok, "reachable combination: " + recipe.id)
						crafted = true
				if not crafted:
					break
			for puzzle in puzzles:
				if state.can_solve(puzzle.id):
					_expect(state.visit(puzzle.location), "puzzle scene reachable: " + puzzle.id)
					var before := _snapshot(state)
					_expect(not state.try_solve(puzzle.id, {"invalid": true}).ok, "wrong answer rejected: " + puzzle.id)
					_expect(before == _snapshot(state), "wrong answer preserves state: " + puzzle.id)
					_expect(state.try_solve(puzzle.id, puzzle.solution).ok, "authored solution accepted: " + puzzle.id)
					var save_path := TEST_DIR + "/full-case.json"
					state.elapsed_seconds += 4.25
					_expect(state.save_game(save_path), "checkpoint saves after " + puzzle.id + ": " + state.last_error)
					var reload := State.new()
					_expect(reload.load_content() and reload.load_game(save_path), "checkpoint loads after " + puzzle.id + ": " + reload.last_error)
					_expect(_snapshot(reload) == _snapshot(state), "checkpoint fidelity after " + puzzle.id)
					saves += 1
			if state.solved.size() == puzzles.size():
				break
			if state.solved.size() == previous_count:
				completed = false
				var pending: Array = []
				for puzzle in puzzles:
					if puzzle.id not in state.solved:
						pending.append(puzzle.id)
				_expect(false, "progression stalled; pending: " + str(pending))
				break
		_expect(completed and state.solved.size() == puzzles.size(), "opening-to-ending state traversal in " + ("reverse" if reverse else "forward") + " order")
		_expect(saves == puzzles.filter(func(p): return p.type != "hidden").size(), "save/load tested at every submitted investigation and every room completion")
		for chapter in state.data.chapters:
			_expect(state.chapter_unlocked(chapter.id) and chapter.final_puzzle in state.solved, "chapter accessible and complete: " + chapter.id)
		print("CONTENT_TRAVERSAL: ", "reverse" if reverse else "forward", "; ", state.solved.size(), " puzzles; ", state.evidence.size(), " evidence entries; ", state.inventory.size(), " inventory objects; ", saves, " save roundtrips. Automated solver uses authored answers; this is not a human playthrough or duration test.")


func _test_av_save_migration() -> void:
	var fixture_path := TEST_DIR + "/fixture.json"
	var path := TEST_DIR + "/legacy-av.json"
	var state := State.new()
	_expect(state.load_content(fixture_path), "migration fixture loads")
	state.examine("card")
	state.try_solve("hidden", "found")
	state.elapsed_seconds = 72.5
	state.settings.music = 0.42
	state.settings.large_text = true
	var legacy: Dictionary = state._record()
	legacy.version = 1
	for key in ["voice", "ambience", "subtitles", "auto_voice"]:
		legacy.settings.erase(key)
	_write(path, legacy)
	state.new_game()
	_expect(state.load_game(path), "original alpha version-1 save loads")
	_expect(state.solved == ["hidden"] and state.evidence == ["card"] and state.inventory == ["paper", "token"], "migration preserves all case progress")
	_expect(state.elapsed_seconds == 72.5 and state.settings.music == 0.42 and state.settings.large_text, "migration preserves original time and settings")
	_expect(state.settings.voice == 0.9 and state.settings.ambience == 0.5 and state.settings.subtitles and state.settings.auto_voice, "migration adds only new AV defaults")
	state.settings.voice = 0.27
	state.settings.ambience = 0.31
	state.settings.auto_voice = false
	state.settings.subtitles = false
	_expect(state.save_game(path), "migrated progress saves with Detective state")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(saved.version == State.SAVE_VERSION and saved.version == 5, "migrated save has explicit current version")
	var migrated := _snapshot(state)
	_expect(state.load_game(path) and _snapshot(state) == migrated, "all four AV preferences roundtrip")
	_expect(state.load_backup(path), "valid original alpha checkpoint retained as backup")
	_expect(state.settings.voice == 0.9 and state.solved == ["hidden"], "version1 backup recovers with AV defaults")
	var before := _snapshot(state)
	for corruption in ["missing_legacy_key", "bad_legacy_audio", "unknown_legacy_key", "missing_v2_voice", "bad_v2_voice", "bad_v2_subtitles"]:
		var bad: Dictionary = legacy.duplicate(true) if "legacy" in corruption else saved.duplicate(true)
		match corruption:
			"missing_legacy_key": bad.settings.erase("music")
			"bad_legacy_audio": bad.settings.music = "loud"
			"unknown_legacy_key": bad.settings.voice = 0.5
			"missing_v2_voice": bad.settings.erase("voice")
			"bad_v2_voice": bad.settings.voice = 2.0
			"bad_v2_subtitles": bad.settings.subtitles = "yes"
		_write(TEST_DIR + "/av-corrupt.json", bad)
		_expect(not state.load_game(TEST_DIR + "/av-corrupt.json"), "AV migration rejects " + corruption)
		_expect(before == _snapshot(state), "AV migration failure is transactional: " + corruption)
