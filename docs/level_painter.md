# Level Painter

1. Open a level: `scenes/levels/level_01.tscn` (double-click it in FileSystem), then click 2D at the top.
2. Open the **Level Painter** tab (top right, next to Inspector). If it's not there: Project > Project Settings > Plugins > enable Level Painter.
3. Turn on **Paint**.
4. Pick a type and a picture, then click in the level to place it. Right-click erases. Cmd/Ctrl+Z undoes.
5. Turn Paint off to move, rotate or change things in the Inspector.
6. Save (Cmd/Ctrl+S) and test with Run Current Scene (Cmd+R on Mac, F6 on Windows).

## Types

| Type | What it does |
|---|---|
| Solid | normal bounce |
| Bounce | springy, Rico comes off faster |
| Slide | almost no bounce, Rico slides along it |
| Black hole | pulls Rico in, touching the middle resets |
| UFO | moves back and forth, beam captures Rico, landing on it beats it |
| Goal | the delivery house (only one, so it moves) |
| Rico | where Rico starts (only one, so it moves) |

Solid, Bounce and Slide count as "objects used". Black holes and UFOs don't.

Pictures come from any png in `assets/graphics/`. Add new ones there and click Refresh pictures. "(default)" uses the platform (with its thruster animation) for bouncers and the house for the goal. Rico flies through the platform's flames and bounces off the metal part.

The UFO and black hole don't have art yet, so they're invisible in game. Turn on **Debug > Visible Collision Shapes** (top menu) to see them while testing.

## Settings in the Inspector

- **Level root** (Level01 etc): level name, target time (star 1), max objects (star 2), play area. Star 3 is beating every UFO.
- **Bouncers:** texture, bounce (1 = same speed back), friction (1 = no grip)
- **Black hole:** pull radius, strength, core radius
- **UFO:** travel (how far it goes and comes back), trip time, boost
- **Goal:** texture

## Rules

- The timer only runs while Rico is flying.
- UFO beam, black hole, going off screen, getting stuck or flying more than 15 seconds resets Rico, the UFOs and the counts. The timer just pauses.
- Next level goes to the next number (level_02 > level_03). To add more, duplicate level_10.tscn and call it level_11.tscn.
