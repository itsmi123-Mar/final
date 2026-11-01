extends Control

@onready var pupil_name_label: Label = $profile_box/name
@onready var grade_label: Label = $profile_box/grade
@onready var total_score_label: Label = $overall/score
@onready var total_stars_label: Label = $star_box/total
@onready var completed_levels_label: Label = $lvl_completed_box3/Label
@onready var back_button: TextureButton = $back
@onready var home_button: TextureButton = $home
var level_rows: GridContainer


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	home_button.pressed.connect(_on_home_pressed)
	_setup_history_list()
	_refresh_scoreboard()


func _refresh_scoreboard() -> void:
	var record := PlayerData.get_current_progress()
	if record.is_empty():
		pupil_name_label.text = "No pupil logged in"
		grade_label.text = ""
		total_score_label.text = "0"
		total_stars_label.text = "0"
		completed_levels_label.text = "0"
		return

	pupil_name_label.text = str(record.get("name", "Pupil"))
	grade_label.text = str(record.get("grade", ""))
	total_score_label.text = str(record.get("total_score", 0))
	total_stars_label.text = str(record.get("total_stars", 0))
	completed_levels_label.text = str(PlayerData.get_completed_level_count()) + "/10"

	# Display every saved play attempt (including retries and both Level 0 tests).
	for child in level_rows.get_children():
		child.queue_free()
	var history := PlayerData.get_attempt_history()
	if history.is_empty():
		_add_cell("No games yet", 150, HORIZONTAL_ALIGNMENT_LEFT)
		_add_cell("—", 80, HORIZONTAL_ALIGNMENT_CENTER)
		_add_cell("☆☆☆", 70, HORIZONTAL_ALIGNMENT_CENTER)
		_add_cell("Play to begin", 130, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		for i in range(history.size() - 1, -1, -1):
			var attempt: Dictionary = history[i]
			var stage := str(attempt.get("stage", attempt.get("level_id", "Game")))
			var score_text := "%s (%s✓/%s✗)" % [str(attempt.get("score", 0)), str(attempt.get("correct", 0)), str(attempt.get("wrong", 0))]
			var stars := int(attempt.get("stars", 0))
			var star_text := "★".repeat(stars) + "☆".repeat(3 - stars)
			var date_text := str(attempt.get("date", "—"))
			if date_text.length() > 16:
				date_text = date_text.substr(0, 16).replace("T", " ")
			var duration := int(float(attempt.get("duration_seconds", 0.0)))
			date_text += "\n%02d:%02d" % [duration / 60, duration % 60]
			_add_cell(stage, 150, HORIZONTAL_ALIGNMENT_LEFT)
			_add_cell(score_text, 80, HORIZONTAL_ALIGNMENT_CENTER)
			_add_cell(star_text, 70, HORIZONTAL_ALIGNMENT_CENTER)
			_add_cell(date_text, 130, HORIZONTAL_ALIGNMENT_CENTER)


func _setup_history_list() -> void:
	var old_grid := get_node_or_null("progress_box/lecontentvel") as GridContainer
	if old_grid:
		old_grid.get_parent().remove_child(old_grid)
		old_grid.queue_free()
	var scroll := ScrollContainer.new()
	scroll.name = "GameHistoryScroll"
	scroll.position = Vector2(22, 62)
	scroll.size = Vector2(470, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	$progress_box.add_child(scroll)
	level_rows = GridContainer.new()
	level_rows.name = "GameHistoryRows"
	level_rows.columns = 4
	level_rows.custom_minimum_size = Vector2(455, 0)
	level_rows.add_theme_constant_override("h_separation", 8)
	level_rows.add_theme_constant_override("v_separation", 9)
	scroll.add_child(level_rows)
	$progress_box/header/level.text = "Game"
	$progress_box/header/score.text = "Score"
	$progress_box/header/stars.text = "Stars"
	$progress_box/header/date.text = "Date / Time"


func _add_cell(value: String, column_width: float, alignment: HorizontalAlignment) -> void:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(column_width, 38)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.clip_text = true
	level_rows.add_child(label)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")


func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
