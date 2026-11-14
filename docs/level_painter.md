# Level Painter

1. Open a level: double-click `scenes/levels/level_01.tscn` in FileSystem, then click 2D at the top.
2. Open the **Level Painter** tab (top right). If it's missing: Project > Project Settings > Plugins > enable Level Painter.
3. Turn on **Paint**, pick a type and a picture, click to place. Right-click erases. Cmd/Ctrl+Z undoes.
4. Turn Paint off to move, rotate or edit things in the Inspector.
5. Save (Cmd/Ctrl+S), test with Run Current Scene (Cmd+R / F6).

## Types

| Type | What it does | Counts as a hit? |
|---|---|---|
| Trampoline | launches Rico hard | yes |
| Asteroid belt | a wall (rotate it with E for a ceiling) | yes |
| Car | bounce, sets off the car alarm | yes |
| Black hole | pulls Rico in, the middle spaghettifies him | no |
| UFO | beam lifts Rico up into it (reset), landing on top destroys it | no |
| Goal | the planet with the house on it (only one, so it moves). Set its Hue in the Inspector | |
| Rico | where Rico and his launch pad start (only one, so it moves) | |

## Level Rules tab

The **Level Rules** tab (next to Level Painter) has one row per level. Changes save straight away and only affect that level. They're stored in `data/levels/level_XX.tres`.

- **Time (s):** deliver within this many seconds for the time star
- **Min hits / Max hits:** how many times Rico has to hit objects for the hits star (max 0 = no max)
- **UFOs:** how many UFOs he has to bounce on for the UFO star (-1 = all of them)

Progress (which levels are done, best stars) is saved on the computer and shows on the phone's delivery map: green = done, blue = not yet.
