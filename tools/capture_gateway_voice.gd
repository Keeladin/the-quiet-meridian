extends SceneTree
## Native review of the installed production candidates; isolated player state.

var game: Control
var output := "res://work/gateway-voice/native-review/"
var report: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	assert(ProjectSettings.globalize_path("user://").begins_with(project + "/work/"))
	DirAccess.make_dir_recursive_absolute(output + "screenshots")
	# Decode and exercise playback without repeatedly sounding automated dialogue.
	AudioServer.set_bus_mute(0, true)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.state.new_game()
	game.state.settings.merge({"fullscreen":false,"auto_voice":true,"subtitles":true}, true)
	game._apply_audio()
	game.playing = true
	for size in [Vector2i(1920,1080), Vector2i(960,600)]:
		# Fullscreen avoids the window manager shrinking a 1080p window to
		# the desktop's usable height. Verify rendered pixels before naming it.
		root.mode = Window.MODE_FULLSCREEN if size == Vector2i(1920,1080) else Window.MODE_WINDOWED
		await create_timer(0.4).timeout
		if size != Vector2i(1920,1080): root.size = size
		await create_timer(0.4).timeout
		for conversation_id in ["nadi_arrival", "mara_refuge"]:
			var conversation: Dictionary = {}
			for entry in game.dialogue_data:
				if entry.id == conversation_id: conversation = entry; break
			assert(not conversation.is_empty())
			game.state.location_id = conversation.location
			game._show_location()
			game._conversation(conversation, str(conversation.topics[0].reply), 0)
			var expected: String = str(conversation_id) + "_r0"
			var started_msec := Time.get_ticks_msec()
			while game.audio.current_line_id() != expected or not game.audio.is_voice_active():
				assert(Time.get_ticks_msec()-started_msec < 30000, "Actual question/reply playback did not advance")
				await create_timer(0.03).timeout
			# The reply signal precedes deferred container/layout updates.
			await create_timer(0.3).timeout
			_redraw_controls(game.overlay)
			await process_frame
			await RenderingServer.frame_post_draw
			var name := "%dx%d-%s.png" % [size.x,size.y,conversation_id]
			var captured := root.get_texture().get_image()
			assert(captured.get_size() == size, "Capture dimensions differ from requested review size")
			assert(captured.save_png(output + "screenshots/" + name) == OK)
			report.append({"file":name,"line_id":expected,"voice_path":game.voice_catalog.lines[expected].path,
				"rendered_size":[captured.get_width(),captured.get_height()],
				"controls":_button_snapshot(game.overlay),
				"audio":game.audio.debug_state(),"pose":game.character_stage.pose_snapshot(),
				"subtitle_visible":game.subtitle_label.visible,"subtitle":game.subtitle_label.text})
			game._close_modal()
			await create_timer(0.15).timeout
	game.stop_audio_for_exit()
	var file := FileAccess.open(output + "capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures":report,"scope":"Actual local voice resources in native Godot UI; technical playback evidence, not subjective listening acceptance."},"\t")+"\n")
	file.close()
	# Let the audio mixer release streams before destroying its players.
	await create_timer(0.25).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("GATEWAY_VOICE_CAPTURE_OK: four actual-voice screenshots across two native resolutions")
	quit(0)

func _button_snapshot(node: Node) -> Array:
	var result: Array = []
	if node is Button:
		var bounds: Rect2 = node.get_global_rect()
		result.append({"text":node.text,"visible":node.is_visible_in_tree(),
			"rect":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y]})
	for child in node.get_children(): result.append_array(_button_snapshot(child))
	return result

func _redraw_controls(node: Node) -> void:
	if node is CanvasItem: node.queue_redraw()
	for child in node.get_children(): _redraw_controls(child)
