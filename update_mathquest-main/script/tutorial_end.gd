extends Control

func _ready() -> void:
	var button := get_node_or_null("continue_button") as BaseButton
	if button and not button.pressed.is_connected(_start_level):
		button.pressed.connect(_start_level)

func _start_level() -> void:
	# The three tutorial scenes have now been shown; continue to this level's battle.
	var error := get_tree().change_scene_to_file("res://scene/gameplay.tscn")
	if error != OK:
		push_error("Could not open gameplay scene after tutorial.")
