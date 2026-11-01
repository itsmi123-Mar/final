# MathQuest login + JSON persistence starter

This project is based on the uploaded MathQuest UI/UX project. Existing art and scene layouts are retained.

## Test login accounts
These are fictional examples in `script/data/player_data.gd`:
- Name: `ana`, Grade: `Grade 3`, Password: `Test123`
- Name: `ben`, Grade: `Grade 4`, Password: `Test456`

The name check ignores capitalization and surrounding spaces. Grade must match the registered account, and the password must match exactly. Replace the sample accounts locally with approved test accounts. Do not share a project ZIP containing real pupil passwords or learner identifiers.

## What was attached
- `script/data/player_data.gd`: Autoload named `PlayerData`; validates the sample accounts and stores pupil progress.
- `script/login.gd`: attached to `scene/login.tscn`; validates fields, shows the existing error label, then changes to the main menu after successful login.
- `script/main_menu.gd`: attached to `scene/main_menu.tscn`; Play opens character selection, Scoreboard opens the scoreboard, Logout returns to login.
- `script/scoreboard.gd`: attached to `scene/scoreboard.tscn`; displays the logged-in pupil's saved summary and per-level results.

The project starts at `res://scene/login.tscn`, and `PlayerData` is registered in Project Settings > Autoload.

## JSON save location
The file is created at `user://mathquest_progress.json` after a successful login. In Godot, use Project > Open User Data Folder to inspect it. It stores pupil profile/progress, not passwords.

## Important
- The existing gameplay scene does not yet have a complete question/answer system. To save a level result from gameplay code, call:
  `PlayerData.save_level_result("Level 1", score, stars, correct_count, wrong_count)`
- This is local-only storage. Progress does not synchronize between computers.
- Passwords embedded in a local game are suitable only for a prototype; they are not secure authentication.
- I could not launch the Godot editor in this environment, so open the project in Godot 4.7 and check the Debugger panel. If a scene's actual node names have changed locally, adjust the paths in the attached script.
