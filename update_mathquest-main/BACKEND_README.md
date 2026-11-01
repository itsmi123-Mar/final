# MathQuest backend (Godot)

## Current architecture

MathQuest currently uses a local, offline backend implemented as the `PlayerData`
autoload (`script/data/player_data.gd`). It persists data in
`user://mathquest_progress.json`; this keeps save data out of the exported game
folder and gives each device/user profile its own save location.

### Implemented services

- Demo pupil authentication with name, password, and grade validation.
- Per-pupil profile and selected-character persistence.
- Level, pre-test, and post-test result history.
- Best score/star retention per activity, plus last-attempt score/date.
- Cumulative correct/total statistics for addition, subtraction,
  multiplication, division, and mixed questions.
- Adaptive question selection based on the weakest operation.
- Campaign unlock checks (pre-test -> levels 1-10 -> post-test).
- Total score, total stars, and completed campaign-level reporting.
- Attempt timing shown on the results screen.
- Defensive handling for missing/invalid save data and older save records.

## Demo accounts

These are local demonstration credentials in `PlayerData.REGISTERED_PUPILS`:

| Name | Password | Grade |
|---|---|---|
| sophia | sophia1 | Grade 3 |
| liam | liam2 | Grade 3 |
| jevon | jevon4 | Grade 4 |
| princess | princess4 | Grade 4 |

They are not production credentials. Do not ship real pupil passwords in a
Godot client. For a deployed classroom system, replace local authentication
with a trusted HTTPS service and store only server-issued session tokens in
Godot. Password hashing, account provisioning, teacher authorization, backups,
and multi-device synchronization belong on that server.

## Save format

The JSON root contains `schema_version` and a `pupils` dictionary. Each pupil
record stores profile fields, selected character, level results, completed
campaign levels, aggregate score/stars, and operation statistics. The save
file can be reset for local testing by deleting `user://mathquest_progress.json`
from the running game's user-data directory.

## Godot setup

`project.godot` registers `PlayerData` as an autoload. Keep this entry enabled:

```ini
[autoload]
PlayerData="*res://script/data/player_data.gd"
```

Open the `update_mathquest-main` folder in Godot 4.7 (or a compatible Godot 4.x
release) and run the project. The entry scene is `scene/login.tscn`.

## Game attempt history and performance records (USC use cases UC-6, UC-7, UC-8)

- Every completed Pre-test, Post-test, and Level 1-10 attempt is appended to each pupil's `attempt_history` in `user://mathquest_progress.json`.
- Each attempt stores date/time, stage, score, correct and wrong answers, stars, elapsed time, collected quest points, and pass/retry status. Replaying a level creates another history entry; the best level result remains separately available for progression and summary totals.
- Pupils can open View Performance / Scoreboard to review their recorded game attempts.
- The teacher can select a pupil from the Grade 3 dashboard to monitor that pupil's full attempt history, completed levels, overall totals, and Pre-test/Post-test score change.
- The teacher can generate a pupil CSV record from the pupil detail screen or a Grade 3 class CSV report from the dashboard. Files are written to `user://reports/` (the exact OS path is shown after generation).
- Existing save files are migrated from their older best-result records when a pupil next logs in. Older records cannot recover retry details or timings that were never stored; those fields are marked as unavailable/zero in migrated entries.

This is local-device persistence. To share records across multiple devices, the project would need a hosted database or server, which is not included in this offline Godot build.
