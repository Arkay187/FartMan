# The Bean Blimp: a plan (for approval, not built yet)

A reason to collect loads of beans. Every bean goes in Fart Man's **Bean Jar**. You spend the jar on
upgrades aboard **the Bean Blimp**: Grandma's giant flying bean-shaped airship, parked over the world map.

## The loop

1. Play a stage and grab beans. A counter on the HUD shows the beans grabbed in this stage.
2. At the end of the stage, "+312 BEANS!" pours into a big jar on screen, with a cha-ching and a toot.
3. On the 3D world map the blimp hovers over the level you're on. Press Y to go aboard. Inside, walk to a
   station and press jump to shop.
4. Buy an upgrade. It works straight away in every stage. Go back for more beans: replay a favourite
   stage, or raid the bean rooms (about 110 beans each, 10 rooms in the game).

## Rules (kind to a 6 year old)

- **Beans in the jar are never lost.** They are banked at every toilet, at the end of the stage, and when
  you quit from the pause menu. The only beans you can lose are the ones you spill when hurt and don't
  grab back. That gives the spill a meaning without being cruel.
- **Replaying pays.** Beans come back every time you play a stage, so farming a favourite level is fine.
- **The game stays beatable with no upgrades.** Upgrades make it easier and more fun; they're never needed.
- **Every upgrade can be switched off** in the blimp, so Dad can play it hard.
- **Prices**: the first upgrade should be affordable after 1-1, and about one upgrade per stage on a first
  play-through. Everything together costs 3 or 4 play-throughs that grab nearly every bean, so there's
  always something to save for.
  All prices live in one table, so they're easy to change.

## Where the beans come from (counted from the built stages)

| | Beans |
|---|---|
| World 1 stages (1-1, 1-2, 1-3, 1-4) | 320, 377, 285, 13 |
| World 2 stages | 342, 337, 312, 14 |
| World 3 stages | 310, 389, 319, 276 |
| Placed in the whole game | about 3,300 |
| Enemy drops and boss showers, one play-through | about 600 |
| A first play-through, roughly | 2,000 to 2,500 |

## The stations (each is a little room you walk into, side-on, like a cut-away ship)

### Grandma's Kitchen: belly upgrades
| Upgrade | What it does | Price |
|---|---|---|
| Bigger Belly 1 / 2 / 3 | Gas tank 125 / 150 / 200 (hover lasts longer) | 150 / 400 / 800 |
| Super Beans | Each bean gives 50% more gas | 350 |

### Nurse Nora's Heart Hut: staying alive
| Upgrade | What it does | Price |
|---|---|---|
| Extra Heart 1 / 2 | 4 hearts, then 5 | 250 / 700 |
| Big Hearts | Heart pickups heal 2 | 300 |
| Sticky Beans | Spilled beans stay 10 s instead of 5, and fewer spill | 250 |

### The Hot Sauce Lab: fire burp upgrades
| Upgrade | What it does | Price |
|---|---|---|
| More Fireballs 1 / 2 | 4, then 5 fireballs at once | 250 / 550 |
| Big Fireballs | Bigger balls that squash a wider row | 350 |
| Bouncy Fireballs | They hop over small gaps and roll longer | 500 |
| Spicy Start | Every stage starts with the Fire Burp | 1,000 |
| Long Chilli 1 / 2 | Chilli lasts 9 s, then 12 s | 200 / 500 |

### The Gadget Garage: moves and luck
| Upgrade | What it does | Price |
|---|---|---|
| Bean Magnet 1 / 2 / 3 | Beans fly to you from 2 / 4 / 6 m away | 200 / 500 / 1,000 |
| Lucky Beans | Enemies drop more beans, and pickups twice as often | 400 |
| Super Stomp | A stomp sends out a shockwave that squashes nearby enemies | 700 |
| Triple Jump | One more fart double jump in the air (an extra air fart in CLASSIC) | 1,200 |

### The Wardrobe: just for fun (no effect on play)
- **Hats** (100 to 400 each): cowboy, crown, pirate, propeller cap, chef's hat, traffic cone.
- **Fart colours** (150 to 300): rainbow, sparkly gold, purple, "invisible" (just the sound).
- **Fart sounds** (100 to 250): trumpet, duck quack, tuba, squeaky toy.
- Kids love dressing up: this is the cheapest way to make every bean feel worth it.

## Golden Beans unlock things (they're never spent)
There are 36 Golden Beans (3 per stage). Collecting them opens parts of the blimp:
- **6**: the Trophy Room (a shelf of the Golden Beans and bosses you've beaten) and a free gold crown.
- **12**: the Jukebox (play any song from the game).
- **18**: **Bean Sprout**, a little pet bean that floats behind you and grabs beans near you.
- **24**: **The Bean Vault**, a secret bonus stage on the map that's nothing but bean rooms and bouncers.
- **36**: the Golden Fart Man suit.

The blimp itself grows as you go. New rooms light up, Grandma's kitchen gets busier, and flags go up for
each boss beaten.

## Full price list, roughly
Kitchen 1,700 + Heart Hut 1,500 + Hot Sauce Lab 3,350 + Garage 4,000 + Wardrobe about 3,000 = **about 13,500
beans**. That's about 3.5 play-throughs grabbing nearly everything (about 3,900 each), or about 6 first-time
ones. Replays and bean rooms are quicker, so it goes faster than it sounds. Tune it after the first
week of play: if he's buying something after nearly every stage, it's about right.

## How it would be built (the technical bit)
- **Save**: the save file gets `bean_jar`, `upgrades` (name and level), `upgrades_off`, `wardrobe_owned` and
  `wardrobe_worn`. Banking happens at toilets, at stage end and on quit.
- **Counting**: beans tell the stage when they're eaten (like points do now). The HUD shows "beans this stage".
- **The table**: one script lists every upgrade: name, station, picture, levels, prices, and what it changes.
- **Applying upgrades**: a small helper runs at the start of every stage. It sets the player's numbers: tank
  size, hearts, fireball count, chilli time, air jumps, magnet range. The Bean Magnet and Super Stomp are
  small new nodes on the player.
- **The blimp**: a hub scene made by the builder. Fart Man walks along the inside of the blimp, past station
  rooms. Each station opens a big, simple shop panel with pictures, a bean price, and a jar that shows how
  many more beans you need. Up and down to pick, jump to buy, back to leave.
- **The map**: the world map is a 3D diorama (being built now). The Bean Blimp hovers above whichever level
  you're on, with Fart Man in the gondola, and flies along the path when you move. Pressing Y goes aboard.
  The map already has a `board_ship()` hook waiting for the hub.
- **Tests**: buying takes beans and can't go below zero. Upgrades are saved and come back after reloading.
  Each upgrade really changes the player in a stage. Banking works at toilets, stage end and quit. Spilled
  beans not grabbed are lost from the jar. The map gets you to the blimp and back.

## Build order (each step is playable on its own)
1. **The Bean Jar**: counting, banking, the HUD counter, the end-of-stage pour, and the jar total on the map.
2. **The blimp and the shop**: the Kitchen, Heart Hut, Hot Sauce Lab and Garage, about 15 upgrades.
3. **The Wardrobe**: hats, fart colours, fart sounds.
4. **Golden Bean unlocks**: the Trophy Room, Jukebox, Bean Sprout, the Bean Vault, the golden suit, and the
   blimp growing.

## Things to decide
1. The name: **the Bean Blimp**? (Or the Windbag, the Gas Giant, the Toot Tank...)
2. Never losing banked beans (recommended), or losing a stage's beans if you quit halfway?
3. Should upgrades be switchable off? (Recommended: yes, for Dad.)
4. Who runs the shop: Grandma, or a new character (a robot? a talking bean)?
