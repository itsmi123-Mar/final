extends Control

const PRETEST_SCENE := "res://scene/pretest.tscn"
const LEVEL_START_SCENE := "res://scene/lvl_start.tscn"
const POSTTEST_SCENE := "res://scene/post_test.tscn"
const MAIN_MENU_SCENE := "res://scene/main_menu.tscn"
const CHARACTER_SCENE := "res://scene/choose_character.tscn"
const SCOREBOARD_SCENE := "res://scene/scoreboard.tscn"

func _ready() -> void:
	# Decorative Controls later in the scene tree can sit over the level buttons.
	# Let clicks pass through them while keeping actual buttons clickable.
	_set_decorative_controls_mouse_ignored(self)

	_connect_button("level_grid/pretest", _open_pretest)
	for level in range(1, 11):
		var level_id := level
		_connect_button("level_grid/lvl_%d" % level, func(): _open_level(level_id))
	_connect_button("level_grid/post_test", _open_posttest)
	_connect_button("my_scoreboard", func(): _change_scene(SCOREBOARD_SCENE))
	_connect_button("home", func(): _change_scene(MAIN_MENU_SCENE))
	_connect_button("logout", _logout)
	_connect_button("back", func(): _change_scene(CHARACTER_SCENE))
	_refresh_locks()

func _set_decorative_controls_mouse_ignored(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			if child is BaseButton:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_decorative_controls_mouse_ignored(child)

func _connect_button(path: String, callback: Callable) -> void:
	var button := get_node_or_null(path) as BaseButton
	if button == null:
		push_warning("Level screen button not found: " + path)
		return
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _refresh_locks() -> void:
	var pre_done := PlayerData.has_pretest_passed()
	var pre := get_node_or_null("level_grid/pretest") as BaseButton
	if pre:
		pre.disabled = false

	for level in range(1, 11):
		var button := get_node_or_null("level_grid/lvl_%d" % level) as BaseButton
		var unlocked: bool = pre_done if level == 1 else PlayerData.has_level_star(level - 1)
		if button:
			button.disabled = not unlocked
			button.mouse_filter = Control.MOUSE_FILTER_STOP
		var lock := get_node_or_null("lock%d" % level) as CanvasItem
		if lock:
			lock.visible = not unlocked

	var post_unlocked := PlayerData.has_level_star(10)
	var post := get_node_or_null("level_grid/post_test") as BaseButton
	if post:
		post.disabled = not post_unlocked
	var post_lock := get_node_or_null("lock11") as CanvasItem
	if post_lock:
		post_lock.visible = not post_unlocked

func _open_pretest() -> void:
	PlayerData.current_level = 0
	PlayerData.current_quiz_mode = "pretest"
	_change_scene(PRETEST_SCENE)

func _open_level(level: int) -> void:
	if level == 1 and not PlayerData.has_pretest_passed():
		_refresh_locks()
		push_warning("Complete the pretest with at least one star to unlock Level 1.")
		return
	if level > 1 and not PlayerData.has_level_star(level - 1):
		_refresh_locks()
		push_warning("Earn at least one star on Level %d first." % (level - 1))
		return
	PlayerData.current_level = level
	PlayerData.current_quiz_mode = "level"
	_change_scene(LEVEL_START_SCENE)

func _open_posttest() -> void:
	if not PlayerData.has_level_star(10):
		return
	PlayerData.current_quiz_mode = "post_test"
	_change_scene(POSTTEST_SCENE)

func _logout() -> void:
	PlayerData.logout()
	_change_scene("res://scene/login.tscn")

func _change_scene(scene_path: String) -> void:
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Could not open scene: %s (error %d)" % [scene_path, err])
