extends SceneTree
const State = preload("res://scripts/game_state.gd")
var checks := 0
var failures := 0
var path := "user://campaign-search-state.json"
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("SEARCH STATE FAIL: ", message)
func write_record(record: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(record)); file.close()
func _initialize() -> void:
	var state := State.new()
	expect(state.load_content(), "complete campaign loads")
	expect(state.searches.size() == 36, "every location has a search")
	var total := 0
	for definition in state.searches.values(): total += definition.items.size()
	expect(total == 507, "all 507 authored finds present")
	var before: Dictionary = state._record()
	expect(not state.examine("ch1_l1_a").ok, "evidence cannot bypass the picture search")
	expect(not state.find_search_object("ch1_l2", "key").ok, "cross-room finds rejected")
	expect(not state.find_search_object("ch1_l1", "unknown").ok, "unknown finds rejected")
	expect(not state.find_search_object("ch6_l6", "key").ok, "locked-room finds rejected")
	expect(state._record() == before, "invalid actions preserve full state")
	var first: String = state.searches.ch1_l1.items[0].id
	expect(state.find_search_object("ch1_l1", first).ok, "first visible find records")
	expect(state.evidence.is_empty() and state.inventory.is_empty(), "partial search has not prematurely awarded room evidence")
	expect(state.save_game(path), "partial search saves")
	var partial: Dictionary = state._record()
	var restored := State.new(); restored.load_content()
	expect(restored.load_game(path) and restored._record() == partial, "partial search reloads exactly")
	expect(restored.visit("ch1_l2") and restored.visit("ch1_l1") and restored.search_progress.ch1_l1 == [first], "leaving and returning retains finds")
	for damage in ["repeat", "unknown", "room", "locked", "early_evidence", "wrong_type"]:
		var bad: Dictionary = partial.duplicate(true)
		match damage:
			"repeat": bad.search_progress.ch1_l1.append(first)
			"unknown": bad.search_progress.ch1_l1.append("invented")
			"room": bad.search_progress["missing"] = []
			"locked": bad.search_progress.ch2_l1 = [state.searches.ch2_l1.items[0].id]
			"early_evidence": bad.evidence.append("ch1_l1_a")
			"wrong_type": bad.search_progress.ch1_l1 = "bad"
		write_record(bad)
		expect(not restored.load_game(path) and restored._record() == partial, "transactional rejection: " + damage)
	for item in restored.searches.ch1_l1.items:
		if item.id != first: expect(restored.find_search_object("ch1_l1", item.id).ok, "find remaining " + item.id)
	expect(restored.search_complete("ch1_l1") and restored.evidence.size() == 3 and "p01" in restored.solved, "room completion awards all clues and resolves its collection task")
	before = restored._record()
	expect(not restored.find_search_object("ch1_l1", first).ok and restored._record() == before, "completed find cannot duplicate clues, items or solved tasks")
	expect(restored.save_game(path) and state.load_game(path) and state._record() == before, "completed room reloads exactly")
	var invalid_complete: Dictionary = before.duplicate(true)
	invalid_complete.evidence.pop_back(); write_record(invalid_complete)
	expect(not state.load_game(path) and state._record() == before, "completed room missing evidence rejected transactionally")
	var legacy: Dictionary = before.duplicate(true)
	legacy.version = 2; legacy.erase("search_progress")
	write_record(legacy)
	expect(state.load_game(path) and state.search_complete("ch1_l1"), "old completed room migrates without repeating work")
	expect(state.search_progress.size() == 1, "migration leaves unvisited rooms unsearched")
	var untouched := FileAccess.get_file_as_string(path)
	expect(state.save_game(path + ".new") and FileAccess.get_file_as_string(path) == untouched, "migrated copy preserves the original save")
	legacy.solved = []; legacy.evidence = ["ch1_l1_a"]; legacy.inventory = []
	var item: String = state.get_hotspot("ch1_l1_a").get("item", "")
	if not item.is_empty(): legacy.inventory.append(item)
	write_record(legacy)
	expect(state.load_game(path) and state.search_complete("ch1_l1") and state.evidence.size() == 3, "partially investigated legacy room retains progress and migrates its discoveries")
	expect(state.save_game(path + ".new") and restored.load_game(path + ".new"), "migrated legacy state is valid in the new format")
	state.new_game()
	for room in state.data.chapters[0].locations:
		if room == "ch1_l6": continue
		state.visit(room)
		for target in state.searches[room].items: state.find_search_object(room,target.id)
	expect(not state._search_requirements_met(state.get_puzzle("p10"), state.search_progress), "chapter resolution waits for all six rooms")
	state.visit("ch1_l6")
	for target in state.searches.ch1_l6.items: state.find_search_object("ch1_l6",target.id)
	expect(state._search_requirements_met(state.get_puzzle("p10"), state.search_progress), "six searches satisfy the chapter search gate")
	print("CAMPAIGN_SEARCH_STATE_" + ("OK" if failures == 0 else "FAILED") + ": %d assertions; partial progress, duplicate rewards, invalid saves, legacy migration, chapter gates" % checks)
	quit(0 if failures == 0 else 1)
