# Anda

A 16-bit top-down action RPG about young Temüjin winning his people back, one raid at a time.
Nine dungeons from the Secret History of the Mongols, a camp that grows as clans are recruited,
and a nine-tail banner as the progress bar.

**Nine Tails (v1.0.0)**: all nine dungeons are playable end to end, from the Onon riverbank to the
kurultai of 1206. Title, intro, camp hub that grows with the banner, fourteen maps, nine bosses,
five companions with abilities, riding, night raids, timed stands, fourteen cutscenes, saving and
continuing.

Dungeons in order: the riverbank (Begter), Burkhan Khaldun (Targhutai), the Tayichiud camp and
Sorkan-Shira's ger (the cangue escape, guard captain), the horse thieves (mounted, Bo'orchu),
the Merkit raid (Jamukha as ally, Chilger, Börte), Dalan Balzhut (a scripted loss), the Tatar
camp (Qasar, Shigi Qutuqu), Baljuna and the Kereyit camp (Jelme, Senggum, Jebe), and Mount Naqu
(Subutai, Tayang Khan, Jamukha's end).

## Play

Builds are in `build/` after an export (see below). From source:

```
/Applications/Godot.app/Contents/MacOS/Godot --path .          # play
/Applications/Godot.app/Contents/MacOS/Godot --path . -e       # open the editor
```

Controls: WASD or arrows move, J sword (keep tapping to chain swings), K bow (hold, release
to shoot), Space roll (passes through enemies, costs stamina; spur when riding), E talk or cook at
the campfire, Q companion ability, Tab switch companion, Esc pause menu, F11 fullscreen. Every key can be
changed in Settings (title screen or pause menu), which also has music and sound sliders and a
fullscreen switch.

Stamina (the small bar under the banner count) pays for rolls and, a little, for sword swings:
three rolls in a row, then a breath. The sword chains three swings, the third a lunge, then rests
half a second. Bosses answer three quick hits with an immediate counter.
Only the camp, the steppe and the place the story is at can be entered; a closed exit says so.
After the kurultai the whole steppe opens for free riding, and the ending rolls the credits.
Tayang Khan and Jamukha hit for a full heart; every boss fights faster below half health and
answers a sword wall with an instant counter. Every second tail on the banner adds a heart, from
six health at the river to twelve at Mount Naqu. Enemies commit to a direction partway into a
wind-up, so a late sidestep works.

Finding the way: the line at the top says what to do, a gold chevron marks the target when it is
on screen and sits at the screen edge pointing toward it when it is not, and every exit carries a
sign with the name of the place it leads to (gold when it is the way to the objective).
Gamepad: left stick, X sword, Y bow, A dodge, B talk, RB ability, LB switch, Start pause.

Companions: Bo'orchu whistles your horse on open ground, Qasar looses a three-arrow volley,
Jelme binds a wound once per fight, Jebe fires a piercing arrow, Subutai sets a snare.

## Build

Export templates for Godot 4.7.2 are installed under `~/Library/Application Support/Godot/export_templates/`.

```
Godot --headless --path . --export-release "macOS"   build/Anda-macOS.zip
Godot --headless --path . --export-release "Windows" build/windows/Anda.exe
Godot --headless --path . --export-release "Linux"   build/linux/Anda.x86_64
Godot --headless --path . --export-release "Web"     build/web/index.html
```

The macOS build is unsigned; users outside the developer machine need to right-click, Open once.
The Web preset has threads disabled, so the browser build runs on itch.io without special headers.

Releasing on itch.io: `tools/package_itch.sh` exports all four and zips them into `build/itch/`,
`tools/push_itch.sh youruser/anda` uploads them with butler (after a one-time `butler login`).
Page text, tags, cover and screenshots are in `docs/itch-page.md` and `docs/store/`.

## Layout

```
project.godot            640x360 pixel-perfect, integer scaled, nearest filtering
export_presets.cfg       macOS, Windows, Linux, Web presets
scenes/                  Title, Cutscene, Level, Hero, Enemy, FontTest (dev)
src/Game.gd              autoload: state, routing, fades, input, theme, saving, test hooks
src/Sfx.gd               autoload: synthesised sound effects, music and ambience playback
src/Save.gd              one JSON save slot in user://
src/Settings.gd          volumes, fullscreen and key bindings, one JSON file in user://
src/Sheets.gd            slices the processed sprite sheets into textures
src/Vfx.gd               one-shot effects and floating text
src/SlashArc.gd          procedural sword sweep
src/world/Maps.gd        the levels, as ASCII maps (one character per 32 px tile)
src/world/Level.gd       turns a map into tiles, props, enemies, pickups, exits
src/world/TileSets.gd    builds the TileSet from the 32 px tile grids
src/entities/            Hero, Enemy (6 kinds), Prop, Pickup, Npc, Arrow
src/ui/                  Hud, DialogBox, Menu, PauseMenu, SettingsMenu, Title, Cutscene
assets/raw/              untouched AI downloads, one folder per category
assets/processed/        cleaned sprites the game loads
assets/audio/music/      one MP3 per map by Kevin MacLeod (CC BY 4.0, see CREDITS.md)
assets/audio/sfx/        recorded effects from Kenney packs (CC0); name_1.ogg, name_2.ogg are random takes
assets/fonts/            Alegreya (game font) and Alegreya Sans, both SIL Open Font License
tools/                   asset pipeline and music generator (see docs/asset-guide.md)
docs/                    asset guide, prompts, palette
```

## Editing levels

Levels live in `src/world/Maps.gd` as text. The legend is at the top of that file. Exits are
any character listed in the map's `exits`: walking onto `1` in the camp puts you on `1` in the
overworld. Other per-map keys: `night` (blue tint and torch lights), `mounted`, `aggro_scale`,
`npc` and `enemies` (which character spawns which kind), `when` and `unless` (story flags that
gate a spawn), `triggers` (story beats), `allies` (followers who fight beside you), `survive`,
`waves` and `survive_trigger` (timed stands), `growth` (camp props that need banner tails).
All rows of a map must be the same width.

## Adding assets

Drop raw PNGs into `assets/raw/<category>/`, add a rule to `tools/process_all.py` for a new
asset, then:

```
python3 -I tools/process_all.py
python3 -I tools/contact_sheet.py
```

`tools/generate_assets.py` runs the queue in `docs/chatgpt-oneshot-prompt.txt` through the
OpenAI Images API (key in `~/.config/anda/openai.env`). `tools/make_music.py` regenerates the
placeholder music.

Audio: effects are looked up as `assets/audio/sfx/<name>.ogg` or numbered takes `<name>_1.ogg`,
`<name>_2.ogg` (swoosh, hit, hurt, dodge, ui, pickup, enemy_die, boss, step); a name with no file
falls back to a synthesised sound (arrow, cook, wind). Music is `assets/audio/music/<map>.mp3`
(or .ogg) per map plus `title` and `boss`, crossfaded on change. Attribution is in CREDITS.md.

## Test hooks

Environment variables used for automated checks (ignored otherwise):

```
ANDA_MAP=riverbank                       start directly on a map
ANDA_POS=1000,300                        put the hero at these pixel coordinates
ANDA_SHOT=/tmp/shot.png                  save a screenshot after about a second and quit
ANDA_AUTO="right:1.0,attack,wait:0.3"    scripted input before the screenshot
ANDA_TAILS=5  ANDA_FISH=2                starting banner tails and fish
ANDA_FLAGS=begter,thanked                story flags to set
ANDA_SURVIVE=3                           shorten a timed stand
ANDA_DEBUG=1                             print scene and interaction tracing
ANDA_AUTO steps also accept "killboss" to end the active boss fight
ANDA_DEBUG=1 also prints every hit an enemy takes ("Begter takes 1, hp 7"), boss enrages and exit decisions
ANDA_FONT=res://... ANDA_FONT_SIZE=17 ANDA_FONT_WEIGHT=500 ANDA_FONT_SPACING=0   try another font without editing code
ANDA_BOT=1 ANDA_SPEED=3                  an automated player runs the whole game and logs "[bot]" lines
```

The automated player (`src/Bot.gd`) follows the guide target over the level's walk grid, fights
with the sword, rolls away from wind-ups, dismounts and shoots when riding, talks, clicks through
cutscenes, and reports map changes, objectives, deaths, stalls and the finish:

```
rm -f "~/Library/Application Support/Godot/app_userdata/Anda/anda_save.json"
ANDA_BOT=1 ANDA_SPEED=3 Godot --headless --path . 2>&1 | grep "\[bot\]"
```

Headless error check: `Godot --headless --path . --quit-after 90` with `ANDA_MAP` set.

## Known limits

- Balance is first-pass only. Enemy numbers live in `src/entities/Enemy.gd` PARAMS; at most two
  foot soldiers attack at once, the rest circle.
- The overworld has grown thirteen exits around its edges; the signs and the guide chevron stand
  in for a drawn map screen.
- Jamukha's final choice is told in the cutscene rather than offered as a dialog choice.
