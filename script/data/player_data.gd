extends Node

const SAVE_PATH := "user://mathquest_progress.json"

# Replace these fictional test accounts with approved test accounts locally.
# Do not commit real pupil identifiers or passwords to a shared repository.
const REGISTERED_TEACHERS := {
	"sheryl g. ancheta": {"display_name": "Sheryl G. Ancheta", "password": "Sheryl1", "grade": "Grade 3"},
	"jim cesar baylon": {"display_name": "Jim Cesar Baylon", "password": "Jim1", "grade": "Grade 4"}
}

# Student sign-in: enter the learner's full name and use their LRN as password.
const REGISTERED_PUPILS := {
	"jacchaeus james p. agustin": {"password": "100085220007", "grade": "Grade 4"},
	"jevon wayne q. quemquem": {"password": "100085220008", "grade": "Grade 4"},
	"avi kristine a. coloma": {"password": "100085220013", "grade": "Grade 4"},
	"angela marie b. layaoen": {"password": "100085220022", "grade": "Grade 4"},
	"princess xia c. moral": {"password": "100085220014", "grade": "Grade 4"},
	"sophia faith b. apin": {"password": "107886230108", "grade": "Grade 3"},
	"ma. bella christe g. gudoy": {"password": "100085230015", "grade": "Grade 3"},
	"deib lohr c. pugat": {"password": "100085230020", "grade": "Grade 3"},
	"macc khenzie g. cudiamat": {"password": "100085230002", "grade": "Grade 3"},
	"liam jaeden d. tapec": {"password": "100085230011", "grade": "Grade 3"}
}

var current_pupil_id: String = ""
var current_role: String = "pupil"
var current_teacher: Dictionary = {}
var selected_student_id: String = ""
var selected_character: String = "m_wizard"
var current_pupil: Dictionary = {}
var current_level: int = 0
var current_score: int = 0
var current_stars: int = 0
var quiz_correct: int = 0
var quiz_wrong: int = 0
var operation_stats: Dictionary = {}
var current_quiz_mode: String = "level"
var last_quiz_score: int = 0
var last_quiz_stars: int = 0

func _default_operation_stats() -> Dictionary:
	return {
		"addition": {"correct": 0, "total": 0},
		"subtraction": {"correct": 0, "total": 0},
		"multiplication": {"correct": 0, "total": 0},
		"division": {"correct": 0, "total": 0},
		"mixed": {"correct": 0, "total": 0}
	}


func get_operation_stats() -> Dictionary:
	var progress := get_current_progress()
	var saved: Variant = progress.get("operation_stats", {})
	var normalized := _default_operation_stats()
	if saved is Dictionary:
		for operation in normalized.keys():
			var item: Variant = saved.get(operation, {})
			if item is Dictionary:
				var total := maxi(0, int(item.get("total", 0)))
				var correct := clampi(int(item.get("correct", 0)), 0, total)
				normalized[operation] = {"correct": correct, "total": total}
	return normalized

func save_operation_stats(stats: Dictionary) -> void:
	if current_pupil_id.is_empty():
		return
	var data := _load_data()
	var pupils: Dictionary = data.get("pupils", {})
	if not pupils.has(current_pupil_id):
		return
	var pupil: Dictionary = pupils[current_pupil_id]
	var saved: Dictionary = pupil.get("operation_stats", _default_operation_stats())
	for op in _default_operation_stats().keys():
		var old_value: Variant = saved.get(op, {"correct": 0, "total": 0})
		var add_value: Variant = stats.get(op, {"correct": 0, "total": 0})
		var old: Dictionary = old_value if old_value is Dictionary else {"correct": 0, "total": 0}
		var add: Dictionary = add_value if add_value is Dictionary else {"correct": 0, "total": 0}
		var old_total := maxi(0, int(old.get("total", 0)))
		var old_correct := clampi(int(old.get("correct", 0)), 0, old_total)
		var add_total := maxi(0, int(add.get("total", 0)))
		var add_correct := clampi(int(add.get("correct", 0)), 0, add_total)
		saved[op] = {"correct": old_correct + add_correct, "total": old_total + add_total}
	pupil["operation_stats"] = saved
	pupils[current_pupil_id] = pupil
	data["pupils"] = pupils
	if _write_data(data):
		current_pupil = pupil.duplicate(true)

func has_level_star(level_number: int) -> bool:
	var progress := get_current_progress()
	var results: Dictionary = progress.get("level_results", {})
	var result: Dictionary = results.get("level_%d" % level_number, {})
	return int(result.get("stars", 0)) >= 1

func has_pretest_passed() -> bool:
	var progress := get_current_progress()
	var results: Dictionary = progress.get("level_results", {})
	return int(results.get("pretest", {}).get("stars", 0)) >= 1


func _ready() -> void:
	_load_data()


func _load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"pupils": {}}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not read MathQuest progress file.")
		return {"pupils": {}}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary and parsed.get("pupils", {}) is Dictionary:
		return {"schema_version": 1, "pupils": parsed.get("pupils", {})}
	push_warning("MathQuest progress file is invalid; starting with an empty progress store.")
	return {"schema_version": 1, "pupils": {}}


func _write_data(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write MathQuest progress file.")
		return false

	data["schema_version"] = 1
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func login_teacher(teacher_name: String, teacher_password: String, selected_grade: String) -> bool:
	var key := teacher_name.strip_edges().to_lower()
	if key.is_empty() or teacher_password.is_empty() or selected_grade.is_empty():
		return false
	if not REGISTERED_TEACHERS.has(key):
		return false
	var account: Dictionary = REGISTERED_TEACHERS[key]
	if teacher_password != str(account.get("password", "")) or selected_grade != str(account.get("grade", "")):
		return false
	current_role = "teacher"
	current_teacher = {"username": key, "name": str(account.get("display_name", teacher_name.strip_edges())), "grade": selected_grade}
	current_pupil_id = ""
	current_pupil = {}
	return true


func login_pupil(first_name: String, pupil_password: String, selected_grade: String) -> bool:
	var key := first_name.strip_edges().to_lower()
	if key.is_empty() or pupil_password.is_empty() or selected_grade.is_empty():
		return false
	if not REGISTERED_PUPILS.has(key):
		return false

	var account: Dictionary = REGISTERED_PUPILS[key]
	if pupil_password != str(account.get("password", "")):
		return false
	if selected_grade != str(account.get("grade", "")):
		return false

	current_role = "pupil"
	current_teacher = {}
	current_pupil_id = key
	var data := _load_data()
	var pupils: Dictionary = data.get("pupils", {})

	if not pupils.has(key):
		pupils[key] = {
			"name": first_name.strip_edges(),
			"grade": selected_grade,
			"total_score": 0,
			"total_stars": 0,
			"selected_character": "m_wizard",
			"completed_levels": [],
			"level_results": {},
			"attempt_history": [],
			"operation_stats": _default_operation_stats()
		}
	else:
		# Refresh non-sensitive profile fields without resetting progress.
		pupils[key]["name"] = first_name.strip_edges()
		pupils[key]["grade"] = selected_grade
		if not pupils[key].has("operation_stats") or not (pupils[key]["operation_stats"] is Dictionary):
			pupils[key]["operation_stats"] = _default_operation_stats()
		if not pupils[key].has("level_results") or not (pupils[key]["level_results"] is Dictionary):
			pupils[key]["level_results"] = {}
		if not pupils[key].has("completed_levels") or not (pupils[key]["completed_levels"] is Array):
			pupils[key]["completed_levels"] = []
		if not pupils[key].has("attempt_history") or not (pupils[key]["attempt_history"] is Array):
			pupils[key]["attempt_history"] = []
		# Migrate older saved best-results into the new history view when possible.
		# Older versions stored only one best result and sometimes one last-attempt score.
		var existing_history: Variant = pupils[key]["attempt_history"]
		if existing_history is Array and existing_history.is_empty():
			var legacy_results: Dictionary = pupils[key].get("level_results", {})
			var migrated: Array = []
			for legacy_id in legacy_results.keys():
				var legacy: Dictionary = legacy_results[legacy_id]
				var legacy_stage := str(legacy_id)
				var legacy_mode := "Level"
				if legacy_id == "pretest":
					legacy_stage = "Level 0 - Pre-test"
					legacy_mode = "Pre-test"
				elif legacy_id == "posttest":
					legacy_stage = "Level 0 - Post-test"
					legacy_mode = "Post-test"
				elif str(legacy_id).begins_with("level_"):
					legacy_stage = "Level %s" % str(legacy_id).trim_prefix("level_")
				migrated.append({"level_id": str(legacy_id), "stage": legacy_stage, "mode": legacy_mode, "score": int(legacy.get("score", 0)), "stars": int(legacy.get("stars", 0)), "correct": int(legacy.get("correct", 0)), "wrong": int(legacy.get("wrong", 0)), "duration_seconds": 0.0, "quest_points": 0, "passed": int(legacy.get("stars", 0)) >= 1, "date": str(legacy.get("date", "")), "legacy_record": true})
				if legacy.has("last_attempt_score"):
					migrated.append({"level_id": str(legacy_id), "stage": legacy_stage, "mode": legacy_mode, "score": int(legacy.get("last_attempt_score", 0)), "stars": 0, "correct": int(legacy.get("last_attempt_score", 0)), "wrong": 0, "duration_seconds": 0.0, "quest_points": 0, "passed": false, "date": str(legacy.get("last_attempt_date", "")), "legacy_record": true})
			pupils[key]["attempt_history"] = migrated

	data["pupils"] = pupils
	if not _write_data(data):
		current_pupil_id = ""
		current_pupil = {}
		return false

	current_pupil = pupils[key].duplicate(true)
	selected_character = str(current_pupil.get("selected_character", "m_wizard"))
	if selected_character not in ["m_wizard", "f_wizard", "m_archer", "f_archer", "princess", "warrior"]:
		selected_character = "m_wizard"
	return true


func get_saved_selected_character() -> String:
	if current_pupil_id.is_empty():
		return selected_character if selected_character in ["m_wizard", "f_wizard", "m_archer", "f_archer", "princess", "warrior"] else "m_wizard"
	var pupil := get_current_progress()
	var saved := str(pupil.get("selected_character", selected_character))
	return saved if saved in ["m_wizard", "f_wizard", "m_archer", "f_archer", "princess", "warrior"] else "m_wizard"



func get_unlocked_characters() -> Array[String]:
	var unlocked: Array[String] = ["m_wizard", "f_wizard"]
	var progress := get_current_progress()
	var completed: Array = progress.get("completed_levels", [])
	if completed.has("level_2"):
		unlocked.append("m_archer")
	if completed.has("level_4"):
		unlocked.append("f_archer")
	if completed.has("level_6"):
		unlocked.append("princess")
	if completed.has("level_8"):
		unlocked.append("warrior")
	return unlocked

func save_selected_character(character_id: String) -> bool:
	if character_id not in get_unlocked_characters():
		return false
	selected_character = character_id
	if current_pupil_id.is_empty():
		return true
	var data := _load_data()
	var pupils: Dictionary = data.get("pupils", {})
	if not pupils.has(current_pupil_id):
		return false
	var pupil: Dictionary = pupils[current_pupil_id]
	pupil["selected_character"] = character_id
	pupils[current_pupil_id] = pupil
	data["pupils"] = pupils
	if not _write_data(data):
		return false
	current_pupil = pupil.duplicate(true)
	return true


func save_level_result(level_id: String, score: int, stars: int, correct: int = 0, wrong: int = 0) -> void:
	if current_pupil_id.is_empty():
		push_warning("No pupil is logged in; result was not saved.")
		return

	var data := _load_data()
	var pupils: Dictionary = data.get("pupils", {})
	if not pupils.has(current_pupil_id):
		return

	var pupil: Dictionary = pupils[current_pupil_id]
	var results: Dictionary = pupil.get("level_results", {})
	var old_result: Dictionary = results.get(level_id, {})
	var old_score := int(old_result.get("score", 0))
	var old_stars := int(old_result.get("stars", 0))

	var is_new_best := score > old_score or stars > old_stars
	var result_record := old_result.duplicate(true)
	if is_new_best or old_result.is_empty():
		result_record = {
			"score": maxi(score, old_score),
			"stars": maxi(stars, old_stars),
			"correct": correct,
			"wrong": wrong,
			"date": Time.get_datetime_string_from_system(false, true)
		}
	else:
		result_record["score"] = old_score
		result_record["stars"] = old_stars
		result_record["last_attempt_score"] = score
		result_record["last_attempt_date"] = Time.get_datetime_string_from_system(false, true)
	results[level_id] = result_record
	pupil["level_results"] = results

	# UC-6 / UC-8: preserve every completed attempt, not only the best score.
	# This gives pupils a personal game history and lets the teacher monitor progress over time.
	var history: Array = pupil.get("attempt_history", [])
	var attempt_date := Time.get_datetime_string_from_system(false, true)
	var mode_label := "Level"
	var stage_label := level_id
	if level_id == "pretest":
		mode_label = "Pre-test"
		stage_label = "Level 0 - Pre-test"
	elif level_id == "posttest":
		mode_label = "Post-test"
		stage_label = "Level 0 - Post-test"
	elif level_id.begins_with("level_"):
		stage_label = "Level %s" % level_id.trim_prefix("level_")
	var attempt := {
		"attempt_number": history.size() + 1,
		"level_id": level_id,
		"stage": stage_label,
		"mode": mode_label,
		"score": score,
		"stars": clampi(stars, 0, 3),
		"correct": correct,
		"wrong": wrong,
		"duration_seconds": snappedf(last_elapsed_seconds, 0.1),
		"quest_points": current_attempt_points,
		"passed": stars >= 1,
		"date": attempt_date
	}
	history.append(attempt)
	pupil["attempt_history"] = history
	current_attempt_points = 0

	var completed: Array = pupil.get("completed_levels", [])
	# Only the ten campaign stages count toward level completion. Pre/post-tests
	# remain in level_results for reporting but are not campaign levels.
	if level_id.begins_with("level_") and stars >= 1 and not completed.has(level_id):
		completed.append(level_id)
	pupil["completed_levels"] = completed

	# Keep best score/stars for each level when recalculating totals.
	var total_score := 0
	var total_stars := 0
	for result_value in results.values():
		if result_value is Dictionary:
			total_score += int(result_value.get("score", 0))
			total_stars += int(result_value.get("stars", 0))
	pupil["total_score"] = total_score
	pupil["total_stars"] = total_stars

	pupils[current_pupil_id] = pupil
	data["pupils"] = pupils
	if _write_data(data):
		current_pupil = pupil.duplicate(true)


func get_current_progress() -> Dictionary:
	if current_pupil_id.is_empty():
		return {}
	var data := _load_data()
	var pupils: Dictionary = data.get("pupils", {})
	var record: Dictionary = pupils.get(current_pupil_id, {})
	return record.duplicate(true)


func get_completed_level_count() -> int:
	var progress := get_current_progress()
	var completed: Array = progress.get("completed_levels", [])
	return completed.size()


func get_pupil_record(pupil_id: String) -> Dictionary:
	for record in get_all_pupil_records():
		if str(record.get("id", "")) == pupil_id:
			return record
	return {}


func get_attempt_history(pupil_id: String = "") -> Array:
	var target_id := pupil_id if not pupil_id.is_empty() else current_pupil_id
	if target_id.is_empty():
		return []
	var record := get_pupil_record(target_id)
	var history: Variant = record.get("attempt_history", [])
	return history.duplicate(true) if history is Array else []


func get_all_pupil_records() -> Array:
	# Return every registered pupil so teachers can select the whole class,
	# including pupils who have not played yet. Empty profiles are display-only
	# and are not written to the save file or given fabricated results.
	var data := _load_data()
	var pupils: Dictionary = data.get("pupils", {})
	var records: Array = []
	for pupil_id in REGISTERED_PUPILS.keys():
		var account: Dictionary = REGISTERED_PUPILS[pupil_id]
		var record: Dictionary
		if pupils.has(pupil_id) and pupils[pupil_id] is Dictionary:
			record = pupils[pupil_id].duplicate(true)
		else:
			record = {
				"name": str(pupil_id).capitalize(),
				"grade": str(account.get("grade", "")),
				"total_score": 0,
				"total_stars": 0,
				"completed_levels": [],
				"level_results": {},
				"attempt_history": [],
				"operation_stats": _default_operation_stats()
			}
		record["id"] = pupil_id
		records.append(record)
	return records


func logout() -> void:
	current_role = "pupil"
	current_teacher = {}
	current_pupil_id = ""
	current_pupil = {}
	current_level = 0
	current_score = 0
	current_stars = 0
	quiz_correct = 0
	quiz_wrong = 0
	current_quiz_mode = "level"
	last_quiz_score = 0
	last_quiz_stars = 0
	level_start_ticks = 0
	last_elapsed_seconds = 0.0
	current_attempt_points = 0
	selected_student_id = ""


# Hidden timer for the current level attempt.
var level_start_ticks: int = 0
var last_elapsed_seconds: float = 0.0
var current_attempt_points: int = 0


func start_level_timer() -> void:
	level_start_ticks = Time.get_ticks_msec()
	last_elapsed_seconds = 0.0
	current_attempt_points = 0


func finish_level_timer() -> float:
	if level_start_ticks > 0:
		last_elapsed_seconds = (
			Time.get_ticks_msec() - level_start_ticks
		) / 1000.0

		level_start_ticks = 0

	return last_elapsed_seconds


func get_last_elapsed_text() -> String:
	var total_seconds: int = int(last_elapsed_seconds)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, seconds]


func add_collection_points(points: int, level_number: int) -> void:
	if points <= 0 or current_pupil_id.is_empty():
		return
	var data := _load_data()
	var pupils: Dictionary = data.get("pupils", {})
	if not pupils.has(current_pupil_id):
		return
	var pupil: Dictionary = pupils[current_pupil_id]
	pupil["total_points"] = int(pupil.get("total_points", 0)) + points
	current_attempt_points += points
	var level_points: Dictionary = pupil.get("level_points", {})
	var key := "level_%d" % level_number
	level_points[key] = int(level_points.get(key, 0)) + points
	pupil["level_points"] = level_points
	pupils[current_pupil_id] = pupil
	data["pupils"] = pupils
	if _write_data(data):
		current_pupil = pupil.duplicate(true)
