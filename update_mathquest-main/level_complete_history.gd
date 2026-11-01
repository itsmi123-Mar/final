extends Control

func _ready() -> void:
	# The elapsed time is deliberately not shown during play; it appears only on this results screen.
	var timer_label := get_node_or_null("elapsed_time") as Label
	if timer_label == null:
		timer_label = Label.new()
		timer_label.name = "elapsed_time"
		timer_label.text = "Time: %s" % PlayerData.get_last_elapsed_text()
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_label.position = Vector2(100, 830)
		timer_label.size = Vector2(410, 40)
		timer_label.add_theme_font_size_override("font_size", 24)
		add_child(timer_label)
	timer_label.text = "Time: %s" % PlayerData.get_last_elapsed_text()
