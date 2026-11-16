extends RefCounted
## Spoiler-aware directions derived from the existing campaign state.
var campaign: RefCounted
var data: Dictionary

func configure(state: RefCounted, content: Dictionary) -> void:
	campaign = state
	data = content

func title() -> String:
	if campaign.data.chapters[-1].final_puzzle in campaign.solved: return "The truth is on record."
	if campaign.search_complete("ch4_l6"): return "Prove who ordered the flood."
	return data.title

func mission() -> String:
	if campaign.data.chapters[-1].final_puzzle in campaign.solved: return data.resolved
	if campaign.search_complete("ch4_l6"): return data.after_mara
	return data.mission

func room_goal(id: String) -> String:
	return str(data.rooms.get(id, {}).get("goal", "Search this room for evidence."))

func discovery(id: String) -> String:
	if not campaign.search_complete(id): return ""
	return str(data.rooms.get(id, {}).get("discovery", ""))

func next_step() -> Dictionary:
	if campaign.data.chapters[-1].final_puzzle in campaign.solved:
		return {"action":"ending", "title":"Read the conclusion", "detail":data.resolved}
	var chapter: Dictionary = {}
	var current: Dictionary = campaign.get_location(campaign.location_id)
	for candidate in campaign.data.chapters:
		if candidate.id == current.chapter: chapter = candidate
	if chapter.final_puzzle in campaign.solved:
		for candidate in campaign.data.chapters:
			if campaign.chapter_unlocked(candidate.id) and candidate.final_puzzle not in campaign.solved:
				chapter = candidate
				break
	if current.chapter == chapter.id and not campaign.search_complete(current.id):
		return _search_step(current.id)
	# Finish the investigation in front of the player before suggesting a
	# preparation elsewhere (e.g. Transit Hall before the Darkroom's viewer).
	for puzzle in campaign.data.puzzles:
		if puzzle.location == current.id and puzzle.id not in campaign.solved and campaign.can_solve(puzzle.id):
			return _puzzle_step(puzzle)
	for puzzle in campaign.data.puzzles:
		if puzzle.chapter != chapter.id or puzzle.id in campaign.solved: continue
		if campaign.can_solve(puzzle.id): return _puzzle_step(puzzle)
	# Suggest only a combination that feeds an unfinished investigation in this
	# chapter, rather than every recipe whose parts happen to be in the bag.
	for puzzle in campaign.data.puzzles:
		if puzzle.chapter != chapter.id or puzzle.id in campaign.solved: continue
		for recipe in campaign.data.recipes:
			if recipe.result in campaign.inventory or recipe.result not in puzzle.items: continue
			var ready := true
			for ingredient in recipe.ingredients:
				if ingredient not in campaign.inventory: ready = false
			if ready:
				var names: Array[String] = []
				for ingredient in recipe.ingredients: names.append(str(campaign.get_item(ingredient).name))
				return {"action":"inventory", "title":"Prepare " + str(campaign.get_item(recipe.result).name), "detail":"Combine " + " and ".join(names) + " for " + str(puzzle.title) + "."}
	for id in chapter.locations:
		if not campaign.search_complete(id): return _search_step(id)
	return {"action":"casebook", "title":"Review your connected investigations", "detail":"The room searches are complete. Your casebook lists the remaining connections and their evidence."}

func _search_step(id: String) -> Dictionary:
	return {"action":"search", "location":id, "title":"Search " + str(campaign.searches[id].title), "detail":room_goal(id)}

func _puzzle_step(puzzle: Dictionary) -> Dictionary:
	return {"action":"puzzle", "id":puzzle.id, "location":puzzle.location, "title":"Investigate · " + str(puzzle.title), "detail":"Your evidence is ready for this investigation at " + str(campaign.get_location(puzzle.location).title) + "."}
