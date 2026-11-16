# Session Notes

## Session 1 (2026-11-16)

### Decisions made
- Godot 4.7, GDScript only, Jolt physics, 2.5D: gameplay on X/Y, Z locked to 0.
- Player is a CharacterBody3D. Typed GDScript, all tunables in @export.
- Controls for now use Godot's built-in actions: arrow keys to move, Space to jump.
  The action names are @export so we can swap to custom ones (A/D, gamepad) later.
- Grey boxes first, no art.
- Rules now live in CLAUDE.md (Claude Code does not load CLAUDE.md.txt).
  The old CLAUDE.md.txt is still there and can be deleted; everything in it is in CLAUDE.md.

### Files created
- CLAUDE.md: project rules and design.
- scripts/player.gd: left/right movement and a normal jump.
- scenes/, art/, audio/: empty folders (each has a .gitkeep).
- SESSION_NOTES.md: this file.

### Git
- Git for Windows 2.56 installed. Repo created on branch `main` with a first commit.
- Git name/email are set for this repo only (not globally).

### Node setup still to do in the editor
- scenes/player.tscn: CharacterBody3D "Player" (attach scripts/player.gd)
  with a MeshInstance3D (CapsuleMesh) and a CollisionShape3D (CapsuleShape3D).
- scenes/test_level.tscn: Node3D root, a StaticBody3D floor (BoxMesh + BoxShape3D,
  size about 30 x 1 x 4), the Player placed above it, a Camera3D at about (0, 3, 12),
  and a DirectionalLight3D.

### What to do next
1. Delete the old CLAUDE.md.txt.
2. Build the two scenes above and check walking and jumping feel good.
3. Replace the simple jump with the charge jump: tap = hop, hold = Toot / Trump / Thunder, over-hold = pfft.
4. Add the gas tank and bean pickups.
5. Make the camera follow the player.
