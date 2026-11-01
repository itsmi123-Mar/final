extends Control

const DASHBOARD_SCENE := "res://teacher/main_scene.tscn"

var status_label: Label
var export_dialog: FileDialog
var pupil_record: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		child.queue_free()
	pupil_record = PlayerData.get_pupil_record(PlayerData.selected_student_id)
	_build_view()

func _build_view() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#eef4ff")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(key, 16)
	add_child(margin)
	var column := VBoxContainer.new()
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 9)
	margin.add_child(column)
	if pupil_record.is_empty():
		column.add_child(_label("Pupil record not found.", 18, Color("#263858")))
		_add_button(column, "BACK TO STUDENTS", _back)
		return

	var name_label := _label(str(pupil_record.get("name", "Pupil")).to_upper(), 22, Color("#263858"), HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(name_label)
	column.add_child(_label("%s  •  PERFORMANCE RECORD" % str(pupil_record.get("grade", "")), 14, Color("#53627a"), HORIZONTAL_ALIGNMENT_CENTER))

	var completed: Variant = pupil_record.get("completed_levels", [])
	var completed_count := completed.size() if completed is Array else 0
	var history: Variant = pupil_record.get("attempt_history", [])
	var attempt_count := history.size() if history is Array else 0
	var stats := _panel("#ffffff")
	column.add_child(stats)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 14)
	stats_grid.add_theme_constant_override("v_separation", 6)
	stats.add_child(stats_grid)
	_add_stat(stats_grid, "TOTAL SCORE", str(pupil_record.get("total_score", 0)))
	_add_stat(stats_grid, "TOTAL STARS", str(pupil_record.get("total_stars", 0)))
	_add_stat(stats_grid, "LEVELS COMPLETED", "%d / 10" % completed_count)
	_add_stat(stats_grid, "RECORDED ATTEMPTS", str(attempt_count))

	column.add_child(_label("TEST RESULTS", 17, Color("#263858")))
	var test_panel := _panel("#ffffff")
	column.add_child(test_panel)
	var results: Dictionary = pupil_record.get("level_results", {})
	var pre: Dictionary = results.get("pretest", {})
	var post: Dictionary = results.get("posttest", {})
	var test_text := "Pre-test: %s     |     Post-test: %s" % [str(pre.get("score", "No result")), str(post.get("score", "No result"))]
	if not pre.is_empty() and not post.is_empty():
		var delta := int(post.get("score", 0)) - int(pre.get("score", 0))
		test_text += "\nChange: %s%d points" % ["+" if delta > 0 else "", delta]
	else:
		test_text += "\nImprovement is available after both tests are completed."
	var test_label := _label(test_text, 14, Color("#263858"))
	test_panel.add_child(test_label)

	column.add_child(_label("LEVEL PROGRESS", 17, Color("#263858")))
	var progress_panel := _panel("#ffffff")
	column.add_child(progress_panel)
	var level_text := "Completed: "
	var completed_names: Array[String] = []
	if completed is Array:
		for level in completed:
			completed_names.append(str(level))
	if completed_names.is_empty():
		level_text += "No levels completed yet"
	else:
		for index in range(completed_names.size()):
			if index > 0:
				level_text += ", "
			level_text += completed_names[index]
	var progress_label := _label(level_text, 13, Color("#263858"))
	progress_panel.add_child(progress_label)

	column.add_child(_label("GAME ATTEMPTS  •  NEWEST FIRST", 17, Color("#263858")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var history_box := VBoxContainer.new()
	history_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_box.add_theme_constant_override("separation", 7)
	scroll.add_child(history_box)
	if not history is Array or history.is_empty():
		history_box.add_child(_label("No performance records are available for this pupil yet.", 14, Color("#53627a")))
	else:
		for index in range(history.size() - 1, -1, -1):
			var attempt: Dictionary = history[index]
			var seconds := int(float(attempt.get("duration_seconds", 0.0)))
			var passed_text := "PASSED" if bool(attempt.get("passed", false)) else "RETRY"
			var detail := "%s  •  %s\nScore: %s  |  Correct: %s  |  Wrong: %s  |  Stars: %s\nTime: %02d:%02d  |  Quest points: %s\n%s  •  %s" % [str(attempt.get("stage", "Game")), str(attempt.get("mode", "Level")), str(attempt.get("score", 0)), str(attempt.get("correct", 0)), str(attempt.get("wrong", 0)), str(attempt.get("stars", 0)), seconds / 60, seconds % 60, str(attempt.get("quest_points", 0)), str(attempt.get("date", "Date unavailable")), passed_text]
			var card := _panel("#ffffff")
			history_box.add_child(card)
			card.add_child(_label(detail, 13, Color("#263858")))

	status_label = _label("", 12, Color("#236b43"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)
	_add_button(column, "GENERATE & DOWNLOAD PUPIL RECORD (CSV)", _choose_export)
	_add_button(column, "BACK TO STUDENTS", _back)

	export_dialog = FileDialog.new()
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.add_filter("*.csv", "CSV spreadsheet")
	export_dialog.file_selected.connect(_save_student_report)
	add_child(export_dialog)

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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color_hex)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _add_stat(parent: Control, caption: String, value: String) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	parent.add_child(box)
	box.add_child(_label(caption, 10, Color("#64748b")))
	box.add_child(_label(value, 21, Color("#263858")))

func _add_button(parent: Control, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)

func _choose_export() -> void:
	var safe_name := str(pupil_record.get("name", "pupil")).to_lower().replace(" ", "_").replace(".", "").replace("/", "_").replace("\\", "_")
	export_dialog.current_file = "%s_mathquest_performance_record.csv" % safe_name
	export_dialog.popup_centered_ratio(0.8)

func _save_student_report(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Unable to write the selected file. Choose a writable folder and try again."
		return
	file.store_line("RecordType,Pupil,Grade,TotalScore,TotalStars,CompletedLevels,PreTestScore,PostTestScore,Improvement,Date,Stage,Mode,Score,Correct,Wrong,Stars,DurationSeconds,QuestPoints,Passed,RecordStatus")
	var results: Dictionary = pupil_record.get("level_results", {})
	var pre: Dictionary = results.get("pretest", {})
	var post: Dictionary = results.get("posttest", {})
	var completed: Variant = pupil_record.get("completed_levels", [])
	var improvement: Variant = ""
	if not pre.is_empty() and not post.is_empty():
		improvement = int(post.get("score", 0)) - int(pre.get("score", 0))
	var summary: Array = ["SUMMARY", pupil_record.get("name", ""), pupil_record.get("grade", ""), pupil_record.get("total_score", 0), pupil_record.get("total_stars", 0), completed.size() if completed is Array else 0, pre.get("score", ""), post.get("score", ""), improvement, "", "", "", "", "", "", "", "", "", "", "No saved attempts" if (pupil_record.get("attempt_history", []) is Array and pupil_record.get("attempt_history", []).is_empty()) else "Saved results available"]
	file.store_line(_csv_row(summary))
	var history: Variant = pupil_record.get("attempt_history", [])
	if history is Array:
		for attempt in history:
			var values: Array = ["ATTEMPT", pupil_record.get("name", ""), pupil_record.get("grade", ""), "", "", "", "", "", "", attempt.get("date", ""), attempt.get("stage", ""), attempt.get("mode", ""), attempt.get("score", 0), attempt.get("correct", 0), attempt.get("wrong", 0), attempt.get("stars", 0), attempt.get("duration_seconds", 0), attempt.get("quest_points", 0), attempt.get("passed", false), "Recorded attempt"]
			file.store_line(_csv_row(values))
	file.close()
	status_label.text = "Pupil record downloaded: %s" % path

func _csv_row(values: Array) -> String:
	var cells: Array[String] = []
	for value in values:
		cells.append('"%s"' % str(value).replace('"', '""'))
	return ",".join(cells)

func _back() -> void:
	get_tree().change_scene_to_file(DASHBOARD_SCENE)
