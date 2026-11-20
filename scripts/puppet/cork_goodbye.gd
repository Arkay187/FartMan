extends RefCounted
## What happens when Colonel Cork is beaten. Read top to bottom.
## He is so full of fizz that he pops like a champagne cork!

const STEPS: Array = [
	["say", "boss", "OH NO... I FEEL FIZZY!", 1.8, 1.8],
	["shake", 0.2, 0.6],
	["say", "player", "UH OH...", 1.2, 1.6],
	["call", "cork", "pop"],
	["wait", 1.3],
	["say", "player", "POP GOES THE COLONEL!", 1.8, 1.6],
	["clip", "player", "victory"],
	["call", "cork", "open_gate"],
]
