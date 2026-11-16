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

## Core mechanic
- Hold jump to charge a fart. Release to launch. Tap jump for a small hop.
- Three charge tiers: Toot, Trump, Thunder. Over-holding makes a weak "pfft".
- Gas tank drains per fart, refills from bean pickups.

## Planned scope
- 3 levels: Garden, Bean Factory, Space.
- 1 boss: Big Bad Burp.
