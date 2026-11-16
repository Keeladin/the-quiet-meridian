extends SceneTree

const Stage = preload("res://scripts/character_stage.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _run() -> void:
	var stage := Stage.new()
	root.add_child(stage)
	stage.size = Vector2(320, 320)
	stage.set_process(false)
	for id in ["iona", "mara", "rowan", "nadi", "sera", "elian", "ada"]:
		var texture: Texture2D = load("res://assets/art/characters/" + id + "-expressions.png")
		expect(texture != null, id + " packaged atlas loads")
		if texture == null: continue
		expect(texture.get_width() == texture.get_height() * 2, id + " eight equal square cells")
		var source_image := Image.new()
		source_image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/art/characters/" + id + "-expressions.png"))
		expect(source_image.detect_alpha() != Image.ALPHA_NONE, id + " alpha preserved in source")
		stage.configure(id, texture, false)
		stage.set_emotion("neutral")
		stage.set_speaking(false)
		var idle_frames := {}
		for step in 120:
			stage.set_visual_time(step * 0.05)
			idle_frames[stage.pose_snapshot().frame] = true
		expect(idle_frames.has(0) and idle_frames.has(1), id + " resting and painted blink frames appear")
		expect(not idle_frames.has(2) and not idle_frames.has(3), id + " no false speaking without voice")
		stage.set_speaking(true)
		var speaking_frames := {}
		for step in 160:
			stage.set_visual_time(step * 0.05)
			speaking_frames[stage.pose_snapshot().frame] = true
		expect(speaking_frames.has(2) and speaking_frames.has(3) and speaking_frames.has(6), id + " speech and hand frames cycle")
		stage.set_speaking(false)
		stage.set_emotion("concern")
		stage.set_reduced_motion(true)
		var snapshot: Dictionary = stage.pose_snapshot()
		stage.set_visual_time(1000.0)
		stage._process(10.0)
		expect(snapshot == stage.pose_snapshot(), id + " reduced motion freezes time and pose")
		expect(int(snapshot.frame) == 5, id + " concern remains available without motion")
		stage.set_speaking(true)
		expect(stage.pose_snapshot().frame == 5, id + " reduced motion does not animate mouth")
		stage.set_emotion("relief")
		expect(stage.pose_snapshot().frame == 4, id + " static relief remains expressive")
		expect(stage.get_child(0).texture.atlas == texture, id + " changing speaker replaces actual texture")
		stage.set_speaking(false)
	stage.free()
	if failures.is_empty(): print("CHARACTER_TESTS_OK: ", checks, " checks; seven painted expression sheets, speech gating, blink/gesture poses and reduced motion")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
