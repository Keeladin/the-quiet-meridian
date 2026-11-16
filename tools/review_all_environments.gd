extends SceneTree
## Native review captures, not a gameplay or pacing test.
## Run with isolated XDG directories and no --headless argument.
## --script tools/review_all_environments.gd -- --output-dir=/repository/work/env-full-review
const Stage = preload("res://scripts/environment_stage.gd")
const POSES := [0.0,1.25,2.5,3.75]
var output_dir := ""
var failures: Array[String] = []
var results: Array = []
var selected_locations: PackedStringArray = []

class Guides extends Control:
	var profile: Dictionary
	func _draw() -> void:
		for kind in ["water","water_exclusions","fog"]:
			var color: Color = {"water":Color.CYAN,"water_exclusions":Color.WHITE,"fog":Color.GREEN}[kind]
			for region in profile.get(kind,[]):
				var rect := Rect2(Vector2(region[0],region[1])*size,Vector2(region[2],region[3])*size)
				draw_rect(rect,color,false,1.7)
		for lamp in profile.get("lamps",[]):
			draw_set_transform(Vector2(lamp[0],lamp[1])*size,0.0,Vector2(lamp[2]*size.x,lamp[3]*size.y))
			draw_arc(Vector2.ZERO,1.0,0.0,TAU,32,Color.GOLD,0.035,true)
			draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
			draw_circle(Vector2(lamp[0],lamp[1])*size,3,Color.GOLD)
		for mechanism in profile.get("mechanisms",[]):
			var region: Array = mechanism.rect
			draw_rect(Rect2(Vector2(region[0],region[1])*size,Vector2(region[2],region[3])*size),Color.MAGENTA,false,2.0)
		for steam in profile.get("steam",[]):
			var origin := Vector2(steam[0],steam[1])*size
			draw_line(origin,origin-Vector2(0,steam[3]*size.y),Color.ORANGE,2.0)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Native Compatibility renderer required; this harness must not claim headless image evidence.")
		quit(2)
		return
	output_dir = ProjectSettings.globalize_path("res://work/env-full-review")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="): output_dir = argument.trim_prefix("--output-dir=")
		if argument.begins_with("--locations="): selected_locations = argument.trim_prefix("--locations=").split(",",false)
	if not output_dir.simplify_path().begins_with(ProjectSettings.globalize_path("res://work/")):
		printerr("Review captures must stay inside repository work/.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DisplayServer.window_set_size(Vector2i(1280,720))
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/game.json"))
	var profile_source := FileAccess.get_file_as_string("res://content/environment-effects.json")
	var profiles: Dictionary = JSON.parse_string(profile_source)
	var snapshot := FileAccess.open(output_dir.path_join("environment-effects.snapshot.json"),FileAccess.WRITE)
	snapshot.store_string(profile_source)
	snapshot.close()
	for id in selected_locations:
		if not profiles.has(id):
			printerr("Unknown review location: "+id)
			quit(2)
			return
	for location in content.locations:
		if not selected_locations.is_empty() and not location.id in selected_locations: continue
		await _capture_location(location,profiles[location.id])
	if selected_locations.is_empty():
		for chapter in range(1,7):
			await _contact_sheet(chapter,"guides",content)
			await _contact_sheet(chapter,"pose-3",content)
	var revision: Array = []
	OS.execute("git",["rev-parse","HEAD"],revision)
	var report := {
		"utc":Time.get_datetime_string_from_system(true)+"Z",
		"source_revision":str(revision[0]).strip_edges() if not revision.is_empty() else "unknown",
		"engine":Engine.get_version_info().string,
		"display_server":DisplayServer.get_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(),
		"video_adapter":RenderingServer.get_video_adapter_name(),
		"resolution":[1280,720],"pose_seconds":POSES,"changed_pixel_sampling_stride":4,
		"profiles_sha256":FileAccess.get_sha256(output_dir.path_join("environment-effects.snapshot.json")),
		"stage_sha256":FileAccess.get_sha256("res://scripts/environment_stage.gd"),
		"shader_sha256":FileAccess.get_sha256("res://shaders/environment_water.gdshader"),
		"scope":"Native render/effect review; not gameplay, duration, comfort or release acceptance.",
		"scenes":results,"failures":failures
	}
	var file := FileAccess.open(output_dir.path_join("render-report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	print("ENVIRONMENT_FULL_REVIEW_"+("OK" if failures.is_empty() else "FAILED")+": %d native scenes; exact reduced-motion identity; four motion poses; report %s" % [results.size(),output_dir])
	quit(0 if failures.is_empty() else 1)

func _capture_location(location: Dictionary, profile: Dictionary) -> void:
	var stage := Stage.new()
	root.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.configure(load(location.art),profile,false)
	var first: Image
	var changes: Array = []
	var last: Image
	var start_ms := Time.get_ticks_msec()
	for index in range(POSES.size()):
		stage.set_visual_time(POSES[index])
		var capture: Image = await _capture()
		_save(capture,location.id+"-pose-%d.png" % index)
		if index == 0: first = capture
		else: changes.append(_changed_samples(first,capture))
		last = capture
	stage.set_reduced_motion(true)
	var reduced: Image = await _capture()
	stage.advance(1.0)
	stage.pulse_at(Vector2(0.5,0.5))
	var reduced_later: Image = await _capture()
	var identical: bool = reduced.get_data() == reduced_later.get_data()
	_save(reduced,location.id+"-reduced.png")
	var guides := Guides.new()
	guides.profile = profile
	guides.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(guides)
	guides.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_save(await _capture(),location.id+"-guides.png")
	var heatmap := Image.create(320,180,false,Image.FORMAT_RGB8)
	for y in range(180):
		for x in range(320):
			var a := first.get_pixel(x*4,y*4)
			var b := last.get_pixel(x*4,y*4)
			var delta := maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
			heatmap.set_pixel(x,y,Color(minf(delta*18.0,1.0),minf(delta*3.0,0.6),0.0))
	heatmap.resize(1280,720,Image.INTERPOLATE_NEAREST)
	_save(heatmap,location.id+"-difference.png")
	var any_motion := false
	for value in changes: any_motion = any_motion or value > 0
	if not any_motion: failures.append(location.id+": no animated pixel difference")
	if not identical: failures.append(location.id+": reduced-motion frames differ")
	results.append({"id":location.id,"name":location.title,"changed_samples_from_first_pose":changes,
		"sample_count":57600,"reduced_motion_pixel_identical":identical,
		"water_regions":profile.water.size(),"lamps":profile.lamps.size(),"mechanisms":profile.mechanisms.size(),
		"capture_elapsed_ms":Time.get_ticks_msec()-start_ms})
	print(location.id+": changes="+str(changes)+"; reduced identical="+str(identical))
	stage.queue_free()
	await process_frame

func _contact_sheet(chapter: int, suffix: String, content: Dictionary) -> void:
	root.content_scale_size = Vector2i(1440,660)
	DisplayServer.window_set_size(Vector2i(1440,660))
	var sheet := Control.new()
	root.add_child(sheet)
	var background := ColorRect.new()
	background.color = Color(0.025,0.035,0.04)
	background.size = Vector2(1440,660)
	sheet.add_child(background)
	var heading := Label.new()
	heading.text = "Chapter %d — %s | cyan water · white exclusions · green fog · gold lamps · magenta mechanisms" % [chapter,suffix]
	heading.position = Vector2(12,8)
	heading.add_theme_font_size_override("font_size",18)
	sheet.add_child(heading)
	for index in range(6):
		var id := "ch%d_l%d" % [chapter,index+1]
		var texture := ImageTexture.create_from_image(Image.load_from_file(output_dir.path_join(id+"-"+suffix+".png")))
		var image_rect := TextureRect.new()
		image_rect.texture = texture
		image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image_rect.stretch_mode = TextureRect.STRETCH_SCALE
		image_rect.size = Vector2(480,270)
		image_rect.position = Vector2((index%3)*480,40+(index/3)*310)
		sheet.add_child(image_rect)
		var label := Label.new()
		var title: String = id
		for location in content.locations:
			if location.id == id: title += " — "+location.title
		label.text = title
		label.position = image_rect.position+Vector2(8,273)
		label.add_theme_font_size_override("font_size",18)
		sheet.add_child(label)
	_save(await _capture(),"chapter-%d-%s.png" % [chapter,suffix])
	sheet.queue_free()
	await process_frame

func _capture() -> Image:
	await process_frame
	# A backgrounded review window may stop presenting automatic frames.
	# Force the real Compatibility renderer before synchronous image readback.
	RenderingServer.force_draw(true)
	return root.get_texture().get_image()

func _save(image: Image, filename: String) -> void:
	if image.save_png(output_dir.path_join(filename)) != OK: failures.append("Failed to save "+filename)

func _changed_samples(first: Image, second: Image) -> int:
	var count := 0
	for y in range(0,first.get_height(),4):
		for x in range(0,first.get_width(),4):
			if first.get_pixel(x,y) != second.get_pixel(x,y): count += 1
	return count
