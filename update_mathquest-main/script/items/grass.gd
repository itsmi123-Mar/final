extends Sprite2D

@export var frame_speed: float = 10.0
var time_passed: float = 0.0

func _process(delta: float) -> void:
	var frame_count := maxi(1, hframes * vframes)
	# Normalize any invalid frame left over from a previous scene/import state.
	if frame < 0 or frame >= frame_count:
		frame = 0
	if frame_speed <= 0.0:
		return
	time_passed += delta
	if time_passed >= 1.0 / frame_speed:
		time_passed = 0.0
		# Wrap before assigning the frame; assigning frame_count first causes
		# Godot's out-of-bounds error for a 25-frame sprite (valid: 0..24).
		frame = (frame + 1) % frame_count
