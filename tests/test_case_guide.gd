extends SceneTree
const State = preload("res://scripts/game_state.gd")
const Guide = preload("res://scripts/case_guide.gd")
var checks := 0
var failures := 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("CASE GUIDE FAIL: ", message)
func _initialize() -> void:
	var state := State.new()
	expect(state.load_content(), "campaign loads")
	var guide := Guide.new()
	guide.configure(state, JSON.parse_string(FileAccess.get_file_as_string("res://content/story-guide.json")))
	expect(guide.data.rooms.size() == state.data.locations.size(), "every room has a purpose and discovery")
	for location in state.data.locations:
		expect(not guide.room_goal(location.id).is_empty(), "room has a clear purpose: " + location.id)
		expect(guide.discovery(location.id).is_empty(), "unearned discovery is hidden: " + location.id)
	expect(guide.next_step().location == "ch1_l1", "new game starts with the receipt search")
	var steps := 0
	var chapters := []
	while steps < 180 and state.data.chapters[-1].final_puzzle not in state.solved:
		steps += 1
		var before: Dictionary = state._record()
		var step: Dictionary = guide.next_step()
		expect(state._record() == before, "asking for guidance does not change progress")
		match str(step.action):
			"search":
				expect(state.visit(step.location), "recommended search is unlocked")
				expect(guide.discovery(step.location).is_empty(), "recommended search does not spoil discovery")
				for item in state.searches[step.location].items:
					if item.id not in state.search_progress.get(step.location, []):
						expect(state.find_search_object(step.location, item.id).ok, "recommended search can be played")
				expect(not guide.discovery(step.location).is_empty(), "completed search explains what it revealed")
			"inventory":
				var combined := false
				for recipe in state.data.recipes:
					if recipe.result not in state.inventory and recipe.ingredients[0] in state.inventory and recipe.ingredients[1] in state.inventory:
						expect(state.combine(recipe.ingredients[0], recipe.ingredients[1]).ok, "recommended combination is available")
						combined = true
						break
				expect(combined, "inventory guidance does not dead-end")
			"puzzle":
				expect(state.visit(step.location) and state.can_solve(step.id), "recommended investigation is available")
				var puzzle: Dictionary = state.get_puzzle(step.id)
				expect(state.try_solve(step.id, puzzle.solution).ok, "recommended investigation progresses with authored solution")
				for chapter in state.data.chapters:
					if chapter.final_puzzle == step.id: chapters.append(chapter.id)
			_:
				expect(false, "guide stalled: " + str(step))
				break
		expect(guide.mission() == guide.data.mission if not state.search_complete("ch4_l6") else guide.mission() != guide.data.mission, "mission changes when Mara is actually found")
		expect(state._record() != before, "every suggested action advances the investigation")
	expect(chapters == ["ch1", "ch2", "ch3", "ch4", "ch5", "ch6"], "guidance reaches all six chapter conclusions in order")
	expect(state.solved.size() == 60 and guide.next_step().action == "ending", "guide reaches final conclusion without a dead end")
	expect(guide.mission() == guide.data.resolved, "completed mission recognises resolution")
	print("CASE_GUIDE_" + ("OK" if failures == 0 else "FAILED") + ": %d checks; %d guided actions from new case to conclusion" % [checks, steps])
	quit(0 if failures == 0 else 1)
