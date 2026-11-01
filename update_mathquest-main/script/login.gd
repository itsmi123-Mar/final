extends Control

const MAIN_MENU_SCENE := "res://scene/main_menu.tscn"
const TEACHER_SCENE := "res://teacher/main_scene.tscn"

@onready var name_input: LineEdit = $name
@onready var grade_input: OptionButton = $grade
@onready var password_input: LineEdit = $password
@onready var message_label: Label = $Label
@onready var enter_button: Button = $enter


func _ready() -> void:
	message_label.hide()
	password_input.secret = true
	enter_button.pressed.connect(_on_enter_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	password_input.text_submitted.connect(_on_password_submitted)


func _on_name_submitted(_text: String) -> void:
	password_input.grab_focus()


func _on_password_submitted(_text: String) -> void:
	_on_enter_pressed()


func _on_enter_pressed() -> void:
	var first_name := name_input.text.strip_edges()
	var password := password_input.text
	if first_name.is_empty():
		_show_error("Enter your full registered name.")
		name_input.grab_focus()
		return
	if grade_input.selected < 0:
		_show_error("Please select your grade.")
		return
	if password.is_empty():
		_show_error("Please enter your password.")
		password_input.grab_focus()
		return

	var selected_grade := grade_input.get_item_text(grade_input.selected)
	if PlayerData.login_teacher(first_name, password, selected_grade):
		message_label.hide()
		get_tree().change_scene_to_file(TEACHER_SCENE)
		return
	if PlayerData.login_pupil(first_name, password, selected_grade):
		message_label.hide()
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	else:
		_show_error("Name, grade, or password is incorrect. Students: use your LRN as password.")


func _show_error(message: String) -> void:
	message_label.text = message
	message_label.show()
