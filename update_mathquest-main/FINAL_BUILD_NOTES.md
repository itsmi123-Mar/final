# MathQuest Final Build Notes

## Teacher demo account
- Teacher name / username: `Osh` (login is case-insensitive)
- Password: `1`
- Grade: `Grade 3`

## Student demo accounts
- `sophia` / `sophia1` / Grade 3
- `liam` / `liam2` / Grade 3
- `jevon` / `jevon4` / Grade 4
- `princess` / `princess4` / Grade 4

## Game flow
- Level 0 is used for both the pre-test and post-test. The saved result keys are separate (`pretest` and `posttest`).
- Passing the pre-test unlocks Level 1.
- Levels 1–10 are the campaign.
- Completing Level 10 unlocks the post-test.
- Campaign battles contain 10 questions. 7–9 correct answers trigger the combo finisher; 10 correct answers trigger the perfect finisher.
- After the quiz battle, the player moves the avatar with keyboard arrows / A-D or the on-screen left/right buttons and collects five crystals. Moving right to the far-right trail exit reveals Continue to Next Level (enabled after all five crystals are collected) and Exit Game.
- Campaign star thresholds: 7 correct = 1 star, 8–9 = 2 stars, 10 = 3 stars.
- Pre/post-test star thresholds: 10–14 correct = 1 star, 15–17 = 2 stars, 18–20 = 3 stars.

## Save data
Progress is stored locally in `user://mathquest_progress.json` on the device running the game.

## Run
Open `project.godot` with Godot 4.7. The project uses Godot 4.x scene and script formats.

## Verification note
Resource path references were statically checked and the output ZIP archive was integrity-tested. This build environment did not have the Godot executable, so a live engine launch / gameplay test could not be performed here. Run the project in Godot 4.7 and check the Debugger for any platform-specific import or runtime warnings.
