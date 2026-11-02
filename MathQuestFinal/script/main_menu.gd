extends Control

const LOGIN_SCENE := "res://scene/login.tscn"
const CHARACTER_SCENE := "res://scene/choose_character.tscn"
const SCOREBOARD_SCENE := "res://scene/scoreboard.tscn"

@onready var play_button: Button = $play
@onready var logout_button: TextureButton = $logout
@onready var scoreboard_button: TextureButton = $scoreboard


func _ready() -> void:
	_show_selected_wizard()
	play_button.pressed.connect(_on_play_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	scoreboard_button.pressed.connect(_on_scoreboard_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SCENE)


func _on_scoreboard_pressed() -> void:
	get_tree().change_scene_to_file(SCOREBOARD_SCENE)


func _on_logout_pressed() -> void:
	PlayerData.logout()
	get_tree().change_scene_to_file(LOGIN_SCENE)


func _show_selected_wizard() -> void:
	# The old menu illustration was always the male wizard. Replace it with
	# the pupil's saved choice so the menu matches character selection/gameplay.
	var old_display := get_node_or_null("choose_ char")
	if old_display:
		old_display.visible = false
	var character_id := PlayerData.get_saved_selected_character()
	if character_id not in ["m_wizard", "f_wizard"]:
		character_id = "m_wizard"
	var packed := load("res://scene/char/%s.tscn" % character_id) as PackedScene
	if packed == null:
		push_warning("Could not load selected wizard for the main menu.")
		return
	var display := packed.instantiate() as Node2D
	display.name = "SelectedWizardDisplay"
	display.position = Vector2(300, 600)
	# The female wizard artwork is authored at a smaller internal scale.
	display.scale = Vector2.ONE * (0.78 if character_id == "m_wizard" else 1.55)
	add_child(display)
