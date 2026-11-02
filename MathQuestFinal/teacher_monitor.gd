
extends Control

const LOGIN_SCENE := "res://scene/login.tscn"
const DASHBOARD_SCENE := "res://teacher/main_scene.tscn"

const DESIGN_SIZE := Vector2(1947, 1329)

var content_root: Control
var background: TextureRect
var details_scroll: ScrollContainer
var details_box: VBoxContainer
var selected_record: Dictionary = {}


func _ready() -> void:
	if PlayerData.current_user_role != "teacher":
		get_tree().change_scene_to_file(LOGIN_SCENE)
		return

	_setup_original_ui()
	_load_pupil_performance()

	if not get_viewport().size_changed.is_connected(
		_update_layout
	):
		get_viewport().size_changed.connect(_update_layout)


# =====================================================
# ORIGINAL UI AND RESPONSIVE SIZE
# =====================================================

func _setup_original_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	content_root = Control.new()
	content_root.name = "OriginalMonitorUI"
	content_root.size = DESIGN_SIZE
	add_child(content_root)

	var original_children: Array[Node] = []

	for child in get_children():
		if child != content_root:
			original_children.append(child)

	for child in original_children:
		remove_child(child)
		content_root.add_child(child)

	move_child(content_root, 0)

	background = content_root.get_node_or_null(
		"TextureRect"
	) as TextureRect

	var back_button := content_root.get_node_or_null(
		"back"
	) as BaseButton

	if back_button != null:
		if not back_button.pressed.is_connected(_go_back):
			back_button.pressed.connect(_go_back)

		if back_button is TextureButton:
			var texture_button := back_button as TextureButton
			texture_button.ignore_texture_size = true
			texture_button.stretch_mode = (
				TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			)

		# Correct oversized original button.
		back_button.position = Vector2(115, 118)
		back_button.size = Vector2(180, 180)

	_create_details_container()
	_update_layout()


func _update_layout() -> void:
	var viewport_size := get_viewport_rect().size

	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return

	var scale_factor: float = min(
		(viewport_size.x - 20.0) / DESIGN_SIZE.x,
		(viewport_size.y * 0.46) / DESIGN_SIZE.y
	)

	content_root.scale = Vector2.ONE * scale_factor

	var displayed_width := DESIGN_SIZE.x * scale_factor
	var displayed_height := DESIGN_SIZE.y * scale_factor

	content_root.position = Vector2(
		(viewport_size.x - displayed_width) / 2.0,
		12
	)

	if background != null:
		background.position = Vector2.ZERO
		background.size = DESIGN_SIZE
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_SCALE
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if details_scroll != null:
		var details_y: float = (
			12.0 + displayed_height + 10.0
		)

		details_scroll.position = Vector2(
			12,
			details_y
		)

		details_scroll.size = Vector2(
			viewport_size.x - 24,
			maxf(80, viewport_size.y - details_y - 12)
		)


# =====================================================
# PERFORMANCE DETAILS CONTAINER
# =====================================================

func _create_details_container() -> void:
	details_scroll = ScrollContainer.new()
	details_scroll.name = "PerformanceScroll"
	details_scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	details_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)
	details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(details_scroll)

	var panel := PanelContainer.new()
	panel.name = "PerformancePanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#ffffff")
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(14)

	panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	details_scroll.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	details_box = VBoxContainer.new()
	details_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_box.add_theme_constant_override("separation", 8)
	margin.add_child(details_box)


# =====================================================
# LOAD SELECTED PUPIL
# =====================================================

func _load_pupil_performance() -> void:
	selected_record.clear()

	var pupil_id := str(
		PlayerData.selected_teacher_pupil_id
	)

	if not pupil_id.is_empty():
		selected_record = PlayerData.get_pupil_record_by_id(
			pupil_id
		)

	if selected_record.is_empty():
		var records: Array = (
			PlayerData.get_teacher_pupil_records()
		)

		if not records.is_empty():
			selected_record = records[0].duplicate(true)

	if selected_record.is_empty():
		_show_no_records()
		return

	PlayerData.selected_teacher_pupil_id = str(
		selected_record.get("id", "")
	)

	_display_pupil_performance()


# =====================================================
# DISPLAY PUPIL PERFORMANCE
# =====================================================

func _display_pupil_performance() -> void:
	var pupil_name := str(
		selected_record.get("name", "Pupil")
	)

	var grade := str(
		selected_record.get("grade", "N/A")
	)

	var total_score := float(
		selected_record.get("total_score", 0)
	)

	var total_stars := int(
		selected_record.get("total_stars", 0)
	)

	var completed: Array = selected_record.get(
		"completed_levels", []
	)

	var results: Dictionary = selected_record.get(
		"level_results", {}
	)

	# Summary cards.
	_set_label(
		"Total stars/Label",
		str(total_stars)
	)

	_set_label(
		"Levels/Label2",
		"%d/10" % completed.size()
	)

	_set_label(
		"overall sco/Label",
		str(total_score)
	)

	# Original table columns:
	# Level | Stars | Score | Time | Date

	_set_label("stars", "All")
	_set_label("score", str(total_stars))
	_set_label("score2", str(total_score))
	_set_label("name", "--")
	_set_label("date", _get_latest_date(results))

	_build_performance_details(
		pupil_name,
		grade,
		total_score,
		total_stars,
		completed,
		results
	)


# =====================================================
# BUILD COMPLETE PERFORMANCE INFORMATION
# =====================================================

func _build_performance_details(
	pupil_name: String,
	grade: String,
	total_score: float,
	total_stars: int,
	completed: Array,
	results: Dictionary
) -> void:
	_clear_details()

	_add_heading("PUPIL PERFORMANCE DETAILS")

	_add_detail("Learner: " + pupil_name)
	_add_detail("Grade: " + grade)
	_add_detail("Completed Levels: %d/10" % completed.size())
	_add_detail("Total Score: %s" % str(total_score))
	_add_detail("Total Stars: %d" % total_stars)

	_add_separator()

	# Pre-test and post-test.
	_add_heading("TEST RESULTS")

	var comparison: Dictionary = (
		PlayerData.get_pre_post_comparison(
			selected_record
		)
	)

	var pretest := int(
		comparison.get("pretest_score", 0)
	)

	var posttest := int(
		comparison.get("posttest_score", 0)
	)

	var improvement := int(
		comparison.get("improvement", 0)
	)

	_add_detail("Pre-test Score: %d/20" % pretest)
	_add_detail("Post-test Score: %d/20" % posttest)

	if comparison.get("has_both", false):
		_add_detail(
			"Improvement: %+d" % improvement
		)
	else:
		_add_detail(
			"Improvement: Not available (incomplete test records)"
		)

	_add_separator()

	# Mathematical operations.
	_add_heading("MATHEMATICAL OPERATION PERFORMANCE")

	var operation_stats: Dictionary = (
		selected_record.get("operation_stats", {})
	)

	var operations: Array[String] = [
		"addition",
		"subtraction",
		"multiplication",
		"division",
		"mixed"
	]

	if operation_stats.is_empty():
		_add_detail("No operation statistics available.")
	else:
		for operation in operations:
			var stat: Dictionary = operation_stats.get(
				operation,
				{"correct": 0, "total": 0}
			)

			var correct := int(stat.get("correct", 0))
			var total := int(stat.get("total", 0))

			var percentage := 0.0

			if total > 0:
				percentage = (
					float(correct) / float(total)
				) * 100.0

			_add_detail(
				"%s: %d/%d (%.1f%%)"
				% [
					operation.capitalize(),
					correct,
					total,
					percentage
				]
			)

	_add_separator()

	# Individual level results.
	_add_heading("LEVEL RESULTS")

	if results.is_empty():
		_add_detail("No level results available.")
		return

	var result_ids: Array = results.keys()
	result_ids.sort_custom(_sort_result_ids)

	for result_id in result_ids:
		var value: Variant = results[result_id]

		if not value is Dictionary:
			continue

		var result: Dictionary = value

		_add_detail(
			"%s | Score: %s | Stars: %s"
			% [
				str(result_id),
				str(result.get("score", 0)),
				str(result.get("stars", 0))
			]
		)

		_add_detail(
			"Correct: %s | Wrong: %s"
			% [
				str(result.get("correct", 0)),
				str(result.get("wrong", 0))
			]
		)

		_add_detail(
			"Date: %s"
			% str(result.get("date", "N/A"))
		)

		_add_separator()


func _sort_result_ids(a: Variant, b: Variant) -> bool:
	return str(a).naturalnocasecmp_to(str(b)) < 0


func _get_latest_date(results: Dictionary) -> String:
	var latest := ""

	for value in results.values():
		if value is Dictionary:
			var date_value := str(
				value.get("date", "")
			)

			if date_value > latest:
				latest = date_value

	if latest.is_empty():
		return "--"

	return latest


# =====================================================
# DETAILS UI HELPERS
# =====================================================

func _clear_details() -> void:
	for child in details_box.get_children():
		child.queue_free()


func _add_heading(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override(
		"font_color",
		Color("#172c40")
	)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_box.add_child(label)


func _add_detail(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override(
		"font_color",
		Color("#222222")
	)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_box.add_child(label)


func _add_separator() -> void:
	var separator := HSeparator.new()
	details_box.add_child(separator)


# =====================================================
# NO RECORDS
# =====================================================

func _show_no_records() -> void:
	_set_label("Total stars/Label", "0")
	_set_label("Levels/Label2", "0/10")
	_set_label("overall sco/Label", "0")

	_set_label("stars", "--")
	_set_label("score", "0")
	_set_label("score2", "0")
	_set_label("name", "--")
	_set_label("date", "--")

	_clear_details()

	_add_heading("PUPIL PERFORMANCE")
	_add_detail("No performance records are available.")
	_add_detail("Please select a pupil from the teacher dashboard.")


# =====================================================
# SET ORIGINAL LABELS
# =====================================================

func _set_label(path: String, value: String) -> void:
	var label := content_root.get_node_or_null(
		path
	) as Label

	if label != null:
		label.text = value


# =====================================================
# BACK TO DASHBOARD
# =====================================================

func _go_back() -> void:
	get_tree().change_scene_to_file(DASHBOARD_SCENE)
