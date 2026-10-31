extends Control

const OPS := ["addition", "subtraction", "multiplication", "division", "mixed"]
const OP_SYMBOLS := {"addition": "+", "subtraction": "−", "multiplication": "×", "division": "÷"}
const PRESET_PRE := [
	["addition", "12 + 7", 19], ["addition", "24 + 15", 39], ["addition", "36 + 8", 44], ["addition", "47 + 22", 69],
	["subtraction", "18 − 9", 9], ["subtraction", "35 − 12", 23], ["subtraction", "52 − 27", 25], ["subtraction", "70 − 34", 36],
	["multiplication", "3 × 4", 12], ["multiplication", "6 × 7", 42], ["multiplication", "8 × 5", 40], ["multiplication", "9 × 3", 27],
	["division", "12 ÷ 3", 4], ["division", "35 ÷ 5", 7], ["division", "48 ÷ 6", 8], ["division", "27 ÷ 9", 3],
	["mixed", "4 + 3 × 2", 10], ["mixed", "(12 − 4) ÷ 2", 4], ["mixed", "5 × 3 − 4", 11], ["mixed", "18 ÷ 3 + 2", 8]
]
const PRESET_POST := [
	["addition", "168 + 257", 425], ["addition", "386 + 179", 565], ["addition", "475 + 268", 743], ["addition", "597 + 186", 783],
	["subtraction", "503 − 278", 225], ["subtraction", "700 − 356", 344], ["subtraction", "824 − 467", 357], ["subtraction", "901 − 586", 315],
	["multiplication", "24 × 6", 144], ["multiplication", "37 × 8", 296], ["multiplication", "46 × 7", 322], ["multiplication", "58 × 9", 522],
	["division", "144 ÷ 12", 12], ["division", "216 ÷ 9", 24], ["division", "324 ÷ 6", 54], ["division", "420 ÷ 7", 60],
	["mixed", "18 + 6 × 4", 42], ["mixed", "(45 − 21) ÷ 3", 8], ["mixed", "7 × 8 − 19", 37], ["mixed", "96 ÷ 8 + 17", 29]
]

var questions: Array[Dictionary] = []
var question_index := 0
var correct_count := 0
var wrong_count := 0
var stats_this_attempt: Dictionary = {}
var current_question: Dictionary = {}
var answer_buttons: Array[Button] = []
var is_post_test := false
var is_pretest := false

func _ready() -> void:
	PlayerData.start_level_timer()
	is_post_test = get_tree().current_scene.scene_file_path == "res://scene/post_test.tscn" or PlayerData.current_quiz_mode == "post_test"
	if is_post_test:
		PlayerData.current_level = 0
		PlayerData.current_quiz_mode = "post_test"
	is_pretest = not is_post_test and PlayerData.current_level == 0
	if is_pretest:
		PlayerData.current_quiz_mode = "pretest"
	for op in OPS:
		stats_this_attempt[op] = {"correct": 0, "total": 0}
	for button_name in ["ans1", "ans2", "ans3", "ans4"]:
		var b := get_node_or_null("level_grid/" + button_name) as Button
		if b:
			answer_buttons.append(b)
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
			questions.append({"op": q[0], "prompt": q[1], "answer": q[2]})
	elif is_post_test:
		for q in PRESET_POST:
			questions.append({"op": q[0], "prompt": q[1], "answer": q[2]})
	else:
		var stats: Dictionary = PlayerData.get_operation_stats()
		var weakest := "addition"
		var lowest_rate := 2.0
		for op in OPS:
			var item: Dictionary = stats.get(op, {"correct": 0, "total": 0})
			var total := int(item.get("total", 0))
			var rate := float(item.get("correct", 0)) / float(total) if total > 0 else 0.5
			if rate < lowest_rate:
				lowest_rate = rate
				weakest = op
		var counts: Dictionary = {}
		for op in OPS:
			counts[op] = 12 if op == weakest else 2
		for op in OPS:
			for i in range(int(counts[op])):
				questions.append(_make_question(op, PlayerData.current_level))
		questions.shuffle()

func _make_question(op: String, level: int) -> Dictionary:
	var a := 0
	var b := 0
	var answer := 0
	var prompt := ""
	var scale := 10 + level * 8
	match op:
		"addition":
			a = randi_range(10, scale * 3)
			b = randi_range(2, scale * 2)
			answer = a + b
			prompt = "%d + %d" % [a, b]
		"subtraction":
			a = randi_range(15, scale * 4)
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
			var c := randi_range(1, 15 + level * 2)
			if randi_range(0, 1) == 0:
				answer = a + b * c
				prompt = "%d + %d × %d" % [a, b, c]
			else:
				answer = a * b - c
				prompt = "%d × %d − %d" % [a, b, c]
	return {"op": op, "prompt": prompt, "answer": answer}

func _show_question() -> void:
	if question_index >= questions.size():
		_finish_quiz()
		return
	current_question = questions[question_index]
	$lvl_n.text = ("Post-test" if is_post_test else ("Pre-test" if is_pretest else "Level %d" % PlayerData.current_level)) + "   %d/%d" % [question_index + 1, questions.size()]
	$eque.text = str(current_question["prompt"]) + " = ?"
	var answer := int(current_question["answer"])
	var choices: Array[int] = [answer]
	while choices.size() < 4:
		var delta := randi_range(1, maxi(4, int(abs(answer) * 0.25) + 3))
		var candidate := answer + (delta if randi_range(0, 1) == 0 else -delta)
		if candidate >= 0 and not choices.has(candidate):
			choices.append(candidate)
	choices.shuffle()
	for i in range(answer_buttons.size()):
		answer_buttons[i].text = str(choices[i])
		answer_buttons[i].disabled = false

func _on_answer(button: Button) -> void:
	for b in answer_buttons:
		b.disabled = true
	var op := str(current_question["op"])
	var is_correct := int(button.text) == int(current_question["answer"])
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
	PlayerData.finish_level_timer()
	var score := correct_count
	var stars := 0
	if score >= 18:
		stars = 3
	elif score >= 15:
		stars = 2
	elif score >= 10:
		stars = 1
	PlayerData.current_score = score
	PlayerData.current_stars = stars
	PlayerData.quiz_correct = correct_count
	PlayerData.quiz_wrong = wrong_count
	PlayerData.last_quiz_score = score
	PlayerData.last_quiz_stars = stars
	PlayerData.save_operation_stats(stats_this_attempt)
	if is_post_test:
		PlayerData.save_level_result("posttest", score, stars, correct_count, wrong_count)
		get_tree().change_scene_to_file("res://scene/lvl_complete.tscn")
	elif is_pretest:
		PlayerData.save_level_result("pretest", score, stars, correct_count, wrong_count)
		get_tree().change_scene_to_file("res://scene/lvl_complete.tscn")
	else:
		PlayerData.save_level_result("level_%d" % PlayerData.current_level, score, stars, correct_count, wrong_count)
		if stars > 0:
			get_tree().change_scene_to_file("res://scene/lvl_complete.tscn")
		else:
			get_tree().change_scene_to_file("res://scene/lvl_retry.tscn")
