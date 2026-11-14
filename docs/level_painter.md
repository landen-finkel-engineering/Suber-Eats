# Level Painter

Build Suber-Out's 10 levels right inside Godot. Pick **what** an object is and **which picture** it uses, then click to place it. Press play to test the level straight away.

---

## Open the painter

1. Open the project in Godot (see the main README).
2. In the **FileSystem** panel (bottom left), open `scenes/levels/` and double-click **`level_01.tscn`**. Levels 1–10 are already there, and each starts with a Start and a Planet.
3. At the top of the editor, click **2D** to see the level. The white box is the 320 × 180 screen. The red box is the play area: if Rico leaves it, he's lost in space.
4. Find the **Level Painter** tab in the top-right panel, next to Inspector and Node.
   - Don't see it? Go to **Project → Project Settings → Plugins** and tick **Enabled** next to *Level Painter*.

## Paint

1. Turn on **Paint mode**.
2. Choose **1. What is it?**:

| Choice | What it does | Counts as an object used? |
|---|---|---|
| **Solid** | Normal surface, normal bounce | Yes, every bounce |
| **Bounce** | Springy: Rico leaves faster than he arrived | Yes |
| **Slide** | Barely bounces and has no grip, so Rico slides along it | Yes |
| **Black hole** | Pulls Rico in within its purple ring. Touching the center resets the attempt. | No |
| **UFO** | Floats back and forth. Its beam captures Rico (reset). Bouncing on top defeats it and boosts Rico. | No (defeats count for star 3) |
| **Planet** | The delivery goal (one per level, so clicking moves it) | — |
| **Start** | Where Rico launches from (one per level, so clicking moves it) | — |

3. Choose **2. Picture**. Every PNG anywhere in `assets/graphics/` is listed, or pick **(placeholder)** for a colored shape.
4. **Click** in the 2D view to place it. **Right-click** an object to erase it. **Cmd+Z / Ctrl+Z** undoes.
5. **Grid snap** lines objects up to an 8-pixel grid. Set it to 0 to place freely.
6. Save with **Cmd+S / Ctrl+S**.

## Adjust objects

Turn **Paint mode off**, then click an object to select it.

- **Move:** drag it. **Rotate:** press E, or use the rotate tool in the toolbar.
- **Fine-tune** in the **Inspector** on the right:

| Object | Settings |
|---|---|
| Solid / Bounce / Slide | **Kind**, **Texture**, **Bounciness** (1.0 = same speed back), **Friction** (1.0 = no slowdown). Under **Collision**: **Round Shape**, plus **Collision Size / Offset** to make the hit box smaller than the picture, for example to leave out a platform's thrusters. |
| Black hole | **Pull Radius**, **Strength**, **Core Radius** |
| UFO | **Travel** (how far it goes and back; the dotted line in the editor), **Trip Time**, **Beam Length / Width**, **Boost Speed** |
| Planet | **Texture**, **Radius** |
| Start | **Pad Texture** |

## Level settings (stars)

Click the top node of the level (for example *Level01*). In the Inspector you'll find:

- **Level Name**: shown in the corner of the screen.
- **Target Time** (star 1): deliver within this many seconds of flying time.
- **Max Objects** (star 2): use this many objects or fewer.
- Star 3 is automatic: defeat every UFO in the level.
- **Background / Background Color**: a 320 × 180 picture, or a color with stars.
- **Play Area**: the red "lost in space" box.

Tip: play the level a few times and see what your own best run scores. Then set Target Time and Max Objects a little above that.

## Test a level

With the level open, press **Run Current Scene**: the clapperboard ▶ button at the top right, or **Cmd+R** on Mac / **F6** on Windows.

- Pinch, pull back, and let go (or hold the mouse and drag).
- The timer only runs while Rico flies. A UFO capture, a black hole, flying off-screen or getting stuck resets Rico, the UFOs and the counts, but the timer just pauses.
- **Esc** opens the pause menu (Resume / Restart level). **C** shows or hides the camera. **M** switches between hand and mouse.
- After a delivery, the results show your stars, with **Next level** and **Try again** buttons.

The ▶ **Run Project** button (Cmd+B / F5) always starts at Level 1.

## Adding pictures

1. Export PNGs at 1× scale into a folder under `assets/graphics/`, for example `assets/graphics/objects/`.
2. Click **Refresh pictures** in the Level Painter.
3. Rico's picture is taken from `assets/graphics/sprites/characters/rico.png`, or from `assets/graphics/unorganized/rico1.png` until that file exists.

## More than 10 levels

In FileSystem, right-click `level_10.tscn`, choose **Duplicate**, and name the copy `level_11.tscn`. **Next level** finds levels by their number automatically.
