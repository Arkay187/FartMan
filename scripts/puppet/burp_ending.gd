extends RefCounted
## The ending. Big Bad Burp is beaten, and he tells a secret: he has never farted in his life.
## Fart Man gives him a bean. Then: the biggest fart in history! Very few words.

const STEPS: Array = [
	["wait", 0.5],
	["say", "boss", "OOOH... MY TUMMY...", 1.8, 2.6],
	["say", "player", "WHAT'S WRONG?", 1.4, 1.6],
	["say", "boss", "I'VE NEVER FARTED.", 2.0, 2.6],
	["say", "player", "NEVER?!", 1.2, 1.6],
	["say", "boss", "NOT ONCE. EVER.", 1.8, 2.6],
	["say", "player", "HAVE A BEAN!", 1.4, 1.6],
	["call", "burp", "eat_bean"],
	["wait", 1.2],
	["say", "boss", "GULP... UH OH.", 1.4, 2.6],
	["call", "burp", "rumble"],
	["wait", 1.6],
	["say", "player", "UH OH...", 1.0, 1.6],
	["call", "burp", "big_fart"],
	["wait", 2.6],
	["say", "boss", "I FEEL MUCH BETTER!", 1.8, 2.6],
	["clip", "player", "victory"],
	["say", "player", "EVERYBODY FARTS!", 1.8, 1.6],
	["wait", 0.6],
]
