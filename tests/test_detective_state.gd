extends SceneTree
## Detective budgets use explicitly supplied active time; no wall clock or player saves.
const State = preload("res://scripts/game_state.gd")
const SAVE := "user://detective-regression.json"
var checks := 0
var failures := 0

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("DETECTIVE FAIL: ", message)

func fresh() -> RefCounted:
	var state := State.new()
	expect(state.load_content(), "campaign content loads")
	return state

func write_save(record: Dictionary) -> void:
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(record)); file.close()

func clear_search(state: RefCounted, room: String) -> Dictionary:
	state.visit(room)
	var result := {}
	for item in state.searches[room].items:
		if item.id not in state.search_progress.get(room, []): result = state.find_search_object(room, item.id)
	return result

func roundtrip(state: RefCounted) -> RefCounted:
	expect(state.save_game(SAVE), "live Detective ledger saves: " + state.last_error)
	var result := fresh()
	expect(result.load_game(SAVE), "Detective ledger loads: " + result.last_error)
	expect(result._record() == state._record(), "all budgets, purchases, counters and progress roundtrip exactly")
	return result

func _initialize() -> void:
	_test_search_budgets()
	_test_retry_and_rewards()
	_test_empty_bank()
	_test_puzzles()
	_test_save_validation_and_migration()
	_test_inventory()
	print("DETECTIVE_STATE_" + ("OK" if failures == 0 else "FAILED") + ": %d assertions; active clocks, penalties, hints, economy, exact retry refunds, migration, transactional saves, inventory history" % checks)
	quit(0 if failures == 0 else 1)

func _test_search_budgets() -> void:
	var s := fresh()
	var before: Dictionary = s._record()
	expect(s.insight_balance() == 6, "new bank starts at six")
	expect(s.search_status("ch1_l1").duration == 600 and s.search_status("ch1_l3").duration == 480, "17 targets receive ten minutes; 14 receive eight")
	s.search_status(); s.puzzle_status("p02"); s.active_inventory(); s.archived_inventory()
	expect(before == s._record(), "status and inventory queries do not start clocks or attempts")
	expect(not s.advance_search(-1) and not s.advance_search(NAN) and not s.advance_search(20,"ch1_l2"), "invalid or cross-room ticks ignored")
	expect(before == s._record(), "ignored ticks are side-effect free")
	s.advance_search(1.25)
	expect(s.search_status().remaining == 598.75, "clock advances only by explicitly supplied active time")
	var frozen: Dictionary = s.search_status()
	s.visit("ch1_l2"); s.advance_search(5); s.visit("ch1_l1")
	expect(s.search_status() == frozen, "time in another room never advances the original search")
	var hint: Dictionary = s.request_search_hint()
	expect(hint.ok and hint.cost == 0 and hint.id == s.searches.ch1_l1.items[0].id and s.insight_balance() == 6, "first hint is free and selects an unfound object")
	before = s._record()
	expect(not s.request_search_hint().ok and before == s._record(), "cooldown blocks duplicate hint without charging")
	s.advance_search(44)
	expect(not s.request_search_hint().ok and s.search_status().hint_cooldown == 1, "hint requires 45 active seconds")
	s.advance_search(1)
	expect(s.request_search_hint().cost == 1 and s.insight_balance() == 5, "second hint costs one Insight")
	s.advance_search(45)
	expect(s.request_search_hint().cost == 1 and s.insight_balance() == 4, "third hint costs one Insight")
	s.advance_search(45)
	before = s._record()
	expect(not s.request_search_hint().ok and before == s._record() and s.search_status().hints_left == 0, "three-hint cap persists after cooldown")
	var duration: float = s.search_status().remaining
	for i in range(5):
		var miss: Dictionary = s.register_search_miss()
		if i == 2: expect(miss.warning and miss.penalty == 0, "third rapid miss warns without subtracting time")
		if i == 4: expect(miss.penalty == 10 and s.search_status().penalties == 1, "fifth rapid miss applies one ten-second penalty")
	expect(s.search_status().remaining == duration-10, "one burst subtracts exactly ten seconds")
	for i in range(4):
		s.register_search_miss(); s.advance_search(3.25)
	expect(s.search_status().penalties == 1, "spaced wrong clicks never accumulate into a burst")
	var first: String = s.searches.ch1_l1.items[0].id
	expect(s.find_search_object("ch1_l1",first).ok, "valid find is accepted with time remaining")
	before = s._record()
	expect(not s.find_search_object("ch1_l1",first).ok and before == s._record(), "repeat found object never counts as a miss")
	s = roundtrip(s)
	expect(s.advance_search(10000) and s.search_status().expired and s.search_status().remaining == 0, "clock stops exactly at zero")
	before = s._record()
	expect(not s.find_search_object("ch1_l1",s.searches.ch1_l1.items[1].id).ok and not s.request_search_hint().ok and not s.register_search_miss().ok and before == s._record(), "expired search blocks finds, hints and further miss penalties")
	expect(s.buy_search_time().ok and s.search_status().remaining == 30, "one Insight rescues an expired search for thirty seconds")
	expect(s.buy_search_time().ok and s.search_status().remaining == 60 and s.insight_balance() == 2, "second extension adds thirty seconds and charges once")
	before = s._record()
	expect(not s.buy_search_time().ok and before == s._record(), "two-extension cap cannot be exceeded")
	s = roundtrip(s)
	expect(s.search_status().hints_used == 3 and s.search_status().extensions == 2, "reload cannot refresh purchases or hint allowance")
	var near := fresh()
	near.advance_search(598)
	for i in range(5): near.register_search_miss()
	expect(near.search_status().expired and near.search_status().penalty_seconds == 2, "penalty at two seconds removes only remaining time")
	expect(near.buy_search_time().ok and near.search_status().remaining == 30, "rescue does not inherit negative time from a clipped penalty")
	roundtrip(near)

func _test_retry_and_rewards() -> void:
	var s := fresh()
	expect(clear_search(s,"ch1_l2").insight_awarded == 3 and s.insight_balance() == 9, "first clean room pays three Insight")
	expect(s.try_solve("p02","0050").insight_awarded == 1 and s.insight_balance() == 10, "first successful deduction pays one")
	var story := {"evidence":s.evidence.duplicate(),"inventory":s.inventory.duplicate(),"solved":s.solved.duplicate(),"other":s.search_progress.ch1_l2.duplicate()}
	s.visit("ch1_l1"); s.find_search_object("ch1_l1",s.searches.ch1_l1.items[0].id)
	s.request_search_hint(); s.advance_search(45); s.request_search_hint(); s.advance_search(45); s.request_search_hint()
	s.buy_search_time(); s.buy_search_time()
	var before: Dictionary = s._record()
	expect(not s.retry_search().ok and before == s._record(), "unfinished unexpired search cannot restart to reroll hints")
	s.advance_search(10000)
	s = roundtrip(s)
	var retried: Dictionary = s.retry_search()
	expect(retried.ok and retried.refunded == 4 and s.insight_balance() == 10, "retry refunds exactly two paid hints and two extensions")
	expect(not s.search_progress.has("ch1_l1") and s.search_status().remaining == 600 and s.search_status().hints_used == 0 and s.search_status().extensions == 0, "retry clears only current finds and resets full allowance")
	expect(s.evidence == story.evidence and s.inventory == story.inventory and s.solved == story.solved and s.search_progress.ch1_l2 == story.other, "retry preserves every other room and all story work")
	before = s._record()
	expect(not s.retry_search().ok and before == s._record(), "retry cannot refund the same purchase twice")
	for i in range(5): s.register_search_miss()
	expect(clear_search(s,"ch1_l1").insight_awarded == 2 and s.insight_balance() == 12, "penalized first clear pays two without the clean bonus")
	expect("p01" in s.solved and not s.detective.puzzle_rewards.has("p01"), "auto-resolved hidden task never duplicates the search reward")
	before = s._record()
	expect(not s.retry_search().ok and not s.buy_search_time().ok and not s.request_search_hint().ok and not s.try_solve("p01","found").ok and before == s._record(), "completed searches cannot be retried, charged, or farmed")
	roundtrip(s)

func _test_puzzles() -> void:
	var s := fresh()
	var before: Dictionary = s._record()
	s.advance_puzzle("p02",10)
	expect(not s.request_puzzle_hint("p02").ok and not s.try_solve("p02","0000").ok and before == s._record(), "unavailable puzzles cannot start clocks, consume hints or count errors")
	clear_search(s,"ch1_l2")
	before = s._record()
	expect(not s.try_solve("p02",123).ok and not s.try_solve("p02","").ok and before == s._record(), "incomplete or malformed answer does not count as wrong submission")
	expect(s.request_puzzle_hint("p02").cost == 0, "deduction has a separate free hint")
	s.advance_puzzle("p02",45)
	expect(s.request_puzzle_hint("p02").cost == 1, "second deduction hint costs one")
	s.advance_puzzle("p02",45)
	expect(s.request_puzzle_hint("p02").cost == 1, "third deduction hint costs one")
	s.advance_puzzle("p02",45)
	before = s._record()
	expect(not s.request_puzzle_hint("p02").ok and before == s._record(), "deduction hint cap is three")
	s.try_solve("p02","0000")
	before = s._record()
	expect(not s.try_solve("p02"," 00 00 ").ok and before == s._record(), "identical normalized repeat does not add a penalty")
	s.try_solve("p02","0001"); s.try_solve("p02","0002")
	expect(s.puzzle_status("p02").submit_cooldown == 10 and not s.puzzle_status("p02").can_submit, "three actual wrong submissions lock Submit for ten active seconds")
	s = roundtrip(s)
	before = s._record()
	expect(not s.try_solve("p02","0050").ok and before == s._record(), "correct answer cannot bypass saved submission cooldown")
	s.visit("ch1_l1"); s.advance_puzzle("p02",100); s.visit("ch1_l2")
	expect(s.puzzle_status("p02").submit_cooldown == 10, "leaving a puzzle freezes its active cooldown")
	s.advance_puzzle("p02",9)
	expect(not s.try_solve("p02","0050").ok, "submission remains locked until the last second")
	s.advance_puzzle("p02",1)
	expect(s.try_solve("p02","0050").insight_awarded == 1 and s.insight_balance() == 8, "correct retry succeeds once and awards one after hint spending")
	before = s._record()
	expect(not s.try_solve("p02","0050").ok and not s.request_puzzle_hint("p02").ok and before == s._record(), "completed deduction cannot repeat rewards or hints")
	before = s._record()
	expect(not s.try_solve("p07",["SHORE"]).ok and before == s._record(), "partial sequence submission never counts as an incorrect answer")
	clear_search(s,"ch1_l3")
	before = s._record()
	expect(not s.try_solve("p03","not an option").ok and before == s._record(), "invalid option cannot create a deduction penalty")
	s.try_solve("p03",s.get_puzzle("p03").options[0]); s.advance_puzzle("p03",61)
	s.try_solve("p03",s.get_puzzle("p03").options[1]); s.try_solve("p03",s.get_puzzle("p03").options[3])
	expect(s.puzzle_status("p03").submit_cooldown == 0, "wrong submissions older than sixty active seconds expire")
	roundtrip(s)

func _test_save_validation_and_migration() -> void:
	var s := fresh()
	clear_search(s,"ch1_l2"); s.try_solve("p02","0050")
	s.visit("ch1_l1"); s.find_search_object("ch1_l1",s.searches.ch1_l1.items[0].id)
	s.request_search_hint(); s.advance_search(45); s.request_search_hint(); s.buy_search_time()
	var valid: Dictionary = s._record()
	for damage in ["balance","hint_cap","extensions","clock","unknown","locked","unearned_reward","missing_reward","future_puzzle","wrong_events"]:
		var bad: Dictionary = valid.duplicate(true)
		match damage:
			"balance": bad.detective.insight += 1
			"hint_cap": bad.detective.searches.ch1_l1.hints_used = 4
			"extensions": bad.detective.searches.ch1_l1.extensions = 3
			"clock": bad.detective.searches.ch1_l1.remaining += 20
			"unknown": bad.detective.searches.unknown = bad.detective.searches.ch1_l1.duplicate(true)
			"locked": bad.detective.searches.ch2_l1 = s.detective.default_search(s._search_duration("ch2_l1"))
			"unearned_reward": bad.detective.search_rewards.ch1_l1 = 3; bad.detective.insight += 3
			"missing_reward": bad.detective.search_rewards.erase("ch1_l2"); bad.detective.insight -= 3
			"future_puzzle": bad.detective.puzzles.p04 = s.detective.default_puzzle()
			"wrong_events": bad.detective.puzzles.p02.wrong_submissions = [5.0]
		write_save(bad)
		expect(not s.load_game(SAVE) and s._record() == valid, "corrupt ledger rejected transactionally: " + damage)
	var legacy: Dictionary = valid.duplicate(true)
	legacy.version = 3; legacy.erase("detective")
	write_save(legacy)
	expect(s.load_game(SAVE), "untimed version-three progress migrates")
	expect(s.search_progress == legacy.search_progress and s.evidence == legacy.evidence and s.solved == legacy.solved and s.inventory == legacy.inventory, "v3 migration preserves partial searches and all story collections exactly")
	expect(s.insight_balance() == 6 and s.search_status().remaining == 600 and s.search_status().hints_used == 0, "migrated partial search receives one full first attempt and six starting Insight")
	expect(s.detective.search_rewards.ch1_l2 == 0 and s.detective.puzzle_rewards.p02 == 0, "previous completed rooms and puzzles are already claimed without retroactive rewards")
	s = roundtrip(s)
	var before: Dictionary = s._record()
	s.visit("ch1_l2")
	expect(not s.try_solve("p02","0050").ok and s.insight_balance() == 6, "migrated completed deduction cannot farm a new reward")
	s.visit("ch1_l1")
	expect(before == s._record(), "revisiting completed legacy progress makes no ledger changes")
	expect(clear_search(s,"ch1_l1").insight_awarded == 3 and s.insight_balance() == 9, "formerly partial legacy room earns its first completion reward")
	roundtrip(s)

func _test_inventory() -> void:
	var s := fresh()
	clear_search(s,"ch1_l3"); s.try_solve("p03",s.get_puzzle("p03").solution)
	clear_search(s,"ch1_l4")
	expect("tissue" in s.active_inventory() and "paste" in s.active_inventory(), "uncombined ingredients remain visible while their recipe is needed")
	expect(s.combine("tissue","paste").ok, "recipe makes its combined item")
	expect("tissue" not in s.active_inventory() and "paste" not in s.active_inventory() and "repair_kit" in s.active_inventory(), "combined result replaces both visible ingredients")
	expect("tissue" in s.inventory and "paste" in s.inventory and "repair_kit" in s.inventory, "complete collection history preserves recipe provenance")
	expect(s.try_solve("p04","assembled").ok and "repair_kit" not in s.active_inventory() and "repair_kit" in s.archived_inventory(), "finished tool retires only after its remaining investigation is complete")
	roundtrip(s)

func _test_empty_bank() -> void:
	var s := fresh()
	s.request_search_hint(); s.advance_search(45); s.request_search_hint(); s.advance_search(45); s.request_search_hint()
	s.buy_search_time(); s.buy_search_time()
	s.visit("ch1_l2"); s.buy_search_time(); s.buy_search_time()
	expect(s.insight_balance() == 0, "authorized purchases can exhaust the shared bank without becoming negative")
	expect(s.request_search_hint().ok, "a room's first free hint still works with no Insight")
	s.advance_search(45)
	var before: Dictionary = s._record()
	expect(not s.request_search_hint().ok and before == s._record(), "unaffordable paid hint does not consume a hint or mutate the ledger")
	s.visit("ch1_l3")
	before = s._record()
	expect(not s.buy_search_time().ok and before == s._record(), "unaffordable extension cannot change time or allowance")
	s.visit("ch1_l2"); s.advance_search(10000)
	expect(s.retry_search().refunded == 2 and s.insight_balance() == 2, "bankruptcy retry refunds only this room's spending")
	s.visit("ch1_l1")
	expect(s.search_status().hints_used == 3 and s.search_status().extensions == 2, "another room's purchases and hint caps survive bankruptcy recovery")
	roundtrip(s)
	var future := fresh()
	clear_search(future,"ch1_l3"); future.try_solve("p03",future.get_puzzle("p03").solution)
	clear_search(future,"ch1_l4"); future.combine("tissue","paste")
	# A future content revision can use a tool twice: retire only after both uses.
	future.get_puzzle("p05").items.append("repair_kit")
	future.try_solve("p04","assembled")
	expect("repair_kit" in future.active_inventory(), "tool with another unfinished use stays in the active inventory")
	future.try_solve("p05",future.get_puzzle("p05").solution)
	expect("repair_kit" not in future.active_inventory() and "repair_kit" in future.inventory, "tool retires after its final use while history remains")
