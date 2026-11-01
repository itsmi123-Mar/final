extends Control

const DASHBOARD_SCENE := "res://teacher/main_scene.tscn"

var status_label: Label
var history_box: VBoxContainer

func _ready() -> void:
	for child in get_children():
		child.queue_free()
	_build_view()

func _build_view() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#eaf3ff")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(key, 18)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var pupil := PlayerData.get_pupil_record(PlayerData.selected_student_id)
	if pupil.is_empty():
		var missing := Label.new()
		missing.text = "Student record not found."
		column.add_child(missing)
		_add_button(column, "BACK TO STUDENTS", func(): get_tree().change_scene_to_file(DASHBOARD_SCENE))
		return
	var title := Label.new()
	title.text = "%s - PERFORMANCE HISTORY" % str(pupil.get("name", "Student")).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("#263858"))
	column.add_child(title)
	var profile := Label.new()
	var completed_value: Variant = pupil.get("completed_levels", [])
	var completed_count := completed_value.size() if completed_value is Array else 0
	profile.text = "%s  |  Total score: %s  |  Total stars: %s  |  Levels completed: %s/10" % [str(pupil.get("grade", "")), str(pupil.get("total_score", 0)), str(pupil.get("total_stars", 0)), str(completed_count)]
	profile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile.add_theme_color_override("font_color", Color("#263858"))
	column.add_child(profile)
	var test_summary := _test_comparison(pupil)
	test_summary.add_theme_color_override("font_color", Color("#263858"))
	test_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(test_summary)
	var heading := Label.new()
	heading.text = "ALL GAME ATTEMPTS (NEWEST FIRST)"
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color("#263858"))
	column.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	history_box = VBoxContainer.new()
	history_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_box.add_theme_constant_override("separation", 7)
	scroll.add_child(history_box)
	var history: Array = pupil.get("attempt_history", [])
	if history.is_empty():
		var empty := Label.new()
		empty.text = "No game history has been recorded for this pupil yet."
		history_box.add_child(empty)
	else:
		for i in range(history.size() - 1, -1, -1):
			var attempt: Dictionary = history[i]
			var seconds := int(float(attempt.get("duration_seconds", 0.0)))
			var passed_text := "PASSED" if bool(attempt.get("passed", false)) else "RETRY"
			var detail := "%s  |  %s\nScore: %s  |  Correct: %s  |  Wrong: %s  |  Stars: %s/3\nTime: %02d:%02d  |  Quest points: %s\n%s  |  %s" % [str(attempt.get("stage", "Game")), str(attempt.get("mode", "Level")), str(attempt.get("score", 0)), str(attempt.get("correct", 0)), str(attempt.get("wrong", 0)), str(attempt.get("stars", 0)), seconds / 60, seconds % 60, str(attempt.get("quest_points", 0)), str(attempt.get("date", "")), passed_text]
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", _card_style())
			history_box.add_child(card)
			var label := Label.new()
			label.text = detail
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_color_override("font_color", Color("#263858"))
			label.add_theme_font_size_override("font_size", 14)
			card.add_child(label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color("#236b43"))
	column.add_child(status_label)
	_add_button(column, "GENERATE / DOWNLOAD STUDENT RECORD (CSV)", _export_report.bind(pupil))
	_add_button(column, "BACK TO STUDENTS", func(): get_tree().change_scene_to_file(DASHBOARD_SCENE))

func _test_comparison(pupil: Dictionary) -> Label:
	var results: Dictionary = pupil.get("level_results", {})
	var pre: Dictionary = results.get("pretest", {})
	var post: Dictionary = results.get("posttest", {})
	var text := "Pre-test: %s/20    Post-test: %s/20" % [str(pre.get("score", "—")), str(post.get("score", "—"))]
	if not pre.is_empty() and not post.is_empty():
		var change := int(post.get("score", 0)) - int(pre.get("score", 0))
		text += "    Improvement: %s%s points" % ["+" if change > 0 else "", str(change)]
	else:
		text += "    Complete both tests to view improvement."
	var label := Label.new()
	label.text = text
	return label

func _add_button(parent: Control, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 46)
	button.pressed.connect(callback)
	parent.add_child(button)

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

func _export_report(pupil: Dictionary) -> void:
	var directory := "user://reports"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var safe_name := str(pupil.get("name", "student")).to_lower().replace(" ", "_")
	var path := "%s/%s_mathquest_record.csv" % [directory, safe_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Could not create the report file."
		return
	file.store_line("Date,Stage,Mode,Score,Correct,Wrong,Stars,DurationSeconds,QuestPoints,Passed")
	for attempt in pupil.get("attempt_history", []):
		var values: Array = [attempt.get("date", ""), attempt.get("stage", ""), attempt.get("mode", ""), attempt.get("score", 0), attempt.get("correct", 0), attempt.get("wrong", 0), attempt.get("stars", 0), attempt.get("duration_seconds", 0), attempt.get("quest_points", 0), attempt.get("passed", false)]
		var escaped: Array[String] = []
		for value in values:
			escaped.append('"%s"' % str(value).replace('"', '""'))
		file.store_line(",".join(escaped))
	file.close()
	status_label.text = "Record generated: %s" % ProjectSettings.globalize_path(path)
