
extends Control

const MAIN_MENU_SCENE: String = "res://scene/main_menu.tscn"
const TEACHER_MENU_SCENE: String = "res://teacher/main_scene.tscn"

@onready var name_input: LineEdit = $name
@onready var grade_input: OptionButton = $grade
@onready var password_input: LineEdit = $password
@onready var message_label: Label = $Label
@onready var enter_button: Button = $enter


func _ready() -> void:
	message_label.hide()
	password_input.secret = true

	if not enter_button.pressed.is_connected(_on_enter_pressed):
		enter_button.pressed.connect(_on_enter_pressed)

	if not name_input.text_submitted.is_connected(_on_name_submitted):
		name_input.text_submitted.connect(_on_name_submitted)

	if not password_input.text_submitted.is_connected(_on_password_submitted):
		password_input.text_submitted.connect(_on_password_submitted)


func _on_name_submitted(_text: String) -> void:
	password_input.grab_focus()


func _on_password_submitted(_text: String) -> void:
	_on_enter_pressed()


func _on_enter_pressed() -> void:
	var entered_name: String = name_input.text.strip_edges()
	var entered_password: String = password_input.text.strip_edges()

	if entered_name.is_empty():
		_show_error("Please enter your name.")
		name_input.grab_focus()
		return

	if grade_input.item_count == 0 or grade_input.selected < 0:
		_show_error("Please select your grade.")
		return

	if entered_password.is_empty():
		_show_error("Please enter your password.")
		password_input.grab_focus()
		return

	var selected_grade: String = grade_input.get_item_text(
		grade_input.selected
	)

	# Teacher authentication
	if PlayerData.login_teacher(
		entered_name,
		entered_password,
		selected_grade
	):
		message_label.hide()
		get_tree().change_scene_to_file(TEACHER_MENU_SCENE)
		return

	# Pupil authentication using registered full name and LRN password
	if PlayerData.login_pupil(
		entered_name,
		entered_password,
		selected_grade
	):
		message_label.hide()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		return

	_show_error("Name, grade, or password is incorrect.")


func _show_error(message: String) -> void:
	message_label.text = message
	message_label.show()
