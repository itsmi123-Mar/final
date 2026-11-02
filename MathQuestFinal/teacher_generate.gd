
extends Control

# ============================================================
# MATHQUEST - TEACHER GENERATE RECORDS
# UC-7: Generate Records
# Scene: res://teacher/gen.tscn
# ============================================================

const DASHBOARD_SCENE := "res://teacher/main_scene.tscn"

var pupil_records: Array = []
var selected_record: Dictionary = {}
var selected_pupil_id: String = ""
var selected_mode: String = "group"

var pupil_list: VBoxContainer
var report_content: VBoxContainer
var status_label: Label
var selected_label: Label
var download_dialog: FileDialog


# ============================================================
# INITIALIZATION
# ============================================================

func _ready() -> void:
	if PlayerData.current_user_role != "teacher":
		get_tree().change_scene_to_file("res://scene/login.tscn")
		return

	_build_interface()
	_load_pupils()

	if not PlayerData.selected_teacher_pupil_id.is_empty():
		_select_pupil(PlayerData.selected_teacher_pupil_id)
	elif not pupil_records.is_empty():
		_select_group()
	else:
		_clear_report()
		_show_status("No pupil records are available.")


# ============================================================
# DATA HELPERS
# ============================================================

# completed_levels may be an Array or an integer.
func _get_completed_level_count(record: Dictionary) -> int:
	var completed: Variant = record.get("completed_levels", 0)

	if completed is Array:
		return completed.size()

	if completed is int:
		return completed

	if completed is float:
		return int(completed)

	return 0


func _get_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value

	return {}


func _get_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback

	return str(value)


# ============================================================
# BUILD USER INTERFACE
# ============================================================

func _build_interface() -> void:
	for node_name in ["bg", "back", "Button"]:
		var old_node := get_node_or_null(node_name)
		if old_node is Control:
			old_node.hide()

	var background := ColorRect.new()
	background.name = "GenerateBackground"
	background.color = Color("#edf3ed")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)

	var margin := MarginContainer.new()
	margin.name = "GenerateLayout"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	add_child(margin)

	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 9)
	margin.add_child(main)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main.add_child(header)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(85, 45)
	back_button.pressed.connect(_go_back)
	header.add_child(back_button)

	var title := Label.new()
	title.text = "GENERATE RECORDS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("#174b35"))
	header.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "View and download pupil performance records."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 14)
	main.add_child(subtitle)

	# Pupil selection
	var pupil_heading := Label.new()
	pupil_heading.text = "AVAILABLE PUPILS"
	pupil_heading.add_theme_font_size_override("font_size", 18)
	pupil_heading.add_theme_color_override("font_color", Color("#174b35"))
	main.add_child(pupil_heading)

	var group_button := Button.new()
	group_button.text = "Generate Group Report"
	group_button.custom_minimum_size = Vector2(0, 45)
	group_button.pressed.connect(_select_group)
	main.add_child(group_button)

	var pupil_scroll := ScrollContainer.new()
	pupil_scroll.custom_minimum_size = Vector2(0, 170)
	pupil_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pupil_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(pupil_scroll)

	pupil_list = VBoxContainer.new()
	pupil_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pupil_list.add_theme_constant_override("separation", 6)
	pupil_scroll.add_child(pupil_list)

	selected_label = Label.new()
	selected_label.text = "Selected report: Group"
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_label.add_theme_font_size_override("font_size", 15)
	selected_label.add_theme_color_override("font_color", Color("#174b35"))
	main.add_child(selected_label)

	# Report preview
	var report_heading := Label.new()
	report_heading.text = "PERFORMANCE SUMMARY"
	report_heading.add_theme_font_size_override("font_size", 18)
	report_heading.add_theme_color_override("font_color", Color("#174b35"))
	main.add_child(report_heading)

	var report_panel := PanelContainer.new()
	report_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_panel.custom_minimum_size = Vector2(0, 260)
	main.add_child(report_panel)

	var report_scroll := ScrollContainer.new()
	report_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	report_panel.add_child(report_scroll)

	report_content = VBoxContainer.new()
	report_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_content.add_theme_constant_override("separation", 7)
	report_scroll.add_child(report_content)

	# Status
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color("#a04432"))
	main.add_child(status_label)

	# Download
	var download_button := Button.new()
	download_button.text = "DOWNLOAD EXCEL REPORT"
	download_button.custom_minimum_size = Vector2(0, 55)
	download_button.add_theme_font_size_override("font_size", 18)
	download_button.pressed.connect(_download_record)
	main.add_child(download_button)

	_setup_download_dialog()


# ============================================================
# DOWNLOAD DIALOG
# ============================================================

func _setup_download_dialog() -> void:
	download_dialog = FileDialog.new()
	download_dialog.name = "RecordSaveDialog"
	download_dialog.title = "Save MathQuest Performance Report"
	download_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	download_dialog.access = FileDialog.ACCESS_FILESYSTEM
	download_dialog.add_filter("*.csv", "Excel-compatible CSV")
	download_dialog.current_file = "MathQuest_Pupil_Record.csv"

	var documents_path := OS.get_system_dir(
		OS.SYSTEM_DIR_DOCUMENTS
	)

	if not documents_path.is_empty():
		download_dialog.current_dir = documents_path
	else:
		download_dialog.current_dir = OS.get_system_dir(
			OS.SYSTEM_DIR_DESKTOP
		)

	download_dialog.file_selected.connect(_save_record)
	add_child(download_dialog)


# ============================================================
# LOAD PUPILS
# ============================================================

func _load_pupils() -> void:
	pupil_records = PlayerData.get_teacher_pupil_records()

	for child in pupil_list.get_children():
		child.queue_free()

	if pupil_records.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No pupils are registered in your grade."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pupil_list.add_child(empty_label)
		return

	for item in pupil_records:
		if not item is Dictionary:
			continue

		var record: Dictionary = item
		var pupil_id := str(record.get("id", ""))
		var pupil_name := str(record.get("name", "Pupil"))
		var pupil_score := int(record.get("total_score", 0))

		var pupil_button := Button.new()
		pupil_button.text = "%s | Score: %d" % [
			pupil_name,
			pupil_score
		]
		pupil_button.custom_minimum_size = Vector2(0, 44)
		pupil_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pupil_button.pressed.connect(
			_select_pupil.bind(pupil_id)
		)

		pupil_list.add_child(pupil_button)


# ============================================================
# SELECT INDIVIDUAL PUPIL
# ============================================================

func _select_pupil(pupil_id: String) -> void:
	if pupil_id.is_empty():
		_show_status("Invalid pupil selection.")
		return

	var pupil_report: Dictionary = PlayerData.get_pupil_report(
		pupil_id
	)

	if pupil_report.is_empty():
		selected_record.clear()
		selected_pupil_id = ""
		_clear_report()
		_show_status("Unable to retrieve this pupil's report.")
		return

	var progress_value: Variant = pupil_report.get("progress", {})

	if not progress_value is Dictionary:
		_show_status("The pupil performance data is invalid.")
		return

	selected_record = progress_value.duplicate(true)

	selected_pupil_id = pupil_id
	selected_mode = "single"

	PlayerData.selected_teacher_pupil_id = pupil_id

	selected_label.text = "Selected pupil: " + str(
		pupil_report.get("learner", "Pupil")
	)

	_display_individual_report(selected_record)
	_show_status("Pupil performance report loaded.")


# ============================================================
# SELECT GROUP
# ============================================================

func _select_group() -> void:
	selected_mode = "group"
	selected_pupil_id = ""
	selected_record.clear()

	pupil_records = PlayerData.get_teacher_pupil_records()

	selected_label.text = "Selected report: All pupils - Grade " + str(
		PlayerData.get_teacher_grade()
	)

	if pupil_records.is_empty():
		_clear_report()
		_show_status("No pupil records are available.")
		return

	_display_group_report()
	_show_status("Group performance report loaded.")


# ============================================================
# REPORT DISPLAY HELPERS
# ============================================================

func _clear_report() -> void:
	for child in report_content.get_children():
		child.queue_free()


func _add_report_line(
	value: String,
	font_size: int = 14,
	is_heading: bool = false
) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)

	if is_heading:
		label.add_theme_color_override(
			"font_color",
			Color("#174b35")
		)
	else:
		label.add_theme_color_override(
			"font_color",
			Color("#263d30")
		)

	report_content.add_child(label)


# ============================================================
# INDIVIDUAL PERFORMANCE REPORT
# ============================================================

func _display_individual_report(record: Dictionary) -> void:
	_clear_report()

	var comparison: Dictionary = PlayerData.get_pre_post_comparison(
		record
	)

	var completed_count := _get_completed_level_count(record)

	var results: Dictionary = _get_dictionary(
		record.get("level_results", {})
	)

	var operations: Dictionary = _get_dictionary(
		record.get("operation_stats", {})
	)

	_add_report_line("PUPIL INFORMATION", 17, true)
	_add_report_line("Name: " + str(record.get("name", "Pupil")))
	_add_report_line("LRN: " + str(record.get("id", "")))
	_add_report_line("Grade: " + str(record.get("grade", "")))

	_add_report_line("OVERALL PERFORMANCE", 17, true)
	_add_report_line(
		"Total Score: %d" % int(record.get("total_score", 0))
	)
	_add_report_line(
		"Total Stars: %d" % int(record.get("total_stars", 0))
	)
	_add_report_line(
		"Completed Levels: %d" % completed_count
	)

	_add_report_line("TEST RESULTS", 17, true)

	var pretest: Dictionary = _get_dictionary(
		results.get("pretest", {})
	)

	var posttest: Dictionary = _get_dictionary(
		results.get("posttest", {})
	)

	if pretest.is_empty() and posttest.is_empty():
		_add_report_line("No pre-test or post-test results recorded.")
	else:
		_add_report_line(
			"Pre-test Score: %d" % int(
				comparison.get("pretest_score", 0)
			)
		)
		_add_report_line(
			"Post-test Score: %d" % int(
				comparison.get("posttest_score", 0)
			)
		)
		_add_report_line(
			"Improvement: %+d" % int(
				comparison.get("improvement", 0)
			)
		)

	_add_report_line("LEVEL RESULTS", 17, true)

	if results.is_empty():
		_add_report_line("No level results recorded.")
	else:
		var result_ids: Array = results.keys()
		result_ids.sort()

		for result_id in result_ids:
			var result: Dictionary = _get_dictionary(
				results[result_id]
			)

			if result.is_empty():
				continue

			_add_report_line(str(result_id), 15, true)
			_add_report_line(
				"Score: %d | Stars: %d" % [
					int(result.get("score", 0)),
					int(result.get("stars", 0))
				]
			)
			_add_report_line(
				"Correct: %d | Wrong: %d" % [
					int(result.get("correct", 0)),
					int(result.get("wrong", 0))
				]
			)
			_add_report_line(
				"Date: " + str(result.get("date", "Not recorded"))
			)

	_add_report_line(
		"MATHEMATICAL OPERATION PERFORMANCE",
		17,
		true
	)

	if operations.is_empty():
		_add_report_line("No operation statistics recorded.")
	else:
		var operation_ids: Array = operations.keys()
		operation_ids.sort()

		for operation_id in operation_ids:
			_add_report_line(
				"%s: %s" % [
					str(operation_id),
					str(operations[operation_id])
				]
			)


# ============================================================
# GROUP PERFORMANCE REPORT
# ============================================================

func _display_group_report() -> void:
	_clear_report()

	var total_score := 0
	var total_stars := 0
	var total_completed := 0
	var pupils_with_results := 0

	_add_report_line("GROUP PERFORMANCE SUMMARY", 18, true)
	_add_report_line(
		"Grade: " + str(PlayerData.get_teacher_grade())
	)
	_add_report_line(
		"Number of pupils: %d" % pupil_records.size()
	)

	for item in pupil_records:
		if not item is Dictionary:
			continue

		var record: Dictionary = item

		total_score += int(record.get("total_score", 0))
		total_stars += int(record.get("total_stars", 0))
		total_completed += _get_completed_level_count(record)

		var results: Dictionary = _get_dictionary(
			record.get("level_results", {})
		)

		if not results.is_empty():
			pupils_with_results += 1

	_add_report_line("COMBINED PERFORMANCE", 17, true)
	_add_report_line("Combined Score: %d" % total_score)
	_add_report_line("Combined Stars: %d" % total_stars)
	_add_report_line("Completed Levels: %d" % total_completed)
	_add_report_line(
		"Pupils with saved results: %d" % pupils_with_results
	)

	_add_report_line("INDIVIDUAL PUPIL SUMMARIES", 17, true)

	for item in pupil_records:
		if not item is Dictionary:
			continue

		var record: Dictionary = item
		var completed_count := _get_completed_level_count(record)

		var comparison: Dictionary = PlayerData.get_pre_post_comparison(
			record
		)

		_add_report_line(
			str(record.get("name", "Pupil")),
			15,
			true
		)

		_add_report_line(
			"Score: %d | Stars: %d | Completed Levels: %d" % [
				int(record.get("total_score", 0)),
				int(record.get("total_stars", 0)),
				completed_count
			]
		)

		_add_report_line(
			"Pre-test: %d | Post-test: %d | Improvement: %+d" % [
				int(comparison.get("pretest_score", 0)),
				int(comparison.get("posttest_score", 0)),
				int(comparison.get("improvement", 0))
			]
		)


# ============================================================
# DOWNLOAD REPORT
# ============================================================

func _download_record() -> void:
	pupil_records = PlayerData.get_teacher_pupil_records()

	if pupil_records.is_empty():
		_show_status("No performance records are available.")
		return

	if selected_mode == "single":
		if selected_pupil_id.is_empty():
			_show_status("Please select a pupil first.")
			return

		var pupil_report: Dictionary = PlayerData.get_pupil_report(
			selected_pupil_id
		)

		if pupil_report.is_empty():
			_show_status("Unable to retrieve the pupil report.")
			return

		var progress_value: Variant = pupil_report.get("progress", {})

		if not progress_value is Dictionary:
			_show_status("The pupil performance data is invalid.")
			return

		selected_record = progress_value.duplicate(true)
		download_dialog.current_file = "MathQuest_Pupil_Record.csv"

	else:
		download_dialog.current_file = "MathQuest_Group_Records.csv"

	download_dialog.popup_centered_ratio(0.8)


func _save_record(path: String) -> void:
	var csv_content := ""

	if selected_mode == "single":
		if selected_record.is_empty():
			_show_status("No pupil record selected.")
			return

		csv_content = PlayerData.build_record_csv(
			selected_record
		)

	else:
		if pupil_records.is_empty():
			_show_status("No pupil records are available.")
			return

		csv_content = _build_group_csv(pupil_records)

	if csv_content.is_empty():
		_show_status("Unable to generate the performance report.")
		return

	# UTF-8 BOM helps Microsoft Excel recognize the encoding.
	var excel_content := "\uFEFF" + csv_content

	var file := FileAccess.open(path, FileAccess.WRITE)

	if file == null:
		_show_status("Unable to save the report. Check the selected folder.")
		return

	file.store_string(excel_content)
	file.close()

	_show_status("Report saved successfully: " + path)


# ============================================================
# GROUP CSV
# ============================================================

func _build_group_csv(records: Array) -> String:
	var lines: Array[String] = []

	lines.append("MATHQUEST GROUP PERFORMANCE REPORT")
	lines.append(
		"Grade," + _csv_cell(str(PlayerData.get_teacher_grade()))
	)
	lines.append("")
	lines.append(
		"Name,LRN,Grade,Total Score,Total Stars,Completed Levels," +
		"Assessment/Level,Score,Stars,Correct,Wrong,Date," +
		"Pre-test Score,Post-test Score,Improvement"
	)

	for item in records:
		if not item is Dictionary:
			continue

		var record: Dictionary = item

		var completed_count := _get_completed_level_count(record)

		var results: Dictionary = _get_dictionary(
			record.get("level_results", {})
		)

		var comparison: Dictionary = PlayerData.get_pre_post_comparison(
			record
		)

		var pupil_name := _csv_cell(
			str(record.get("name", ""))
		)

		var pupil_id := _csv_cell(
			str(record.get("id", ""))
		)

		var grade := _csv_cell(
			str(record.get("grade", ""))
		)

		var total_score := str(record.get("total_score", 0))
		var total_stars := str(record.get("total_stars", 0))
		var completed_text := str(completed_count)

		var pre_score := str(
			comparison.get("pretest_score", 0)
		)

		var post_score := str(
			comparison.get("posttest_score", 0)
		)

		var improvement := str(
			comparison.get("improvement", 0)
		)

		if results.is_empty():
			lines.append(
				"%s,%s,%s,%s,%s,%s,,,,,,,%s,%s,%s" % [
					pupil_name,
					pupil_id,
					grade,
					total_score,
					total_stars,
					completed_text,
					pre_score,
					post_score,
					improvement
				]
			)
			continue

		var result_ids: Array = results.keys()
		result_ids.sort()

		for result_id in result_ids:
			var result: Dictionary = _get_dictionary(
				results[result_id]
			)

			if result.is_empty():
				continue

			lines.append(
				"%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" % [
					pupil_name,
					pupil_id,
					grade,
					total_score,
					total_stars,
					completed_text,
					_csv_cell(str(result_id)),
					str(result.get("score", 0)),
					str(result.get("stars", 0)),
					str(result.get("correct", 0)),
					str(result.get("wrong", 0)),
					_csv_cell(str(result.get("date", ""))),
					pre_score,
					post_score,
					improvement
				]
			)

	return "\n".join(lines)


func _csv_cell(value: String) -> String:
	return "\"" + value.replace("\"", "\"\"") + "\""


# ============================================================
# NAVIGATION AND STATUS
# ============================================================

func _go_back() -> void:
	get_tree().change_scene_to_file(DASHBOARD_SCENE)


func _show_status(message: String) -> void:
	if status_label:
		status_label.text = message
