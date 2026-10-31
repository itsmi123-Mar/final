extends Control

const CHARACTER_NAMES: Array[String] = ["m_wizard", "m_archer", "f_archer", "f_wizard", "princess", "warrior"]
const ALL_CHARACTER_NAMES: Array[String] = ["m_wizard", "m_archer", "f_archer", "f_wizard", "princess", "warrior"]
const DISPLAY_NAMES := {
	"m_wizard": "Male Wizard", "m_archer": "Male Archer",
	"f_archer": "Female Archer", "f_wizard": "Female Wizard",
	"princess": "Princess", "warrior": "Warrior"
}
const MENU_SCENE := "res://scene/main_menu.tscn"
const LEVEL_SCENE := "res://scene/select_level.tscn"

var selected_character: String = "m_wizard"
var lock_labels: Array[Label] = []
var selected_label: Label
var original_scales: Dictionary = {}

func _ready() -> void:
	# Both wizard characters are available from the start.
	selected_character = str(PlayerData.get_saved_selected_character())
	if not CHARACTER_NAMES.has(selected_character):
		selected_character = "m_wizard"
	PlayerData.selected_character = selected_character
	for character in ALL_CHARACTER_NAMES:
		var character_node := get_node_or_null(character) as Node2D
		if character_node:
			character_node.visible = true

	var confirm_button := get_node_or_null("confirm") as Button
	if confirm_button:
		if not confirm_button.pressed.is_connected(_on_confirm):
			confirm_button.pressed.connect(_on_confirm)

	var back_button := get_node_or_null("back") as BaseButton
	if back_button:
		if not back_button.pressed.is_connected(_on_back):
			back_button.pressed.connect(_on_back)

	selected_label = Label.new()
	selected_label.name = "SelectedCharacterLabel"
	selected_label.text = "✓ SELECTED: WIZARD"
	selected_label.add_theme_font_size_override("font_size", 18)
	selected_label.add_theme_color_override("font_color", Color(0.1, 0.8, 0.2))
	selected_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	selected_label.add_theme_constant_override("shadow_offset_x", 2)
	selected_label.add_theme_constant_override("shadow_offset_y", 2)
	selected_label.z_index = 100
	add_child(selected_label)

	for character in CHARACTER_NAMES:
		var node := get_node_or_null(character) as Node2D
		if node:
			original_scales[character] = node.scale

	_refresh_character_locks()
	_update_selection_visual()

func _get_unlocked_characters() -> Array:
	return PlayerData.get_unlocked_characters()

func _refresh_character_locks() -> void:
	for label in lock_labels:
		if is_instance_valid(label):
			label.queue_free()
	lock_labels.clear()

	var unlocked := _get_unlocked_characters()
	for character in CHARACTER_NAMES:
		var node := get_node_or_null(character) as Node2D
		if node == null:
			continue
		var is_unlocked: bool = unlocked.has(character)
		node.modulate = Color.WHITE if is_unlocked else Color(0.45, 0.45, 0.45, 1.0)
		if not is_unlocked:
			var lock := Label.new()
			lock.name = "Lock_" + character
			lock.text = "🔒 LOCKED"
			lock.add_theme_font_size_override("font_size", 16)
			lock.add_theme_color_override("font_color", Color(1.0, 0.82, 0.15))
			lock.position = node.position + Vector2(-50, 60)
			lock.z_index = 100
			add_child(lock)
			lock_labels.append(lock)

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var mouse_position := get_global_mouse_position()
	var unlocked := _get_unlocked_characters()
	for character in CHARACTER_NAMES:
		var node := get_node_or_null(character) as Node2D
		if node == null or not unlocked.has(character):
			continue
		var sprite := node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if sprite == null or sprite.sprite_frames == null:
			continue
		if not sprite.sprite_frames.has_animation(sprite.animation):
			continue
		var frame_count := sprite.sprite_frames.get_frame_count(sprite.animation)
		if frame_count <= 0:
			continue
		var frame_index := clampi(sprite.frame, 0, frame_count - 1)
		var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, frame_index)
		if texture == null:
			continue

		# The mouse is converted to the sprite's local space, so the rectangle
		# is centered on the sprite origin and does not need get_rect().
		var local_mouse := sprite.to_local(mouse_position)
		var texture_size := texture.get_size()
		var sprite_rect := Rect2(-texture_size / 2.0, texture_size)
		if sprite_rect.has_point(local_mouse):
			selected_character = character
			PlayerData.selected_character = character
			_update_selection_visual()
			get_viewport().set_input_as_handled()
			return

func _update_selection_visual() -> void:
	for character in CHARACTER_NAMES:
		var node := get_node_or_null(character) as Node2D
		if node == null:
			continue
		var base_scale: Vector2 = original_scales.get(character, Vector2.ONE)
		node.scale = base_scale * (1.08 if character == selected_character else 1.0)

	if selected_label:
		var selected_node := get_node_or_null(selected_character) as Node2D
		if selected_node:
			selected_label.text = "✓ SELECTED: " + str(DISPLAY_NAMES.get(selected_character, selected_character)).to_upper()
			selected_label.position = selected_node.position + Vector2(-65, 95)

func _on_confirm() -> void:
	var unlocked := _get_unlocked_characters()
	if not unlocked.has(selected_character):
		selected_character = "m_wizard"
	if not PlayerData.save_selected_character(selected_character):
		push_warning("Could not save selected wizard; keeping the selection for this session.")
		PlayerData.selected_character = selected_character
	var error := get_tree().change_scene_to_file(LEVEL_SCENE)
	if error != OK:
		push_error("Could not open level selection scene: " + LEVEL_SCENE)

func _on_back() -> void:
	var error := get_tree().change_scene_to_file(MENU_SCENE)
	if error != OK:
		push_error("Could not return to main menu scene: " + MENU_SCENE)
