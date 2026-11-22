extends RefCounted
## What happens when Big Bad Burp is beaten the first time: he flies off in a huff,
## and a Rocket Burrito falls from the sky.

const STEPS: Array = [
	["say", "boss", "OW! THAT'S ENOUGH!", 1.6, 2.6],
	["shake", 0.2, 0.5],
	["say", "boss", "I'M OFF! BYE!", 1.4, 2.6],
	["call", "burp", "fly_off"],
	["wait", 1.4],
	["say", "player", "HE'S GETTING AWAY!", 1.6, 1.6],
	["call", "burp", "drop_burrito"],
	["say", "player", "A ROCKET BURRITO!", 1.6, 1.6],
]
