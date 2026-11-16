extends RefCounted
## Sneezy Weezy's hello. Read top to bottom: who says what.
## Change the words or add your own jokes! (See scene_player.gd for every kind of step.)

const STEPS: Array = [
	["wait", 0.4],
	["say", "boss", "AH... AH... ACHOO!", 1.6, 1.6],
	["shake", 0.15, 0.4],
	["say", "boss", "WHO DARES COME IN HERE?", 1.8, 1.6],
	["say", "player", "GIVE BACK THE BEANS!", 1.8, 1.6],
	["say", "boss", "NEVER! ...ACHOO!", 1.5, 1.6],
]
