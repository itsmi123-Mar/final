# MathQuest Backend Additions

This update preserves the original Godot project assets, scenes, and existing gameplay files, and adds backend behavior.

## USD workflow implemented
- Pupil and teacher authentication from the existing login screen.
- Pupil progress stored locally in `user://mathquest_progress.json`.
- Saved avatar selection and level-based avatar unlocks:
  - Wizard characters: available initially.
  - Male Archer: after passing Level 2.
  - Female Archer: after passing Level 4.
  - Princess: after passing Level 6.
  - Warrior: after passing Level 8.
- Pre-test must be passed before Level 1 unlocks.
- Levels 1–10 unlock in order after passing the previous level.
- Tutorials are shown at the beginning of each five-level set (Levels 1 and 6).
- Level results, operation statistics, scores, stars, completion dates, and retries are saved.
- Post-test unlocks after Level 10 is passed; pre-test and post-test scores are compared.
- Pupil scoreboard reads the saved progress.
- Teacher dashboard filters pupils by the teacher's assigned grade.
- Teacher can monitor a pupil's test/level results and generate CSV records for one pupil or the whole grade.

## Teacher demo accounts
| Teacher | Grade | Password |
|---|---|---|
| Sheryl G. Ancheta | Grade 3 | `Sheryl1` |
| Jim Cesar Baylon | Grade 4 | `Jim1` |

## Pupil accounts
The existing `REGISTERED_PUPILS` demo accounts in `script/data/player_data.gd` were preserved. Replace those entries with the approved pupil roster and actual LRN/password values when provided. The uploaded project did not contain a complete LRN roster, so no LRN values were invented.

## Data and export
- Local save: `user://mathquest_progress.json` (Godot user data folder).
- CSV reports: teacher selects a destination using the operating system save dialog.
- Data is stored on the computer running the game; this is a local/offline backend, not a shared online database.

## Run
Open `project.godot` in Godot 4.x and run the project. Teacher login uses the accounts above. Pupils continue to use the existing account definitions.
