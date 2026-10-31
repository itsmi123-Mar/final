extends Control

const LOGIN_SCENE := "res://scene/login.tscn"

func _ready() -> void:
	# Rebuild the teacher screen responsively for the project's 610x1060
	# portrait viewport. The original artboard was wider than the game window,
	# which pushed controls off-screen on phones.
	for child in get_children():
		child.queue_free()
	_build_dashboard()

func _build_dashboard() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#eaf3ff")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var teacher: Dictionary = PlayerData.current_teacher
	var display_name := str(teacher.get("name", "Osh"))
	var grade := str(teacher.get("grade", "Grade 3"))

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _panel_style("#7544c8"))
	column.add_child(header)
	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 6)
	header_box.add_theme_constant_override("margin_left", 16)
	header_box.add_theme_constant_override("margin_right", 16)
	header_box.add_theme_constant_override("margin_top", 16)
	header_box.add_theme_constant_override("margin_bottom", 16)
	header.add_child(header_box)
	var welcome := Label.new()
	welcome.text = "WELCOME, %s!" % display_name.to_upper()
	welcome.add_theme_font_size_override("font_size", 28)
	welcome.add_theme_color_override("font_color", Color.WHITE)
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_box.add_child(welcome)
	var grade_label := Label.new()
	grade_label.text = grade
	grade_label.add_theme_font_size_override("font_size", 20)
	grade_label.add_theme_color_override("font_color", Color.WHITE)
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_box.add_child(grade_label)

	var pupils := _pupils_in_grade(grade)
	var summary := PanelContainer.new()
	summary.add_theme_stylebox_override("panel", _panel_style("#ffffff"))
	column.add_child(summary)
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 5)
	summary_box.add_theme_constant_override("margin_left", 16)
	summary_box.add_theme_constant_override("margin_right", 16)
	summary_box.add_theme_constant_override("margin_top", 14)
	summary_box.add_theme_constant_override("margin_bottom", 14)
	summary.add_child(summary_box)
	var count_title := Label.new()
	count_title.text = "GRADE 3 STUDENTS"
	count_title.add_theme_font_size_override("font_size", 15)
	count_title.add_theme_color_override("font_color", Color("#53627a"))
	count_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_box.add_child(count_title)
	var count := Label.new()
	count.text = str(pupils.size())
	count.add_theme_font_size_override("font_size", 42)
	count.add_theme_color_override("font_color", Color("#263858"))
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_box.add_child(count)

	var list_title := Label.new()
	list_title.text = "STUDENT PROGRESS"
	list_title.add_theme_font_size_override("font_size", 20)
	list_title.add_theme_color_override("font_color", Color("#263858"))
	column.add_child(list_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	if pupils.is_empty():
		var empty := Label.new()
		empty.text = "No Grade 3 student records yet."
		empty.add_theme_color_override("font_color", Color("#53627a"))
		list.add_child(empty)
	else:
		for pupil in pupils:
			var row := Button.new()
			var game_history: Variant = pupil.get("attempt_history", [])
			var game_count := game_history.size() if game_history is Array else 0
			row.text = "%s  •  Score %s  •  Stars %s  •  Games %s\nView performance history →" % [str(pupil.get("name", "Student")), str(pupil.get("total_score", 0)), str(pupil.get("total_stars", 0)), str(game_count)]
			row.custom_minimum_size = Vector2(0, 76)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_font_size_override("font_size", 16)
			row.pressed.connect(_open_student_history.bind(str(pupil.get("id", ""))))
			list.add_child(row)

	var report_status := Label.new()
	report_status.name = "ReportStatus"
	report_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report_status.add_theme_color_override("font_color", Color("#236b43"))
	column.add_child(report_status)
	var class_report := Button.new()
	class_report.text = "GENERATE GRADE REPORT (CSV)"
	class_report.custom_minimum_size = Vector2(0, 48)
	class_report.pressed.connect(_export_grade_report.bind(pupils))
	column.add_child(class_report)

	var logout := Button.new()
	logout.text = "LOG OUT"
	logout.custom_minimum_size = Vector2(0, 52)
	logout.pressed.connect(_logout)
	column.add_child(logout)

func _panel_style(color_hex: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color_hex)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _pupils_in_grade(grade: String) -> Array:
	var matching: Array = []
	for pupil in PlayerData.get_all_pupil_records():
		if str(pupil.get("grade", "")) == grade:
			matching.append(pupil)
	matching.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("name", "")).to_lower() < str(b.get("name", "")).to_lower())
	return matching

func _open_student_history(pupil_id: String) -> void:
	PlayerData.selected_student_id = pupil_id
	get_tree().change_scene_to_file("res://teacher/monitor.tscn")


func _export_grade_report(pupils: Array) -> void:
	var directory := "user://reports"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var grade := str(PlayerData.current_teacher.get("grade", "Grade 3")).to_lower().replace(" ", "_")
	var path := "%s/%s_mathquest_class_report.csv" % [directory, grade]
	var file := FileAccess.open(path, FileAccess.WRITE)
	var status := get_node_or_null("ReportStatus") as Label
	if file == null:
		if status:
			status.text = "Could not create the class report file."
		return
	file.store_line("Pupil,Grade,Date,Stage,Mode,Score,Correct,Wrong,Stars,DurationSeconds,QuestPoints,Passed")
	for pupil in pupils:
		var history: Variant = pupil.get("attempt_history", [])
		if not (history is Array):
			continue
		for attempt in history:
			var values: Array = [pupil.get("name", ""), pupil.get("grade", ""), attempt.get("date", ""), attempt.get("stage", ""), attempt.get("mode", ""), attempt.get("score", 0), attempt.get("correct", 0), attempt.get("wrong", 0), attempt.get("stars", 0), attempt.get("duration_seconds", 0), attempt.get("quest_points", 0), attempt.get("passed", false)]
			var escaped: Array[String] = []
			for value in values:
				escaped.append('"%s"' % str(value).replace('"', '""'))
			file.store_line(",".join(escaped))
	file.close()
	if status:
		status.text = "Grade report saved: %s" % ProjectSettings.globalize_path(path)


func _logout() -> void:
	PlayerData.logout()
	get_tree().change_scene_to_file(LOGIN_SCENE)
