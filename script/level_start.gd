extends Control

const TUTORIALS := {
	1: "WELCOME TO LEVEL 1!\n\nAddition (+): put numbers together. Example: 3 + 2 = 5.\nSubtraction (−): take away. Example: 7 − 4 = 3.\nMultiplication (×): equal groups. Example: 3 × 4 = 12.\nDivision (÷): share equally. Example: 12 ÷ 3 = 4.\nMixed questions use more than one operation. Do multiplication/division before addition/subtraction.",
	2: "LEVEL 2 TIPS\n\nRead the whole question before choosing. For subtraction, subtract the smaller place values carefully. For multiplication, think of equal groups. For division, ask what number times the divisor gives the dividend. Mixed questions: do × and ÷ before + and −.",
	3: "LEVEL 3 TIPS\n\nTake your time and check your calculation. Addition combines amounts; subtraction finds the difference; multiplication is repeated addition; division splits into equal groups. In mixed questions, follow the order of operations and solve parentheses first.",
	4: "LEVEL 4 TIPS\n\nBreak larger numbers into hundreds, tens, and ones when adding or subtracting. For multiplication, multiply each place value carefully. For division, use multiplication to check your answer. Always solve parentheses first in mixed questions.",
	5: "LEVEL 5 TIPS\n\nStrategy: estimate first, solve step by step, then check whether your answer makes sense. Multiplication and division come before addition and subtraction unless parentheses change the order.",
	6: "LEVEL 6 TIPS\n\nLook for a quick method: regroup when adding, borrow when subtracting, split a multiplication into easier parts, and check division by multiplying the quotient by the divisor.",
	7: "LEVEL 7 TIPS\n\nSome questions may have bigger numbers. Do not rush. Work one step at a time, keep track of place values, and use the inverse operation to check your answer.",
	8: "LEVEL 8 TIPS\n\nFor mixed expressions, solve brackets first, then multiplication/division from left to right, then addition/subtraction from left to right. Check each step before selecting an answer.",
	9: "LEVEL 9 TIPS\n\nChallenge yourself with careful mental math. Estimate the answer, calculate in steps, and use the opposite operation to check it. Accuracy matters more than speed.",
	10: "FINAL LEVEL TIPS\n\nUse everything you have learned. Solve parentheses first, then multiplication/division, then addition/subtraction. Check your answer before choosing. You can do it!"
}

func _ready() -> void:
	$Lvl_n.text = "Level %d" % PlayerData.current_level
	var star := get_node_or_null("hollow_star") as CanvasItem
	if star:
		star.hide()
	_show_tutorial()

	var play_button := get_node_or_null("play") as Button
	if play_button and not play_button.pressed.is_connected(_play_level):
		play_button.pressed.connect(_play_level)
	var extra_play_button := get_node_or_null("play3") as Button
	if extra_play_button:
		extra_play_button.hide()
	var back_button := get_node_or_null("back") as Button
	if back_button and not back_button.pressed.is_connected(_go_back):
		back_button.pressed.connect(_go_back)

func _show_tutorial() -> void:
	# The project has three designed tutorial pages. Use those scenes instead
	# of adding a text label over the level-start screen.
	pass

func _play_level() -> void:
	PlayerData.current_quiz_mode = "level"
	get_tree().change_scene_to_file("res://scene/tutorial.tscn")

func _go_back() -> void:
	get_tree().change_scene_to_file("res://scene/select_level.tscn")
