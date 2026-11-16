class_name StoryPages
extends RefCounted
## All the storybook stories as plain lists. Edit the words and colours here!
##
## Each page has:
##   "text"  - one short line in CAPITALS
##   "color" - the colour of the placeholder card
##   "image" - optional path to a drawing, like "res://art/story/burp.png".
##             If the file exists it is shown instead of the coloured card.

const OPENING: Array[Dictionary] = [
	{"text": "GRANDMA GROWS THUNDER BEANS!", "color": Color(0.4, 0.75, 0.35), "image": "res://art/story/opening_1.png"},
	{"text": "BIG BAD BURP STEALS THEM ALL!", "color": Color(0.55, 0.35, 0.7), "image": "res://art/story/opening_2.png"},
	{"text": "HE FLIES OFF TO PLANET WHIFF!", "color": Color(0.3, 0.6, 0.75), "image": "res://art/story/opening_3.png"},
	{"text": "ONE BOWL IS LEFT. A BOY EATS IT!", "color": Color(0.95, 0.6, 0.3), "image": "res://art/story/opening_4.png"},
	{"text": "FART MAN!", "color": Color(0.9, 0.25, 0.25), "image": "res://art/story/opening_5.png"},
]


## Look a story up by name ("opening"). Unknown names give an empty list.
static func get_story(story_name: String) -> Array[Dictionary]:
	match story_name:
		"opening":
			return OPENING
	return []
