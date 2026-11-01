extends Control

func _ready() -> void:
	var is_post := PlayerData.current_quiz_mode == "post_test"
	$Lvl_n.text = "Level 0 · Post-test Results" if is_post else ("Level 0 · Pre-test Results" if PlayerData.current_level == 0 else "Level %d Results" % PlayerData.current_level)
	$correct.text = "Correct answers: %d / %d" % [PlayerData.current_score, 10 if PlayerData.current_level >= 1 and PlayerData.current_level <= 10 and PlayerData.current_quiz_mode == "level" else 20]
	$wrong.text = "Stars earned: %d" % PlayerData.current_stars

	# Show only the stars the player actually earned.
	var left_star := get_node_or_null("solid_star") as CanvasItem
	var center_star := get_node_or_null("solid_star2") as CanvasItem
	var right_star := get_node_or_null("solid_star3") as CanvasItem
	if left_star:
		left_star.visible = PlayerData.current_stars >= 1
	if center_star:
		center_star.visible = PlayerData.current_stars >= 2
	if right_star:
		right_star.visible = PlayerData.current_stars >= 3

	$play.hide()
	$play3.show()
	var continue_button := get_node_or_null("play3") as Button
	if continue_button:
		continue_button.text = "Continue" if PlayerData.current_stars > 0 else "Retry"
		if not continue_button.pressed.is_connected(_continue):
			continue_button.pressed.connect(_continue)
	var back_button := get_node_or_null("back") as BaseButton
	if back_button and not back_button.pressed.is_connected(_go_back):
		back_button.pressed.connect(_go_back)

func _go_back() -> void:
	get_tree().change_scene_to_file("res://scene/select_level.tscn")

func _continue() -> void:
	if PlayerData.current_quiz_mode == "post_test":
		if PlayerData.current_stars == 0:
			get_tree().change_scene_to_file("res://scene/post_test.tscn")
		else:
			PlayerData.current_quiz_mode = "level"
			get_tree().change_scene_to_file("res://scene/select_level.tscn")
	elif PlayerData.current_stars == 0:
		if PlayerData.current_level == 0:
			PlayerData.current_quiz_mode = "pretest"
			get_tree().change_scene_to_file("res://scene/pretest.tscn")
		else:
			PlayerData.current_quiz_mode = "level"
			get_tree().change_scene_to_file("res://scene/gameplay.tscn")
	elif PlayerData.current_level == 0:
		PlayerData.current_level = 1
		PlayerData.current_quiz_mode = "level"
		get_tree().change_scene_to_file("res://scene/select_level.tscn")
	elif PlayerData.current_level >= 10:
		PlayerData.current_quiz_mode = "post_test"
		get_tree().change_scene_to_file("res://scene/post_test.tscn")
	else:
		PlayerData.current_level += 1
		PlayerData.current_quiz_mode = "level"
		get_tree().change_scene_to_file("res://scene/select_level.tscn")
