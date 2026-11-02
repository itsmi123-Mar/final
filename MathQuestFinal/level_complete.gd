
extends Control


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:

	var is_posttest: bool = (
		PlayerData.current_quiz_mode == "post_test"
	)

	var is_pretest: bool = (
		PlayerData.current_level == 0
		and PlayerData.current_quiz_mode == "pretest"
	)

	# ==========================================
	# RESULT TITLE
	# ==========================================

	if is_posttest:

		$Lvl_n.text = "Post-test Completed!"

	elif is_pretest:

		$Lvl_n.text = "Pre-test Results"

	else:

		$Lvl_n.text = "Level %d Results" % PlayerData.current_level

	# ==========================================
	# DISPLAY SCORE
	# ==========================================

	# Each quiz contains 20 questions.
	$correct.text = "Correct answers: %d / 20" % PlayerData.current_score

	$wrong.text = "Stars earned: %d" % PlayerData.current_stars

	# ==========================================
	# DISPLAY EARNED STARS
	# ==========================================

	var left_star := get_node_or_null(
		"solid_star"
	) as CanvasItem

	var center_star := get_node_or_null(
		"solid_star2"
	) as CanvasItem

	var right_star := get_node_or_null(
		"solid_star3"
	) as CanvasItem

	if left_star:
		left_star.visible = PlayerData.current_stars >= 2

	if center_star:
		center_star.visible = PlayerData.current_stars >= 1

	if right_star:
		right_star.visible = PlayerData.current_stars >= 2

	# ==========================================
	# CONTINUE / RETRY BUTTON
	# ==========================================

	var play_button := get_node_or_null(
		"play"
	) as BaseButton

	if play_button:
		play_button.hide()

	var continue_button := get_node_or_null(
		"play3"
	) as Button

	if continue_button:

		continue_button.show()

		if _has_passed_current_quiz():
			continue_button.text = "Continue"
		else:
			continue_button.text = "Retry"

		if not continue_button.pressed.is_connected(_continue):
			continue_button.pressed.connect(_continue)

	# ==========================================
	# BACK BUTTON
	# ==========================================

	var back_button := get_node_or_null(
		"back"
	) as BaseButton

	if back_button:

		if not back_button.pressed.is_connected(_go_back):
			back_button.pressed.connect(_go_back)


# ==========================================
# CHECK IF CURRENT QUIZ WAS PASSED
# ==========================================

func _has_passed_current_quiz() -> bool:

	# Pre-test:
	# At least 10 correct answers out of 20.
	if PlayerData.current_quiz_mode == "pretest":

		return PlayerData.current_score >= 10

	# Regular levels and post-test:
	# At least one star is required.
	return PlayerData.current_stars >= 1


# ==========================================
# BACK TO LEVEL SELECTION
# ==========================================

func _go_back() -> void:

	get_tree().change_scene_to_file(
		"res://scene/select_level.tscn"
	)


# ==========================================
# CONTINUE OR RETRY
# ==========================================

func _continue() -> void:

	var passed: bool = _has_passed_current_quiz()

	# ==========================================
	# POST-TEST
	# ==========================================

	if PlayerData.current_quiz_mode == "post_test":

		if not passed:

			# Failed Post-test: retry Post-test.
			get_tree().change_scene_to_file(
				"res://scene/post_test.tscn"
			)

		else:

			# Passed Post-test: return to level selection.
			PlayerData.current_quiz_mode = "level"

			get_tree().change_scene_to_file(
				"res://scene/select_level.tscn"
			)

		return

	# ==========================================
	# PRE-TEST - LEVEL 0
	# ==========================================

	if PlayerData.current_level == 0:

		if not passed:

			# Failed Pre-test: retry Pre-test.
			PlayerData.current_quiz_mode = "pretest"

			get_tree().change_scene_to_file(
				"res://scene/pretest.tscn"
			)

		else:

			# Passed Pre-test: unlock Level 1.
			PlayerData.current_level = 1
			PlayerData.current_quiz_mode = "level"

			get_tree().change_scene_to_file(
				"res://scene/select_level.tscn"
			)

		return

	# ==========================================
	# REGULAR LEVELS 1-10
	# ==========================================

	if not passed:

		# Failed regular level:
		# Return to the level start screen
		# for the same level.
		PlayerData.current_quiz_mode = "level"

		get_tree().change_scene_to_file(
			"res://scene/lvl_start.tscn"
		)

		return

	# ==========================================
	# LEVEL 10 PASSED
	# ==========================================

	if PlayerData.current_level >= 10:

		# Unlock and proceed to Post-test.
		PlayerData.current_quiz_mode = "post_test"

		get_tree().change_scene_to_file(
			"res://scene/post_test.tscn"
		)

		return

	# ==========================================
	# LEVEL 1-9 PASSED
	# ==========================================

	# Return to level selection.
	# The next level will be unlocked there.
	PlayerData.current_level += 1
	PlayerData.current_quiz_mode = "level"

	get_tree().change_scene_to_file(
		"res://scene/select_level.tscn"
	)
