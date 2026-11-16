extends SceneTree
const Search = preload("res://scripts/hidden_object_state.gd")
var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	var scenes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/hidden-object-scenes.json"))
	var observations: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/campaign_search_observations.json"))
	for location in scenes:
		var scene: Dictionary = scenes[location]
		var search := Search.new()
		expect(search.configure(scene), "definition validates " + location)
		expect(observations.has(location), "independent observations exist " + location)
		if not observations.has(location): continue
		for id in observations[location].interiors:
			var p: Array = observations[location].interiors[id]
			expect(search.hit_at(Vector2(p[0], p[1])) == id, location + "/" + id + " matches its observed visible interior")
		for id in observations[location].alternatives:
			for p in observations[location].alternatives[id]:
				expect(search.hit_at(Vector2(p[0], p[1])) == id, location + "/" + id + " alternate depiction is accepted")
		for item in scene.items:
			expect(search.find_object(item.id), "find " + location + "/" + item.id)
			expect(not search.find_object(item.id), "repeat cannot award " + location + "/" + item.id)
		expect(search.complete(), "all listed targets complete " + location)
	if failures: printerr("CAMPAIGN_SEARCH_ART_FAILED: ", failures, "/", checks)
	else: print("CAMPAIGN_SEARCH_ART_OK: ", checks, " across ", scenes.size(), " scenes")
	quit(1 if failures else 0)
