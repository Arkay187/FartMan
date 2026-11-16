# Fart Man

A silly 2.5D platformer for a 6 year old and his dad. Fun and readable beat clever.

## Engine
- Godot 4.x, GDScript only. No C#.
- 3D low-poly art on a 2D gameplay plane (2.5D). Gameplay locked to X and Y, Z fixed.
- Use CharacterBody3D for the player. Use typed GDScript.
- Grey boxes first. No art until the game feels fun.

## Rules
- Keep scripts small, one job each, with short comments a parent could read.
- Put every tunable (charge time, jump heights, gas cost) in @export variables so we can tweak them in the editor.
- Never edit .tscn files by hand unless I ask. Create scripts and tell me which nodes to add.
- Scripts in res://scripts, scenes in res://scenes, art in res://art, sounds in res://audio.
- Update SESSION_NOTES.md at the end of each session: decisions made, files created, what to do next.
- Commit finished, tested work and push it to GitHub (origin main) automatically. No need to ask first.

## How scenes get made and tested (for Claude)
- Scenes are not hand-edited. `tools/build_scenes.gd` builds every .tscn with the engine itself.
  To add or change a scene, edit that script and rebuild. It overwrites the scenes, so first
  check `git status scenes` is clean in case Rich changed one in the editor.
- `pwsh tools/run_tests.ps1 -Build` rebuilds all scenes and runs every headless play-test in
  `tools/tests`. Each test fakes key presses and prints what happened. Add a test for each
  new feature, and keep the old ones passing.
- Tests can't see the screen. Always say plainly what was not checked by eye.
- Rich usually has the Godot editor open. Never close or kill it; only headless runs are ours.
- Git is at `C:\Program Files\Git\cmd` and may not be on PATH in a fresh shell.

## Core mechanic
- Two buttons. JUMP (Space / pad A): instant free Toot hop, ground only. FART (F or Z / pad X or B): hold to charge, release to launch. Fart also works in the air as a timed double jump.
- Three jumps: Toot (jump button), Trump (fart, partly full), Thunder (fart, belly full, big). A fart tap too short does nothing (fizzles).
- Holding fart grows his belly (a proxy model for now). Letting go hides it and launches.
- Jump size = how full the belly is at the moment of release. The fun is timing the release.
- Holding too long lets out a long squeaky fart: the belly slowly deflates and gas leaks away.
  It must never loop or fail while held; releasing jumps with whatever belly is left (empty belly or no gas = a harmless fizzle).
- He does not slow down while charging. The game should feel fast.
- Gas tank drains per fart, refills from bean pickups. Tap jumps are free.

## Planned scope
- The approved design is in GAME_DESIGN.md. Read it before adding features and follow its build order.
- 3 worlds (Grandma's Garden, Bean Factory, Planet Whiff), each 2 running stages, 1 flight stage and a boss.
- Bosses: Sneezy Weezy, Colonel Cork, Big Bad Burp. No low gravity anywhere.
- Story is told with speech bubbles, short puppet-show scenes and storybook pages. Very few words.
