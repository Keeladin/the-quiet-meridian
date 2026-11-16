extends Control

const SAMPLE_ART = preload("res://assets/art/setup-key.png")

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	center.add_child(layout)
	var heading := Label.new()
	heading.text = "MYSTERY GAME"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	layout.add_child(heading)
	var picture := TextureRect.new()
	picture.texture = SAMPLE_ART
	picture.custom_minimum_size = Vector2(240, 240)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layout.add_child(picture)
	var description := Label.new()
	description.text = "Development workspace ready\nFull-length adventure development has not started."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 20)
	layout.add_child(description)
	var detail := Label.new()
	detail.text = "Original artwork · Godot 4 · Windows + Linux"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.modulate = Color(0.65, 0.75, 0.76)
	layout.add_child(detail)
	if "--setup-smoke-test" in OS.get_cmdline_user_args():
		await _smoke_test()

func _smoke_test() -> void:
	if SAMPLE_ART.get_width() < 1 or SAMPLE_ART.get_height() < 1:
		_fail("Packaged texture did not load")
		return
	# This verifies writable user storage, not a future game's save system.
	var path := "user://setup-storage-probe.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Cannot write user storage")
		return
	file.store_string(JSON.stringify({"probe": "mystery-game-setup"}))
	file.close()
	var restored = JSON.parse_string(FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not restored is Dictionary or restored.get("probe") != "mystery-game-setup":
		_fail("User storage round trip failed")
		return
	for index in range(8):
		await get_tree().process_frame
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--setup-screenshot=") and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var result := get_viewport().get_texture().get_image().save_png(argument.trim_prefix("--setup-screenshot="))
			if result != OK:
				_fail("Screenshot could not be written")
				return
	print("SETUP_SMOKE_OK: scene, original texture, and user storage")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
