# Suber-Out

A 2D pixel art game made with [Godot 4](https://godotengine.org/).

---

## Getting the project onto your computer

Do this once per computer.

1. **Install Godot 4.4 or newer**, the **standard** version (not ".NET"), from <https://godotengine.org/download>. Everyone on the team should use the same version. Check yours under **Help > About Godot**.
2. **Install Git**, or [GitHub Desktop](https://desktop.github.com/) if you'd rather not use the command line.
3. **Clone the repo.** Pick one:
   - **GitHub Desktop:** File > Clone Repository > URL tab > paste `https://github.com/landen-finkel-engineering/Suber-Out.git` > Clone.
   - **Command line:**
     ```bash
     git clone https://github.com/landen-finkel-engineering/Suber-Out.git
     ```
4. **Open it in Godot.** Open Godot. In the Project Manager, click **Import**, go to the `Suber-Out` folder you just cloned, pick `project.godot`, and click **Import & Edit**. The first time it opens, Godot spends a few seconds importing the assets.
5. **Press F5** (⌘ B on Mac) or click the ▶ button at the top right to run the game. Right now this opens the **pinch test**: pinch, pull back, and let go to launch Rico, with your hand on camera or the mouse. Full guide: [docs/pinch_test.md](docs/pinch_test.md).

---

## Where things go

```
Suber-Out/
├── project.godot          Godot project settings (open this in Godot)
│
├── scenes/                🎬 SCENES (.tscn): levels, characters, UI screens
│   ├── main.tscn          placeholder start scene
│   ├── tests/             test scenes, e.g. pinch_test.tscn (runs when you press Play)
│   ├── levels/
│   ├── characters/        player.tscn, guard.tscn, ...
│   ├── objects/           doors, pickups, platforms, ...
│   └── ui/                title screen, HUD, pause menu, ...
│
├── scripts/               💻 CODE (.gd GDScript files)
│   ├── main.gd
│   ├── hand_tracking/     camera + hand tracking (HandTracker node)
│   ├── tests/             code for test scenes
│   ├── autoload/          global scripts (game state, save data, audio manager)
│   ├── player/
│   ├── enemies/
│   ├── objects/
│   └── ui/
│
├── assets/                🎨 GAME-READY FILES that Godot loads (see assets/README.md)
│   ├── graphics/
│   │   ├── sprites/
│   │   │   ├── characters/
│   │   │   ├── enemies/
│   │   │   ├── items/
│   │   │   └── effects/   explosions, sparkles, particles
│   │   ├── tilesets/      tiles for building levels
│   │   ├── backgrounds/   parallax layers, skies
│   │   └── ui/            buttons, icons, HUD frames
│   ├── fonts/
│   └── audio/
│       ├── music/
│       └── sfx/
│
├── art_source/            🖌️ WORKING ART FILES (.aseprite, .psd, .kra); Godot ignores this folder
├── addons/                Godot plugins (GDMP = MediaPipe hand tracking)
└── docs/                  design notes, level sketches, to-do lists; Godot ignores this folder
```

**Quick rule:** code goes in `scripts/`, finished graphics go in `assets/graphics/`, and the files you draw in go in `art_source/`.

| I made a... | Put it in |
|---|---|
| GDScript file (`.gd`) | `scripts/<area>/` |
| Scene (`.tscn`) | `scenes/<area>/` |
| Exported sprite / sprite sheet (`.png`) | `assets/graphics/sprites/<type>/` |
| Tileset image | `assets/graphics/tilesets/` |
| Background | `assets/graphics/backgrounds/` |
| Button, icon, menu art | `assets/graphics/ui/` |
| Aseprite / Photoshop / Krita file | `art_source/<same type>/` |
| Song | `assets/audio/music/` (`.ogg` works best) |
| Sound effect | `assets/audio/sfx/` (`.wav` works best) |
| Font | `assets/fonts/` |

### Naming

- Use **lowercase_with_underscores** for every file and folder: `player_run.png`, `guard_patrol.gd`. Mixed case causes "file not found" bugs when a game made on Windows runs on Mac or Linux.
- Give a scene and its script the same name: `scenes/characters/player.tscn` ↔ `scripts/player/player.gd`.
- **Move or rename files inside Godot's FileSystem panel**, not in File Explorer or Finder. Godot fixes the links between scenes and files automatically when you do it inside the editor.

---

## Pixel art settings (already set up)

These are already in `project.godot`, so you don't have to do anything:

- **Game resolution:** 320 × 180, scaled up to a 1280 × 720 window. To change it, go to Project > Project Settings > Display > Window > Viewport Width/Height.
- **Integer scaling**, so pixels stay perfectly square.
- **Nearest-neighbor filtering**, so sprites stay crisp instead of blurry.
- **Pixel snapping**, so sprites don't wobble between pixels.

---

## Working together without breaking things

1. **Pull before you start working.** In GitHub Desktop, click "Fetch origin" and then "Pull". On the command line, run `git pull`.
2. **Commit small and often**, with messages that say what changed: "Add guard walk animation", not "stuff".
3. **Don't edit the same scene (`.tscn`) at the same time as someone else.** Scene files merge badly. Agree in the group chat on who is working on which scene.
4. **Push when you're done:** "Push origin" in GitHub Desktop, or `git push` on the command line.
5. **Never commit the `.godot/` folder.** It's already in `.gitignore`, and Godot rebuilds it on every computer.
6. **Do commit the `.import` and `.uid` files** that Godot creates next to your PNGs, sounds, and scripts. They hold the import settings and keep the links between files working.
