extends Control

func _ready() -> void:
	var is_post: bool = PlayerData.current_quiz_mode == "post_test"
	var title := get_node_or_null("Lvl_n") as Label
	if title:
		title.text = "Level 0 · Post-test Results" if is_post else ("Level 0 · Pre-test Results" if PlayerData.current_level == 0 else "Level %d Results" % PlayerData.current_level)

	# This scene does not contain nodes named `correct` or `wrong` in its .tscn.
	# Create result labels if they are missing instead of assigning text to null.
	var correct_label := get_node_or_null("correct") as Label
	if correct_label == null:
		correct_label = Label.new()
		correct_label.name = "correct"
		correct_label.position = Vector2(120, 390)
		correct_label.size = Vector2(360, 40)
		correct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		correct_label.add_theme_font_size_override("font_size", 22)
		add_child(correct_label)
	correct_label.text = "Correct answers: %d / %d" % [PlayerData.current_score, 20 if PlayerData.current_level == 0 or is_post else 10]

	var stars_label := get_node_or_null("wrong") as Label
	if stars_label == null:
		stars_label = Label.new()
		stars_label.name = "wrong"
		stars_label.position = Vector2(120, 435)
		stars_label.size = Vector2(360, 40)
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_label.add_theme_font_size_override("font_size", 22)
		add_child(stars_label)
	stars_label.text = "Stars earned: %d" % PlayerData.current_stars

	var play_button := get_node_or_null("play") as Button
	if play_button:
		play_button.hide()
	var continue_button := get_node_or_null("play3") as Button
	if continue_button:
		continue_button.show()
		continue_button.text = "Continue" if PlayerData.current_stars > 0 else "Retry"
		if not continue_button.pressed.is_connected(_continue):
			continue_button.pressed.connect(_continue)

	var back_button := get_node_or_null("back") as BaseButton
	if back_button and not back_button.pressed.is_connected(_back):
		back_button.pressed.connect(_back)

func _back() -> void:
	get_tree().change_scene_to_file("res://scene/select_level.tscn")

func _continue() -> void:
	if PlayerData.current_quiz_mode == "post_test":
		if PlayerData.current_stars == 0:
			get_tree().change_scene_to_file("res://scene/post_test.tscn")
		else:
			PlayerData.current_quiz_mode = "level"
			get_tree().change_scene_to_file("res://scene/select_level.tscn")
		return

	if PlayerData.current_level == 0:
		if PlayerData.current_stars == 0:
			PlayerData.current_quiz_mode = "pretest"
			get_tree().change_scene_to_file("res://scene/pretest.tscn")
		else:
			PlayerData.current_level = 1
			PlayerData.current_quiz_mode = "level"
			get_tree().change_scene_to_file("res://scene/select_level.tscn")
		return

	if PlayerData.current_stars == 0:
		# Retry the same battle level, not the pretest.
		PlayerData.current_quiz_mode = "level"
		get_tree().change_scene_to_file("res://scene/gameplay.tscn")
	elif PlayerData.current_level >= 10:
		PlayerData.current_quiz_mode = "post_test"
		get_tree().change_scene_to_file("res://scene/post_test.tscn")
	else:
		PlayerData.current_level += 1
		PlayerData.current_quiz_mode = "level"
		get_tree().change_scene_to_file("res://scene/select_level.tscn")
