# MathQuest Final Build Notes

## Classroom accounts

Teacher sign-in uses the teacher's full name, assigned grade, and password:
- Sheryl G. Ancheta — Grade 3 — `Sheryl1`
- Jim Cesar Baylon — Grade 4 — `Jim1`

Pupil sign-in uses the pupil's full registered name, correct grade, and LRN as the password. The 10 supplied pupils are registered in `script/data/player_data.gd` (5 Grade 3 and 5 Grade 4). Treat LRNs as confidential education records; do not distribute credentials publicly.

## Game flow
- Level 0 is used for both the pre-test and post-test. The saved result keys are separate (`pretest` and `posttest`).
- Passing the pre-test unlocks Level 1.
- Levels 1–10 are the campaign.
- Completing Level 10 unlocks the post-test.
- Campaign battles contain 10 questions. 7–9 correct answers trigger the combo finisher; 10 correct answers trigger the perfect finisher.
- After the quiz battle, the player moves the avatar with keyboard arrows / A-D or the on-screen left/right buttons and collects five crystals. Moving right to the far-right trail exit reveals Continue to Next Level (enabled after all five crystals are collected) and Exit Game.
- Campaign star thresholds: 7 correct = 1 star, 8 correct = 2 stars, 9–10 correct = 3 stars.
- Pre/post-test star thresholds: 10–14 correct = 1 star, 15–17 = 2 stars, 18–20 = 3 stars.

## Teacher dashboard
The dashboard filters pupils by the logged-in teacher's assigned grade, displays the matching grade and pupil count, opens individual performance history, and exports a class CSV report.

## Save data
Progress is stored locally in `user://mathquest_progress.json` on the device running the game. It is not synchronized across devices.

## Run
Open `project.godot` with Godot 4.7. The project uses Godot 4.x scene and script formats.

## Verification note
All scene/script resource path references were statically checked and the output ZIP archive was integrity-tested. This environment did not have the Godot executable, so a live engine launch / gameplay test could not be performed here. Run the project in Godot 4.7 and check the Debugger for any platform-specific import or runtime warnings.
