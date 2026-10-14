# Anda on itch.io

Everything needed for the store page, in the order the itch.io "Create a new project" form asks for it.

## Form fields

- **Title:** Anda
- **Project URL:** anda (so the page is youruser.itch.io/anda)
- **Short description:** A 16-bit action RPG about young Temüjin winning his people back, one raid at a time.
- **Classification:** Game
- **Kind of project:** HTML (the browser build is the main one; the desktop builds are downloads on the same page)
- **Release status:** Released
- **Pricing:** No payments, or $0 with donations (Pay what you want)
- **Genre:** Action
- **Tags:** pixel-art, action-rpg, 2d, top-down, godot, historical, mongolia, singleplayer, zelda-like, story-rich
- **Made with:** Godot
- **Average session:** About an hour
- **Languages:** English
- **Inputs:** Keyboard, Gamepad (any)
- **Multiplayer:** No
- **Accessibility:** none to tick

## Embed settings (for the HTML build)

- Tick "This file will be played in the browser" on Anda-Web.zip (or the html5 channel pushed by butler).
- Embed in page, viewport 1280 x 720, fullscreen button on, mobile friendly off (the game needs a keyboard or a pad).
- Leave "SharedArrayBuffer support" off. The web export has threads disabled, so it needs no special headers.
- Background colour #1a1424.

## Theme (Edit theme on the page)

Colours are the game's own palette (docs/anda.gpl).

| Setting | Value | Palette name |
|---|---|---|
| BG (page) | #1A1423 | outline |
| BG 2 (content column) | #2E2A3B | shadow, the menu panel colour |
| Text | #F1E9D2 | felt_cream |
| Link | #FFD45C | fire_light |
| Link hover (More options) | #F28C28 | fire |
| Button (More options) | #B23A2F | red |
| Button text (More options) | #F1E9D2 | felt_cream |

- Font: Merriweather (a serif suits the chronicle tone and matches the in-game Alegreya; Lora is the alternative). Size: Large.
- Background image (Colour, More options): `docs/store/background_tile_96.png`, repeat on, fixed off. Skip it for a plain dark page.
- Banner image (Layout, More options): `docs/store/banner_960x480.png`.
- Screenshots: Right side, so the eight shots run down beside the text. Auto also works.
- Leave the header and footer colours alone; they follow BG.

## Images

All in `docs/store/`.

- Cover image: `cover_630x500.png` (itch wants 630 x 500).
- Banner: `banner_960x480.png`. Background tile: `background_tile_96.png`.
- Screenshots, in this order: 01_begter, 03_merkit_raid, 02_targhutai, 04_riding, 05_naqu, 07_cutscene, 06_camp, 08_hoelun.

## Description (paste into the page body)

Spring, 1171. Yesügei is dead, poisoned at a Tatar feast. The Tayichiud took the herds and left Hoelun with five children, a river, and a single white tail on a pole.

Anda is a 16-bit top-down action RPG about young Temüjin, the boy who became Chinggis Khan. Fish the Onon, settle it with your brother, slip the cangue, ride down the horse thieves, raid the Merkit camp by night, lose a battle and win the steppe. Nine dungeons from the Secret History of the Mongols, a camp that grows as clans join you, and a nine-tailed banner as the progress bar.

- Nine bosses, from Begter at the riverbank to Tayang Khan on Mount Naqu.
- Five companions with their own abilities: Bo'orchu whistles your horse, Qasar looses a volley, Jelme binds a wound, Jebe fires a piercing shot, Subutai sets a snare.
- Riding, night raids with torchlight, timed stands, fourteen illustrated cutscenes.
- A guide chevron and signposted exits, so you always know where the story goes next.
- Saves automatically. About an hour to the kurultai.

**Controls.** WASD or arrows move, J sword (keep tapping to chain), K bow (hold, release), Space roll (costs stamina), E talk, Q companion, Tab switch companion, Esc menu, F11 fullscreen. Gamepad: left stick, X sword, Y bow, A roll, B talk, RB ability, LB switch, Start pause.

**Downloads.** The browser version plays here. Windows, macOS and Linux builds are below. The macOS app is unsigned: right-click it and choose Open the first time.

Pixel art generated with image models and cleaned by hand to a 35-colour palette. Made in Godot 4.7.

Music by Kevin MacLeod (incompetech.com), licensed under Creative Commons: By Attribution 4.0 (http://creativecommons.org/licenses/by/4.0/): Teller of the Tales, Ishikari Lore, Eastern Thought, Tabuk, Hidden Agenda, Lightless Dawn, Shamanistic, Private Reflection, Drums of the Deep, Crusade, Ibn Al-Noor, Oppressive Gloom, Darkest Child, Lord of the Land, Heavy Interlude. Sound effects from Kenney (kenney.nl), CC0. Fonts Alegreya and Alegreya Sans, SIL Open Font License.

## Uploading

One-time setup on this machine (already done): butler is installed at `~/.local/bin/butler`. Log in once; it opens the browser:

```
butler login
```

Create the project page on itch.io first (Dashboard, Create new project, fill in the fields above, Save). Then from the project folder:

```
tools/package_itch.sh            # re-export all four builds and zip them into build/itch/
tools/push_itch.sh youruser/anda  # upload html5, mac, windows and linux channels
```

Butler uploads only what changed, so later pushes are quick. Channel names ending in html5, mac, windows and linux make itch tag the platforms automatically; after the first push, open the page's Edit screen and tick "This file will be played in the browser" on the html5 upload.

Without butler: upload the four zips from `build/itch/` by hand on the Edit page. Tick the browser box on Anda-Web.zip and the platform icons on the other three.

## Checklist before publishing

- Play the browser build once on the actual itch page (sound starts only after the first click or key).
- Set the page to Public under Visibility and access.
- Devlog post: the first playtest fixes (sword, roll, guide) are a natural first entry.
