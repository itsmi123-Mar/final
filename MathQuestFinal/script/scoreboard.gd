extends Control

@onready var pupil_name_label: Label = $profile_box/name
@onready var grade_label: Label = $profile_box/grade
@onready var total_score_label: Label = $overall/score
@onready var total_stars_label: Label = $star_box/total
@onready var completed_levels_label: Label = $lvl_completed_box3/Label
@onready var back_button: TextureButton = $back
@onready var home_button: TextureButton = $home
@onready var level_rows: GridContainer = $progress_box/lecontentvel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	home_button.pressed.connect(_on_home_pressed)
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
	var completed: Array = record.get("completed_levels", [])
	completed_levels_label.text = str(completed.size()) + "/10"

	# Remove sample rows from the designed UI and replace with saved level results.
	for child in level_rows.get_children():
		child.queue_free()

	var results: Dictionary = record.get("level_results", {})
	var level_ids: Array = results.keys()
	level_ids.sort()
	for level_id in level_ids:
		var result: Dictionary = results[level_id]
		_add_cell(str(level_id), 100, HORIZONTAL_ALIGNMENT_LEFT)
		_add_cell(str(result.get("score", 0)), 80, HORIZONTAL_ALIGNMENT_CENTER)
		_add_cell(str(result.get("stars", 0)), 70, HORIZONTAL_ALIGNMENT_CENTER)
		var date_text := str(result.get("date", ""))
		# Display a readable date even when older records have no timestamp.
		if date_text.is_empty():
			date_text = "—"
		elif date_text.length() > 10:
			date_text = date_text.substr(0, 10)
		_add_cell(date_text, 130, HORIZONTAL_ALIGNMENT_CENTER)


func _add_cell(value: String, column_width: float, alignment: HorizontalAlignment) -> void:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(column_width, 24)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.clip_text = true
	level_rows.add_child(label)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")


func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
