extends RefCounted
## Colonel Cork's hello. Read top to bottom: who says what.
## Change the words or add your own jokes! (See scene_player.gd for every kind of step.)

const STEPS: Array = [
	["wait", 0.4],
	["say", "boss", "I CORKED UP YOUR FACTORY!", 2.0, 1.8],
	["shake", 0.15, 0.4],
	["say", "player", "GIVE BACK THE BEANS!", 1.8, 1.6],
	["say", "boss", "NEVER! CHARGE!", 1.5, 1.8],
]
