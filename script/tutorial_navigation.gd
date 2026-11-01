extends Control
@export_file("*.tscn") var next_scene: String = "res://scene/tutorial_board.tscn"
func _ready() -> void:
 var skip_button := get_node_or_null("skip") as Button
 if skip_button: skip_button.pressed.connect(_go_next)
func _go_next() -> void:
 if ResourceLoader.exists(next_scene): get_tree().change_scene_to_file(next_scene)
 else: get_tree().change_scene_to_file("res://scene/login.tscn")
