extends SceneTree
const State=preload("res://scripts/game_state.gd")
const CityMap=preload("res://scripts/city_map.gd")
var checks:=0
var failures:=0
var state:RefCounted
var map:Control
var host:MarginContainer
var screenshots:=""
var requests:Array[String]=[]
func _initialize()->void:call_deferred("run_checks")
func expect(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("CITY MAP FAIL: ",message)
func settle()->void:
	for i in range(10):await process_frame
func run_checks()->void:
	var project:=ProjectSettings.globalize_path("res://").trim_suffix("/")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			screenshots=arg.trim_prefix("--screenshots=").simplify_path()
			if not screenshots.begins_with(project+"/work/") or DisplayServer.get_name()=="headless":quit(2);return
			DirAccess.make_dir_recursive_absolute(screenshots)
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1280,800)
	root.content_scale_size=Vector2i(1600,1000)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	state=State.new();expect(state.load_content(),"campaign loads")
	host=MarginContainer.new();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:host.add_theme_constant_override("margin_"+edge,45)
	map=CityMap.new();map.campaign=state;host.add_child(map)
	map.travel_requested.connect(func(id:String):requests.append(id))
	await settle()
	expect(root.get_visible_rect().encloses(map.get_global_rect()),"overview including legend fits viewport")
	expect(map.data.districts.size()==6 and map.pin_buttons.size()==6,"overview has six district pins")
	expect(map.surface.painting.get_size()==Vector2(1600,1000),"original geographic map loads")
	var names:=[]
	for label in map.room_labels.values():names.append(label.text)
	expect("Old Harbour" in names and "Civic Quarter" not in names and names.count("Uncharted")==5,"future district names stay concealed")
	var first_snapshot:Dictionary=state._record()
	map.show_district("civic");await settle()
	expect(map.selected_district.is_empty() and map.travel_button==null,"locked district offers no travel")
	expect(state._record()==first_snapshot and requests.is_empty(),"browsing locked map does not change progress")
	map.show_city();await settle();await capture("city-overview")
	map.pin_buttons.old_harbour.pressed.emit();await settle()
	expect(map.selected_district=="old_harbour" and map.pin_buttons.size()==6,"district pin opens six geographic room pins")
	map.pin_buttons.ch1_l3.grab_focus();await settle()
	expect(map.selected_location=="ch1_l3" and map.travel_button!=null,"keyboard focus reveals room travel card")
	map.pin_buttons.ch1_l2.pressed.emit();await settle()
	expect(map.selected_location=="ch1_l2" and map.travel_button!=null,"room pin opens its travel card")
	map.travel_button.pressed.emit()
	expect(requests==["ch1_l2"] and state.location_id=="ch1_l1","travel emits chosen destination without mutating campaign")
	expect(map.location_status("ch1_l2")=="unsearched","unfinished room has search status")
	state.search_progress.ch1_l2=[]
	for item in state.searches.ch1_l2.items:state.search_progress.ch1_l2.append(item.id)
	expect(map.location_status("ch1_l2")=="investigation","completed search retains unfinished investigation status")
	for puzzle in state.data.puzzles:
		if puzzle.location=="ch1_l2":state.solved.append(puzzle.id)
	expect(map.location_status("ch1_l2")=="resolved","resolved room has distinct complete status")
	map.show_district("old_harbour");map.select_location("ch1_l2");await settle();await capture("harbour-detail")
	# Unlock the remaining geography solely for presentation checks; no saves written.
	for chapter in state.data.chapters:
		if chapter.final_puzzle not in state.solved:state.solved.append(chapter.final_puzzle)
	var ids:=[]
	for large in [false,true]:
		state.settings.large_text=large
		map.queue_free();await settle();map=CityMap.new();map.campaign=state;host.add_child(map);await settle()
		for district in map.data.districts:
			map.show_district(district.id);await settle()
			for room in district.rooms:
				if not large:ids.append(room.location)
				var pin:Control=map.pin_buttons[room.location]
				expect(map.surface.get_global_rect().grow(1).encloses(pin.get_global_rect()),"room pin remains inside map: "+room.location)
				expect(not pin.accessibility_name.is_empty() and not pin.tooltip_text.is_empty(),"pin has accessible status and label: "+room.location)
				map.select_location(room.location);await settle()
				expect(map.get_global_rect().grow(1).encloses(map.travel_button.get_global_rect()),"travel action fits component: "+room.location)
			if not large:await capture(district.id+"-detail")
		await capture("large-text" if large else "detail")
	expect(ids.size()==36 and _unique(ids).size()==36,"all 36 campaign rooms occur exactly once")
	root.size=Vector2i(960,600);await settle()
	for district in map.data.districts:
		map.show_district(district.id);map.select_location(district.rooms[0].location);await settle()
		expect(root.get_visible_rect().encloses(map.get_global_rect()),"large text map fits minimum window: "+district.id)
		expect(map.get_child(map.get_child_count()-1).size.y<=70,"status legend remains a readable horizontal row: "+district.id)
		for label in map.room_labels.values():
			expect(map.surface.get_global_rect().grow(1).encloses(label.get_global_rect()),"room label fits map at minimum window: "+label.text)
	await capture("minimum-window-large-text")
	map.show_city();await settle();await capture("all-districts")
	map.queue_free();host.queue_free();await settle();map=null;state=null
	print("CITY_MAP_"+("OK" if failures==0 else "FAILED")+": %d checks; six districts, 36 room pins, status gating and travel actions"%checks)
	quit(0 if failures==0 else 1)
func _unique(values:Array)->Array:
	var result:=[]
	for value in values:
		if value not in result:result.append(value)
	return result
func capture(name:String)->void:
	if screenshots.is_empty():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(screenshots.path_join(name+".png"))
