extends Control

const LOGIN_SCENE := "res://scene/login.tscn"
const MONITOR_SCENE := "res://teacher/monitor.tscn"

var report_dialog: FileDialog
var status_label: Label
var grade_pupils: Array = []

func _ready() -> void:
	for child in get_children():
		child.queue_free()
	_build_dashboard()

func _build_dashboard() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#eef4ff")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var column := VBoxContainer.new()
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var teacher: Dictionary = PlayerData.current_teacher
	var display_name := str(teacher.get("name", "Teacher"))
	var grade := str(teacher.get("grade", "Grade 3"))
	grade_pupils = _pupils_in_grade(grade)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _panel_style("#6542a6"))
	column.add_child(header)
	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 4)
	header.add_child(header_box)
	var welcome := _label("TEACHER DASHBOARD", 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	header_box.add_child(welcome)
	var identity := _label("%s  •  %s" % [display_name, grade], 16, Color("#f1eaff"), HORIZONTAL_ALIGNMENT_CENTER)
	header_box.add_child(identity)

	var summary := _panel("#ffffff")
	column.add_child(summary)
	var summary_box := VBoxContainer.new()
	summary.add_child(summary_box)
	var count := 0
	var active := 0
	var attempts_total := 0
	for pupil in grade_pupils:
		count += 1
		var history: Variant = pupil.get("attempt_history", [])
		if history is Array:
			attempts_total += history.size()
			if not history.is_empty():
				active += 1
	var summary_label := _label("%d PUPILS     •     %d WITH SAVED RESULTS     •     %d GAME ATTEMPTS" % [count, active, attempts_total], 15, Color("#263858"), HORIZONTAL_ALIGNMENT_CENTER)
	summary_box.add_child(summary_label)

	var section := _label("MONITOR PUPIL PERFORMANCE", 19, Color("#263858"))
	column.add_child(section)
	var hint := _label("Select a pupil to review scores, completed levels, test results, progress, and attempt history.", 13, Color("#53627a"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 7)
	scroll.add_child(list)
	if grade_pupils.is_empty():
		list.add_child(_label("No pupil accounts are assigned to this grade.", 14, Color("#53627a")))
	else:
		for pupil in grade_pupils:
			var history: Variant = pupil.get("attempt_history", [])
			var games := history.size() if history is Array else 0
			var completed: Variant = pupil.get("completed_levels", [])
			var completed_count := completed.size() if completed is Array else 0
			var row := Button.new()
			row.text = "%s\nScore %s  •  Levels %d/10  •  Attempts %d" % [str(pupil.get("name", "Pupil")), str(pupil.get("total_score", 0)), completed_count, games]
			row.custom_minimum_size = Vector2(0, 68)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_font_size_override("font_size", 15)
			row.pressed.connect(_open_student.bind(str(pupil.get("id", ""))))
			list.add_child(row)

	status_label = _label("", 12, Color("#236b43"))
	status_label.name = "ReportStatus"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)
	var export_button := Button.new()
	export_button.text = "GENERATE & DOWNLOAD GRADE RECORD (CSV)"
	export_button.custom_minimum_size = Vector2(0, 48)
	export_button.pressed.connect(_choose_grade_export)
	column.add_child(export_button)
	var logout := Button.new()
	logout.text = "LOG OUT"
	logout.custom_minimum_size = Vector2(0, 44)
	logout.pressed.connect(_logout)
	column.add_child(logout)

	report_dialog = FileDialog.new()
	report_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	report_dialog.access = FileDialog.ACCESS_FILESYSTEM
	report_dialog.add_filter("*.csv", "CSV spreadsheet")
	report_dialog.file_selected.connect(_save_grade_report)
	add_child(report_dialog)

func _label(value: String, size: int, color: Color, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _panel(color_hex: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(color_hex))
	return panel

func _panel_style(color_hex: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color_hex)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
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

func _open_student(pupil_id: String) -> void:
	if pupil_id.is_empty():
		return
	PlayerData.selected_student_id = pupil_id
	get_tree().change_scene_to_file(MONITOR_SCENE)

func _choose_grade_export() -> void:
	if grade_pupils.is_empty():
		status_label.text = "No pupil records are available to export."
		return
	var grade := str(PlayerData.current_teacher.get("grade", "Grade")).to_lower().replace(" ", "_")
	report_dialog.current_file = "%s_mathquest_class_record.csv" % grade
	report_dialog.popup_centered_ratio(0.8)

func _save_grade_report(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Unable to write the selected file. Choose a writable folder and try again."
		return
	file.store_line("RecordType,Pupil,Grade,TotalScore,TotalStars,CompletedLevels,PreTestScore,PostTestScore,Improvement,Date,Stage,Mode,Score,Correct,Wrong,Stars,DurationSeconds,QuestPoints,Passed,RecordStatus")
	for pupil in grade_pupils:
		_write_pupil_summary(file, pupil)
		_write_attempt_rows(file, pupil)
	file.close()
	status_label.text = "Grade record downloaded: %s" % path

func _write_pupil_summary(file: FileAccess, pupil: Dictionary) -> void:
	var results: Dictionary = pupil.get("level_results", {})
	var pre: Dictionary = results.get("pretest", {})
	var post: Dictionary = results.get("posttest", {})
	var improvement: Variant = ""
	if not pre.is_empty() and not post.is_empty():
		improvement = int(post.get("score", 0)) - int(pre.get("score", 0))
	var completed: Variant = pupil.get("completed_levels", [])
	var values: Array = ["SUMMARY", pupil.get("name", ""), pupil.get("grade", ""), pupil.get("total_score", 0), pupil.get("total_stars", 0), completed.size() if completed is Array else 0, pre.get("score", ""), post.get("score", ""), improvement, "", "", "", "", "", "", "", "", "", "", "No saved attempts" if (pupil.get("attempt_history", []) is Array and pupil.get("attempt_history", []).is_empty()) else "Saved results available"]
	file.store_line(_csv_row(values))

func _write_attempt_rows(file: FileAccess, pupil: Dictionary) -> void:
	var history: Variant = pupil.get("attempt_history", [])
	if not history is Array:
		return
	for attempt in history:
		var values: Array = ["ATTEMPT", pupil.get("name", ""), pupil.get("grade", ""), "", "", "", "", "", "", attempt.get("date", ""), attempt.get("stage", ""), attempt.get("mode", ""), attempt.get("score", 0), attempt.get("correct", 0), attempt.get("wrong", 0), attempt.get("stars", 0), attempt.get("duration_seconds", 0), attempt.get("quest_points", 0), attempt.get("passed", false), "Recorded attempt"]
		file.store_line(_csv_row(values))

func _csv_row(values: Array) -> String:
	var cells: Array[String] = []
	for value in values:
		cells.append('"%s"' % str(value).replace('"', '""'))
	return ",".join(cells)

func _logout() -> void:
	PlayerData.logout()
	get_tree().change_scene_to_file(LOGIN_SCENE)
