extends Node2D

const QUESTION_TOTAL: int = 10
const HERO_MOVE_SPEED: float = 320.0
const PORTAL_REACH_DISTANCE: float = 75.0

const LEVEL_ENEMIES := {
	1: {"enemy": "slime", "world": "grass_land"},
	2: {"enemy": "musroom", "world": "shroom_forest"},
	3: {"enemy": "sampling", "world": "lvl1-2"},
	4: {"enemy": "cactus", "world": "desert"},
	5: {"enemy": "goblin", "world": "lvl1-2"},
	6: {"enemy": "wolf", "world": "grass_land"},
	7: {"enemy": "bandit", "world": "desert"},
	8: {"enemy": "necromacer", "world": "night_forest"},
	9: {"enemy": "oger", "world": "shroom_forest"},
	10: {"enemy": "demon", "world": "night_forest"}
}

const HERO_NODES := {
	"m_wizard": "side_m_wiard",
	"m_archer": "m_archer",
	"f_wizard": "side_f_wizard",
	"f_archer": "side_f_archer",
	"warrior": "side_m_warrior",
	"princess": "princess"
}

const OPS := [
	"addition",
	"subtraction",
	"multiplication",
	"division",
	"mixed"
]

var player_hp: int = 100
var enemy_hp: int = 100

var correct_answers: int = 0
var wrong_answers: int = 0
var question_number: int = 0
var correct_combo: int = 0

var battle_finished: bool = false
var action_in_progress: bool = false
var portal_created: bool = false
var portal_reached: bool = false

var move_direction: float = 0.0

var current_question: Dictionary = {}
var battle_questions: Array[Dictionary] = []
var answer_buttons: Array[Button] = []
var stats_this_attempt: Dictionary = {}

var hero: Node2D = null
var enemy: Node2D = null

var hero_sprite: AnimatedSprite2D = null
var enemy_sprite: AnimatedSprite2D = null

var hero_start_position: Vector2 = Vector2.ZERO
var enemy_start_position: Vector2 = Vector2.ZERO

var ground_line_y: float = 0.0

var portal_node: Node2D = null
var portal_tween: Tween = null

var hero_bar: ProgressBar
var enemy_bar: ProgressBar

var hp_label: Label
var question_label: Label
var status_label: Label
var feedback_label: Label

var hud_column: VBoxContainer
var answer_grid: GridContainer

var hp_row_container: HBoxContainer
var return_button: Button
var portal_controls_container: HBoxContainer


func _ready() -> void:
	randomize()

	if PlayerData.current_level < 1 or PlayerData.current_level > 10:
		PlayerData.current_level = 1

	player_hp = 100
	enemy_hp = 100

	correct_answers = 0
	wrong_answers = 0
	question_number = 0
	correct_combo = 0

	battle_finished = false
	action_in_progress = false
	portal_created = false
	portal_reached = false

	stats_this_attempt.clear()

	for op in OPS:
		stats_this_attempt[op] = {
			"correct": 0,
			"total": 0
		}

	_configure_arena()
	_create_battle_ui()
	_build_questions()
	_update_hp()
	_show_question()


func _configure_arena() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	var level_data: Dictionary = LEVEL_ENEMIES.get(
		PlayerData.current_level,
		LEVEL_ENEMIES[1]
	)

	var backgrounds: Node = get_node_or_null("background")

	hero = null
	enemy = null
	hero_sprite = null
	enemy_sprite = null

	if backgrounds != null:
		for world in backgrounds.get_children():
			world.visible = world.name == str(level_data["world"])

			if not world.visible:
				continue

			for child in world.get_children():
				if child is CharacterBody2D:
					child.visible = child.name == str(level_data["enemy"])

					if child.visible:
						enemy = child as Node2D
						enemy_sprite = enemy.find_child(
							"AnimatedSprite2D",
							true,
							false
						) as AnimatedSprite2D

	for child in get_children():
		if HERO_NODES.values().has(child.name):
			child.visible = (
				child.name == str(
					HERO_NODES.get(
						PlayerData.selected_character,
						"side_m_wiard"
					)
				)
			)

			if child.visible:
				hero = child as Node2D

	if hero == null:
		push_error("Selected hero was not found in gameplay.tscn.")
		return

	if enemy == null:
		push_error("Selected monster was not found in gameplay.tscn.")
		return

	hero_sprite = hero.find_child(
		"AnimatedSprite2D",
		true,
		false
	) as AnimatedSprite2D

	enemy_sprite = enemy.find_child(
		"AnimatedSprite2D",
		true,
		false
	) as AnimatedSprite2D

	if hero_sprite == null or enemy_sprite == null:
		push_error("Character AnimatedSprite2D was not found.")
		return

	_play_idle(hero_sprite)
	_play_idle(enemy_sprite)

	ground_line_y = viewport_size.y * 0.78

	_place_character(
		hero,
		hero_sprite,
		viewport_size.x * 0.16,
		ground_line_y,
		viewport_size.y * 0.30
	)

	_place_character(
		enemy,
		enemy_sprite,
		viewport_size.x * 0.84,
		ground_line_y,
		viewport_size.y * 0.30
	)

	hero_start_position = hero.global_position
	enemy_start_position = enemy.global_position

	_setup_animation_size_lock(hero_sprite)
	_setup_animation_size_lock(enemy_sprite)

	hero.show()
	enemy.show()


func _place_character(
	character: Node2D,
	sprite: AnimatedSprite2D,
	center_x: float,
	floor_y: float,
	target_height: float
) -> void:
	if not is_instance_valid(character) or not is_instance_valid(sprite):
		return

	var texture: Texture2D = _get_current_texture(sprite)

	if texture == null or texture.get_height() <= 0:
		return

	var current_height: float = (
		float(texture.get_height()) * absf(sprite.global_scale.y)
	)

	if current_height <= 0.0:
		return

	var scale_factor: float = target_height / current_height

	sprite.global_scale = Vector2(
		sprite.global_scale.x * scale_factor,
		sprite.global_scale.y * scale_factor
	)

	texture = _get_current_texture(sprite)

	if texture == null:
		return

	var half_width: float = (
		float(texture.get_width()) * absf(sprite.global_scale.x) * 0.5
	)

	var safe_x: float = clampf(
		center_x,
		half_width + 10.0,
		get_viewport_rect().size.x - half_width - 10.0
	)

	character.global_position.x += safe_x - sprite.global_position.x

	var bottom_difference: float = floor_y - _sprite_bottom_y(sprite)
	character.global_position.y += bottom_difference


func _get_current_texture(sprite: AnimatedSprite2D) -> Texture2D:
	if sprite == null or sprite.sprite_frames == null:
		return null

	var animation_name: StringName = sprite.animation

	if not sprite.sprite_frames.has_animation(animation_name):
		return null

	var count: int = sprite.sprite_frames.get_frame_count(animation_name)

	if count <= 0:
		return null

	var index: int = clampi(sprite.frame, 0, count - 1)

	return sprite.sprite_frames.get_frame_texture(animation_name, index)


func _sprite_bottom_y(sprite: AnimatedSprite2D) -> float:
	if sprite == null:
		return 0.0

	var texture: Texture2D = _get_current_texture(sprite)

	if texture == null:
		return sprite.global_position.y

	var half_height: float = (
		float(texture.get_height()) * 0.5 * absf(sprite.global_scale.y)
	)

	var offset_y: float = sprite.offset.y * absf(sprite.global_scale.y)

	if sprite.centered:
		return sprite.global_position.y + offset_y + half_height

	return (
		sprite.global_position.y
		+ offset_y
		+ float(texture.get_height()) * absf(sprite.global_scale.y)
	)


# ============================================================
# FIXED ANIMATION SIZE
# ============================================================

func _setup_animation_size_lock(sprite: AnimatedSprite2D) -> void:
	if not is_instance_valid(sprite) or sprite.sprite_frames == null:
		return

	var reference_texture: Texture2D = null

	if sprite.sprite_frames.has_animation("idle"):
		if sprite.sprite_frames.get_frame_count("idle") > 0:
			reference_texture = sprite.sprite_frames.get_frame_texture("idle", 0)

	if reference_texture == null:
		reference_texture = _get_current_texture(sprite)

	if reference_texture == null or reference_texture.get_height() <= 0:
		return

	# Save the exact scale established during arena placement.
	sprite.set_meta("fixed_animation_scale", sprite.scale)

	# Prevent animation frames from changing the displayed character size.
	var frame_callable := Callable(
		self,
		"_normalize_sprite_animation_size"
	).bind(sprite)

	if not sprite.frame_changed.is_connected(frame_callable):
		sprite.frame_changed.connect(frame_callable)

	var animation_callable := Callable(
		self,
		"_normalize_sprite_animation_size"
	).bind(sprite)

	if not sprite.animation_changed.is_connected(animation_callable):
		sprite.animation_changed.connect(animation_callable)

	_normalize_sprite_animation_size(sprite)


func _normalize_sprite_animation_size(sprite: AnimatedSprite2D) -> void:
	if not is_instance_valid(sprite):
		return

	if not sprite.has_meta("fixed_animation_scale"):
		return

	# IMPORTANT:
	# Never calculate a new scale using the attack or hurt frame.
	# Always restore the original idle scale.
	var fixed_scale: Vector2 = sprite.get_meta("fixed_animation_scale")

	sprite.scale = fixed_scale


# ============================================================
# BATTLE HUD
# ============================================================

func _create_battle_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "BattleHUD"
	add_child(layer)

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.size = Vector2(
		minf(574.0, viewport_size.x - 36.0),
		minf(410.0, viewport_size.y * 0.58)
	)
	layer.add_child(panel)

	var column := VBoxContainer.new()
	hud_column = column
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)

	var title := Label.new()
	title.text = "LEVEL %d BATTLE" % PlayerData.current_level
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	column.add_child(title)

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
	hero_bar.value = 100
	hero_bar.show_percentage = false
	hero_column.add_child(hero_bar)

	var enemy_column := VBoxContainer.new()
	enemy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(enemy_column)

	var enemy_title := Label.new()
	enemy_title.text = str(
		LEVEL_ENEMIES[PlayerData.current_level]["enemy"]
	).to_upper()
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_column.add_child(enemy_title)

	enemy_bar = ProgressBar.new()
	enemy_bar.max_value = 100
	enemy_bar.value = 100
	enemy_bar.show_percentage = false
	enemy_column.add_child(enemy_bar)

	hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hp_label)

	question_label = Label.new()
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.custom_minimum_size = Vector2(0, 58)
	question_label.add_theme_font_size_override("font_size", 28)
	column.add_child(question_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(feedback_label)

	answer_grid = GridContainer.new()
	answer_grid.columns = 2
	answer_grid.add_theme_constant_override("h_separation", 10)
	answer_grid.add_theme_constant_override("v_separation", 10)
	column.add_child(answer_grid)

	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 23)
		button.pressed.connect(_on_answer.bind(button))

		answer_grid.add_child(button)
		answer_buttons.append(button)

	return_button = Button.new()
	return_button.text = "Return to Level Selection"
	return_button.pressed.connect(_exit_to_level_selection)
	column.add_child(return_button)


# ============================================================
# QUESTION GENERATION
# ============================================================

func _build_questions() -> void:
	battle_questions.clear()

	var stats: Dictionary = PlayerData.get_operation_stats()

	var weakest: String = "addition"
	var lowest_rate: float = 2.0

	for op in OPS:
		var stat: Dictionary = stats.get(
			op,
			{"correct": 0, "total": 0}
		)

		var total: int = int(stat.get("total", 0))
		var rate: float = 0.5

		if total > 0:
			rate = float(stat.get("correct", 0)) / float(total)

		if rate < lowest_rate:
			lowest_rate = rate
			weakest = op

	for i in range(QUESTION_TOTAL):
		var operation: String

		if i < 4:
			operation = weakest
		else:
			operation = OPS[randi_range(0, OPS.size() - 1)]

		battle_questions.append(
			_make_question(operation, PlayerData.current_level)
		)

	battle_questions.shuffle()


func _make_question(op: String, level: int) -> Dictionary:
	var a: int = 0
	var b: int = 0
	var c: int = 0
	var answer: int = 0
	var prompt: String = ""

	match op:
		"addition":
			var max_number: int = mini(20, 5 + level * 2)
			a = randi_range(1, max_number)
			b = randi_range(1, max_number)
			answer = a + b
			prompt = "%d + %d" % [a, b]

		"subtraction":
			a = randi_range(5, mini(50, 10 + level * 4))
			b = randi_range(1, a)
			answer = a - b
			prompt = "%d - %d" % [a, b]

		"multiplication":
			a = randi_range(2, 9)
			b = randi_range(2, 9)
			answer = a * b
			prompt = "%d x %d" % [a, b]

		"division":
			b = randi_range(2, 9)
			answer = randi_range(2, 9)
			a = b * answer
			prompt = "%d / %d" % [a, b]

		"mixed":
			if randi_range(0, 1) == 0:
				a = randi_range(1, 9)
				b = randi_range(2, 6)
				c = randi_range(2, 6)
				answer = a + b * c
				prompt = "%d + %d x %d" % [a, b, c]
			else:
				a = randi_range(2, 8)
				b = randi_range(2, 8)
				c = randi_range(1, mini(9, a * b - 1))
				answer = a * b - c
				prompt = "%d x %d - %d" % [a, b, c]

	return {
		"op": op,
		"prompt": prompt,
		"answer": answer
	}


# ============================================================
# DISPLAY QUESTION
# ============================================================

func _show_question() -> void:
	if battle_finished:
		return

	if question_number >= QUESTION_TOTAL:
		_finish_battle()
		return

	current_question = battle_questions[question_number]

	question_label.text = (
		"Question %d/10\n%s = ?"
		% [
			question_number + 1,
			current_question["prompt"]
		]
	)

	status_label.text = "Correct = Hero attacks! Wrong = Monster attacks!"
	feedback_label.text = ""

	var answer: int = int(current_question["answer"])
	var choices: Array[int] = [answer]

	while choices.size() < 4:
		var delta: int = randi_range(
			1,
			maxi(4, int(abs(answer) * 0.2) + 3)
		)

		var candidate: int = maxi(
			0,
			answer + (
				delta if randi_range(0, 1) == 0 else -delta
			)
		)

		if not choices.has(candidate):
			choices.append(candidate)

	choices.shuffle()

	for i in range(answer_buttons.size()):
		answer_buttons[i].text = str(choices[i])
		answer_buttons[i].disabled = false


# ============================================================
# ANSWER PROCESSING
# ============================================================

func _on_answer(button: Button) -> void:
	if battle_finished or action_in_progress:
		return

	action_in_progress = true

	for answer_button in answer_buttons:
		answer_button.disabled = true

	var op: String = str(current_question["op"])
	var stat: Dictionary = stats_this_attempt[op]

	stat["total"] = int(stat["total"]) + 1

	var is_correct: bool = (
		int(button.text) == int(current_question["answer"])
	)

	if is_correct:
		correct_answers += 1
		stat["correct"] = int(stat["correct"]) + 1
		correct_combo += 1

		feedback_label.text = "CORRECT! HERO SKILL ACTIVATED!"

		await _hero_attack_once()

		enemy_hp = maxi(0, enemy_hp - 10)
		_update_hp()
	else:
		wrong_answers += 1
		correct_combo = 0

		feedback_label.text = "WRONG ANSWER! MONSTER ATTACKS!"

		await get_tree().create_timer(0.35).timeout

		await _enemy_attack_once()

		player_hp = maxi(0, player_hp - 10)
		_update_hp()

	question_number += 1

	await get_tree().create_timer(0.4).timeout

	action_in_progress = false

	if question_number >= QUESTION_TOTAL:
		_finish_battle()
	else:
		_show_question()


# ============================================================
# HERO ATTACK
# ============================================================

func _hero_attack_once() -> void:
	if not is_instance_valid(hero) or not is_instance_valid(enemy):
		return

	await _play_and_wait(
		hero_sprite,
		["skill", "magic", "cast", "attack"]
	)

	if is_instance_valid(hero_sprite) and is_instance_valid(enemy_sprite):
		await _create_magic_projectile()

	await _enemy_recoil_once()

	_play_idle(hero_sprite)


func _create_magic_projectile() -> void:
	if not is_instance_valid(hero_sprite):
		return

	if not is_instance_valid(enemy_sprite):
		return

	var projectile := Node2D.new()
	projectile.name = "MagicProjectile"

	projectile.global_position = (
		hero_sprite.global_position + Vector2(25, -55)
	)

	add_child(projectile)

	var glow := Polygon2D.new()
	glow.color = Color(1.0, 0.55, 0.05, 0.35)

	var glow_points := PackedVector2Array()

	for i in range(20):
		var angle: float = TAU * float(i) / 20.0
		glow_points.append(
			Vector2(
				cos(angle) * 23.0,
				sin(angle) * 23.0
			)
		)

	glow.polygon = glow_points
	projectile.add_child(glow)

	var orb := Polygon2D.new()
	orb.color = Color(1.0, 0.72, 0.12, 1.0)

	var points := PackedVector2Array()

	for i in range(20):
		var angle: float = TAU * float(i) / 20.0
		points.append(
			Vector2(
				cos(angle) * 13.0,
				sin(angle) * 13.0
			)
		)

	orb.polygon = points
	projectile.add_child(orb)

	var destination: Vector2 = (
		enemy_sprite.global_position + Vector2(0, -65)
	)

	var tween := create_tween()

	tween.tween_property(
		projectile,
		"global_position",
		destination,
		0.38
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished

	if is_instance_valid(enemy):
		var original_color: Color = enemy.modulate
		var impact := create_tween()

		impact.tween_property(
			enemy,
			"modulate",
			Color(1.0, 0.3, 0.2, original_color.a),
			0.08
		)

		impact.tween_property(
			enemy,
			"modulate",
			original_color,
			0.12
		)

		await impact.finished

	if is_instance_valid(projectile):
		projectile.queue_free()


# ============================================================
# MONSTER ATTACK
# ============================================================

func _enemy_attack_once() -> void:
	if not is_instance_valid(enemy) or not is_instance_valid(hero):
		return

	await _play_and_wait(
		enemy_sprite,
		["attack"]
	)

	await _play_and_wait(
		hero_sprite,
		["hurt"]
	)

	await _hero_recoil_once()

	_play_idle(hero_sprite)
	_play_idle(enemy_sprite)


# ============================================================
# CHARACTER ANIMATION HELPERS
# ============================================================

func _play_and_wait(
	sprite: AnimatedSprite2D,
	candidates: Array
) -> void:
	if not is_instance_valid(sprite):
		return

	if sprite.sprite_frames == null:
		return

	var selected_animation: StringName = &""

	for candidate in candidates:
		var animation_name := StringName(str(candidate))

		if sprite.sprite_frames.has_animation(animation_name):
			if sprite.sprite_frames.get_frame_count(animation_name) <= 0:
				continue

			selected_animation = animation_name
			break

	if selected_animation == &"":
		return

	sprite.sprite_frames.set_animation_loop(
		selected_animation,
		false
	)

	sprite.play(selected_animation)

	_normalize_sprite_animation_size(sprite)

	var frame_count: int = sprite.sprite_frames.get_frame_count(
		selected_animation
	)

	var fps: float = sprite.sprite_frames.get_animation_speed(
		selected_animation
	)

	var duration: float = 0.45

	if fps > 0.0:
		duration = float(frame_count) / fps

	duration = clampf(duration, 0.2, 1.2)

	await get_tree().create_timer(duration).timeout

	if not is_instance_valid(sprite):
		return

	_play_idle(sprite)
	_normalize_sprite_animation_size(sprite)


func _play_idle(sprite: AnimatedSprite2D) -> void:
	if not is_instance_valid(sprite):
		return

	if sprite.sprite_frames == null:
		return

	if sprite.sprite_frames.has_animation("idle"):
		sprite.sprite_frames.set_animation_loop("idle", true)
		sprite.play("idle")
		_normalize_sprite_animation_size(sprite)


# ============================================================
# DAMAGE REACTIONS
# ============================================================

func _enemy_recoil_once() -> void:
	if not is_instance_valid(enemy):
		return

	var original_color: Color = enemy.modulate
	var tween := create_tween()

	tween.tween_property(
		enemy,
		"modulate",
		Color(1.0, 0.3, 0.3, original_color.a),
		0.08
	)

	tween.tween_property(
		enemy,
		"modulate",
		original_color,
		0.12
	)

	await tween.finished


func _hero_recoil_once() -> void:
	if not is_instance_valid(hero):
		return

	var original_color: Color = hero.modulate
	var tween := create_tween()

	tween.tween_property(
		hero,
		"modulate",
		Color(1.0, 0.4, 0.4, original_color.a),
		0.08
	)

	tween.tween_property(
		hero,
		"modulate",
		original_color,
		0.12
	)

	await tween.finished


# ============================================================
# HP UPDATE
# ============================================================

func _update_hp() -> void:
	if is_instance_valid(hero_bar):
		hero_bar.value = player_hp

	if is_instance_valid(enemy_bar):
		enemy_bar.value = enemy_hp

	if is_instance_valid(hp_label):
		hp_label.text = (
			"Hero HP: %d/100     Enemy HP: %d/100"
			% [player_hp, enemy_hp]
		)


# ============================================================
# BATTLE RESULT
# ============================================================

func _finish_battle() -> void:
	if battle_finished:
		return

	if question_number < QUESTION_TOTAL:
		return

	battle_finished = true

	for button in answer_buttons:
		button.disabled = true

	PlayerData.current_score = correct_answers
	PlayerData.quiz_correct = correct_answers
	PlayerData.quiz_wrong = wrong_answers
	PlayerData.last_quiz_score = correct_answers

	PlayerData.save_operation_stats(stats_this_attempt)

	var earned_stars: int = 0

	if correct_answers == 10:
		earned_stars = 3
	elif correct_answers >= 8:
		earned_stars = 2
	elif correct_answers == 7:
		earned_stars = 1

	PlayerData.current_stars = earned_stars
	PlayerData.last_quiz_stars = earned_stars

	PlayerData.save_level_result(
		"level_%d" % PlayerData.current_level,
		correct_answers,
		earned_stars,
		correct_answers,
		wrong_answers
	)

	if correct_answers <= 6:
		status_label.text = "BATTLE FAILED!"
		question_label.text = "MONSTER SURVIVED!"

		feedback_label.text = (
			"%d/10 correct. You need at least 7 correct answers to defeat the monster."
			% correct_answers
		)

		_show_result_choices(
			"TRY AGAIN!",
			"%d/10 correct. You need at least 7 correct answers to defeat the monster."
			% correct_answers,
			false
		)

		return

	if correct_answers >= 7 and correct_answers <= 9:
		status_label.text = "MONSTER DEFEATED!"

		question_label.text = (
			"VICTORY!\n%d/10 CORRECT!"
			% correct_answers
		)

		feedback_label.text = (
			"YOU EARNED %d STAR(S)!"
			% earned_stars
		)

		await _hero_attack_once()

		enemy_hp = 0
		_update_hp()

		await get_tree().create_timer(0.3).timeout
		await _show_portal_and_enter()

		return

	if correct_answers == 10:
		status_label.text = "PERFECT SCORE!"
		question_label.text = "PERFECT VICTORY!"
		feedback_label.text = "ALL 10 CORRECT! YOU EARNED 3 STARS!"

		enemy_hp = 0
		_update_hp()

		await get_tree().create_timer(0.3).timeout
		await _show_portal_and_enter()

		return


# ============================================================
# PORTAL APPEARANCE
# ============================================================

func _show_portal_and_enter() -> void:
	if portal_created:
		return

	portal_created = true
	portal_reached = false
	move_direction = 0.0

	if not is_instance_valid(hero):
		_show_portal_choices()
		return

	if is_instance_valid(enemy_sprite):
		await _play_and_wait(
			enemy_sprite,
			["dead", "death"]
		)

	if is_instance_valid(enemy):
		enemy.hide()

	status_label.text = "MONSTER DEFEATED!"
	feedback_label.text = "A MAGICAL PORTAL HAS APPEARED!"

	var viewport_size: Vector2 = get_viewport_rect().size

	portal_node = Node2D.new()
	portal_node.name = "LevelPortal"

	portal_node.global_position = Vector2(
		viewport_size.x * 0.84,
		ground_line_y - 65.0
	)

	portal_node.scale = Vector2(0.65, 0.65)

	add_child(portal_node)

	var outer := Polygon2D.new()
	outer.color = Color(0.38, 0.12, 0.95, 0.95)

	var outer_points := PackedVector2Array()

	for i in range(48):
		var angle: float = TAU * float(i) / 48.0
		outer_points.append(
			Vector2(
				cos(angle) * 48.0,
				sin(angle) * 85.0
			)
		)

	outer.polygon = outer_points
	portal_node.add_child(outer)

	var inner := Polygon2D.new()
	inner.color = Color(0.1, 0.8, 1.0, 0.95)

	var inner_points := PackedVector2Array()

	for i in range(48):
		var angle: float = TAU * float(i) / 48.0
		inner_points.append(
			Vector2(
				cos(angle) * 34.0,
				sin(angle) * 70.0
			)
		)

	inner.polygon = inner_points
	portal_node.add_child(inner)

	var glow := Polygon2D.new()
	glow.color = Color(0.3, 0.7, 1.0, 0.25)

	var glow_points := PackedVector2Array()

	for i in range(48):
		var angle: float = TAU * float(i) / 48.0
		glow_points.append(
			Vector2(
				cos(angle) * 58.0,
				sin(angle) * 95.0
			)
		)

	glow.polygon = glow_points
	portal_node.add_child(glow)

	portal_node.move_child(glow, 0)

	portal_tween = create_tween()
	portal_tween.set_loops()

	portal_tween.tween_property(
		portal_node,
		"rotation",
		TAU,
		2.0
	)

	feedback_label.text = (
		"USE LEFT AND RIGHT BUTTONS TO REACH THE PORTAL!"
	)

	_create_portal_movement_controls()


# ============================================================
# MANUAL AVATAR MOVEMENT
# ============================================================

func _process(delta: float) -> void:
	if not portal_created or portal_reached:
		return

	if not is_instance_valid(hero) or not is_instance_valid(portal_node):
		return

	if move_direction == 0.0:
		return

	var viewport_width: float = get_viewport_rect().size.x

	var new_x: float = (
		hero.global_position.x
		+ move_direction * HERO_MOVE_SPEED * delta
	)

	hero.global_position.x = clampf(
		new_x,
		40.0,
		viewport_width - 40.0
	)

	if is_instance_valid(hero_sprite):
		hero_sprite.flip_h = move_direction < 0.0

		if hero_sprite.sprite_frames.has_animation("walk"):
			hero_sprite.play("walk")
			_normalize_sprite_animation_size(hero_sprite)

	var distance: float = absf(
		hero.global_position.x - portal_node.global_position.x
	)

	if distance <= PORTAL_REACH_DISTANCE:
		_on_hero_reached_portal()


# ============================================================
# PORTAL MOVEMENT BUTTONS
# ============================================================

func _create_portal_movement_controls() -> void:
	if is_instance_valid(portal_controls_container):
		portal_controls_container.queue_free()

	var layer := get_node_or_null("BattleHUD") as CanvasLayer

	if layer == null:
		return

	portal_controls_container = HBoxContainer.new()
	portal_controls_container.name = "PortalMovementControls"

	portal_controls_container.set_anchors_preset(
		Control.PRESET_BOTTOM_LEFT
	)

	portal_controls_container.position = Vector2(25, -110)

	portal_controls_container.add_theme_constant_override(
		"separation",
		25
	)

	layer.add_child(portal_controls_container)

	var left_button := Button.new()
	left_button.text = "◀"
	left_button.custom_minimum_size = Vector2(100, 75)
	left_button.add_theme_font_size_override("font_size", 35)

	left_button.button_down.connect(
		func():
			if not portal_reached:
				move_direction = -1.0

				if is_instance_valid(hero_sprite):
					hero_sprite.flip_h = true
	)

	left_button.button_up.connect(
		func():
			if move_direction < 0.0:
				move_direction = 0.0
				_play_idle(hero_sprite)
	)

	portal_controls_container.add_child(left_button)

	var right_button := Button.new()
	right_button.text = "▶"
	right_button.custom_minimum_size = Vector2(100, 75)
	right_button.add_theme_font_size_override("font_size", 35)

	right_button.button_down.connect(
		func():
			if not portal_reached:
				move_direction = 1.0

				if is_instance_valid(hero_sprite):
					hero_sprite.flip_h = false
	)

	right_button.button_up.connect(
		func():
			if move_direction > 0.0:
				move_direction = 0.0
				_play_idle(hero_sprite)
	)

	portal_controls_container.add_child(right_button)


# ============================================================
# HERO REACHES PORTAL
# ============================================================

func _on_hero_reached_portal() -> void:
	if portal_reached:
		return

	portal_reached = true
	move_direction = 0.0

	if is_instance_valid(hero_sprite):
		_play_idle(hero_sprite)

	if is_instance_valid(portal_controls_container):
		portal_controls_container.hide()

	feedback_label.text = "YOU REACHED THE PORTAL!"

	await get_tree().create_timer(0.5).timeout

	if is_instance_valid(hero):
		hero.hide()

	if is_instance_valid(portal_node):
		portal_node.hide()

	if is_instance_valid(portal_tween):
		portal_tween.kill()

	_show_portal_choices()


# ============================================================
# PORTAL RESULT BUTTONS
# ============================================================

func _show_portal_choices() -> void:
	if is_instance_valid(answer_grid):
		answer_grid.hide()

	if is_instance_valid(return_button):
		return_button.hide()

	if is_instance_valid(hp_row_container):
		hp_row_container.hide()

	if is_instance_valid(hp_label):
		hp_label.hide()

	if is_instance_valid(portal_controls_container):
		portal_controls_container.hide()

	question_label.text = (
		"LEVEL %d CLEARED!"
		% PlayerData.current_level
	)

	if correct_answers >= 7 and correct_answers <= 9:
		status_label.text = (
			"MONSTER DEFEATED! YOU EARNED %d STAR(S)!"
			% PlayerData.current_stars
		)
	else:
		status_label.text = "PERFECT SCORE! YOU EARNED 3 STARS!"

	feedback_label.text = "CHOOSE WHAT TO DO NEXT."

	var next_button := Button.new()

	if PlayerData.current_level < 10:
		next_button.text = "CONTINUE TO NEXT LEVEL"
	else:
		next_button.text = "CONTINUE TO POST-TEST"

	next_button.custom_minimum_size = Vector2(0, 52)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.pressed.connect(_continue_to_next_level)

	hud_column.add_child(next_button)

	var exit_button := Button.new()
	exit_button.text = "EXIT TO LEVEL SELECTION"
	exit_button.custom_minimum_size = Vector2(0, 48)
	exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_button.pressed.connect(_exit_to_level_selection)

	hud_column.add_child(exit_button)


# ============================================================
# NEXT LEVEL
# ============================================================

func _continue_to_next_level() -> void:
	if PlayerData.current_level >= 10:
		PlayerData.current_quiz_mode = "post_test"

		get_tree().change_scene_to_file(
			"res://scene/post_test.tscn"
		)
	else:
		PlayerData.current_level += 1
		PlayerData.current_quiz_mode = "level"

		get_tree().change_scene_to_file(
			"res://scene/lvl_start.tscn"
		)


# ============================================================
# EXIT TO LEVEL SELECTION
# ============================================================

func _exit_to_level_selection() -> void:
	move_direction = 0.0

	if is_instance_valid(portal_tween):
		portal_tween.kill()

	get_tree().change_scene_to_file(
		"res://scene/select_level.tscn"
	)


# ============================================================
# RETRY OR EXIT
# ============================================================

func _show_result_choices(
	title_text: String,
	message_text: String,
	passed: bool
) -> void:
	if is_instance_valid(answer_grid):
		answer_grid.hide()

	if is_instance_valid(return_button):
		return_button.hide()

	if is_instance_valid(hp_row_container):
		hp_row_container.hide()

	if is_instance_valid(hp_label):
		hp_label.hide()

	question_label.text = title_text
	status_label.text = message_text

	feedback_label.text = (
		"Correct: %d/10     Incorrect: %d/10"
		% [correct_answers, wrong_answers]
	)

	var action_button := Button.new()

	action_button.custom_minimum_size = Vector2(0, 50)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if passed:
		action_button.text = "CONTINUE TO NEXT LEVEL"
		action_button.pressed.connect(_continue_to_next_level)
	else:
		action_button.text = (
			"RETRY LEVEL %d"
			% PlayerData.current_level
		)

		action_button.pressed.connect(
			func():
				get_tree().reload_current_scene()
		)

	hud_column.add_child(action_button)

	var exit_button := Button.new()

	exit_button.text = "EXIT TO LEVEL SELECTION"
	exit_button.custom_minimum_size = Vector2(0, 46)
	exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_button.pressed.connect(_exit_to_level_selection)

	hud_column.add_child(exit_button)
