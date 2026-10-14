# Anda: Asset Generation Guide

How to produce every art, animation, audio and font asset for the game with ChatGPT and a few free tools, and how to hand the results back so they can be dropped straight into the Godot project.

Read sections 1, 3 and 6 before generating anything. Generate the three "style lock" images in section 6 first and get them checked before mass producing.

---

## 1. Fixed technical spec (v2, locked after the style check)

These numbers are locked. Every asset is built against them.

The first style check showed that ChatGPT draws at its own density no matter what logical size is requested: about 7 to 9 source pixels per logical pixel, so a subject that fills a 1024 px canvas comes out around 150 to 180 logical pixels wide. Temüjin came out 66 px tall instead of 22. Shrinking that to the original spec destroyed the art, so the game now runs at the density ChatGPT naturally produces. The look is the same, the pixels are finer, and the screen scale drops from 6x to 3x.

| Thing | Value |
|---|---|
| Engine | Godot 4, 2D, pixel perfect |
| Base canvas | 640 x 360 px, shown at 3x (1920 x 1080) |
| View | top-down 3/4, like Link's Awakening or Stardew Valley |
| Tile size | 32 x 32 |
| Hero, enemy, NPC, companion cell | 96 x 96 (body about 40 wide, 66 tall, as in the style lock) |
| Mounted hero and cavalry cell | 144 x 144 |
| Boss cell | 192 x 192 (final Jamukha: 288 x 288) |
| Item icons | 32 x 32 |
| HUD icons | 16 x 16 |
| Portraits | 128 x 128 |
| Cutscene stills | ChatGPT native, about 220 x 146, shown at 2x inside a framed panel |
| Title logo | about 400 x 160 |
| UI 9-slice panels | 48 x 48 with 16 px corners |
| Font | m5x7 or Pixel Operator rendered at 2x |
| Palette | ANDA palette, section 2 |
| Facing directions | down, up, side (drawn facing right). Left is flipped in engine. |
| Sprite origin | bottom centre of the cell |
| File format | PNG with alpha. Never JPG, never screenshots, never GIF. |

Sizes in section 4 were written for the v1 spec. Convert them like this: tiles, props, icons, UI and VFX are 2x the listed number. Character cells use the v2 cells above. Treat all of them as relative sizes for judging proportions, not as numbers to put in prompts.

How to control size in ChatGPT, since the logical size in a prompt is ignored:
- A single subject filling the canvas comes out at 150 to 180 logical px. Right for gers, trees, carts, bosses.
- A three direction character sheet comes out at about 66 px per figure. Right for every person.
- A 4 x 4 grid gives cells of about 32 px. Right for small animals, icons, small props, tiles.
- An 8 x 8 grid gives cells of about 16 px. Right for HUD icons.
- Anything that should be smaller than 32 px must be requested inside a grid, never alone.

---

## 2. Palette ANDA palette

Paste this list into prompts where colour matters. ChatGPT will not match it exactly. All assets get snapped to this palette after generation, so consistency comes from the post-process, not from ChatGPT.

```
outline       #1a1423
shadow        #2e2a3b
night navy    #243a5e
deep blue     #2b5fa8
sky           #7fb2e5
water dark    #3d7fa6
water light   #6fb0c9
grass gold    #c9a84a
grass dry     #a88a2f
grass dark    #7a6a24
green         #6b8f3e
green dark    #3f6a2f
forest        #22452b
earth         #8c6239
earth dark    #5c3f23
earth deep    #3a2616
leather       #b07d4a
felt cream    #f1e9d2
felt tan      #d9cfb1
felt grey     #a89f85
skin          #e8b98a
skin dark     #b8865a
red           #b23a2f
red dark      #7a2219
fire          #f28c28
fire light    #ffd45c
snow          #f6f8fb
snow shadow   #c8d4e3
stone         #8a8f9a
stone dark    #565a66
enemy purple  #6a3f7a
white         #ffffff
tan           #d8944a
fur shadow    #6a4a3a
skin light    #f6b07a
```

---

## 3. Master style block

Paste this at the top of every image prompt, word for word. Then add the subject lines from section 5.

```
STYLE: 16-bit pixel art, top-down 3/4 view in the style of The Legend of Zelda: Link's Awakening and Stardew Valley. Crisp square pixels, no anti-aliasing, no blur, no gradients, no glow, no photo textures. Limited palette of at most 32 colours. 1 pixel dark outline (#1a1423) around the subject. Flat shading with two tones per colour and a single light source from the top left. Setting: 12th century Mongolian steppe. Clothing is the deel (long wrap robe with a sash), pointed felt hats with upturned brims, felt boots with upturned toes, braided hair loops behind the ears. Transparent background PNG. The subject is centred and fills the canvas. No text, no labels, no watermark, no grid lines, no drop shadow.
```

If ChatGPT refuses or fails to give a transparent background, replace the last sentence of the first line with: `Solid flat magenta background #FF00FF, no other magenta anywhere in the image.`

---

## 4. Complete asset list with sizes

Priority: **P0** = vertical slice (camp, overworld, dungeons 1 and 2). **P1** = rest of the game. **P2** = polish, cut if short on time.

### 4.1 Hero: Temüjin on foot (32 x 32 cells)

| Animation | Frames | Directions | FPS | Source |
|---|---|---|---|---|
| idle | 4 | 3 | 4 | ChatGPT 1 pose, code bob |
| walk | 6 | 3 | 10 | hand animated |
| sword attack | 4 | 3 | 12 | hand animated |
| bow draw and shoot | 4 | 3 | 10 | ChatGPT 2 poses, code tween |
| dodge roll | 4 | 3 | 12 | ChatGPT 1 pose, code spin |
| lasso throw | 4 | 3 | 10 | ChatGPT 2 poses, code tween |
| hurt | 2 | 3 | 8 | ChatGPT 1 pose, code flash |
| death | 6 | 1 | 6 | ChatGPT 2 poses, code tween |
| cangue variant (dungeon 3): idle, walk, hurt | as above | 3 | | palette and prop swap of base |
| boy variant (dungeon 1): idle, walk | as above | 3 | | P1, smaller head to body ratio |

P0: idle, walk, sword, hurt, bow. Rest P1.

### 4.2 Hero mounted (48 x 48 cells)

| Animation | Frames | Directions | FPS |
|---|---|---|---|
| idle | 4 | 3 | 4 |
| gallop | 6 | 3 | 12 |
| shoot from saddle | 3 | 3 | 10 |
| hurt | 2 | 3 | 8 |

P0: idle, gallop. Horse colours: bay, grey, black (palette swap, one drawing).

### 4.3 Companions (32 x 32, follow the hero, one ability each)

Each needs: idle 4, walk 6, ability pose 2. Three directions.

| Name | Role in game | Visual notes | Priority |
|---|---|---|---|
| Hoelun | mother, camp manager | older woman, dark deel, headscarf, stern | P0 |
| Bo'orchu | horse retrieval ability | young, cheerful, green deel, lasso pole | P0 |
| Qasar | long range shot | Temüjin's brother, big shoulders, huge bow | P1 |
| Börte | camp intel, cutscene | young woman, blue deel, sable collar | P1 |
| Jelme | heal once per dungeon | wiry, leather apron, satchel | P1 |
| Jebe | piercing arrow | lean archer, scar, red headband | P1 |
| Subutai | traps | boyish, smith's soot, hammer | P1 |
| Sorkan-Shira | rescuer, NPC | middle aged, kind, wool cart | P0 (dungeon 3 is P1 but he appears in cutscene) |
| Chila'un and Chimbai | minor allies | two young men, matching grey deels | P2 |
| Shigi Qutuqu | scribe, adopted Tatar | small boy, gold earring | P2 |
| Jamukha (ally version) | fights beside you in dungeon 5 | handsome, white deel with blue sash, confident | P1 |
| Ong Khan (Toghrul) | ally then traitor | old, gold embroidered deel, heavy fur hat | P1 |

### 4.4 Enemies (32 x 32 unless noted)

Each needs: idle 4, walk 6, attack 4, hurt 2, death 4. Three directions.

| Enemy | Where | Visual notes | Priority |
|---|---|---|---|
| Tayichiud swordsman | dungeons 2, 3 | brown lamellar vest, grey deel, curved saber, hide shield | P0 |
| Tayichiud archer | dungeons 2, 3 | lighter, no shield, quiver, bow | P0 |
| Hunter with dog | dungeon 2 | fur hat, spear, a tan dog on a lead (dog is separate sprite) | P0 |
| Horse thief | dungeon 4 | rags, bandanna, knife, mounted 48 x 48 | P1 |
| Merkit raider | dungeon 5 | black deel, red face paint, axe, torch | P1 |
| Tatar warrior | dungeon 7 | enemy purple sash, scale armour, spear | P1 |
| Kereyit heavy | dungeon 8 | full lamellar, helmet, mace, big shield | P1 |
| Naiman lancer | dungeon 9, mounted 48 x 48 | white armour, long lance | P1 |
| Wolf | forest, winter | grey, hunched, glowing eyes at night | P1 |
| Boar | forest | charge attack | P2 |
| Bandit | overworld random | generic steppe raider | P2 |

### 4.5 Bosses

Each needs: idle 4, move 6, attack A 6, attack B 6, hurt 2, death 8. Three directions except the 96 x 96 final boss (one direction).

| Boss | Dungeon | Size | Visual notes | Priority |
|---|---|---|---|---|
| Begter | 1 | 32 | half brother, same age, smug, holds a fish | P0 |
| Targhutai Kiriltugh | 2 | 64 | fat chief, fox fur hat, whip, hunting horn | P0 |
| Cangue guard captain | 3 | 64 | huge, bare chest, wooden club | P1 |
| Horse thief leader | 4 | 48 mounted | fast, two knives | P1 |
| Chilger Bökh | 5 | 64 | wrestler build, bare arms, Merkit braids | P1 |
| Jamukha (scripted loss) | 6 | 64 | white deel, blue sash, calm | P1 |
| Tatar chief | 7 | 64 | gold mask, two sabers | P1 |
| Senggum | 8 | 64 | Ong Khan's son, arrogant, gilded armour | P1 |
| Tayang Khan | 9 | 64 | Naiman king, white robes, retinue | P1 |
| Jamukha (final) | 9 | 96 | same as before but torn, bloodless end | P1 |

### 4.6 NPCs (32 x 32, idle 4, walk 6, three directions)

Herder man, herder woman, child, elder, shaman (Teb Tengri, feathers and drum), smith, trader. P0: herder man, herder woman, child. Rest P1.

### 4.7 Animals

| Animal | Size | Animations | Priority |
|---|---|---|---|
| Horse standalone | 48 x 48 | idle 4, walk 6, gallop 6, graze 4 | P0 |
| Sheep | 16 x 16 | idle 2, walk 4 | P0 |
| Goat | 16 x 16 | idle 2, walk 4 | P1 |
| Yak | 32 x 32 | idle 2, walk 4 | P1 |
| Dog | 16 x 16 | idle 2, run 4, bark 2 | P0 (hunter's dog) |
| Marmot | 16 x 16 | idle 2, dig 4 | P1 |
| Fish shadow in river | 16 x 8 | swim 4 | P0 (dungeon 1) |
| Eagle shadow | 32 x 32 | fly 4 | P2 |
| Camel | 48 x 48 | idle 2, walk 4 | P2 |

### 4.8 Tilesets (16 x 16 tiles, delivered as 4 x 4 grids of texture tiles)

Transitions, cliffs and autotile edges are built on my side from these base textures. ChatGPT is bad at edge pieces, so do not ask for them.

| Tileset | Tiles to generate | Priority |
|---|---|---|
| Steppe summer | grass x4 variants, dry grass x2, dirt path x3, flowers x2, pebbles x2, stepping stones x1 | P0 |
| Steppe winter | snow x4, packed snow x2, ice x2, frozen river x2, dead grass x2 | P1 |
| Forest (Burkhan Khaldun) | pine needle floor x3, undergrowth x3, fallen log x2, mushrooms x1, roots x1 | P0 |
| River water | water x4 (these 4 are the animation frames, must tile and loop), foam edge x2 | P0 |
| Shore and mud (Baljuna) | mud x3, wet sand x2, reeds x2 | P1 |
| Gorge and mountain rock | rock face x3, scree x2, cave floor x2, cave wall x2 | P1 |
| Camp ground | trampled earth x3, hay x2, rug x2 (for ger interiors) | P0 |

### 4.9 Props and objects (static unless frames listed)

| Prop | Size | Notes | Priority |
|---|---|---|---|
| Ger small | 48 x 48 | white felt, red door facing down | P0 |
| Ger medium | 64 x 64 | | P0 |
| Ger chief | 96 x 80 | wider, banner on top | P1 |
| Ger door open / closed | part of above | 2 states | P0 |
| Enemy ger | 64 x 64 | grey felt, dark door, skulls on poles | P0 |
| Ox cart | 48 x 32 | big wooden wheels | P0 |
| Wool cart | 48 x 32 | heaped fleece, hide spot for dungeon 3 | P1 |
| Campfire | 16 x 16, 4 frames | | P0 |
| Cooking tripod and pot | 16 x 24 | | P0 |
| Cauldron (Dalan Balzhut) | 32 x 32, 4 frames boiling | | P1 |
| Horse hitching line | 64 x 16 | | P0 |
| Horse pen fence | 16 x 16 segments x 6 | straight, corner, post, gate | P0 |
| Hay stack | 32 x 32 | | P0 |
| Smithy anvil and bellows | 32 x 32 | | P1 |
| Ovoo cairn | 32 x 48 | stone pile with blue scarves | P0 |
| Nine tail banner | 32 x 64, 10 states | 0 to 9 white yak tails on a pole | P0 |
| Enemy standard | 32 x 48 | black tails | P1 |
| Palisade wall | 16 x 32 segments x 6 | | P1 |
| Palisade gate | 48 x 48, open and closed | | P1 |
| Torch on pole | 16 x 32, 4 frames | | P0 |
| Barrel, pot, basket | 16 x 16 each | pot has a broken state | P0 |
| Chest closed / open | 16 x 16 | | P0 |
| Wood pile | 32 x 16 | | P0 |
| Drying meat rack | 32 x 32 | | P1 |
| Saddle rack | 32 x 16 | | P1 |
| Boulder | 16, 32, 48 | three sizes | P0 |
| Larch tree | 32 x 48 | three variants, summer and autumn gold | P0 |
| Pine tree | 32 x 48 | two variants | P0 |
| Dead tree | 32 x 48 | | P1 |
| Bush | 16 x 16 | three variants | P0 |
| Tall grass | 16 x 16, 2 frames sway | | P0 |
| River reeds | 16 x 24 | | P0 |
| Cangue on ground | 16 x 16 | | P1 |
| Bones and skull | 16 x 16 | | P1 |
| Snow drift | 32 x 16 | | P1 |
| Ong Khan's golden tent | 96 x 80 | | P1 |
| Naiman war camp wall | 16 x 32 segments | white cloth screens | P1 |
| Lantern | 16 x 16, 2 frames | | P2 |

### 4.10 Items and icons (16 x 16, delivered as 4 x 4 grids)

| Group | Icons | Priority |
|---|---|---|
| Weapons | wooden club, iron saber, steel saber, hero saber, short bow, horn bow, war bow, lasso pole | P0 |
| Ammo | arrow, fire arrow, bundle of arrows | P0 |
| Food | airag flask, dried meat, roots, fish, marmot, aaruul cheese | P0 |
| Charms | wolf tooth, blue scarf, eagle feather, bear claw | P1 |
| Gear | felt deel, leather deel, lamellar deel, felt boots, riding boots, fur hat, war helmet | P1 |
| Keys and quest | camp key, cangue key, dungeon key, eight geldings token, sable coat, letter, map, torch, fire kit | P0 for keys, rest P1 |
| Currency | silver coin, gold ingot, sheep token | P1 |

### 4.11 UI

| Element | Size | Notes | Priority |
|---|---|---|---|
| Health pip | 8 x 8, 3 states | full, half, empty. Shaped like an arrowhead | P0 |
| Horse stamina bar | 9-slice 8 x 8 plus fill | | P0 |
| Arrow counter icon | 8 x 8 | | P0 |
| Companion slot frame | 20 x 20 | | P0 |
| Banner progress widget | 24 x 32 | small nine tail banner for the HUD | P1 |
| Dialog box | 24 x 24 9-slice | felt brown, ochre border, knot motif corners | P0 |
| Name plate | 24 x 24 9-slice | | P0 |
| Choice cursor | 8 x 8 | small arrowhead | P0 |
| Menu panel | 24 x 24 9-slice | | P0 |
| Button | 24 x 24 9-slice, 3 states | normal, hover, pressed | P0 |
| Inventory slot | 18 x 18, 2 states | | P1 |
| Map markers | 8 x 8 x 6 | camp, dungeon, boss, shop, quest, player | P1 |
| Boss health bar | 9-slice plus end caps | | P1 |
| Controller and keyboard glyphs | 12 x 12 x 16 | | P1 |
| Transition wipe texture | 320 x 180 greyscale | wind blown grass shape | P2 |
| Title logo | 200 x 80 | ANDA in carved wood letters with a blue scarf | P0 |
| Title background | 320 x 180 | lone rider on a hill at dusk, banner | P0 |

### 4.12 Portraits (48 x 48, bust, 3/4 face, two expressions each: neutral and intense)

Temüjin boy, Temüjin youth, Temüjin khan, Hoelun, Börte, Jamukha young, Jamukha final, Bo'orchu, Qasar, Jelme, Jebe, Subutai, Sorkan-Shira, Shigi Qutuqu, Ong Khan, Targhutai, Chilger Bökh, Tayang Khan, Teb Tengri, Begter. P0: Temüjin boy and youth, Hoelun, Begter, Targhutai, Bo'orchu.

### 4.13 Cutscene stills (320 x 180)

1. Yesügei poisoned at the Tatar feast
2. The abandoned camp, Hoelun raising the family banner
3. The fish and Begter
4. Nine days hiding in the forest
5. The cangue in the river at night
6. Hidden in the wool cart
7. Eight geldings and Bo'orchu on the trail
8. Wedding to Börte and the sable coat
9. The Merkit night raid
10. Börte found in the Merkit camp
11. The cauldrons at Dalan Balzhut
12. The muddy water oath at Baljuna
13. Jamukha's end
14. The kurultai of 1206, nine tail banner raised

P0: 1, 2, 3, 4. Rest P1.

### 4.14 VFX (sprite strips)

| Effect | Size | Frames | Priority |
|---|---|---|---|
| Sword slash arc | 32 x 32 | 4 | P0 |
| Hit spark | 16 x 16 | 4 | P0 |
| Dust puff | 16 x 16 | 4 | P0 |
| Hoof dust | 32 x 16 | 4 | P0 |
| Red burst (damage) | 16 x 16 | 4 | P0 |
| Fire burst | 32 x 32 | 6 | P1 |
| Smoke column | 16 x 48 | 6 | P1 |
| Water splash | 16 x 16 | 4 | P0 |
| Footprints snow | 8 x 8 | 2 | P1 |
| Falling leaves | 8 x 8 | 4 | P2 |
| Snowfall overlay | 64 x 64 tileable | 8 | P1 |
| Rain overlay | 64 x 64 tileable | 8 | P2 |
| Torch light texture | 64 x 64 radial soft circle | 1 | P0 |
| Heal sparkle | 16 x 16 | 6 | P1 |
| Banner tail glow | 32 x 64 | 6 | P1 |
| Enemy alert mark | 8 x 8 | 2 | P0 |
| Sleep mark | 8 x 8 | 2 | P1 |

### 4.15 Audio (not from ChatGPT)

Music, OGG, loopable, roughly 90 seconds each: title, camp, overworld summer, overworld winter, forest stealth, enemy camp, boss, Jamukha final, loss and retreat, kurultai ending. Use Suno or Udio with prompts like "lo-fi chiptune with morin khuur horsehead fiddle lead, throat singing bass drone, steppe wind, 16-bit game soundtrack, loopable".

Sound effects, WAV or OGG: sword swing x3, hit flesh, hit wood, hit shield, bow draw, arrow fly, arrow hit, lasso whip, roll, footsteps on grass, snow and wood (2 each), hoofbeats loop, horse neigh x2, horse snort, ger door, fire crackle loop, wind loop, river loop, wolf howl, dog bark, sheep, UI move, confirm, cancel, item pickup, heal, hurt grunt x3, death, banner tail attach, cauldron boil, chest open, boss stinger. Tools: ChipTone or jsfxr in the browser for the game-y sounds, freesound.org CC0 for animals and ambience, ElevenLabs sound effects as a paid shortcut.

### 4.16 Fonts

m5x7 by Daniel Linssen (free) for dialog, Pixel Operator for menus. Noto Sans Mongolian for the optional traditional script under the logo. Put the .ttf files in `assets/fonts/`.

### Rough image count for ChatGPT

| Priority | Images |
|---|---|
| P0 | about 70 |
| P1 | about 130 |
| P2 | about 40 |

---

## 5. Prompt templates

Each prompt = master style block + one of these. Fill the square brackets.

### 5.1 Character single pose (hero, companion, enemy, NPC, boss)

```
SUBJECT: [name], [age and build], [hair], [clothing with colours from the palette], [weapon or held object].
POSE: [idle standing / sword mid swing / bow fully drawn / rolling / knocked back / lying dead], facing [down toward the viewer / up away from the viewer / right].
SIZE: logical [32 x 32] pixel cell, character about [14] pixels wide and [22] pixels tall, feet on the bottom row, centred. Render that grid scaled up to fill the whole 1024 x 1024 canvas with crisp square pixels of equal size.
```

Example, Temüjin idle down:

```
SUBJECT: Temüjin, a 16 year old Mongol youth, lean, dark hair shaved on the crown with two braided loops behind the ears, faded deep blue deel robe (#2b5fa8) with a red sash (#b23a2f), dark felt boots with upturned toes, a small recurve bow across his back.
POSE: idle standing, relaxed, facing down toward the viewer.
SIZE: logical 32 x 32 pixel cell, character about 14 pixels wide and 22 pixels tall, feet on the bottom row, centred. Render that grid scaled up to fill the whole 1024 x 1024 canvas with crisp square pixels of equal size.
```

Follow up prompts for other directions, with the first image attached:

```
Use the attached sprite as the exact reference: same character, same palette, same proportions, same outline weight. Draw him seen from behind (facing up, away from the viewer), idle standing. Same size rules. Transparent background.
```

```
Same character and rules. Draw him facing right, side view, idle standing.
```

### 5.2 Animation strip (only for the hand-picked animations, expect cleanup)

```
Use the attached sprite as the exact reference. Produce a horizontal sprite strip of [6] frames of a [walk cycle], facing [down]. Each frame is a [32 x 32] logical cell, frames placed left to right with no gap, so the strip is [192 x 32] logical pixels. Keep the head, colours and outline identical in every frame. Only the legs and arms move. Render scaled up to fill a 1536 x 1024 canvas, crisp square pixels, transparent background.
```

ChatGPT will drift between frames. Treat the output as a guide for redrawing in Aseprite, not as final frames (see section 7).

### 5.3 Mounted sprite

```
SUBJECT: Temüjin from the hero reference riding a small stocky Mongolian horse, bay coat (#5c3f23) with black mane and tail, simple wooden saddle, rider holding reins in one hand.
POSE: horse standing idle, facing right.
SIZE: logical 48 x 48 cell, horse about 40 pixels long and 30 pixels tall including the rider, hooves on the bottom row. Render scaled up to fill 1024 x 1024, crisp square pixels.
```

### 5.4 Tile texture grid

```
Produce a 4 x 4 grid of sixteen 16 x 16 pixel tiles, no spacing, no grid lines, no borders, every tile seamless so it repeats in all directions without visible seams. Logical size 64 x 64, rendered scaled up to fill 1024 x 1024 with crisp square pixels.
Row 1: four variants of summer steppe grass, gold green (#c9a84a, #a88a2f, #6b8f3e), sparse short blades.
Row 2: two variants of dry pale grass, two variants of dirt path (#8c6239, #5c3f23).
Row 3: two variants of grass with tiny blue and white flowers, two variants of grass with small pebbles.
Row 4: stepping stones in grass, three more plain grass variants.
Solid background is fine, no transparency needed.
```

For animated water, ask for one row of four tiles that are the four frames of a gentle ripple loop.

### 5.5 Prop

```
SUBJECT: a Mongolian ger (yurt). White felt walls (#f1e9d2) with faint lattice lines, an orange red wooden door (#b23a2f) with a small carved pattern facing down toward the viewer, domed roof with a central ring, two rope bands around the walls.
VIEW: top-down 3/4 so the roof dome and the front wall are both visible.
SIZE: logical 64 x 64, object fills the cell, bottom of the walls on the bottom row. Render scaled up to fill 1024 x 1024 with crisp square pixels. Transparent background.
```

### 5.6 Item icon grid

```
Produce a 4 x 4 grid of sixteen 16 x 16 pixel item icons for a game inventory, each icon centred in its cell with a 1 pixel dark outline, no cell borders, no spacing, logical size 64 x 64 scaled up to fill 1024 x 1024 with crisp square pixels. Transparent background.
Row 1: wooden club, iron saber, steel saber, ornate hero saber with a blue tassel.
Row 2: short bow, horn bow, war bow, long lasso pole with a loop.
Row 3: single arrow, fire arrow, bundle of arrows, leather airag flask.
Row 4: strip of dried meat, bundle of roots, small fish, white aaruul cheese curd.
```

### 5.7 Portrait

```
SUBJECT: pixel art portrait bust of [name], [description], [expression: calm / angry / grieving], 3/4 view facing slightly left, shoulders visible.
SIZE: logical 48 x 48, head about 28 pixels tall. Render scaled up to fill 1024 x 1024 with crisp square pixels. Transparent background.
```

### 5.8 Cutscene still

```
Pixel art illustration, same 16-bit style, wide cinematic composition. Logical size 320 x 180 scaled up with crisp square pixels. Output a landscape 1536 x 1024 image, I will crop to 16:9. Limited palette, strong silhouettes, dusk lighting.
SCENE: [for example: a small Mongol camp of three gers on the Onon river at dawn; a woman in a dark deel stands holding a tall pole with a single white yak tail while five children stand behind her; in the far distance the rest of the clan rides away leaving a dust cloud].
No text.
```

### 5.9 UI 9-slice panel

```
A 24 x 24 pixel UI frame tile for a 9-slice dialog box. Outer 8 pixel border on all sides: dark felt brown (#5c3f23) with a 2 pixel ochre inner line (#c9a84a) and a tiny Mongolian endless knot motif in each corner. Centre 8 x 8 area: flat solid #3a2616 with no detail so it can be stretched. Logical size 24 x 24 scaled up to fill 1024 x 1024 with crisp square pixels. Transparent outside the frame.
```

### 5.10 Title logo

```
Pixel art game logo reading "ANDA" in bold blocky carved wood letters (#8c6239 with #3a2616 shadow), a blue silk scarf (#2b5fa8) wrapped around the first letter, a single white yak tail hanging from the last letter. Logical size 200 x 80 scaled up to fill a 1536 x 1024 canvas with crisp square pixels. Transparent background. No other text.
```

### 5.11 VFX strip

```
Horizontal sprite strip of [4] frames, each a [32 x 32] logical cell, left to right with no gap: [a curved white sword slash arc that appears, widens and fades]. Pixel art, no anti-aliasing, transparent background, render scaled up to fill a 1536 x 1024 canvas with crisp square pixels.
```

---

## 6. ChatGPT workflow rules

1. **Style lock first.** Generate exactly three images: Temüjin idle down, one ger, one 4 x 4 steppe grass grid. Put them in `assets/raw/` and have them checked. Only then mass produce. Everything after should be generated with the Temüjin image attached as the style reference.
2. **One subject per image.** Do not ask for "all enemies on one sheet". Grids are only for tiles and icons.
3. **Always attach the reference.** For every character after the first, attach the Temüjin sprite and say "same style, same palette, same outline weight".
4. **Ask for the logical size every time.** Without it ChatGPT draws at random pixel densities and nothing lines up.
5. **Transparent PNG.** If the background comes back as a checkerboard pattern drawn as pixels, it has faked transparency. Regenerate with the magenta fallback.
6. **Download, never screenshot.** Use the download button. Keep the original 1024 px files. Do not resize, crop or re-save them in Preview or Photos.
7. **Name files as you save them** using the scheme in section 8. Renaming 200 files later is miserable.
8. **Iterate with edits, not fresh prompts.** "Make the sash red", "remove the shield" on the existing image keeps consistency better than regenerating.
9. **Batch by category.** Do all P0 enemies in one session, all P0 props in another. ChatGPT keeps style better inside one conversation.
10. **Expect 70 percent.** AI pixel art has uneven pixel sizes and stray colours. Cleanup is part of the pipeline and is handled after delivery, so do not spend hours polishing in ChatGPT.

---

## 7. Animation: what to do

### The honest situation

ChatGPT cannot keep a character identical across frames. A requested walk cycle comes back with the head changing shape, the colours drifting and the frames at different scales. It is useful as a reference for drawing, not as game frames.

### The plan: three tiers

**Tier A, hand animated (only these):**
- Hero walk, 6 frames, 3 directions
- Hero sword attack, 4 frames, 3 directions
- Hero mounted gallop, 6 frames, 3 directions
- Horse standalone walk and gallop

That is around 60 frames total and is the whole hand-drawn workload. Everything else is Tier B or C.

**Tier B, two static poses from ChatGPT, tweened in code:** bow shoot (drawn and released), lasso (wind up and thrown), death (stagger and lying), companion abilities. I cross-fade, offset and scale the two poses in code.

**Tier C, one static pose from ChatGPT, animated entirely in code:** idle (vertical bob plus 1 pixel squash), hurt (white flash plus knock back), dodge roll (sprite rotation plus blur trail), enemy walks (bob plus tilt), all animals, all NPCs, all props with 2 frames. This is how many successful pixel games handle crowds and it reads fine at 6x scale.

### Tools for Tier A

- **Aseprite** (about 20 USD, Steam or aseprite.org). The standard. Worth it.
- **LibreSprite** (free fork of old Aseprite) or **Piskel** (free, runs in the browser at piskelapp.com) if you want zero cost.
- Optional AI shortcut: **PixelLab** (pixellab.ai) and **Retro Diffusion** generate consistent walk cycles from a single reference sprite. Not required, but they can save most of Tier A.

### How to make a Tier A animation in Aseprite

1. File, New, 32 x 32, transparent.
2. Drag the ChatGPT idle PNG in as a layer, Sprite, Sprite Size to 32 x 32 with Nearest Neighbor, lock that layer as a reference.
3. Draw frame 1 cleanly on a new layer using the ANDA palette palette (load the palette from `docs/anda.gpl`, which I will provide).
4. Duplicate the frame, move legs and arms, repeat. Onion skin on. Walk cycle order: contact, down, pass, up, contact, down (6 frames).
5. Tag the frames: walk_down, walk_up, walk_side.
6. File, Export Sprite Sheet: Sheet type Horizontal Strip, Layers merged, Trim OFF, Padding 0, Output PNG and JSON (Array). Export one PNG per animation and direction.

Piskel: Export, PNG, Spritesheet, Columns = number of frames, Rows = 1.

### Frame rules

- Every frame in a strip has the same cell size (32 x 32, 48 x 48, 64 x 64).
- Frames go left to right, no gap, no padding, no margin.
- The character's feet sit at the same bottom centre spot in every frame.
- Loop animations return to a pose that flows into frame 1.
- Default FPS: idle 4, walk 10, gallop 12, attack 12, hurt 8, death 6, water 4, fire 8. Override in the notes file if a strip needs something else.

### GIF or not

Not GIF. GIF forces a 256 colour palette, dithers the edges, only supports hard transparency and bakes timing into the file. If a tool only gives you GIF, send it anyway and it will be split into a PNG strip, but expect some colour damage. A PNG strip plus the frame count in the filename is all that is needed.

---

## 8. Delivery: how to hand assets over

I can only read files that are on this machine, inside this project folder. Put files here:

```
assets/
  raw/                 untouched ChatGPT downloads, 1024 px, sorted by folder
    hero/
    companions/
    enemies/
    bosses/
    npcs/
    animals/
    tiles/
    props/
    items/
    ui/
    portraits/
    cutscenes/
    vfx/
  strips/              your Aseprite or Piskel exports (Tier A), already at logical size
  audio/
    music/
    sfx/
  fonts/
  NOTES.md             anything unusual: frame rates, which image is the reference, things to fix
```

### File naming

```
<category>_<name>_<animation>_<direction>[_<N>f].png

hero_temujin_idle_down.png           single pose
hero_temujin_walk_down_6f.png        strip of 6 frames
hero_temujin_mounted_gallop_side_6f.png
enemy_tayichiud_sword_attack_side.png
boss_targhutai_idle_down.png
npc_herder_woman_idle_down.png
animal_horse_bay_walk_side_6f.png
tile_steppe_summer_grid01.png
prop_ger_medium.png
prop_banner_7tails.png
item_weapons_grid01.png
ui_dialog_9slice.png
portrait_temujin_youth_neutral.png
cutscene_02_abandoned_camp.png
vfx_slash_4f.png
```

Directions are `down`, `up`, `side`. Lowercase, underscores, no spaces, no capital letters, no accents (temujin not Temüjin).

### Delivery checklist per batch

- [ ] PNG, original download, not re-saved
- [ ] Named per the scheme
- [ ] In the right `raw/` subfolder
- [ ] Strips have the frame count in the name and equal width cells
- [ ] Transparent or magenta background, nothing else
- [ ] NOTES.md updated with anything that needs special handling

Deliver in this order: style lock (3 images), then P0 hero, P0 tiles and props, P0 enemies and bosses, P0 UI and portraits, P0 cutscenes, then P1 by category.

---

## 9. What happens after delivery

For each batch I run a processing script that:

1. Removes the background (alpha or magenta key) and cleans edge fringes.
2. Detects the actual pixel grid in the 1024 px image and downscales to the logical size with nearest neighbour.
3. Snaps every colour to ANDA palette.
4. Pads or crops to the exact cell size with the origin at bottom centre.
5. Assembles strips and generates the Godot SpriteFrames and TileSet resources.
6. Writes a contact sheet PNG so you can eyeball the batch in one image and flag anything to regenerate.

You review the contact sheet, mark rejects in NOTES.md, regenerate those, and the next batch goes through the same path.
