extends VBoxContainer
## A geographic city overview and district detail. This view never changes progress.
signal travel_requested(location_id: String)
const BODY = preload("res://assets/fonts/body.ttf")
const DISPLAY = preload("res://assets/fonts/display.ttf")
const PAPER := Color("eee5cf")
const GOLD := Color("d8b574")
const MUTED := Color("aec0b7")
const INK := Color("14262b")
var campaign: RefCounted
var data: Dictionary = {}
var selected_district := ""
var selected_location := ""
var surface: MapSurface
var pin_buttons: Dictionary = {}
var room_labels: Dictionary = {}
var heading: Label
var city_button: Button
var current_button: Button
var card: VBoxContainer
var travel_button: Button
var context: Label

class MapPin extends Button:
	var status := "unsearched"
	var here := false
	func _ready() -> void:
		custom_minimum_size = Vector2(48, 52)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for key in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(key, StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
	func _draw() -> void:
		var centre := Vector2(size.x / 2, 22)
		var accent := Color("d8b574")
		if status == "resolved": accent = Color("a8c9ab")
		elif status == "locked": accent = Color("a6afa1")
		if here:
			draw_circle(centre, 23, Color("10252a"))
			draw_arc(centre, 22, 0, TAU, 48, Color("f4dc99"), 3, true)
		var triangle := PackedVector2Array([centre+Vector2(-10,10),centre+Vector2(10,10),centre+Vector2(0,28)])
		draw_colored_polygon(triangle,Color("132b31"))
		draw_circle(centre, 18, Color("132b31"))
		draw_arc(centre, 18, 0, TAU, 48, accent, 2, true)
		if has_focus() or is_hovered(): draw_arc(centre, 20, 0, TAU, 48, Color.WHITE, 2, true)
		match status:
			"locked":
				draw_rect(Rect2(centre+Vector2(-7,-2),Vector2(14,11)),accent,false,2)
				draw_arc(centre+Vector2(0,-3),5,PI,TAU,20,accent,2,true)
			"resolved":
				draw_polyline(PackedVector2Array([centre+Vector2(-8,0),centre+Vector2(-2,6),centre+Vector2(9,-7)]),accent,3,true)
			"investigation":
				draw_polyline(PackedVector2Array([centre+Vector2(0,-10),centre+Vector2(9,0),centre+Vector2(0,10),centre+Vector2(-9,0),centre+Vector2(0,-10)]),accent,2,true)
			_:
				draw_arc(centre+Vector2(-2,-2),6,0,TAU,24,accent,2,true)
				draw_line(centre+Vector2(3,3),centre+Vector2(10,10),accent,3,true)

class MapSurface extends Control:
	var painting: Texture2D
	var world := Rect2(0,0,1600,1000)
	var region := Rect2(0,0,1600,1000)
	func image_rect() -> Rect2:
		var scale: float = minf(size.x / region.size.x,size.y / region.size.y)
		var fitted: Vector2 = region.size * scale
		return Rect2((size-fitted)/2,fitted)
	func world_to_screen(point: Vector2) -> Vector2:
		var rect := image_rect()
		return rect.position + (point-region.position)/region.size*rect.size
	func _draw() -> void:
		draw_style_box(_background(),Rect2(Vector2.ZERO,size))
		if painting != null:
			draw_texture_rect_region(painting,image_rect(),region)
			draw_rect(image_rect(),Color("7c927c"),false,1)
	func _background() -> StyleBoxFlat:
		var box := StyleBoxFlat.new(); box.bg_color=Color("10272d"); box.set_corner_radius_all(6)
		return box

func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://content/city-map.json"))
	custom_minimum_size = Vector2(760, 690 if campaign.settings.large_text else 650)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	var top := HBoxContainer.new();top.add_theme_constant_override("separation",12);add_child(top)
	city_button = _button(top,"City overview",show_city)
	heading = _label(top,"LETH · THE TIDAL CITY",24,GOLD)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	current_button = _button(top,"Your location",_show_current)
	context = _label(self,"",18,MUTED)
	var body := HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",18);add_child(body)
	surface = MapSurface.new()
	surface.painting=load(str(data.art))
	surface.custom_minimum_size=Vector2(440,500 if not campaign.settings.large_text else 540)
	surface.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	surface.size_flags_vertical=Control.SIZE_EXPAND_FILL
	surface.clip_contents=true
	body.add_child(surface)
	surface.resized.connect(_place_pins)
	var panel := PanelContainer.new();panel.custom_minimum_size.x=290 if not campaign.settings.large_text else 325
	panel.size_flags_horizontal=Control.SIZE_SHRINK_END
	var style := StyleBoxFlat.new();style.bg_color=INK;style.set_content_margin_all(18);style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel",style);body.add_child(panel)
	card=VBoxContainer.new();card.add_theme_constant_override("separation",14);panel.add_child(card)
	var legend:=HBoxContainer.new();legend.add_theme_constant_override("separation",20);add_child(legend)
	for pair in [["unsearched","Search remaining"],["investigation","Investigation remaining"],["resolved","Fully resolved"],["locked","Locked"]]:
		var entry:=HBoxContainer.new();entry.add_theme_constant_override("separation",4);entry.size_flags_horizontal=Control.SIZE_EXPAND_FILL;legend.add_child(entry)
		var symbol:=MapPin.new();symbol.status=pair[0];symbol.mouse_filter=Control.MOUSE_FILTER_IGNORE;symbol.focus_mode=Control.FOCUS_NONE;entry.add_child(symbol)
		var description:=_label(entry,pair[1],17,MUTED)
		description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	show_city()

func _label(parent: Node,value: String,font_size: int,color: Color=PAPER) -> Label:
	var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",BODY)
	label.add_theme_font_size_override("font_size",font_size+(2 if campaign.settings.large_text else 0))
	label.add_theme_color_override("font_color",color);parent.add_child(label)
	return label

func _button(parent: Node,value: String,action: Callable) -> Button:
	var button:=Button.new();button.text=value;button.custom_minimum_size.y=44
	button.add_theme_font_override("font",BODY);button.add_theme_font_size_override("font_size",18+(2 if campaign.settings.large_text else 0))
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.pressed.connect(action);parent.add_child(button)
	return button

func _district(id: String) -> Dictionary:
	for district in data.districts:
		if district.id==id: return district
	return {}

func _district_for(location_id: String) -> Dictionary:
	for district in data.districts:
		for room in district.rooms:
			if room.location==location_id:return district
	return {}

func location_status(id: String) -> String:
	var location: Dictionary=campaign.get_location(id)
	if location.is_empty() or not campaign.chapter_unlocked(location.chapter):return "locked"
	if not campaign.search_complete(id):return "unsearched"
	for puzzle in campaign.data.puzzles:
		if puzzle.location==id and puzzle.id not in campaign.solved:return "investigation"
	return "resolved"

func district_status(district: Dictionary) -> String:
	if not campaign.chapter_unlocked(district.chapter):return "locked"
	var unresolved:=false
	for room in district.rooms:
		var status:=location_status(room.location)
		if status=="unsearched":return "unsearched"
		if status=="investigation":unresolved=true
	return "investigation" if unresolved else "resolved"

func _status_label(status: String) -> String:
	return {"locked":"Locked","unsearched":"Search remaining","investigation":"Investigation remaining","resolved":"Fully resolved"}.get(status,"")

func _clear_pins() -> void:
	for child in surface.get_children():
		surface.remove_child(child);child.queue_free()
	pin_buttons.clear();room_labels.clear()

func _clear_card() -> void:
	travel_button=null
	for child in card.get_children():
		card.remove_child(child);child.queue_free()

func show_city() -> void:
	selected_district="";selected_location="";city_button.disabled=true
	heading.text="LETH · THE TIDAL CITY"
	context.text="Choose a district pin. The outlined pin marks where you are."
	surface.region=surface.world
	_clear_pins();_clear_card()
	var current:Dictionary=_district_for(campaign.location_id)
	for district in data.districts:
		var locked:bool=not campaign.chapter_unlocked(district.chapter)
		_add_pin(str(district.id),Vector2(district.pin[0],district.pin[1]),"Uncharted" if locked else str(district.name),district_status(district),district.id==current.get("id",""),show_district.bind(str(district.id)))
		pin_buttons[district.id].focus_entered.connect(_preview_district.bind(str(district.id)))
	_label(card,"YOUR LOCATION",14,GOLD)
	_label(card,str(campaign.searches.get(campaign.location_id,{}).get("title",campaign.get_location(campaign.location_id).title)),26)
	_label(card,str(current.get("name","")),20,MUTED)
	_button(card,"Open this district",_show_current)
	card.add_child(HSeparator.new())
	_label(card,"Follow the streets and waterways to places you have unlocked. New district names appear as your investigation reaches them.",19,MUTED)
	_place_pins()

func _preview_district(id: String) -> void:
	var district:=_district(id)
	if district.is_empty():return
	_clear_card()
	if not campaign.chapter_unlocked(district.chapter):
		_label(card,"UNCHARTED DISTRICT",15,GOLD)
		_label(card,"Follow your current investigation to open this part of the city.",23)
		return
	_label(card,"DISTRICT",14,GOLD)
	_label(card,str(district.name),26)
	_label(card,str(district.description),19,MUTED)
	var completed:=0
	for room in district.rooms:
		if campaign.search_complete(room.location):completed+=1
	_label(card,"%d / %d searches complete"%[completed,district.rooms.size()],20,GOLD)
	_button(card,"Open this district",show_district.bind(id))

func _show_current() -> void:
	var district:=_district_for(campaign.location_id)
	if not district.is_empty():
		show_district(str(district.id));select_location(campaign.location_id)

func show_district(id: String) -> void:
	var district:=_district(id)
	if district.is_empty():return
	if not campaign.chapter_unlocked(district.chapter):
		_clear_card();_label(card,"UNCHARTED DISTRICT",15,GOLD)
		_label(card,"Follow your current investigation to open this part of the city.",23)
		return
	selected_district=id;selected_location="";city_button.disabled=false
	heading.text=str(district.name)
	context.text=str(district.description)+" Select a pin to view its discoveries and travel."
	_clear_pins();_clear_card()
	for room in district.rooms:
		var location_id:String=room.location
		var title:String=campaign.searches[location_id].title
		_add_pin(location_id,Vector2(room.point[0],room.point[1]),title,location_status(location_id),location_id==campaign.location_id,select_location.bind(location_id),str(room.get("label_side","right")))
		pin_buttons[location_id].focus_entered.connect(select_location.bind(location_id))
	_label(card,"EXPLORE THIS DISTRICT",14,GOLD)
	_label(card,"Select a place on the map.",25)
	_label(card,"The pin symbols distinguish an unfinished search from evidence that still needs an investigation.",19,MUTED)
	_place_pins()

func select_location(id: String) -> void:
	var district:=_district_for(id)
	if district.is_empty() or not campaign.chapter_unlocked(district.chapter):return
	if selected_district!=district.id:show_district(str(district.id))
	selected_location=id
	_clear_card()
	_label(card,"YOU ARE HERE" if id==campaign.location_id else "DESTINATION",14,GOLD)
	var title:=_label(card,str(campaign.searches[id].title),27)
	title.add_theme_font_override("font",DISPLAY)
	_label(card,str(district.name),19,MUTED)
	card.add_child(HSeparator.new())
	var status:=location_status(id)
	_label(card,_status_label(status),21,GOLD)
	var found:int=campaign.search_progress.get(id,[]).size()
	var total:int=campaign.searches[id].items.size()
	_label(card,"%d / %d hidden objects found"%[found,total],19,MUTED)
	var remaining:=0
	for puzzle in campaign.data.puzzles:
		if puzzle.location==id and puzzle.id not in campaign.solved:remaining+=1
	if campaign.search_complete(id):
		_label(card,"Evidence recovered · %d investigation%s remaining"%[remaining,"" if remaining==1 else "s"],19,MUTED)
	else:_label(card,"Complete the picture search to recover this room’s evidence.",19,MUTED)
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;card.add_child(spacer)
	travel_button=_button(card,"Return to this room" if id==campaign.location_id else "Travel here",func():travel_requested.emit(id))
	travel_button.accessibility_name=travel_button.text+": "+str(campaign.searches[id].title)
	for pin_id in pin_buttons:pin_buttons[pin_id].queue_redraw()

func _add_pin(id: String,point: Vector2,title: String,status: String,here: bool,action: Callable,label_side: String="below") -> void:
	var pin:=MapPin.new();pin.status=status;pin.here=here
	pin.tooltip_text=title+" · "+_status_label(status)+(" · You are here" if here else "")
	pin.accessibility_name=pin.tooltip_text
	pin.set_meta("map_point",point);pin.set_meta("label_side",label_side)
	pin.pressed.connect(action);surface.add_child(pin);pin_buttons[id]=pin
	var label:=Label.new();label.text=title;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",BODY);label.add_theme_font_size_override("font_size",17+(2 if campaign.settings.large_text else 0))
	label.add_theme_color_override("font_color",PAPER)
	label.add_theme_color_override("font_shadow_color",Color("10272d"));label.add_theme_constant_override("shadow_outline_size",5)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size=Vector2(175 if campaign.settings.large_text else 155,44)
	label.size=label.custom_minimum_size
	surface.add_child(label);room_labels[id]=label

func _place_pins() -> void:
	if not is_instance_valid(surface) or surface.size.x<=0 or surface.size.y<=0:return
	if selected_district.is_empty():surface.region=surface.world
	else:
		var district:=_district(selected_district)
		var b:Array=district.bounds
		var region:=Rect2(b[0],b[1],b[2],b[3]).grow(65)
		var aspect:float=surface.size.x/surface.size.y
		var centre:=region.get_center()
		if region.size.x/region.size.y<aspect:region.size.x=region.size.y*aspect
		else:region.size.y=region.size.x/aspect
		region.size=region.size.min(surface.world.size)
		region.position=(centre-region.size/2).clamp(Vector2.ZERO,surface.world.size-region.size)
		surface.region=region
	var labels: Array[Rect2]=[]
	for id in pin_buttons:
		var pin:MapPin=pin_buttons[id]
		var point:Vector2=surface.world_to_screen(pin.get_meta("map_point"))
		pin.size=Vector2(48,52)
		pin.position=(point-Vector2(24,23)).clamp(Vector2(3,3),surface.size-pin.size-Vector2(3,3))
		var label:Label=room_labels[id]
		var side:String=pin.get_meta("label_side")
		var candidates:Array[Vector2]=[
			point+Vector2(30,-label.size.y/2),point+Vector2(-label.size.x-30,-label.size.y/2),
			point+Vector2(-label.size.x/2,32),point+Vector2(-label.size.x/2,-label.size.y-30)]
		if side=="left":candidates=[candidates[1],candidates[0],candidates[3],candidates[2]]
		elif side=="below":candidates=[candidates[2],candidates[3],candidates[0],candidates[1]]
		var chosen:Vector2=candidates[0]
		for candidate in candidates:
			var bounded:Vector2=candidate.clamp(Vector2(5,5),surface.size-label.size-Vector2(5,5))
			var rect:=Rect2(bounded,label.size)
			var overlap:=false
			for previous in labels:
				if rect.grow(3).intersects(previous):overlap=true
			if not overlap:
				chosen=bounded;break
		label.position=chosen.clamp(Vector2(5,5),surface.size-label.size-Vector2(5,5))
		labels.append(label.get_rect())
	surface.queue_redraw()
