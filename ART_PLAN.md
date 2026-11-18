# Fart Man: Character Models and Animation Plan (DRAFT, waiting for approval)

How the grey boxes turn into real characters, without breaking the game or the budget.

**Progress (18 Nov 2026):** Phase 1 (animation hooks) is built. Phase 3 has started: Rich
chose route C. Fart Man was made with Tripo from a concept turnaround and is in the game as a
still model (no skeleton yet). Rigging and the clips come next. See SESSION_NOTES.md.

## The short version

1. **Build the animation hooks first, with grey boxes.** The code that plays "run", "jump",
   "hurt" and so on gets written now and works with no art at all (squash and stretch in code).
   When a real model arrives it just plugs in.
2. **Fart Man comes first, and he comes from your son's drawings.** One simple low-poly model,
   made by hand in Blender or generated from a drawing, with about ten animations.
3. **Enemies and bosses use free stand-ins until we make our own.** Free, no-credit-needed
   (CC0) low-poly characters come with animations already, so every enemy can move properly
   on day one.
4. **One world at a time.** After World 1 plays well in grey boxes, give World 1 real art.

## What we need to make

| Character | When needed | Notes |
|---|---|---|
| **Fart Man** | First | Belly that grows, a face, a bottom that toots |
| Burpling | World 1 | Small blob. Easy: mostly squash and stretch |
| Hiccup, Grumpy Gnome, Prickle | World 1 | Simple shapes |
| Sneezy Weezy (boss) | World 1 | A giant flower with a face |
| Grandma | Story | Appears in storybook and a puppet scene |
| Cork Bot, Fizz Bat, Colonel Cork (boss) | World 2 | |
| Burp Bubble, Whiffler, Big Bad Burp (boss) | World 3 | |
| Props: beans, toilets, cans, hoops, burrito | Any time | Simple shapes, much easier than characters |

## How a model gets into the game

- **Format: glTF (`.glb`).** One file per character, containing the mesh, the skeleton and
  all its animations. Godot opens it directly, so there is nothing to convert.
- **Folder:** `art/characters/<name>/<name>.glb`. Storybook drawings go in `art/story/`.
- **Size limit:** about 3,000 triangles for Fart Man and 1,000 for each enemy. Low-poly is the
  style, and it keeps everything fast.
- **The skeleton does the acting, the code does the moving.** Fart Man's physics stay exactly
  as they are (a capsule). The model is only a costume on top, so changing it never changes
  how the game plays.
- **I never hand-edit scenes.** A small script in `tools/` builds each character scene from
  its `.glb`, same as everything else.

## The animation list

Every character uses the same clip names, so one script can drive them all.

**Fart Man (about ten clips):** `idle`, `run`, `jump` (rising), `fall`, `land`, `charge`
(belly growing), `squeak` (the leak), `hurt`, `stomp` (bounce), `flight` (superhero pose),
`victory`, `talk`.

**Enemies:** `walk` (or `idle`), `squash`, and one `attack` where they have one.
**Bosses:** `idle`, `attack`, `hurt`, `dizzy` (the stomp moment), `defeat`.

If a clip is missing, the game falls back to code-made squash and stretch, so a half-finished
character is never broken.

## The belly

The belly is the heart of the game, so it gets special treatment:

- It is a **separate shape that the code scales**, exactly like the pink ball today.
- The real model keeps a belly part with a known name (`Belly`), so the existing
  growing-and-leaking code carries on working unchanged.
- The `charge` animation adds the acting around it (cheeks puffing, eyes scrunching).

## How the code connects (the part I build now)

Fart Man already announces what he is doing (`charge_started`, `farted`, `got_hurt`,
`stomped`, `squeak_started`, `respawned` and the flight signals). A small **animator script**
listens to those and plays the matching clip. Enemies get the same treatment through one
shared script.

This also feeds the puppet-show scenes (build step 6): the scene player will just say
"play `victory`" or "play `talk`" and it works for any character.

## Where the models come from

| Option | Cost | Good for | Catch |
|---|---|---|---|
| **A. Free packs** (Kenney and Quaternius, both CC0, plus Mixamo animations) | Free | Enemy stand-ins, test animations, props | Not our own look |
| **B. Model it ourselves in Blender** (free) | Free, takes time | Fart Man, if you or your son enjoy it | A learning curve |
| **C. Turn drawings into 3D** with an image-to-3D tool | Small fee | Fart Man and bosses from your son's drawings | Needs cleaning up and rigging, check each tool's terms |
| **D. Commission an artist** | Paid | A polished final look | Cost, waiting |

**My recommendation:** A for stand-ins now, **C or B for Fart Man** (drawing first, so your
son's design is the real character), and revisit D only if we want a polished release.

Whichever route, the **drawing comes first**. A page of Fart Man from the front, side and
back, plus a face doing a few expressions, is all anyone needs to start. Those same drawings
can also become the storybook pages.

## Who does what

- **Me (and cheaper models doing the building):** the animator scripts, the character scene
  builder, the grey-box fallback animations, the checks, the credits file, and wiring in
  every model you hand over.
- **You and your son:** the drawings, deciding the look, and the account sign-ups and
  downloads. Downloads and sign-ups are yours to do (I will not make accounts or download
  files without you), and I will tell you exactly which file to grab and where to put it.

## Phases

| Phase | What | You need to do |
|---|---|---|
| **1. Animation hooks** | Animator scripts, clip names, fallback squash and stretch, a test that checks every clip exists | Nothing |
| **2. Fart Man's drawings** | Front, side, back and faces | Draw them |
| **3. Fart Man model** | Model, rig, the ten clips, belly part, built into his scene | Pick route B or C; sign up where needed |
| **4. World 1 enemies and boss** | Stand-ins first, our own versions later | Draw Sneezy Weezy and the Burplings |
| **5. Story characters** | Grandma and Big Bad Burp, for the storybook and puppet scenes | Draw them |
| **6. World 2 and 3 characters** | As the worlds are built | Draw them |

Phase 1 can happen straight away. Phases 2 and 3 can run alongside build step 6 (the puppet
scene player).

## Housekeeping

- **Credits:** every free asset is recorded in `CREDITS.md` with its source and licence. We
  only use CC0 or similarly open assets, and we check any generator's terms before using it.
- **Size:** all art lives in `art/`, and the finished `.glb` files stay small enough to keep
  in the GitHub repo.
- **Checks:** a test loads every character, confirms the clips exist, and fails loudly if a
  name is wrong, so a typo in Blender can't silently break an animation.
- **Not checkable by a script:** whether it looks good and feels fun. That is always yours.

## Decisions I need from you

1. **Who makes Fart Man:** you and your son in Blender, an image-to-3D tool from his drawing,
   or a commissioned artist?
2. **Is the look chunky, soft and cartoony** (my suggestion: big head, big belly, tiny legs)
   or something else?
3. **Is it OK to start Phase 1 now,** before any art exists?
