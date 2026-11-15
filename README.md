# Anti-Kepam

![Cover](submission/cover_1600x1000.jpg)

A Godot 4 game jam game in a GTA-style sunset look (Vice City colours, cel-shaded, thick outlines), written in a mix of English and Malay.

*Kepam* is Malaysian slang for "smelly".

## Story

A kepam boy gets dumped on WhatsApp by his girlfriend:

> "You terlalu kepam untuk I, kita break. Bye."

He has to wash at four places around town, then jump into the Golden Lake, before she marries someone else.

## How to play

**Goal:** wash at all four stations in order, then dive into the Golden Lake before the girlfriend's timer runs out.

| Key / input | Action |
|---|---|
| WASD / arrow keys | Walk around the hub |
| SPACE | Wash / action |
| Mouse (drag, click) | Scrub, aim, answer |
| E | Answer a knock at the door |
| B | Buy soap or tissue near the hygiene shop |
| ESC | Audio settings (anywhere) |

### Stations

1. **R&R** - time your taps to wash without falling asleep.
2. **Gas Station** - scrub graffiti and bacteria off a public toilet with the mouse (soap = bigger eraser) and answer the door when people knock.
3. **LRT** - swipe your card through the reader, answer 6 hygiene questions, then watch him enter the stall (door opens, closes) and shower.
4. **Shopping Mall** - run through a neon maze to four shower points while a ghost chases you.
5. **Golden Lake** - he jumps in off the bank, then you hold SPACE for the final shower. A brighter lake needs better scores at the stations.

Kuman (germs) are the currency. Spend them on soap and tissue at the hub shop.

### Bottom bar

- **Kepam Negeri** - a green gas-cloud bar that fills as the smell spreads across the state.
- **GF face** - the girlfriend's face goes from hopeful to disappointed, sad, crying and finally numb as her timer runs out.

### You lose if

- The kepam spread reaches 100% (the state goes viral on Berita Kepam 26).
- The girlfriend's timer runs out and she marries someone else.
- The ghost at the mall catches the boy.
- The lake is too dim (final score below 60%).

Each loss has its own cinematic ending. Winning has one too.

## Run it

Needs [Godot 4.x](https://godotengine.org/) (developed on 4.7).

```sh
git clone https://github.com/idrisharis12/Anti-Kepam.git
cd Anti-Kepam
godot --path .
```

Or open `project.godot` in the Godot editor and press F5. The first run imports the assets.

Rendering is `gl_compatibility` at 960x540 with `canvas_items` stretch.

## Project layout

```
assets/       backgrounds, sprite sheet, portraits
audio/music/  looping music tracks
audio/sfx/    sound effects (placeholders)
scenes/       small .tscn stubs that attach a script
scripts/      all game code; the UI is built in code
submission/   GamePix icon (512x512) and cover (1600x1000)
```

Autoloads: `GameState` (progress, score, timers) and `Sfx` (music, sound effects, volume).

## Status

Game jam build. Sound effects are generated placeholders.

## Credits

Game design, code and direction: Blakie, built with Claude Code.
Art: generated with an image model, then edited. Music: tracks supplied by the author.
