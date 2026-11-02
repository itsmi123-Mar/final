
extends Control

const LOGIN_SCENE: String = "res://scene/login.tscn"
const MONITOR_SCENE: String = "res://teacher/monitor.tscn"
const GENERATE_SCENE: String = "res://teacher/gen.tscn"

var student_list: VBoxContainer
var action_row: HBoxContainer


func _ready() -> void:
	if PlayerData.current_user_role != "teacher":
		get_tree().change_scene_to_file(LOGIN_SCENE)
		return

	_setup_responsive_layout()
	_load_pupil_records()
	_connect_logout()


func _setup_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_width: float = viewport_size.x
	var screen_height: float = viewport_size.y

	# Background
	var background: TextureRect = get_node_or_null("TextureRect")
	if background:
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_SCALE

	# Welcome title
	var title: Label = get_node_or_null("title")
	if title:
		title.position = Vector2(30, 35)
		title.size = Vector2(screen_width - 100, 60)
		title.add_theme_font_size_override("font_size", 27)

	# Enrolled pupil count
	var count_label: Label = get_node_or_null("total_pupil")
	if count_label:
		count_label.position = Vector2(
			(screen_width - 100) / 2,
			245
		)
		count_label.size = Vector2(100, 100)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 65)

	# Grade label
	var grade_panel: Panel = get_node_or_null("Panel")
	if grade_panel:
		grade_panel.position = Vector2(
			(screen_width - 180) / 2,
			350
		)
		grade_panel.size = Vector2(180, 40)

		var grade_label: Label = grade_panel.get_node_or_null("Grade n")
		if grade_label:
			grade_label.position = Vector2.ZERO
			grade_label.size = Vector2(180, 40)
			grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			grade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Hide the old oversized school-year panel
	var school_year: Control = get_node_or_null("Panel2")
	if school_year:
		school_year.visible = false

	# Scoreboard panel
	var scoreboard: Panel = get_node_or_null("Panel3")
	if scoreboard:
		scoreboard.position = Vector2(20, 470)
		scoreboard.size = Vector2(screen_width - 40, screen_height - 650)
		scoreboard.clip_contents = true

	# Scoreboard heading
	var heading: Label = Label.new()
	heading.name = "scoreboard_heading"
	heading.text = "PUPIL SCOREBOARD"
	heading.position = Vector2(10, 10)
	heading.size = Vector2(screen_width - 60, 45)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", Color("#26384b"))
	scoreboard.add_child(heading)

	# Scrollable pupil list
	var old_list: GridContainer = get_node_or_null("Panel3/students")

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "pupil_scroll"
	scroll.position = Vector2(10, 65)
	scroll.size = Vector2(scoreboard.size.x - 20, scoreboard.size.y - 80)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scoreboard.add_child(scroll)

	student_list = VBoxContainer.new()
	student_list.name = "student_list"
	student_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	student_list.add_theme_constant_override("separation", 10)
	scroll.add_child(student_list)

	if old_list:
		old_list.queue_free()

	# Bottom action buttons
	action_row = HBoxContainer.new()
	action_row.name = "teacher_actions"
	action_row.position = Vector2(20, screen_height - 100)
	action_row.size = Vector2(screen_width - 40, 70)
	action_row.add_theme_constant_override("separation", 12)
	add_child(action_row)

	var monitor_button: Button = _create_action_button(
		"Monitor Performance"
	)
	monitor_button.pressed.connect(_open_monitor)
	action_row.add_child(monitor_button)

	var generate_button: Button = _create_action_button(
		"Generate Records"
	)
	generate_button.pressed.connect(_open_generate)
	action_row.add_child(generate_button)

	# Logout button
	var logout_button: BaseButton = get_node_or_null("TextureButton")
	if logout_button:
		logout_button.position = Vector2(screen_width - 70, 20)
		logout_button.size = Vector2(50, 50)


func _create_action_button(button_text: String) -> Button:
	var button: Button = Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 65)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	return button


func _load_pupil_records() -> void:
	var records: Array = PlayerData.get_teacher_pupil_records()

	var count_label: Label = get_node_or_null("total_pupil")
	if count_label:
		count_label.text = str(records.size())

	var grade_label: Label = get_node_or_null("Panel/Grade n")
	if grade_label:
		grade_label.text = PlayerData.get_teacher_grade()

	if student_list == null:
		return

	for child in student_list.get_children():
		child.queue_free()

	if records.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No pupil records available."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		student_list.add_child(empty_label)
		return

	for item in records:
		var record: Dictionary = item

		var pupil_id: String = str(record.get("id", ""))
		var pupil_name: String = str(record.get("name", "Pupil"))
		var pupil_score: String = str(record.get("total_score", 0))

		var pupil_button: Button = Button.new()
		pupil_button.text = pupil_name + "     |     Score: " + pupil_score
		pupil_button.custom_minimum_size = Vector2(0, 58)
		pupil_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pupil_button.add_theme_font_size_override("font_size", 17)

		pupil_button.pressed.connect(
			_select_pupil.bind(pupil_id)
		)

		student_list.add_child(pupil_button)


func _select_pupil(pupil_id: String) -> void:
	PlayerData.selected_teacher_pupil_id = pupil_id
	get_tree().change_scene_to_file(MONITOR_SCENE)


func _open_monitor() -> void:
	get_tree().change_scene_to_file(MONITOR_SCENE)


func _open_generate() -> void:
	get_tree().change_scene_to_file(GENERATE_SCENE)


func _connect_logout() -> void:
	var logout_button: BaseButton = get_node_or_null("TextureButton")

	if logout_button:
		if not logout_button.pressed.is_connected(_logout):
			logout_button.pressed.connect(_logout)


func _logout() -> void:
	PlayerData.logout()
	get_tree().change_scene_to_file(LOGIN_SCENE)
