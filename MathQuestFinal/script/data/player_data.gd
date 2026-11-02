
extends Node

const SAVE_PATH: String = "user://mathquest_progress.json"

# ==========================================
# REGISTERED PUPIL ACCOUNTS
# LRN is the pupil password.
# ==========================================

const REGISTERED_PUPILS: Dictionary = {
	# GRADE 4
	"100085220007": {
		"name": "Jacchaeus James P. Agustin",
		"password": "100085220007",
		"grade": "Grade 4"
	},
	"100085220008": {
		"name": "Jevon Wayne Q. Quemquem",
		"password": "100085220008",
		"grade": "Grade 4"
	},
	"100085220013": {
		"name": "Avi Kristine A. Coloma",
		"password": "100085220013",
		"grade": "Grade 4"
	},
	"100085220022": {
		"name": "Angela Marie B. Layaoen",
		"password": "100085220022",
		"grade": "Grade 4"
	},
	"100085220014": {
		"name": "Princess Xia C. Moral",
		"password": "100085220014",
		"grade": "Grade 4"
	},

	# GRADE 3
	"107886230108": {
		"name": "Sophia Faith B. Apin",
		"password": "107886230108",
		"grade": "Grade 3"
	},
	"100085230015": {
		"name": "Ma. Bella Christe G. Gudoy",
		"password": "100085230015",
		"grade": "Grade 3"
	},
	"100085230020": {
		"name": "Deib Lohr C. Pugat",
		"password": "100085230020",
		"grade": "Grade 3"
	},
	"100085230002": {
		"name": "Macc Khenzie G. Cudiamat",
		"password": "100085230002",
		"grade": "Grade 3"
	},
	"100085230011": {
		"name": "Liam Jaeden D. Tapec",
		"password": "100085230011",
		"grade": "Grade 3"
	}
}


# ==========================================
# TEACHER ACCOUNTS
# ==========================================

const TEACHER_ACCOUNTS: Dictionary = {
	"sheryl g. ancheta": {
		"name": "Sheryl G. Ancheta",
		"password": "Sheryl1",
		"grade": "Grade 3"
	},
	"jim cesar baylon": {
		"name": "Jim Cesar Baylon",
		"password": "Jim1",
		"grade": "Grade 4"
	}
}


# ==========================================
# USER SESSION VARIABLES
# ==========================================

var current_user_role: String = ""
var current_user_name: String = ""
var current_user_grade: String = ""
var current_user_id: String = ""

var current_teacher: Dictionary = {}
var selected_teacher_pupil_id: String = ""

var current_pupil_id: String = ""
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

var level_start_ticks: int = 0
var last_elapsed_seconds: float = 0.0


# ==========================================
# INITIALIZATION
# ==========================================

func _ready() -> void:
	_load_data()


# ==========================================
# DATA STORAGE
# ==========================================

func _load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"pupils": {}}

	var file: FileAccess = FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		push_warning("Could not read MathQuest progress file.")
		return {"pupils": {}}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary:
		var result: Dictionary = parsed
		var pupils_value: Variant = result.get("pupils", {})

		if pupils_value is Dictionary:
			return result

	return {"pupils": {}}


func _write_data(data: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error("Could not write MathQuest progress file.")
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	return true


# ==========================================
# TEACHER LOGIN
# ==========================================

func login_teacher(
	teacher_name: String,
	teacher_password: String,
	selected_grade: String
) -> bool:

	var key: String = teacher_name.strip_edges().to_lower()

	if not TEACHER_ACCOUNTS.has(key):
		return false

	var account: Dictionary = TEACHER_ACCOUNTS[key]

	if teacher_password.strip_edges() != str(account.get("password", "")):
		return false

	if selected_grade.strip_edges() != str(account.get("grade", "")):
		return false

	current_user_role = "teacher"
	current_user_name = str(account.get("name", ""))
	current_user_grade = str(account.get("grade", ""))
	current_user_id = key

	current_teacher = {
		"name": current_user_name,
		"grade": current_user_grade
	}

	current_pupil_id = ""
	current_pupil = {}
	selected_teacher_pupil_id = ""

	return true


# ==========================================
# PUPIL LOGIN
# Accepts FULL NAME or LRN as username.
# Password must be the registered LRN.
# ==========================================

func login_pupil(
	pupil_name_or_lrn: String,
	pupil_password: String,
	selected_grade: String
) -> bool:

	var entered: String = pupil_name_or_lrn.strip_edges()
	var password: String = pupil_password.strip_edges()
	var grade: String = selected_grade.strip_edges()

	if entered.is_empty() or password.is_empty() or grade.is_empty():
		return false

	var key: String = ""

	# Accept LRN directly.
	if REGISTERED_PUPILS.has(entered):
		key = entered

	else:
		# Find pupil using full name.
		for lrn_value: Variant in REGISTERED_PUPILS.keys():
			var lrn: String = str(lrn_value)
			var account: Dictionary = REGISTERED_PUPILS[lrn]

			var registered_name: String = str(
				account.get("name", "")
			)

			if registered_name.strip_edges().to_lower() == entered.to_lower():
				key = lrn
				break

	if key.is_empty():
		return false

	var pupil: Dictionary = REGISTERED_PUPILS[key]

	if password != str(pupil.get("password", "")):
		return false

	if grade != str(pupil.get("grade", "")):
		return false

	current_pupil_id = key
	current_user_id = key
	current_user_role = "pupil"

	current_user_name = str(pupil.get("name", ""))
	current_user_grade = str(pupil.get("grade", ""))

	current_teacher = {}
	selected_teacher_pupil_id = ""

	# Load or create pupil progress.
	var data: Dictionary = _load_data()
	var pupils: Dictionary = data.get("pupils", {})

	if not pupils.has(key):
		pupils[key] = {
			"name": current_user_name,
			"grade": current_user_grade,
			"total_score": 0,
			"total_stars": 0,
			"selected_character": "m_wizard",
			"completed_levels": [],
			"level_results": {},
			"operation_stats": {}
		}

	else:
		var existing: Dictionary = pupils[key]

		existing["name"] = current_user_name
		existing["grade"] = current_user_grade

		pupils[key] = existing

	data["pupils"] = pupils

	if not _write_data(data):
		logout()
		return false

	var saved_pupil: Dictionary = pupils[key]

	current_pupil = saved_pupil.duplicate(true)

	selected_character = str(
		current_pupil.get("selected_character", "m_wizard")
	)

	if not is_character_unlocked(selected_character):
		selected_character = "m_wizard"

	return true


# ==========================================
# AVATAR UNLOCKING
# ==========================================

func is_character_unlocked(character_id: String) -> bool:

	if character_id in ["m_wizard", "f_wizard"]:
		return true

	var unlock_levels: Dictionary = {
		"m_archer": 2,
		"f_archer": 4,
		"princess": 6,
		"warrior": 8
	}

	var required_level: int = int(
		unlock_levels.get(character_id, 999)
	)

	if required_level == 999:
		return false

	for level_number: int in range(1, required_level + 1):
		if not has_level_star(level_number):
			return false

	return true


func get_unlocked_characters() -> Array:
	var result: Array = []

	var characters: Array = [
		"m_wizard",
		"f_wizard",
		"m_archer",
		"f_archer",
		"princess",
		"warrior"
	]

	for character_id: String in characters:
		if is_character_unlocked(character_id):
			result.append(character_id)

	return result


func get_saved_selected_character() -> String:

	if current_pupil_id.is_empty():
		if is_character_unlocked(selected_character):
			return selected_character

		return "m_wizard"

	var pupil: Dictionary = get_current_progress()

	var saved: String = str(
		pupil.get("selected_character", "m_wizard")
	)

	if is_character_unlocked(saved):
		return saved

	return "m_wizard"


func save_selected_character(character_id: String) -> bool:

	if not is_character_unlocked(character_id):
		return false

	selected_character = character_id

	if current_pupil_id.is_empty():
		return true

	var data: Dictionary = _load_data()
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


# ==========================================
# LEVEL RESULTS
# ==========================================

func save_level_result(
	level_id: String,
	score: int,
	stars: int,
	correct: int = 0,
	wrong: int = 0
) -> void:

	if current_pupil_id.is_empty():
		push_warning("No pupil is logged in.")
		return

	var data: Dictionary = _load_data()
	var pupils: Dictionary = data.get("pupils", {})

	if not pupils.has(current_pupil_id):
		return

	var pupil: Dictionary = pupils[current_pupil_id]

	var results: Dictionary = pupil.get("level_results", {})
	var old_result: Dictionary = results.get(level_id, {})

	var old_score: int = int(old_result.get("score", 0))
	var old_stars: int = int(old_result.get("stars", 0))

	results[level_id] = {
		"score": maxi(score, old_score),
		"stars": maxi(stars, old_stars),
		"correct": correct,
		"wrong": wrong,
		"date": Time.get_datetime_string_from_system(false, true)
	}

	pupil["level_results"] = results

	var completed: Array = pupil.get("completed_levels", [])

	if stars >= 1 and not completed.has(level_id):
		completed.append(level_id)

	pupil["completed_levels"] = completed

	# Calculate overall score and stars.
	var total_score: int = 0
	var total_stars: int = 0

	for result_value: Variant in results.values():
		if result_value is Dictionary:
			var result: Dictionary = result_value

			total_score += int(result.get("score", 0))
			total_stars += int(result.get("stars", 0))

	pupil["total_score"] = total_score
	pupil["total_stars"] = total_stars

	pupils[current_pupil_id] = pupil
	data["pupils"] = pupils

	if _write_data(data):
		current_pupil = pupil.duplicate(true)


# ==========================================
# LEVEL COMPLETION CHECKS
# ==========================================

func has_level_star(level_number: int) -> bool:

	var progress: Dictionary = get_current_progress()

	var results: Dictionary = progress.get("level_results", {})

	var result: Dictionary = results.get(
		"level_%d" % level_number,
		{}
	)

	return int(result.get("stars", 0)) >= 1


# ==========================================
# LEVEL 1 UNLOCK REQUIREMENT
# Pre-test must be completed.
# Score requirement: NONE (0/20 to 20/20).
# ==========================================

func has_pretest_passed() -> bool:

	var progress: Dictionary = get_current_progress()

	var results: Dictionary = progress.get("level_results", {})

	var pretest: Dictionary = results.get("pretest", {})

	return not pretest.is_empty()


# ==========================================
# CURRENT PUPIL PROGRESS
# ==========================================

func get_current_progress() -> Dictionary:

	if current_pupil_id.is_empty():
		return {}

	var data: Dictionary = _load_data()

	var pupils: Dictionary = data.get("pupils", {})

	var record: Dictionary = pupils.get(
		current_pupil_id,
		{}
	)

	return record.duplicate(true)


func get_all_pupil_records() -> Array:

	var data: Dictionary = _load_data()

	var pupils: Dictionary = data.get("pupils", {})

	var records: Array = []

	for pupil_id: Variant in pupils.keys():
		var record: Dictionary = pupils[pupil_id].duplicate(true)

		record["id"] = str(pupil_id)

		records.append(record)

	return records


# ==========================================
# TEACHER GRADE
# ==========================================

func get_teacher_grade() -> String:

	if not current_teacher.is_empty():
		return str(current_teacher.get("grade", ""))

	return current_user_grade


# ==========================================
# TEACHER PUPIL MONITORING
# Only pupils in the teacher's grade.
# Includes pupils who have not played yet.
# ==========================================

func get_teacher_pupil_records() -> Array:

	var records: Array = []

	if current_user_role != "teacher":
		return records

	var teacher_grade: String = get_teacher_grade()

	if teacher_grade.is_empty():
		return records

	var data: Dictionary = _load_data()

	var saved_pupils: Dictionary = data.get("pupils", {})

	for lrn_value: Variant in REGISTERED_PUPILS.keys():

		var lrn: String = str(lrn_value)

		var account: Dictionary = REGISTERED_PUPILS[lrn]

		if str(account.get("grade", "")) != teacher_grade:
			continue

		var record: Dictionary = {
			"id": lrn,
			"name": str(account.get("name", "")),
			"grade": teacher_grade,
			"total_score": 0,
			"total_stars": 0,
			"completed_levels": [],
			"level_results": {},
			"operation_stats": {}
		}

		if saved_pupils.has(lrn):
			var saved_value: Variant = saved_pupils[lrn]

			if saved_value is Dictionary:
				var saved_record: Dictionary = saved_value

				for field: Variant in saved_record.keys():
					record[str(field)] = saved_record[field]

		# Always preserve the registered identity.
		record["id"] = lrn
		record["name"] = str(account.get("name", ""))
		record["grade"] = teacher_grade

		records.append(record)

	return records


# ==========================================
# INDIVIDUAL PUPIL REPORT
# ==========================================

func get_pupil_report(lrn: String) -> Dictionary:

	lrn = lrn.strip_edges()

	if current_user_role != "teacher":
		return {}

	if not REGISTERED_PUPILS.has(lrn):
		return {}

	var account: Dictionary = REGISTERED_PUPILS[lrn]

	if str(account.get("grade", "")) != get_teacher_grade():
		return {}

	var record: Dictionary = get_pupil_record_by_id(lrn)

	if record.is_empty():
		record = {
			"id": lrn,
			"name": str(account.get("name", "")),
			"grade": str(account.get("grade", "")),
			"total_score": 0,
			"total_stars": 0,
			"completed_levels": [],
			"level_results": {},
			"operation_stats": {}
		}

	var completed: Array = record.get("completed_levels", [])

	var results: Dictionary = record.get("level_results", {})

	var pretest: Dictionary = results.get("pretest", {})
	var posttest: Dictionary = results.get("posttest", {})

	var progress: Dictionary = record.duplicate(true)

	progress["pretest_score"] = int(pretest.get("score", 0))
	progress["posttest_score"] = int(posttest.get("score", 0))
	progress["completed_levels"] = completed.size()

	return {
		"learner": str(account.get("name", "")),
		"name": str(account.get("name", "")),
		"lrn": lrn,
		"grade": str(account.get("grade", "")),
		"progress": progress
	}


# ==========================================
# GET PUPIL RECORD BY LRN
# ==========================================

func get_pupil_record_by_id(pupil_id: String) -> Dictionary:

	for record_value: Variant in get_all_pupil_records():

		if not record_value is Dictionary:
			continue

		var record: Dictionary = record_value

		if str(record.get("id", "")) == pupil_id:
			return record.duplicate(true)

	return {}


# ==========================================
# PRE-TEST AND POST-TEST COMPARISON
# ==========================================

func get_pre_post_comparison(record: Dictionary) -> Dictionary:

	var results: Dictionary = record.get("level_results", {})

	var pre: Dictionary = results.get("pretest", {})
	var post: Dictionary = results.get("posttest", {})

	var pre_score: int = int(pre.get("score", 0))
	var post_score: int = int(post.get("score", 0))

	return {
		"pretest_score": pre_score,
		"posttest_score": post_score,
		"improvement": post_score - pre_score,
		"has_both": not pre.is_empty() and not post.is_empty()
	}


# ==========================================
# GENERATE INDIVIDUAL CSV RECORD
# ==========================================

func build_record_csv(record: Dictionary) -> String:

	var lines: Array[String] = []

	lines.append("MATHQUEST PUPIL PERFORMANCE RECORD")

	lines.append(
		"Name,LRN,Grade,Total Score,Total Stars,Completed Levels"
	)

	var completed: Array = record.get("completed_levels", [])

	lines.append(
		"%s,%s,%s,%s,%s,%s" % [
			_csv(str(record.get("name", ""))),
			_csv(str(record.get("id", ""))),
			_csv(str(record.get("grade", ""))),
			str(record.get("total_score", 0)),
			str(record.get("total_stars", 0)),
			str(completed.size())
		]
	)

	lines.append("")

	lines.append(
		"Assessment/Level,Score,Stars,Correct,Wrong,Date"
	)

	var results: Dictionary = record.get("level_results", {})

	var ids: Array = results.keys()

	ids.sort()

	for result_id: Variant in ids:

		var item: Dictionary = results[result_id]

		lines.append(
			"%s,%s,%s,%s,%s,%s" % [
				_csv(str(result_id)),
				str(item.get("score", 0)),
				str(item.get("stars", 0)),
				str(item.get("correct", 0)),
				str(item.get("wrong", 0)),
				_csv(str(item.get("date", "")))
			]
		)

	var comparison: Dictionary = get_pre_post_comparison(record)

	lines.append("")
	lines.append("Pre-test Score,Post-test Score,Improvement")

	lines.append(
		"%d,%d,%d" % [
			int(comparison.get("pretest_score", 0)),
			int(comparison.get("posttest_score", 0)),
			int(comparison.get("improvement", 0))
		]
	)

	return "\n".join(lines)


func _csv(value: String) -> String:

	return "\"" + value.replace("\"", "\"\"") + "\""


# ==========================================
# OPERATION STATISTICS
# ==========================================

func get_operation_stats() -> Dictionary:

	var progress: Dictionary = get_current_progress()

	var stats: Dictionary = progress.get(
		"operation_stats",
		{}
	)

	return stats.duplicate(true)


func save_operation_stats(stats: Dictionary) -> void:

	if current_pupil_id.is_empty():
		return

	var data: Dictionary = _load_data()

	var pupils: Dictionary = data.get("pupils", {})

	if not pupils.has(current_pupil_id):
		return

	var pupil: Dictionary = pupils[current_pupil_id]

	var saved: Dictionary = pupil.get("operation_stats", {})

	for op_value: Variant in stats.keys():

		var op: String = str(op_value)

		var old_value: Variant = saved.get(
			op,
			{"correct": 0, "total": 0}
		)

		var add_value: Variant = stats[op]

		if not old_value is Dictionary:
			continue

		if not add_value is Dictionary:
			continue

		var old: Dictionary = old_value
		var add: Dictionary = add_value

		saved[op] = {
			"correct": int(old.get("correct", 0)) + int(add.get("correct", 0)),
			"total": int(old.get("total", 0)) + int(add.get("total", 0))
		}

	pupil["operation_stats"] = saved

	pupils[current_pupil_id] = pupil
	data["pupils"] = pupils

	if _write_data(data):
		current_pupil = pupil.duplicate(true)


# ==========================================
# LOGOUT
# ==========================================

func logout() -> void:

	current_pupil_id = ""
	current_pupil = {}

	current_user_role = ""
	current_user_name = ""
	current_user_grade = ""
	current_user_id = ""

	current_teacher = {}
	selected_teacher_pupil_id = ""

	current_level = 0
	current_score = 0
	current_stars = 0

	quiz_correct = 0
	quiz_wrong = 0

	operation_stats = {}

	current_quiz_mode = "level"

	last_quiz_score = 0
	last_quiz_stars = 0

	selected_character = "m_wizard"

	level_start_ticks = 0
	last_elapsed_seconds = 0.0


# ==========================================
# LEVEL TIMER
# ==========================================

func start_level_timer() -> void:

	level_start_ticks = Time.get_ticks_msec()

	last_elapsed_seconds = 0.0


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


# ==========================================
# REGISTERED PUPIL COUNT
# ==========================================

func get_registered_pupil_count() -> int:

	return get_teacher_pupil_records().size()


func is_registered_pupil(lrn: String) -> bool:

	return REGISTERED_PUPILS.has(lrn.strip_edges())
