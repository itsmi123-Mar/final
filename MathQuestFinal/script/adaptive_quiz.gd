
extends Control

const OPS := ["addition", "subtraction", "multiplication", "division", "mixed"]

const OP_SYMBOLS := {
	"addition": "+",
	"subtraction": "−",
	"multiplication": "×",
	"division": "÷"
}

const PRESET_PRE := [
	["addition", "12 + 7", 19],
	["addition", "24 + 15", 39],
	["addition", "36 + 8", 44],
	["addition", "47 + 22", 69],

	["subtraction", "18 − 9", 9],
	["subtraction", "35 − 12", 23],
	["subtraction", "52 − 27", 25],
	["subtraction", "70 − 34", 36],

	["multiplication", "3 × 4", 12],
	["multiplication", "6 × 7", 42],
	["multiplication", "8 × 5", 40],
	["multiplication", "9 × 3", 27],

	["division", "12 ÷ 3", 4],
	["division", "35 ÷ 5", 7],
	["division", "48 ÷ 6", 8],
	["division", "27 ÷ 9", 3],

	["mixed", "4 + 3 × 2", 10],
	["mixed", "(12 − 4) ÷ 2", 4],
	["mixed", "5 × 3 − 4", 11],
	["mixed", "18 ÷ 3 + 2", 8]
]

const PRESET_POST := [
	# ADDITION
	["addition", "35 + 24", 59],
	["addition", "48 + 31", 79],
	["addition", "16 + 27", 43],
	["addition", "52 + 38", 90],

	# SUBTRACTION
	["subtraction", "85 − 42", 43],
	["subtraction", "76 − 29", 47],
	["subtraction", "94 − 57", 37],
	["subtraction", "63 − 18", 45],

	# MULTIPLICATION
	["multiplication", "9 × 8", 72],
	["multiplication", "7 × 6", 42],
	["multiplication", "11 × 8", 88],
	["multiplication", "9 × 5", 45],

	# DIVISION
	["division", "72 ÷ 8", 9],
	["division", "81 ÷ 9", 9],
	["division", "96 ÷ 12", 8],
	["division", "84 ÷ 7", 12],

	# MIXED (TWO NUMBERS, TWO OPERATIONS)
	["mixed", "12 + 5 × 3", 27],
	["mixed", "(18 − 6) ÷ 3", 4],
	["mixed", "8 × 7 − 9", 47],
	["mixed", "72 ÷ 8 + 5", 14]
]


var questions: Array[Dictionary] = []

var question_index: int = 0
var correct_count: int = 0
var wrong_count: int = 0

var stats_this_attempt: Dictionary = {}
var current_question: Dictionary = {}

var answer_buttons: Array[Button] = []

var is_post_test: bool = false
var is_pretest: bool = false

var question_total: int = 10


func _ready() -> void:

	is_post_test = (
		get_tree().current_scene.scene_file_path == "res://scene/post_test.tscn"
		or PlayerData.current_quiz_mode == "post_test"
	)

	is_pretest = (
		not is_post_test
		and PlayerData.current_level == 0
	)

	# Only the pre-test and post-test have 20 questions.
	# Levels 1 to 10 have exactly 10 questions.
	if is_pretest or is_post_test:
		question_total = 20
	else:
		question_total = 10

	for op in OPS:
		stats_this_attempt[op] = {
			"correct": 0,
			"total": 0
		}

	for button_name in ["ans1", "ans2", "ans3", "ans4"]:

		var b := get_node_or_null("level_grid/" + button_name) as Button

		if b:
			answer_buttons.append(b)

			if not b.pressed.is_connected(_on_answer.bind(b)):
				b.pressed.connect(_on_answer.bind(b))

	if answer_buttons.size() != 4:
		push_error("Quiz scene needs four answer buttons.")
		return

	_build_questions()
	_show_question()


func _build_questions() -> void:

	questions.clear()

	if is_pretest:

		for q in PRESET_PRE:
			questions.append({
				"op": q[0],
				"prompt": q[1],
				"answer": q[2]
			})

	elif is_post_test:

		for q in PRESET_POST:
			questions.append({
				"op": q[0],
				"prompt": q[1],
				"answer": q[2]
			})

	else:

		var stats: Dictionary = PlayerData.get_operation_stats()

		var weakest: String = "addition"
		var lowest_rate: float = 2.0

		for op in OPS:

			var item: Dictionary = stats.get(
				op,
				{"correct": 0, "total": 0}
			)

			var total: int = int(item.get("total", 0))

			var rate: float = (
				float(item.get("correct", 0)) / float(total)
				if total > 0
				else 0.5
			)

			if rate < lowest_rate:
				lowest_rate = rate
				weakest = op

		# Generate exactly 10 questions.
		# Four questions focus on the weakest operation.
		# The remaining six are distributed among all operations.
		var operation_pool: Array[String] = []

		for i in range(4):
			operation_pool.append(weakest)

		for i in range(6):
			operation_pool.append(
				OPS[randi_range(0, OPS.size() - 1)]
			)

		operation_pool.shuffle()

		for op in operation_pool:
			questions.append(
				_make_question(op, PlayerData.current_level)
			)

	# Safety check: never allow an incorrect question count.
	if questions.size() != question_total:
		push_error(
			"Incorrect question count. Expected %d, got %d."
			% [question_total, questions.size()]
		)


func _make_question(op: String, level: int) -> Dictionary:

	var a: int = 0
	var b: int = 0
	var answer: int = 0
	var prompt: String = ""

	var scale: int = 10 + level * 8

	match op:

		"addition":

			a = randi_range(10, scale * 3)
			b = randi_range(2, scale * 2)

			answer = a + b
			prompt = "%d + %d" % [a, b]

		"subtraction":

			a = randi_range(15, mini(50, scale * 4))
			b = randi_range(1, a)

			answer = a - b
			prompt = "%d − %d" % [a, b]

		"multiplication":

			a = randi_range(2, mini(12 + level, 20))
			b = randi_range(2, mini(10 + level, 20))

			answer = a * b
			prompt = "%d × %d" % [a, b]

		"division":

			b = randi_range(2, mini(12 + level, 20))
			answer = randi_range(2, mini(12 + level * 2, 50))

			a = b * answer
			prompt = "%d ÷ %d" % [a, b]

		"mixed":

			a = randi_range(2, 12 + level * 2)
			b = randi_range(2, 10 + level)

			var c: int = randi_range(1, 15 + level * 2)

			if randi_range(0, 1) == 0:

				answer = a + b * c
				prompt = "%d + %d × %d" % [a, b, c]

			else:

				answer = a * b - c
				prompt = "%d × %d − %d" % [a, b, c]

	return {
		"op": op,
		"prompt": prompt,
		"answer": answer
	}


func _show_question() -> void:

	if question_index >= questions.size():
		_finish_quiz()
		return

	current_question = questions[question_index]

	var quiz_title: String

	if is_post_test:
		quiz_title = "Post-test"
	elif is_pretest:
		quiz_title = "Pre-test"
	else:
		quiz_title = "Level %d" % PlayerData.current_level

	$lvl_n.text = "%s   %d/%d" % [
		quiz_title,
		question_index + 1,
		questions.size()
	]

	$eque.text = str(current_question["prompt"]) + " = ?"

	var answer: int = int(current_question["answer"])

	var choices: Array[int] = [answer]

	while choices.size() < 4:

		var delta: int = randi_range(
			1,
			maxi(4, int(abs(answer) * 0.25) + 3)
		)

		var candidate: int = answer + (
			delta if randi_range(0, 1) == 0 else -delta
		)

		if candidate >= 0 and not choices.has(candidate):
			choices.append(candidate)

	choices.shuffle()

	for i in range(answer_buttons.size()):

		answer_buttons[i].text = str(choices[i])
		answer_buttons[i].disabled = false


func _on_answer(button: Button) -> void:

	for b in answer_buttons:
		b.disabled = true

	var op: String = str(current_question["op"])

	var is_correct: bool = (
		int(button.text) == int(current_question["answer"])
	)

	stats_this_attempt[op]["total"] += 1

	if is_correct:

		correct_count += 1
		stats_this_attempt[op]["correct"] += 1

		button.text = "✓ " + button.text

	else:

		wrong_count += 1

		button.text = "✗ " + button.text

	question_index += 1

	await get_tree().create_timer(0.35).timeout

	_show_question()


func _finish_quiz() -> void:

	var score: int = correct_count
	var total: int = questions.size()

	var stars: int = 0

	# Star requirements are based on the actual number of questions.
	var one_star_required: int = ceili(float(total) * 0.50)
	var two_star_required: int = ceili(float(total) * 0.75)
	var three_star_required: int = ceili(float(total) * 0.90)

	if score >= three_star_required:

		stars = 3

	elif score >= two_star_required:

		stars = 2

	elif score >= one_star_required:

		stars = 1

	PlayerData.current_score = score
	PlayerData.current_stars = stars

	PlayerData.quiz_correct = correct_count
	PlayerData.quiz_wrong = wrong_count

	PlayerData.last_quiz_score = score
	PlayerData.last_quiz_stars = stars

	PlayerData.save_operation_stats(stats_this_attempt)

	if is_post_test:

		PlayerData.save_level_result(
			"posttest",
			score,
			stars,
			correct_count,
			wrong_count
		)

		get_tree().change_scene_to_file(
			"res://scene/lvl_complete.tscn"
		)

	elif is_pretest:

		PlayerData.save_level_result(
			"pretest",
			score,
			stars,
			correct_count,
			wrong_count
		)

		get_tree().change_scene_to_file(
			"res://scene/lvl_complete.tscn"
		)

	else:

		PlayerData.save_level_result(
			"level_%d" % PlayerData.current_level,
			score,
			stars,
			correct_count,
			wrong_count
		)

		if stars > 0:

			get_tree().change_scene_to_file(
				"res://scene/lvl_complete.tscn"
			)

		else:

			get_tree().change_scene_to_file(
				"res://scene/lvl_retry.tscn"
			)
