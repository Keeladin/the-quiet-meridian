class_name EnvironmentStage
extends Control
## Local animation of the existing illustration. This node never owns gameplay.

const WATER_SHADER = preload("res://shaders/environment_water.gdshader")
const GOLD := Color(0.94, 0.78, 0.47, 1.0)
var profile: Dictionary = {}
var reduced_motion := false
var visual_time := 0.0
var illustration: TextureRect
var overlay: Control
var shader_material: ShaderMaterial
var pulses: Array = []
var particles: Array = []
var _configured := false
var _manual_time := false

class EffectsLayer extends Control:
	var host: Control
	func _draw() -> void:
		if is_instance_valid(host): host._draw_effects(self)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = true

func configure(texture: Texture2D, value: Dictionary, reduce: bool = false) -> void:
	profile = value.duplicate(true)
	visual_time = 0.0
	pulses.clear()
	_manual_time = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	illustration = TextureRect.new()
	illustration.texture = texture
	illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustration.stretch_mode = TextureRect.STRETCH_SCALE
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(illustration)
	shader_material = ShaderMaterial.new()
	shader_material.shader = WATER_SHADER
	illustration.material = shader_material
	_set_shader_regions("water_rects", "water_count", profile.get("water", []), 4)
	_set_shader_regions("water_exclusions", "exclusion_count", profile.get("water_exclusions", []), 8)
	_set_shader_regions("fog_rects", "fog_count", profile.get("fog", []), 3)
	_set_shader_regions("lamp_rects", "lamp_count", profile.get("lamps", []), 8)
	var mechanisms: Array = profile.get("mechanisms", [])
	var rectangles: Array = []
	var parameters := PackedVector4Array()
	for mechanism in mechanisms:
		rectangles.append(mechanism.rect)
		var displacement: Array = mechanism.get("displacement", [0.001, 0.0])
		parameters.append(Vector4(float(displacement[0]), float(displacement[1]), float(mechanism.get("speed", 1.0)), float(mechanism.get("phase", 0.0))))
	while parameters.size() < 4: parameters.append(Vector4.ZERO)
	_set_shader_regions("mechanism_rects", "mechanism_count", rectangles, 4)
	shader_material.set_shader_parameter("mechanism_params", parameters)
	shader_material.set_shader_parameter("water_strength", float(profile.get("water_strength", 0.0015)))
	shader_material.set_shader_parameter("fog_opacity", float(profile.get("fog_opacity", 0.11)))
	var tint: Array = profile.get("fog_tint", [0.62,0.70,0.71])
	shader_material.set_shader_parameter("fog_tint", Vector3(tint[0],tint[1],tint[2]))
	overlay = EffectsLayer.new()
	overlay.host = self
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_make_particles()
	_configured = true
	set_reduced_motion(reduce)

func _set_shader_regions(parameter: String, count_parameter: String, regions: Array, limit: int) -> void:
	var values := PackedVector4Array()
	for region in regions.slice(0, limit):
		values.append(Vector4(float(region[0]),float(region[1]),float(region[2]),float(region[3])))
	shader_material.set_shader_parameter(count_parameter, values.size())
	while values.size() < limit: values.append(Vector4.ZERO)
	shader_material.set_shader_parameter(parameter, values)

func _make_particles() -> void:
	particles.clear()
	var generator := RandomNumberGenerator.new()
	generator.seed = int(profile.get("seed", 1729))
	var region: Array = profile.get("particle_region", [0.0,0.0,1.0,1.0])
	for _index in range(int(profile.get("particles", 14))):
		particles.append({"origin":Vector2(generator.randf(),generator.randf()),"phase":generator.randf()*TAU,"speed":generator.randf_range(0.45,1.2),"radius":generator.randf_range(0.6,1.5),"region":Rect2(region[0],region[1],region[2],region[3])})

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value:
		pulses.clear()
	if shader_material != null:
		shader_material.set_shader_parameter("motion", 0.0 if value else 1.0)
	if is_instance_valid(overlay): overlay.queue_redraw()

func set_visual_time(seconds: float) -> void:
	_manual_time = true
	visual_time = maxf(seconds, 0.0)
	_update_shader()
	if is_instance_valid(overlay): overlay.queue_redraw()

func resume_animation() -> void:
	_manual_time = false

func _process(delta: float) -> void:
	if not _configured or reduced_motion or _manual_time: return
	advance(delta)

func advance(delta: float) -> void:
	if not _configured or reduced_motion: return
	var safe_delta := clampf(delta, 0.0, 1.0)
	visual_time += safe_delta
	for pulse in pulses: pulse.age += safe_delta
	pulses = pulses.filter(func(pulse): return float(pulse.age) < 0.85)
	_update_shader()
	if is_instance_valid(overlay): overlay.queue_redraw()

func _update_shader() -> void:
	if shader_material != null: shader_material.set_shader_parameter("clock", visual_time)

func pulse_at(normalized: Vector2, color: Color = GOLD) -> void:
	if reduced_motion or not _configured: return
	pulses.append({"point":normalized.clamp(Vector2.ZERO,Vector2.ONE),"age":0.0,"color":color})
	if pulses.size() > 8: pulses.pop_front()
	if is_instance_valid(overlay): overlay.queue_redraw()

func effect_snapshot() -> Dictionary:
	return {"time":visual_time,"reduced_motion":reduced_motion,"motion_enabled":not reduced_motion,"water_regions":profile.get("water",[]).size(),"fog_regions":profile.get("fog",[]).size(),"lamps":profile.get("lamps",[]).size(),"mechanisms":profile.get("mechanisms",[]).size(),"particles":particles.size(),"pulse_count":pulses.size(),"input_passthrough":mouse_filter == Control.MOUSE_FILTER_IGNORE}

func _draw_effects(canvas: Control) -> void:
	if reduced_motion or not _configured: return
	var dimensions := size
	var weather: String = profile.get("weather", "motes")
	for particle in particles:
		var region: Rect2 = particle.region
		var base: Vector2 = particle.origin
		var phase: float = particle.phase
		var speed: float = particle.speed
		var position: Vector2
		var alpha: float
		if weather == "rain":
			position = Vector2(fposmod(base.x-visual_time*0.012*speed,1.0),fposmod(base.y+visual_time*0.24*speed,1.0))
			position = (region.position+position*region.size)*dimensions
			canvas.draw_line(position,position+Vector2(-2,8)*dimensions.y/560.0,Color(0.65,0.75,0.77,0.11),0.8,true)
		else:
			position = Vector2(fposmod(base.x+sin(visual_time*0.16+phase)*0.035,1.0),fposmod(base.y-visual_time*0.008*speed,1.0))
			position = (region.position+position*region.size)*dimensions
			alpha = (0.05+0.11*(0.5+0.5*sin(visual_time*0.52+phase))) * float(profile.get("particle_opacity",1.0))
			canvas.draw_circle(position,float(particle.radius)*dimensions.y/560.0,Color(0.91,0.84,0.66,alpha))
	for steam in profile.get("steam", []):
		var origin := Vector2(steam[0],steam[1])*dimensions
		var extent := Vector2(steam[2],steam[3])*dimensions
		for i in range(7):
			var life := fposmod(visual_time*0.13+float(i)/7.0,1.0)
			var center := origin+Vector2(sin(life*4.0+float(i))*extent.x*0.18,-life*extent.y)
			var radius := extent.x*(0.16+life*0.35)
			for ring in range(4):
				canvas.draw_set_transform(center,0.0,Vector2(1.8,0.64))
				canvas.draw_circle(Vector2.ZERO,radius*(1.0-float(ring)*0.15),Color(0.74,0.79,0.78,(1.0-life)*0.005))
			canvas.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	for mechanism in profile.get("mechanisms", []):
		if mechanism.get("kind", "") != "flywheel": continue
		var rect: Array = mechanism.rect
		var center := Vector2(rect[0]+rect[2]*0.5,rect[1]+rect[3]*0.5)*dimensions
		var radii := Vector2(rect[2],rect[3])*dimensions*0.5
		canvas.draw_set_transform(center,0.0,Vector2(radii.x/maxf(radii.y,1.0),1.0))
		for i in range(3):
			var angle := visual_time*float(mechanism.get("speed",0.5))+float(i)*TAU/3.0
			canvas.draw_arc(Vector2.ZERO,radii.y*0.94,angle,angle+0.19,10,Color(0.82,0.66,0.37,0.10),1.6,true)
		canvas.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	for pulse in pulses:
		var progress: float = float(pulse.age)/0.85
		var color: Color = pulse.color
		color.a = (1.0-progress)*0.75
		var center: Vector2 = pulse.point*dimensions
		canvas.draw_arc(center,(9.0+progress*34.0)*dimensions.y/560.0,0.0,TAU,48,color,2.0,true)
		color.a *= 0.3
		canvas.draw_circle(center,(5.0+progress*17.0)*dimensions.y/560.0,color)
