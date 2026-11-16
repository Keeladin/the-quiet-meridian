extends RefCounted
## Offline, explicit-active-time rules. Queries never create attempts.
const STARTING_INSIGHT := 6
const HINT_COOLDOWN := 45.0
const MAX_HINTS := 3
const EXTENSION_SECONDS := 30.0
const MAX_EXTENSIONS := 2
var insight := STARTING_INSIGHT
var searches: Dictionary = {}
var puzzles: Dictionary = {}
var search_rewards: Dictionary = {}
var puzzle_rewards: Dictionary = {}

func reset() -> void:
	insight = STARTING_INSIGHT
	searches = {}; puzzles = {}; search_rewards = {}; puzzle_rewards = {}

func default_search(duration: float) -> Dictionary:
	return {"remaining":duration, "active_seconds":0.0, "hints_used":0, "hint_cooldown":0.0, "extensions":0, "penalties":0, "penalty_seconds":0.0, "misses":[]}

func default_puzzle() -> Dictionary:
	return {"active_seconds":0.0, "hints_used":0, "hint_cooldown":0.0, "wrong_submissions":[], "submit_cooldown":0.0, "last_wrong_answer":""}

func search_snapshot(id: String, duration: float) -> Dictionary:
	return searches.get(id, default_search(duration)).duplicate(true)

func puzzle_snapshot(id: String) -> Dictionary:
	return puzzles.get(id, default_puzzle()).duplicate(true)

func ensure_search(id: String, duration: float) -> Dictionary:
	if not searches.has(id): searches[id] = default_search(duration)
	return searches[id]

func ensure_puzzle(id: String) -> Dictionary:
	if not puzzles.has(id): puzzles[id] = default_puzzle()
	return puzzles[id]

func advance_search(id: String, duration: float, delta: float) -> bool:
	if not is_finite(delta) or delta <= 0: return false
	var attempt := ensure_search(id, duration)
	var active := minf(delta, float(attempt.remaining))
	if active <= 0: return false
	attempt.active_seconds += active
	attempt.remaining = maxf(0.0, float(attempt.remaining) - active)
	attempt.hint_cooldown = maxf(0.0, float(attempt.hint_cooldown) - active)
	_trim(attempt.misses, float(attempt.active_seconds), 3.0)
	return attempt.remaining <= 0

func advance_puzzle(id: String, delta: float) -> void:
	if not is_finite(delta) or delta <= 0: return
	var attempt := ensure_puzzle(id)
	attempt.active_seconds += delta
	attempt.hint_cooldown = maxf(0.0, float(attempt.hint_cooldown) - delta)
	attempt.submit_cooldown = maxf(0.0, float(attempt.submit_cooldown) - delta)
	_trim(attempt.wrong_submissions, float(attempt.active_seconds), 60.0)

func search_miss(id: String, duration: float) -> Dictionary:
	var attempt := ensure_search(id, duration)
	_trim(attempt.misses, float(attempt.active_seconds), 3.0)
	attempt.misses.append(float(attempt.active_seconds))
	var warning: bool = attempt.misses.size() >= 3
	var penalty := 0.0
	if attempt.misses.size() >= 5:
		penalty = minf(10.0, float(attempt.remaining))
		attempt.remaining = maxf(0.0, float(attempt.remaining) - penalty)
		attempt.penalty_seconds += penalty
		attempt.penalties += 1
		attempt.misses.clear()
	return {"ok":true, "warning":warning, "penalty":penalty, "expired":attempt.remaining <= 0,
		"text":"Rapid guessing: −10 seconds." if penalty > 0 else ("Slow down and look carefully; rapid guessing costs time." if warning else "Look for the listed objects and shapes.")}

func use_search_hint(id: String, duration: float) -> Dictionary:
	var current := search_snapshot(id, duration)
	var error := _hint_error(current)
	if not error.is_empty(): return {"ok":false,"text":error}
	var attempt := ensure_search(id, duration)
	return _use_hint(attempt)

func use_puzzle_hint(id: String) -> Dictionary:
	var current := puzzle_snapshot(id)
	var error := _hint_error(current)
	if not error.is_empty(): return {"ok":false,"text":error}
	return _use_hint(ensure_puzzle(id))

func _hint_error(attempt: Dictionary) -> String:
	if int(attempt.hints_used) >= MAX_HINTS: return "You have used all three hints for this attempt."
	if float(attempt.hint_cooldown) > 0: return "The next hint is ready in %d seconds." % ceili(float(attempt.hint_cooldown))
	if int(attempt.hints_used) > 0 and insight < 1: return "You need 1 Insight to use another hint."
	return ""

func _use_hint(attempt: Dictionary) -> Dictionary:
	var cost := 0 if int(attempt.hints_used) == 0 else 1
	insight -= cost
	attempt.hints_used += 1
	attempt.hint_cooldown = HINT_COOLDOWN
	return {"ok":true,"level":int(attempt.hints_used),"cost":cost}

func extend_search(id: String, duration: float) -> Dictionary:
	var current := search_snapshot(id, duration)
	if int(current.extensions) >= MAX_EXTENSIONS: return {"ok":false,"text":"Both time extensions have been used for this attempt."}
	if insight < 1: return {"ok":false,"text":"You need 1 Insight to add 30 seconds."}
	var attempt := ensure_search(id, duration)
	insight -= 1
	attempt.extensions += 1
	attempt.remaining += EXTENSION_SECONDS
	return {"ok":true,"cost":1,"text":"30 seconds added · 1 Insight spent."}

func restart_search(id: String, duration: float) -> Dictionary:
	var current := search_snapshot(id, duration)
	var refund := int(current.extensions) + maxi(0, int(current.hints_used) - 1)
	insight += refund
	searches[id] = default_search(duration)
	return {"ok":true,"refunded":refund,"text":"Search restarted." + (" %d Insight refunded." % refund if refund > 0 else "")}

func wrong_answer(id: String, signature: String) -> Dictionary:
	var current := puzzle_snapshot(id)
	if float(current.submit_cooldown) > 0: return {"ok":false,"cooldown":float(current.submit_cooldown),"text":"Review the evidence. You can submit again in %d seconds." % ceili(float(current.submit_cooldown))}
	if current.last_wrong_answer == signature: return {"ok":false,"repeated":true,"text":"That answer still does not fit. Change it before submitting again."}
	var attempt := ensure_puzzle(id)
	_trim(attempt.wrong_submissions, float(attempt.active_seconds), 60.0)
	attempt.wrong_submissions.append(float(attempt.active_seconds))
	attempt.last_wrong_answer = signature
	if attempt.wrong_submissions.size() >= 3:
		attempt.submit_cooldown = 10.0
		attempt.wrong_submissions.clear()
	return {"ok":false,"cooldown":float(attempt.submit_cooldown),"text":"That does not fit the evidence." + (" Take 10 seconds to review it before submitting again." if attempt.submit_cooldown > 0 else " Review the clues or use a hint.")}

func reward_search(id: String, duration: float) -> int:
	if search_rewards.has(id): return 0
	var attempt := ensure_search(id, duration)
	var amount := 2 + (1 if int(attempt.penalties) == 0 else 0)
	search_rewards[id] = amount
	insight += amount
	attempt.misses.clear()
	return amount

func reward_puzzle(id: String) -> int:
	if puzzle_rewards.has(id): return 0
	ensure_puzzle(id)
	puzzle_rewards[id] = 1
	insight += 1
	return 1

func record() -> Dictionary:
	return {"insight":insight,"searches":searches.duplicate(true),"puzzles":puzzles.duplicate(true),"search_rewards":search_rewards.duplicate(true),"puzzle_rewards":puzzle_rewards.duplicate(true)}

func restore(value: Dictionary) -> void:
	insight = int(value.insight)
	searches = value.searches.duplicate(true)
	puzzles = value.puzzles.duplicate(true)
	search_rewards = value.search_rewards.duplicate(true)
	puzzle_rewards = value.puzzle_rewards.duplicate(true)
	# JSON has one numeric type; restore the same integer counters used at runtime.
	for attempt in searches.values():
		for key in ["hints_used", "extensions", "penalties"]: attempt[key] = int(attempt[key])
	for attempt in puzzles.values(): attempt.hints_used = int(attempt.hints_used)
	for id in search_rewards: search_rewards[id] = int(search_rewards[id])
	for id in puzzle_rewards: puzzle_rewards[id] = int(puzzle_rewards[id])

func migrate(search_definitions: Dictionary, progress: Dictionary, puzzle_definitions: Dictionary, solved: Array) -> void:
	reset()
	for id in progress:
		ensure_search(id, duration_for(search_definitions[id].items.size()))
		if progress[id].size() == search_definitions[id].items.size(): search_rewards[id] = 0
	for id in solved:
		if puzzle_definitions[id].type != "hidden":
			ensure_puzzle(id)
			puzzle_rewards[id] = 0

static func duration_for(target_count: int) -> float:
	return 600.0 if target_count > 14 else 480.0

func _trim(events: Array, now: float, window: float) -> void:
	while not events.is_empty() and now - float(events[0]) > window: events.pop_front()

static func validate(value: Variant, definitions: Dictionary, progress: Dictionary, puzzle_definitions: Dictionary, solved: Array) -> String:
	if not value is Dictionary or not _keys_match(value,["insight","searches","puzzles","search_rewards","puzzle_rewards"]): return "Detective progress is missing or damaged."
	if not _integer(value.insight,0,1000000): return "The Insight balance is invalid."
	for field in ["searches","puzzles","search_rewards","puzzle_rewards"]:
		if not value[field] is Dictionary: return "Detective progress contains an invalid collection."
	var expected_balance := STARTING_INSIGHT
	for id in value.searches:
		if not id is String or not definitions.has(id): return "An attempt refers to an unknown search."
		var a: Variant = value.searches[id]
		if not a is Dictionary or not _keys_match(a,["remaining","active_seconds","hints_used","hint_cooldown","extensions","penalties","penalty_seconds","misses"]): return "A search attempt is damaged."
		var duration := duration_for(definitions[id].items.size())
		if not _number(a.remaining,0,duration+60) or not _number(a.active_seconds,0,duration+60) or not _integer(a.hints_used,0,3) or not _number(a.hint_cooldown,0,45) or not _integer(a.extensions,0,2) or not _integer(a.penalties,0,1000000) or not _number(a.penalty_seconds,0,duration+60): return "A search budget is invalid."
		if (int(a.hints_used)==0 and float(a.hint_cooldown)>0) or float(a.penalty_seconds)>float(a.penalties)*10 or (int(a.penalties)>0 and float(a.penalty_seconds)<=0): return "A search penalty or hint record is inconsistent."
		if absf(float(a.remaining) - maxf(0.0,duration+float(a.extensions)*30.0-float(a.active_seconds)-float(a.penalty_seconds))) > 0.025: return "The saved search clock does not match its elapsed time and penalties."
		if not _events_valid(a.misses,float(a.active_seconds),3.0,4): return "The rapid-click record is invalid."
		expected_balance -= int(a.extensions) + maxi(0,int(a.hints_used)-1)
	for id in progress:
		if not value.searches.has(id): return "A started search is missing its attempt."
		if progress[id].size()==definitions[id].items.size() and not value.search_rewards.has(id): return "A completed search is missing its reward record."
	for id in value.search_rewards:
		if not id is String or not definitions.has(id) or progress.get(id,[]).size()!=definitions[id].items.size() or not value.searches.has(id): return "An uncompleted search claims a reward."
		var reward: Variant = value.search_rewards[id]
		if not _integer(reward,0,3) or int(reward)==1: return "A search reward is invalid."
		if int(reward)>0 and int(reward)!=(3 if int(value.searches[id].penalties)==0 else 2): return "A search reward does not match its penalty record."
		expected_balance += int(reward)
	for id in value.puzzles:
		if not id is String or not puzzle_definitions.has(id) or puzzle_definitions[id].type=="hidden": return "An attempt refers to an unknown investigation."
		var a: Variant = value.puzzles[id]
		if not a is Dictionary or not _keys_match(a,["active_seconds","hints_used","hint_cooldown","wrong_submissions","submit_cooldown","last_wrong_answer"]): return "An investigation attempt is damaged."
		if not _number(a.active_seconds,0,1000000000) or not _integer(a.hints_used,0,3) or not _number(a.hint_cooldown,0,45) or not _number(a.submit_cooldown,0,10) or not a.last_wrong_answer is String or a.last_wrong_answer.length()>10000: return "An investigation budget is invalid."
		if int(a.hints_used)==0 and float(a.hint_cooldown)>0: return "An unused investigation hint cannot be recharging."
		if not _events_valid(a.wrong_submissions,float(a.active_seconds),60.0,2): return "The incorrect-submission record is invalid."
		expected_balance -= maxi(0,int(a.hints_used)-1)
	for id in solved:
		if puzzle_definitions[id].type!="hidden" and not value.puzzle_rewards.has(id): return "A completed investigation is missing its reward record."
	for id in value.puzzle_rewards:
		if not id is String or not puzzle_definitions.has(id) or puzzle_definitions[id].type=="hidden" or id not in solved or not value.puzzles.has(id) or not _integer(value.puzzle_rewards[id],0,1): return "An investigation reward is invalid."
		expected_balance += int(value.puzzle_rewards[id])
	if int(value.insight)!=expected_balance: return "The Insight balance does not match earned rewards and purchases."
	return ""

static func _keys_match(value: Dictionary, keys: Array) -> bool:
	if value.size()!=keys.size(): return false
	for key in keys:
		if not value.has(key): return false
	return true

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return _number(value,minimum,maximum) and float(value)==floorf(float(value))

static func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and float(value)<=maximum

static func _events_valid(events: Variant, now: float, window: float, maximum: int) -> bool:
	if not events is Array or events.size()>maximum: return false
	var previous := -1.0
	for value in events:
		if not _number(value,maxf(0,now-window),now) or float(value)<previous: return false
		previous = float(value)
	return true
