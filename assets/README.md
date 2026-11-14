# assets/

Only **finished, game-ready files** go here. Godot imports everything in this folder. Keep your layered working files (Aseprite, Photoshop, Krita) in `art_source/`.

## Graphics (`graphics/`)

- **Format:** PNG with transparency.
- **Export at 1× scale.** Don't upscale before exporting; Godot scales the whole game up for you.
- **Sprite sheets:** keep every frame the same size in an evenly spaced grid, and put the frame size in the file name, e.g. `player_run_16x16.png`. That makes it quick to slice the sheet in Godot's AnimatedSprite2D / SpriteFrames editor.
- **Tilesets:** use one tile size across the whole game (for example 16×16) unless the team agrees on something else.
- **Naming:** `thing_action.png`, all lowercase, e.g. `guard_walk.png`, `coin_spin.png`, `button_play.png`.

| Folder | What goes in it |
|---|---|
| `graphics/sprites/characters/` | the player and friendly characters |
| `graphics/sprites/enemies/` | enemies, bosses |
| `graphics/sprites/items/` | pickups, keys, collectibles |
| `graphics/sprites/effects/` | explosions, dust, sparkles, hit flashes |
| `graphics/tilesets/` | tile sheets for building levels |
| `graphics/backgrounds/` | skies and parallax layers |
| `graphics/ui/` | buttons, icons, health bars, menu frames, logo |

## Audio (`audio/`)

- `music/`: `.ogg` (small files that loop well)
- `sfx/`: `.wav` (no delay when they play)

## Fonts (`fonts/`)

`.ttf` or `.otf`. Pixel fonts look best at their native size, or at exact multiples of it.

## The `.import` files

Godot creates a `something.png.import` file next to every asset. **Commit those too.** They store the import settings, such as filtering and looping.
