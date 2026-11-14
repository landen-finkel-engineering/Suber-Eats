# Suber-Out

Rico delivers Suber Eats orders to other planets. Launch him with your hand (pinch, pull back, let go), bounce off things, and get the food there fast.

Made with Godot 4.7.

## Setup

1. Install Godot 4.7 (standard version) from https://godotengine.org/download
2. Clone this repo with GitHub Desktop (File > Clone Repository > URL) or `git clone https://github.com/landen-finkel-engineering/Suber-Out.git`. Don't use Download ZIP, because macOS blocks the hand tracking plugin from zips.
3. Open Godot, click Import, pick `project.godot`, then Import & Edit.
4. Press Play (F5, or Cmd+B on Mac). Allow the camera when asked. The first run downloads the hand model (~8 MB), so be online.

The game is played with your hand only. Your hand moves the cursor and a pinch is a click, so it presses Start and Next too. (The mouse still works while no hand is in view, which is handy for testing.)

## Controls

- Pinch, pull back, let go: launch Rico
- Pinch a button: press it
- Esc: pause (keyboard)
- C: camera preview on/off
- M: hand tracking on/off

## Making levels

See [docs/level_painter.md](docs/level_painter.md).

## Folders

```
scenes/levels/     level_01 to level_10
scenes/objects/    bouncer, black hole, goal
scenes/enemies/    ufo
scenes/characters/ rico
scenes/ui/         title screen, hud, theme
scripts/           code (same layout as scenes)
assets/graphics/   art (the team's sprites are in unorganized/)
assets/audio/      music and sfx (.m4a voice lines have .ogg copies Godot can play)
assets/fonts/      Silkscreen pixel font (Open Font License)
art_source/        aseprite/psd files (Godot ignores this)
addons/            GDMP (hand tracking) and Level Painter
```

## Rules for working together

- Pull before you start, push when you're done.
- Don't edit the same .tscn file at the same time as someone else.
- Use lowercase_with_underscores for file names.
- Move/rename files inside Godot's FileSystem panel so links don't break.
- Commit the .import and .uid files Godot makes. Never commit the .godot folder.

## Camera problems

- "No camera" or no prompt: System Settings > Privacy & Security > Camera, turn on Godot, restart Godot.
- "Plugin didn't load": you probably downloaded a zip. Clone it instead, or run `xattr -dr com.apple.quarantine path/to/Suber-Out` in Terminal.

## Sounds

All in `scripts/autoload/sound.gd`:

- level start: Suber Eat's Order
- launch: grunt
- UFO beaten: poof
- delivery: doorbell, then you-win on the results screen
- death: Dying SFX (or Dying to Black Hole), then a random Ragebait line
- car alarm isn't used yet

