extends Control
## Authored expression frames. Speech motion runs only while actual voice plays.
## All ongoing motion is frozen when reduced motion is enabled.

var character_id := ""
var reduced_motion := false
var speaking := false
var emotion := "neutral"
var _atlas: Texture2D
var _frame := 0
var _clock := 0.0
var _seed := 0.0
var _gesture_until := 0.0
var _last_frame := -1
var _portrait: TextureRect

func configure(id: String, texture: Texture2D, reduce: bool = false) -> void:
	character_id = id
	_atlas = texture
	_last_frame = -1
	reduced_motion = reduce
	_seed = float(abs(id.hash()) % 100) / 31.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _portrait == null:
		_portrait = TextureRect.new()
		_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_portrait)
		_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_frame()

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	_update_frame()

func set_speaking(value: bool) -> void:
	speaking = value
	_update_frame()

func set_emotion(value: String) -> void:
	emotion = value
	_gesture_until = _clock + 1.8 if value in ["explain", "resolve"] else 0.0
	_update_frame()

func set_visual_time(seconds: float) -> void:
	if not reduced_motion: _clock = maxf(seconds, 0.0)
	_update_frame()

func _process(delta: float) -> void:
	if reduced_motion: return
	_clock += delta
	_update_frame()

func _update_frame() -> void:
	if _portrait == null or _atlas == null: return
	var base := 4 if emotion == "relief" else (5 if emotion == "concern" else 0)
	_frame = base
	if not reduced_motion:
		var blink_phase := fmod(_clock + _seed, 4.8)
		if blink_phase < 0.13: _frame = 1
		elif speaking:
			var cadence := int((_clock + _seed) * 5.2) % 7
			_frame = [0, 2, 3, 2, 0, 3, 0][cadence]
			if fmod(_clock + _seed, 7.0) > 5.8: _frame = 6
		elif _clock < _gesture_until: _frame = 7 if emotion == "resolve" else 6
		# Small breathing is subordinate to painted face and hand animation.
		_portrait.position.y = sin((_clock + _seed) * 1.45) * 0.75
	else:
		_portrait.position.y = 0.0
	if _last_frame == _frame: return
	var cell := Vector2(_atlas.get_width() / 4.0, _atlas.get_height() / 2.0)
	var frame := AtlasTexture.new()
	frame.atlas = _atlas
	frame.region = Rect2(Vector2(_frame % 4, _frame / 4) * cell, cell)
	frame.filter_clip = true
	_portrait.texture = frame
	_last_frame = _frame

func pose_snapshot() -> Dictionary:
	return {"character": character_id, "frame": _frame, "speaking": speaking,
		"reduced_motion": reduced_motion, "time": _clock, "emotion": emotion}
