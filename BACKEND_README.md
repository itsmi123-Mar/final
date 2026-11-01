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

## Classroom accounts

The 10 supplied pupils (five Grade 3 and five Grade 4) are registered in
`script/data/player_data.gd`. Pupils sign in with their full registered name,
assigned grade, and LRN as the password. Teacher accounts:

| Teacher | Grade | Password |
|---|---|---|
| Sheryl G. Ancheta | Grade 3 | `Sheryl1` |
| Jim Cesar Baylon | Grade 4 | `Jim1` |

LRNs are confidential education records. Keep this project and its embedded
credentials restricted to authorized classroom use. This local prototype is
not secure production authentication; a deployed system should use a trusted
HTTPS service and avoid embedding pupil identifiers or passwords in the client.

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
- The teacher dashboard lists all registered pupils in the teacher’s assigned grade, including pupils who have not played yet. A pupil without saved gameplay data is shown with zero totals and an explicit empty-history message; no scores are fabricated or written for that pupil.
- UC-8 Monitor Performance: selecting a pupil opens a responsive, scrollable performance view with total score, total stars, completed levels, number of saved attempts, Pre-test/Post-test scores and change (when both tests exist), and the full attempt history newest-first.
- UC-7 Generate Records: the teacher can generate a pupil CSV from the pupil performance view or a grade-wide CSV from the dashboard. Each CSV includes a summary row for each pupil and separate rows for each saved attempt, including date, stage, mode, score, correct/wrong answers, stars, duration, quest points, and pass/retry status.
- CSV downloads use Godot's native Save File dialog so the teacher can choose a destination and filename. The app reports the selected path after a successful write. If no performance data exists, the summary is still available and the attempt section remains empty rather than inventing results.
- Existing save files are migrated from their older best-result records when a pupil next logs in. Older records cannot recover retry details or timings that were never stored; those fields are marked as unavailable/zero in migrated entries.

This is local-device persistence. To share records across multiple devices, the project would need a hosted database or server, which is not included in this offline Godot build.
