extends SceneTree
## Deterministic environmental motion tests; optional actual renderer previews.
## --headless --path . --script tests/test_environment.gd
## Native: --script tests/test_environment.gd -- --preview-dir=/absolute/repo/work/environment-preview
const Stage = preload("res://scripts/environment_stage.gd")
var checks := 0
var failures := 0
var preview_dir := ""
var profiles: Dictionary
var stage: Control

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--preview-dir="):
			preview_dir = argument.trim_prefix("--preview-dir=")
			var permitted := ProjectSettings.globalize_path("res://work/")
			if not preview_dir.begins_with(permitted):
				printerr("ENVIRONMENT_TEST_REFUSED: previews must stay under repository work/")
				quit(2)
				return
			DirAccess.make_dir_recursive_absolute(preview_dir)
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/game.json"))
	profiles = JSON.parse_string(FileAccess.get_file_as_string("res://content/environment-effects.json"))
	_expect(profiles.size() == 36,"every authored environment has an effects profile")
	var seen := {}
	var water_total := 0
	var machinery_total := 0
	for location in content.locations:
		_expect(profiles.has(location.id),"profile exists for " + location.id)
		if not profiles.has(location.id): continue
		seen[location.id] = true
		var profile: Dictionary = profiles[location.id]
		for kind in ["water","water_exclusions","fog","lamps"]:
			var limit: int = {"water":4,"water_exclusions":8,"fog":3,"lamps":8}[kind]
			_expect(profile[kind].size() <= limit,"shader region budget: " + location.id + "/" + kind)
			for region in profile[kind]:
				_expect(region.size() == 4,"region has four normalized dimensions")
				_expect(float(region[0]) >= 0 and float(region[1]) >= 0 and float(region[2]) > 0 and float(region[3]) > 0,"positive normalized region: " + location.id)
				if kind != "lamps":
					_expect(float(region[0])+float(region[2]) <= 1.001 and float(region[1])+float(region[3]) <= 1.001,"region stays within painting: " + location.id)
		_expect(profile.mechanisms.size() <= 4,"mechanism shader budget")
		_expect(profile.particles >= 0 and profile.particles <= 48,"bounded particle cost")
		_expect(not str(profile.placement_notes).is_empty(),"placement rationale recorded")
		for mechanism in profile.mechanisms:
			_expect(absf(float(mechanism.displacement[0])) <= 0.003 and absf(float(mechanism.displacement[1])) <= 0.003,"mechanical distortion stays subtle")
		water_total += profile.water.size()
		machinery_total += profile.mechanisms.size()
		stage = Stage.new()
		stage.size = Vector2(960,540)
		root.add_child(stage)
		stage.configure(load(location.art),profile,false)
		stage.set_visual_time(0)
		_expect(stage.mouse_filter == Control.MOUSE_FILTER_IGNORE,"stage does not intercept hotspots")
		for child in stage.get_children():
			_expect(child.mouse_filter == Control.MOUSE_FILTER_IGNORE,"stage child passes input through")
		var first: Dictionary = stage.effect_snapshot()
		stage.advance(0.25)
		_expect(stage.effect_snapshot().time > first.time,"ambient clock advances")
		stage.pulse_at(Vector2(0.4,0.5))
		_expect(stage.effect_snapshot().pulse_count == 1,"interaction feedback starts")
		stage.advance(1.0)
		_expect(stage.effect_snapshot().pulse_count == 0,"feedback expires instead of accumulating")
		stage.pulse_at(Vector2(0.4,0.5))
		stage.set_reduced_motion(true)
		var frozen: Dictionary = stage.effect_snapshot()
		stage.advance(0.75)
		stage.pulse_at(Vector2(0.4,0.5))
		_expect(stage.effect_snapshot() == frozen,"reduced motion freezes ambient state and suppresses pulses")
		_expect(float(stage.shader_material.get_shader_parameter("motion")) == 0.0,"reduced motion restores untouched illustration")
		stage.set_reduced_motion(false)
		stage.advance(0.25)
		_expect(stage.effect_snapshot().time > frozen.time,"animation resumes without replacing stage")
		stage.queue_free()
		await process_frame
	_expect(seen.size() == profiles.size(),"no orphaned profile IDs")
	_expect(water_total > 24 and machinery_total > 5,"pass contains local water and mechanical motion, not a global camera pan")
	if not preview_dir.is_empty() and DisplayServer.get_name() != "headless":
		await _render_previews(content)
		await _render_mask_test(content)
	print("ENVIRONMENT_TESTS_" + ("OK" if failures == 0 else "FAILED") + ": %d assertions; 36 scenes; localized water/fog/light/weather/mechanisms; deterministic reduced motion and bounded feedback" % checks)
	quit(0 if failures == 0 else 1)

func _render_previews(content: Dictionary) -> void:
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DisplayServer.window_set_size(Vector2i(1280,720))
	for id in ["ch1_l1","ch2_l3","ch4_l1","ch6_l6"]:
		var location: Dictionary = {}
		for candidate in content.locations:
			if candidate.id == id: location = candidate
		stage = Stage.new()
		root.add_child(stage)
		stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stage.configure(load(location.art),profiles[id],false)
		stage.set_visual_time(0.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var first := root.get_texture().get_image()
		_expect(first.save_png(preview_dir.path_join(id+"-00.png")) == OK,"first native frame saved")
		stage.set_visual_time(3.7)
		await process_frame
		await RenderingServer.frame_post_draw
		var second := root.get_texture().get_image()
		_expect(second.save_png(preview_dir.path_join(id+"-37.png")) == OK,"later native frame saved")
		var changed := _pixel_changes(first,second)
		_expect(changed > 50,"native output actually animates " + id)
		stage.set_reduced_motion(true)
		await process_frame
		await RenderingServer.frame_post_draw
		var frozen := root.get_texture().get_image()
		stage.advance(1.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var frozen_later := root.get_texture().get_image()
		_expect(_pixel_changes(frozen,frozen_later) == 0,"native reduced-motion frames match exactly " + id)
		_expect(frozen.save_png(preview_dir.path_join(id+"-reduced.png")) == OK,"static accessibility frame saved")
		# A short deterministic frame sequence is a shareable proof of motion,
		# independent of playthrough speed or camera motion.
		if id == "ch1_l1":
			stage.set_reduced_motion(false)
			var sequence := preview_dir.path_join("sequence")
			DirAccess.make_dir_recursive_absolute(sequence)
			for frame in range(48):
				stage.set_visual_time(float(frame)/12.0)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(sequence.path_join("frame-%03d.png" % frame))
		stage.queue_free()
		await process_frame

func _render_mask_test(content: Dictionary) -> void:
	var location: Dictionary = content.locations[0]
	var water_only: Dictionary = profiles["ch1_l1"].duplicate(true)
	water_only.fog = []
	water_only.lamps = []
	water_only.mechanisms = []
	water_only.steam = []
	water_only.particles = 0
	stage = Stage.new()
	root.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.configure(load(location.art),water_only,false)
	stage.set_visual_time(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var first := root.get_texture().get_image()
	stage.set_visual_time(3.7)
	await process_frame
	await RenderingServer.frame_post_draw
	var second := root.get_texture().get_image()
	var leaked_changes := 0
	var protected_changes := 0
	var changed_water := 0
	for y in range(0,first.get_height(),4):
		for x in range(0,first.get_width(),4):
			var uv := Vector2((float(x)+0.5)/first.get_width(),(float(y)+0.5)/first.get_height())
			var on_water := false
			var protected := false
			for region in water_only.water:
				on_water = on_water or Rect2(region[0],region[1],region[2],region[3]).has_point(uv)
			for region in water_only.water_exclusions:
				var rect := Rect2(region[0],region[1],region[2],region[3])
				protected = protected or Rect2(rect.position+rect.size*0.12,rect.size*0.76).has_point(uv)
			if first.get_pixel(x,y) == second.get_pixel(x,y): continue
			if not on_water: leaked_changes += 1
			if protected: protected_changes += 1
			if on_water and not protected: changed_water += 1
	_expect(leaked_changes == 0,"water shader leaves pixels outside authored masks exactly unchanged")
	_expect(protected_changes == 0,"water exclusions preserve foreground architecture exactly")
	_expect(changed_water > 10,"water-only render changes actual surface pixels")
	stage.queue_free()
	await process_frame

func _pixel_changes(first: Image, second: Image) -> int:
	if first.get_size() != second.get_size(): return -1
	var count := 0
	for y in range(0,first.get_height(),6):
		for x in range(0,first.get_width(),6):
			if first.get_pixel(x,y) != second.get_pixel(x,y): count += 1
	return count

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("ENVIRONMENT FAIL: ",description)
