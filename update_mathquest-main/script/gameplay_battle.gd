extends Node2D

# Level battle: each correct answer lets the chosen hero damage the monster.
# Wrong answers allow the monster to damage the hero.
const LEVEL_ENEMIES := {
	1: {"enemy": "slime", "world": "grass_land", "background": "grass_land"},
	2: {"enemy": "musroom", "world": "shroom_forest", "background": "shroom_forest"},
	3: {"enemy": "sampling", "world": "lvl1-2", "background": "lvl1-2"},
	4: {"enemy": "cactus", "world": "desert", "background": "desert"},
	5: {"enemy": "goblin", "world": "lvl1-2", "background": "lvl1-2"},
	6: {"enemy": "wolf", "world": "grass_land", "background": "grass_land"},
	7: {"enemy": "bandit", "world": "desert", "background": "desert"},
	8: {"enemy": "necromacer", "world": "night_forest", "background": "night_forest"},
	9: {"enemy": "oger", "world": "shroom_forest", "background": "shroom_forest"},
	10: {"enemy": "demon", "world": "night_forest", "background": "night_forest"}
}

const HERO_NODES := {
	"m_wizard": "side_m_wiard",
	"m_archer": "m_archer",
	"f_wizard": "side_f_wizard",
	"f_archer": "side_f_archer",
	"warrior": "side_m_warrior",
	"princess": "princess"
}
const OPS := ["addition", "subtraction", "multiplication", "division", "mixed"]
const OP_SYMBOLS := {"addition": "+", "subtraction": "−", "multiplication": "×", "division": "÷"}

var player_hp := 100
var enemy_hp := 100
var question_number := 0
const QUESTION_TOTAL := 10
var question_total: int = QUESTION_TOTAL
var correct_answers := 0
var wrong_answers := 0
var current_question: Dictionary = {}
var battle_questions: Array[Dictionary] = []
var answer_buttons: Array[Button] = []
var battle_finished := false
var action_in_progress := false
var stats_this_attempt: Dictionary = {}
var hero: Node2D
var enemy: Node2D
var hero_bar: ProgressBar
var enemy_bar: ProgressBar
var status_label: Label
var question_label: Label
var level_label: Label
var hp_label: Label
var feedback_label: Label
var hud_column: VBoxContainer
var answer_grid: GridContainer
var return_button: Button
var hp_row_container: HBoxContainer
var hero_start_position: Vector2 = Vector2.ZERO
var enemy_start_position: Vector2 = Vector2.ZERO
var ground_line_y: float = 0.0
var combo_used := false
var collection_phase := false
var move_direction := 0.0
var collected_points := 0
var total_pickups := 5
var pickup_nodes: Array[Label] = []
var movement_buttons: Array[Button] = []
var collection_status: Label
var finish_level_button: Button
var exit_game_button: Button
var reached_right_exit := false
var collection_points_value := 10

func _ready() -> void:
	PlayerData.start_level_timer()
	if PlayerData.current_level < 1 or PlayerData.current_level > 10:
		PlayerData.current_level = 1
	_configure_arena()
	_create_battle_ui()
	for op in OPS:
		stats_this_attempt[op] = {"correct": 0, "total": 0}
	_build_questions()
	_show_question()

func _process(delta: float) -> void:
	if not collection_phase or hero == null:
		return
	var direction := move_direction
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction += 1.0
	if direction != 0.0:
		var bounds := get_viewport_rect().size
		hero.global_position.x = clampf(hero.global_position.x + signf(direction) * 260.0 * delta, 42.0, bounds.x - 42.0)
		_play_character_animation(hero, ["run", "walk", "idle"])
		# Reaching the far-right end of the trail opens the level decision menu.
		if direction > 0.0 and hero.global_position.x >= bounds.x - 48.0:
			_show_end_of_trail_choices()
	else:
		_play_character_animation(hero, ["idle"])
	_check_pickups()

func _configure_arena() -> void:
	var level_data: Dictionary = LEVEL_ENEMIES.get(PlayerData.current_level, LEVEL_ENEMIES[1])
	var backgrounds := get_node_or_null("background")
	if backgrounds:
		for child in backgrounds.get_children():
			child.visible = child.name == str(level_data["world"])
			if child.name == str(level_data["world"]):
				for subchild in child.get_children():
					if subchild is CharacterBody2D:
						subchild.visible = subchild.name == str(level_data["enemy"])
						if subchild.visible:
							enemy = subchild
							var enemy_sprite := subchild.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
							if enemy_sprite and enemy_sprite.sprite_frames and enemy_sprite.sprite_frames.has_animation("idle"):
								enemy_sprite.play("idle")

	for child in get_children():
		if child is Node2D and HERO_NODES.values().has(child.name):
			child.visible = child.name == str(HERO_NODES.get(PlayerData.selected_character, "side_m_wiard"))
			if child.visible:
				hero = child

	# Align the visible bottom/feet of both sprites to one shared ground line.
	# Their art has different transparent margins, so aligning their origins or
	# centers makes some characters appear to float or sink.
	var viewport_size := get_viewport_rect().size
	var ground_y := viewport_size.y * 0.83
	ground_line_y = ground_y
	if hero:
		var hero_sprite := hero.find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
		if hero_sprite:
			var desired_hero_center_x := viewport_size.x * 0.24
			hero.global_position.x += desired_hero_center_x - hero_sprite.global_position.x
			hero.global_position.y += ground_y - _sprite_bottom_y(hero_sprite)
		else:
			hero.global_position = Vector2(viewport_size.x * 0.24, ground_y)
		hero.show()
	if enemy:
		var enemy_sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if enemy_sprite:
			# Level 5's goblin artwork is authored much larger than the hero.
			# Scale its rendered frame to approximately the hero's rendered height.
			if PlayerData.current_level == 5 and hero:
				var hero_sprite := hero.find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
				var hero_texture := _current_frame_texture(hero_sprite)
				var enemy_texture := _current_frame_texture(enemy_sprite)
				if hero_texture and enemy_texture and enemy_texture.get_height() > 0:
					var hero_height := float(hero_texture.get_height()) * absf(hero_sprite.global_scale.y)
					var target_height := hero_height * 1.05
					var scale_factor := target_height / float(enemy_texture.get_height())
					enemy_sprite.global_scale = Vector2(scale_factor, scale_factor)
			enemy.global_position.x += viewport_size.x * 0.76 - enemy_sprite.global_position.x
			enemy.global_position.y += ground_y - _sprite_bottom_y(enemy_sprite)
		else:
			enemy.global_position = Vector2(viewport_size.x * 0.76, ground_y)
		enemy.show()
	hero_start_position = hero.global_position if hero else Vector2.ZERO
	enemy_start_position = enemy.global_position if enemy else Vector2.ZERO

func _current_frame_texture(sprite: AnimatedSprite2D) -> Texture2D:
	if sprite == null or sprite.sprite_frames == null:
		return null
	var animation_name: StringName = sprite.animation
	if not sprite.sprite_frames.has_animation(animation_name):
		return null
	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return null
	var frame_index := clampi(sprite.frame, 0, frame_count - 1)
	return sprite.sprite_frames.get_frame_texture(animation_name, frame_index)

func _sprite_bottom_y(sprite: AnimatedSprite2D) -> float:
	if sprite == null or sprite.sprite_frames == null:
		return sprite.global_position.y if sprite else 0.0
	var animation_name: StringName = sprite.animation
	if not sprite.sprite_frames.has_animation(animation_name):
		return sprite.global_position.y
	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return sprite.global_position.y
	var frame_index := clampi(sprite.frame, 0, frame_count - 1)
	var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
	if texture == null:
		return sprite.global_position.y
	var vertical_scale := absf(sprite.global_scale.y)
	return sprite.global_position.y + sprite.offset.y * vertical_scale + texture.get_height() * vertical_scale * 0.5

func _create_battle_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "BattleHUD"
	add_child(layer)
	var panel := PanelContainer.new()
	var viewport_size := get_viewport().get_visible_rect().size
	panel.position = Vector2(14, 14)
	panel.size = Vector2(minf(574.0, viewport_size.x - 28.0), minf(520.0, viewport_size.y * 0.55))
	layer.add_child(panel)
	var column := VBoxContainer.new()
	hud_column = column
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)

	level_label = Label.new()
	level_label.text = "LEVEL %d BATTLE" % PlayerData.current_level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 25)
	column.add_child(level_label)

	var hp_row := HBoxContainer.new()
	hp_row_container = hp_row
	column.add_child(hp_row)
	var hero_column := VBoxContainer.new()
	hero_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hero_column)
	var hero_title := Label.new()
	hero_title.text = "YOUR HERO"
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_column.add_child(hero_title)
	hero_bar = ProgressBar.new()
	hero_bar.max_value = 100
	hero_bar.value = player_hp
	hero_bar.show_percentage = false
	hero_column.add_child(hero_bar)
	var enemy_column := VBoxContainer.new()
	enemy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(enemy_column)
	var enemy_title := Label.new()
	enemy_title.text = str(LEVEL_ENEMIES[PlayerData.current_level]["enemy"]).to_upper()
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_column.add_child(enemy_title)
	enemy_bar = ProgressBar.new()
	enemy_bar.max_value = 100
	enemy_bar.value = enemy_hp
	enemy_bar.show_percentage = false
	enemy_column.add_child(enemy_bar)
	hp_label = Label.new()
	hp_label.text = "Hero HP: 100/100     Enemy HP: 100/100"
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hp_label)
	question_label = Label.new()
	question_label.text = "Loading question..."
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.custom_minimum_size = Vector2(0, 58)
	question_label.add_theme_font_size_override("font_size", 28)
	column.add_child(question_label)
	status_label = Label.new()
	status_label.text = "Choose the correct answer to attack!"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)
	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(feedback_label)
	var grid := GridContainer.new()
	answer_grid = grid
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 23)
		button.pressed.connect(_on_answer.bind(button))
		grid.add_child(button)
		answer_buttons.append(button)
	var back_button := Button.new()
	back_button.text = "Return to Level Selection"
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/select_level.tscn"))
	return_button = back_button
	column.add_child(back_button)

func _build_questions() -> void:
	battle_questions.clear()
	var stats: Dictionary = PlayerData.get_operation_stats()
	var rates: Dictionary = {}
	var weakest := "addition"
	var lowest_rate := 2.0
	for op in OPS:
		var stat: Dictionary = stats.get(op, {"correct": 0, "total": 0})
		var total := int(stat.get("total", 0))
		var rate := float(stat.get("correct", 0)) / float(total) if total > 0 else 0.5
		rates[op] = rate
		if rate < lowest_rate:
			lowest_rate = rate
			weakest = op
	# Later levels become more difficult. At least 4 of 10 questions target the weakest operation.
	for i in range(question_total):
		var op: String
		if i < 4:
			op = weakest
		else:
			op = OPS[randi_range(0, OPS.size() - 1)]
		battle_questions.append(_make_question(op, PlayerData.current_level))
	battle_questions.shuffle()

func _make_question(op: String, level: int) -> Dictionary:
	# Keep all displayed values and answers within one or two digits.
	# Multiplication uses familiar times tables; division always has a whole-number answer.
	var a := 0
	var b := 0
	var c := 0
	var answer := 0
	var prompt := ""
	match op:
		"addition":
			var add_max := mini(20, 5 + level * 2)
			a = randi_range(1, add_max)
			b = randi_range(1, add_max)
			answer = a + b
			prompt = "%d + %d" % [a, b]
		"subtraction":
			a = randi_range(5, mini(50, 10 + level * 4))
			b = randi_range(1, a)
			answer = a - b
			prompt = "%d − %d" % [a, b]
		"multiplication":
			# Easy single-digit times tables (products never exceed 81).
			a = randi_range(2, 9)
			b = randi_range(2, 9)
			answer = a * b
			prompt = "%d × %d" % [a, b]
		"division":
			# Exact division with a one- or two-digit dividend and a small divisor.
			b = randi_range(2, 9)
			answer = randi_range(2, 9)
			a = b * answer
			prompt = "%d ÷ %d" % [a, b]
		"mixed":
			# Simple two-operation equations, with multiplication done first.
			if randi_range(0, 1) == 0:
				a = randi_range(1, 9)
				b = randi_range(2, 6)
				c = randi_range(2, 6)
				answer = a + b * c
				prompt = "%d + %d × %d" % [a, b, c]
			else:
				a = randi_range(2, 8)
				b = randi_range(2, 8)
				c = randi_range(1, mini(9, a * b - 1))
				answer = a * b - c
				prompt = "%d × %d − %d" % [a, b, c]
	return {"op": op, "prompt": prompt, "answer": answer}

func _show_question() -> void:
	if question_number >= QUESTION_TOTAL:
		_finish_battle()
		return
	current_question = battle_questions[question_number]
	question_label.text = "Question %d/%d\n%s = ?" % [question_number + 1, battle_questions.size(), current_question["prompt"]]
	status_label.text = "Correct answer = your hero attacks! Wrong answer = enemy attacks!"
	feedback_label.text = ""
	var answer := int(current_question["answer"])
	var choices: Array[int] = [answer]
	while choices.size() < 4:
		var delta := randi_range(1, maxi(4, int(abs(answer) * 0.2) + 3))
		var candidate := maxi(0, answer + (delta if randi_range(0, 1) == 0 else -delta))
		if not choices.has(candidate):
			choices.append(candidate)
	choices.shuffle()
	for i in range(answer_buttons.size()):
		answer_buttons[i].text = str(choices[i])
		answer_buttons[i].disabled = false

func _on_answer(button: Button) -> void:
	if battle_finished or action_in_progress:
		return
	action_in_progress = true
	for b in answer_buttons:
		b.disabled = true
	var op := str(current_question["op"])
	stats_this_attempt[op]["total"] += 1
	var is_correct := int(button.text) == int(current_question["answer"])
	if is_correct:
		correct_answers += 1
		stats_this_attempt[op]["correct"] += 1
		enemy_hp = maxi(0, enemy_hp - 10)
		feedback_label.text = "Correct! Your hero attacks!"
		await _hero_attack_once()
	else:
		wrong_answers += 1
		player_hp = maxi(0, player_hp - 10)
		feedback_label.text = "Not quite! %s is preparing to attack..." % str(LEVEL_ENEMIES[PlayerData.current_level]["enemy"]).capitalize()
		# Brief wind-up so the player can register the wrong answer before damage.
		await get_tree().create_timer(0.45).timeout
		feedback_label.text = "%s attacks your hero!" % str(LEVEL_ENEMIES[PlayerData.current_level]["enemy"]).capitalize()
		await _enemy_attack_once()
	question_number += 1
	_update_hp()
	# Resolve one action per answer. Animations are non-looping, and the next
	# question cannot be answered until this single attack has completed.
	await get_tree().create_timer(1.0).timeout
	action_in_progress = false
	if not battle_finished:
		_show_question()

func _hero_attack_once() -> void:
	if hero == null or enemy == null:
		return
	# Attack in place: no position tween, so the hero stays on the ground line.
	_play_character_animation(hero, ["attack", "Attack"])
	await get_tree().create_timer(0.42).timeout
	_play_character_animation(enemy, ["hurt", "hit", "damage"])
	await _enemy_recoil_once()

func _enemy_attack_once() -> void:
	if hero == null or enemy == null:
		return
	# Enemy also attacks from its own position; only the animation/recoil plays.
	_play_character_animation(enemy, ["attack", "Attack"])
	await get_tree().create_timer(0.42).timeout
	_play_character_animation(hero, ["hurt", "hit", "damage"])
	await _hero_recoil_once()

func _enemy_recoil_once() -> void:
	if not is_instance_valid(enemy):
		return
	# Show damage without moving or scaling the enemy away from its ground mark.
	var original: Color = enemy.modulate
	var tween := create_tween()
	tween.tween_property(enemy, "modulate", Color(1.0, 0.35, 0.35, original.a), 0.08)
	tween.tween_property(enemy, "modulate", original, 0.12)
	await tween.finished

func _hero_recoil_once() -> void:
	if hero == null:
		return
	var original := hero.modulate
	var tween := create_tween()
	tween.tween_property(hero, "modulate", Color(1.0, 0.45, 0.45), 0.08)
	tween.tween_property(hero, "modulate", original, 0.12)
	await tween.finished

func _play_character_animation(character: Node2D, candidates: Array) -> void:
	if character == null:
		return
	var sprite := character.find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return
	for animation_name in candidates:
		var animation := StringName(str(animation_name))
		if sprite.sprite_frames.has_animation(animation):
			# Prevent an attack/hit animation from repeating in a loop.
			sprite.sprite_frames.set_animation_loop(animation, false)
			if sprite.animation != animation or not sprite.is_playing():
				sprite.play(animation)
			if not sprite.animation_finished.is_connected(_on_battle_animation_finished.bind(sprite)):
				sprite.animation_finished.connect(_on_battle_animation_finished.bind(sprite), CONNECT_ONE_SHOT)
			return

func _on_battle_animation_finished(sprite: AnimatedSprite2D) -> void:
	if not is_instance_valid(sprite) or sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation("idle"):
		sprite.sprite_frames.set_animation_loop("idle", true)
		sprite.play("idle")

func _update_hp() -> void:
	hero_bar.value = player_hp
	enemy_bar.value = enemy_hp
	hp_label.text = "Hero HP: %d/100     Enemy HP: %d/100" % [player_hp, enemy_hp]

func _finish_battle() -> void:
	if battle_finished:
		return
	battle_finished = true
	for button in answer_buttons:
		button.disabled = true
	var stars := 0
	if correct_answers == 10:
		stars = 3
	elif correct_answers >= 8:
		stars = 2
	elif correct_answers >= 7:
		stars = 1
	PlayerData.current_score = correct_answers
	PlayerData.current_stars = stars
	PlayerData.quiz_correct = correct_answers
	PlayerData.quiz_wrong = wrong_answers
	PlayerData.last_quiz_score = correct_answers
	PlayerData.last_quiz_stars = stars
	PlayerData.save_operation_stats(stats_this_attempt)
	# Seven to nine correct answers unleash the finishing combo and defeat the
	# monster. A perfect ten triggers the same finisher as a perfect combo.
	if correct_answers >= 7 and correct_answers <= 10:
		combo_used = true
		enemy_hp = 0
		_update_hp()
		feedback_label.text = "PERFECT COMBO! MONSTER DEFEATED!" if correct_answers == 10 else "COMBO ATTACK! MONSTER DEFEATED!"
		_play_character_animation(hero, ["combo", "special_attack", "attack", "Attack"])
		if enemy:
			_play_character_animation(enemy, ["dead", "death", "hurt", "hit"])
		await get_tree().create_timer(1.0).timeout
	else:
		feedback_label.text = "Battle finished! Collect the quest points!"
	_begin_collection_phase(stars)

func _begin_collection_phase(stars: int) -> void:
	collection_phase = true
	PlayerData.current_stars = stars
	if is_instance_valid(answer_grid):
		answer_grid.hide()
	if is_instance_valid(return_button):
		return_button.hide()
	if is_instance_valid(hp_row_container):
		hp_row_container.hide()
	if is_instance_valid(hp_label):
		hp_label.hide()
	question_label.text = "Quest Trail! Move your hero and collect all the points."
	question_label.custom_minimum_size = Vector2(0, 70)
	status_label.text = "Use ◀ / ▶ or A / D. Collect all 5 crystals to finish Level %d." % PlayerData.current_level
	feedback_label.text = "Quiz: %d/10 correct  •  Stars: %s" % [correct_answers, "★".repeat(stars) + "☆".repeat(3 - stars)]
	_spawn_pickups()
	var move_row := HBoxContainer.new()
	move_row.alignment = BoxContainer.ALIGNMENT_CENTER
	move_row.add_theme_constant_override("separation", 22)
	hud_column.add_child(move_row)
	var left_button := Button.new()
	left_button.text = "◀ LEFT"
	left_button.custom_minimum_size = Vector2(150, 58)
	left_button.button_down.connect(func(): move_direction = -1.0)
	left_button.button_up.connect(func(): move_direction = 0.0)
	move_row.add_child(left_button)
	var right_button := Button.new()
	right_button.text = "RIGHT ▶"
	right_button.custom_minimum_size = Vector2(150, 58)
	right_button.button_down.connect(func(): move_direction = 1.0)
	right_button.button_up.connect(func(): move_direction = 0.0)
	move_row.add_child(right_button)
	collection_status = Label.new()
	collection_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collection_status.add_theme_font_size_override("font_size", 19)
	hud_column.add_child(collection_status)
	finish_level_button = Button.new()
	finish_level_button.text = "Continue to Next Level"
	finish_level_button.custom_minimum_size = Vector2(0, 52)
	finish_level_button.disabled = true
	finish_level_button.hide()
	finish_level_button.pressed.connect(_complete_level_after_collection)
	hud_column.add_child(finish_level_button)
	exit_game_button = Button.new()
	exit_game_button.text = "Exit Game"
	exit_game_button.custom_minimum_size = Vector2(0, 48)
	exit_game_button.hide()
	exit_game_button.pressed.connect(_exit_game)
	hud_column.add_child(exit_game_button)
	_update_collection_status()

func _spawn_pickups() -> void:
	pickup_nodes.clear()
	var viewport_size := get_viewport_rect().size
	for i in range(total_pickups):
		var pickup := Label.new()
		pickup.text = "💎"
		pickup.add_theme_font_size_override("font_size", 34)
		pickup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pickup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pickup.position = Vector2(viewport_size.x * (0.12 + 0.19 * i), ground_line_y - 82.0)
		pickup.z_index = 20
		add_child(pickup)
		pickup_nodes.append(pickup)

func _check_pickups() -> void:
	for pickup in pickup_nodes:
		if is_instance_valid(pickup) and pickup.visible and absf(hero.global_position.x - pickup.global_position.x) <= 48.0:
			pickup.hide()
			collected_points += collection_points_value
			PlayerData.add_collection_points(collection_points_value, PlayerData.current_level)
			_update_collection_status()

func _update_collection_status() -> void:
	if collection_status:
		collection_status.text = "Crystals: %d / %d     Quest points: %d" % [int(collected_points / collection_points_value), total_pickups, collected_points]
	if finish_level_button:
		finish_level_button.disabled = collected_points < total_pickups * collection_points_value
	if finish_level_button and not finish_level_button.disabled:
		status_label.text = "Amazing! All crystals collected. Move RIGHT to the trail exit!"

func _show_end_of_trail_choices() -> void:
	if reached_right_exit:
		return
	reached_right_exit = true
	move_direction = 0.0
	if finish_level_button:
		finish_level_button.show()
		finish_level_button.disabled = collected_points < total_pickups * collection_points_value
	if exit_game_button:
		exit_game_button.show()
	if finish_level_button and finish_level_button.disabled:
		status_label.text = "Trail exit reached! Collect all 5 crystals to continue, or exit the game."
	else:
		status_label.text = "Trail exit reached! Continue to the next level or exit the game."
	if collection_status:
		collection_status.text += "     EXIT REACHED!"

func _exit_game() -> void:
	get_tree().quit()

func _complete_level_after_collection() -> void:
	if collected_points < total_pickups * collection_points_value:
		return
	collection_phase = false
	PlayerData.finish_level_timer()
	PlayerData.save_level_result("level_%d" % PlayerData.current_level, correct_answers, PlayerData.current_stars, correct_answers, wrong_answers)
	get_tree().change_scene_to_file("res://scene/lvl_complete.tscn")
