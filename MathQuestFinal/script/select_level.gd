extends Control

# ==========================================
# SCENE PATHS
# ==========================================

const PRETEST_SCENE := "res://scene/pretest.tscn"
const LEVEL_START_SCENE := "res://scene/lvl_start.tscn"
const POSTTEST_SCENE := "res://scene/post_test.tscn"
const MAIN_MENU_SCENE := "res://scene/main_menu.tscn"
const CHARACTER_SCENE := "res://scene/choose_character.tscn"
const SCOREBOARD_SCENE := "res://scene/scoreboard.tscn"

const LEVEL_BUTTON_SIZE := Vector2(100, 100)
const STAR_LABEL_HEIGHT := 30


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:

	_set_decorative_controls_mouse_ignored(self)

	# Pre-test / Level 0
	_connect_button("level_grid/pretest", _open_pretest)

	# Levels 1-10
	for level in range(1, 11):

		var level_id: int = level

		_connect_button(
			"level_grid/lvl_%d" % level,
			func(): _open_level(level_id)
		)

	# Post-test
	_connect_button("level_grid/post_test", _open_posttest)

	# Other buttons
	_connect_button(
		"my_scoreboard",
		func(): _change_scene(SCOREBOARD_SCENE)
	)

	_connect_button(
		"home",
		func(): _change_scene(MAIN_MENU_SCENE)
	)

	_connect_button("logout", _logout)

	_connect_button(
		"back",
		func(): _change_scene(CHARACTER_SCENE)
	)

	_refresh_locks()

	call_deferred("_update_level_stars")


# ==========================================
# DECORATIVE CONTROL MOUSE SETTINGS
# ==========================================

func _set_decorative_controls_mouse_ignored(node: Node) -> void:

	for child in node.get_children():

		if child is Control:

			if child is BaseButton:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_set_decorative_controls_mouse_ignored(child)


# ==========================================
# BUTTON CONNECTION
# ==========================================

func _connect_button(
	path: String,
	callback: Callable
) -> void:

	var button := get_node_or_null(path) as BaseButton

	if button == null:
		push_warning("Level screen button not found: " + path)
		return

	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


# ==========================================
# REFRESH LEVEL LOCKS
# ==========================================

func _refresh_locks() -> void:

	# Level 0 is always unlocked.
	var pretest_button := get_node_or_null(
		"level_grid/pretest"
	) as BaseButton

	if pretest_button:
		pretest_button.disabled = false

	# Check Pre-test requirement.
	var pretest_passed: bool = PlayerData.has_pretest_passed()

	# Levels 1-10.
	for level in range(1, 11):

		var level_button := get_node_or_null(
			"level_grid/lvl_%d" % level
		) as BaseButton

		var unlocked: bool = false

		if level == 1:
			unlocked = pretest_passed
		else:
			unlocked = PlayerData.has_level_star(level - 1)

		if level_button:
			level_button.disabled = not unlocked
			level_button.mouse_filter = Control.MOUSE_FILTER_STOP

		# Display lock.
		var lock := get_node_or_null(
			"lock%d" % level
		) as CanvasItem

		if lock:
			lock.visible = not unlocked

	# Post-test requires Level 10 completion.
	var posttest_unlocked: bool = PlayerData.has_level_star(10)

	var posttest_button := get_node_or_null(
		"level_grid/post_test"
	) as BaseButton

	if posttest_button:
		posttest_button.disabled = not posttest_unlocked

	var posttest_lock := get_node_or_null(
		"lock11"
	) as CanvasItem

	if posttest_lock:
		posttest_lock.visible = not posttest_unlocked


# ==========================================
# UPDATE LEVEL STARS
# ==========================================

func _update_level_stars() -> void:

	# Wait for GridContainer to finish arranging buttons.
	await get_tree().process_frame

	var progress: Dictionary = PlayerData.get_current_progress()
	var results: Dictionary = progress.get("level_results", {})

	for level in range(1, 11):

		var level_button := get_node_or_null(
			"level_grid/lvl_%d" % level
		) as Control

		if level_button == null:
			continue

		# Keep every level button consistent.
		level_button.custom_minimum_size = LEVEL_BUTTON_SIZE

		var stars_label := level_button.get_node_or_null(
			"Stars"
		) as Label

		if stars_label == null:

			stars_label = Label.new()
			stars_label.name = "Stars"
			level_button.add_child(stars_label)

		# Get saved level results.
		var result: Dictionary = results.get(
			"level_%d" % level,
			{}
		)

		var earned_stars: int = clampi(
			int(result.get("stars", 0)),
			0,
			3
		)

		# Generate three stars.
		var stars_text: String = ""

		for star_index in range(3):

			if star_index < earned_stars:
				stars_text += "★ "
			else:
				stars_text += "☆ "

		stars_label.text = stars_text.strip_edges()

		# ==================================
		# FIX STAR ALIGNMENT
		# ==================================

		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		stars_label.add_theme_font_size_override(
			"font_size",
			20
		)

		stars_label.add_theme_color_override(
			"font_color",
			Color.WHITE
		)

		# Reset anchors to avoid incorrect positioning.
		stars_label.set_anchors_preset(Control.PRESET_TOP_LEFT)

		# Center stars directly below the level button.
		stars_label.position = Vector2(
			0,
			LEVEL_BUTTON_SIZE.y
		)

		stars_label.size = Vector2(
			LEVEL_BUTTON_SIZE.x,
			STAR_LABEL_HEIGHT
		)

		stars_label.custom_minimum_size = Vector2(
			LEVEL_BUTTON_SIZE.x,
			STAR_LABEL_HEIGHT
		)

		# Ensure stars are visible above other controls.
		stars_label.visible = true
		stars_label.z_index = 10

		# Stars must not block button clicks.
		stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ==========================================
# OPEN LEVEL 0 - PRE-TEST
# ==========================================

func _open_pretest() -> void:

	PlayerData.current_level = 0
	PlayerData.current_quiz_mode = "pretest"

	_change_scene(PRETEST_SCENE)


# ==========================================
# OPEN LEVELS 1-10
# ==========================================

func _open_level(level: int) -> void:

	if level < 1 or level > 10:
		return

	# Level 1 requires completed Pre-test.
	if level == 1:

		if not PlayerData.has_pretest_passed():

			_refresh_locks()

			push_warning(
				"Complete the Pre-test first to unlock Level 1."
			)

			return

	# Levels 2-10 require previous level completion.
	elif not PlayerData.has_level_star(level - 1):

		_refresh_locks()

		push_warning(
			"Earn at least one star on Level %d first."
			% (level - 1)
		)

		return

	# Start selected level.
	PlayerData.current_level = level
	PlayerData.current_quiz_mode = "level"

	_change_scene(LEVEL_START_SCENE)


# ==========================================
# OPEN POST-TEST
# ==========================================

func _open_posttest() -> void:

	if not PlayerData.has_level_star(10):

		_refresh_locks()
		return

	PlayerData.current_quiz_mode = "post_test"

	_change_scene(POSTTEST_SCENE)


# ==========================================
# LOGOUT
# ==========================================

func _logout() -> void:

	PlayerData.logout()

	_change_scene("res://scene/login.tscn")


# ==========================================
# CHANGE SCENE
# ==========================================

func _change_scene(scene_path: String) -> void:

	var error: Error = get_tree().change_scene_to_file(
		scene_path
	)

	if error != OK:

		push_error(
			"Could not open scene: %s (error %d)" % [
				scene_path,
				error
			]
		)
