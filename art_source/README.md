# art_source/

Working files for the artists: `.aseprite`, `.ase`, `.psd`, `.kra`, sketches, and reference images.

The `.gdignore` file in this folder tells Godot to **skip this whole folder**, so working files never end up in the game and don't slow down imports.

**Workflow:**
1. Draw in your program and save the file here, e.g. `art_source/characters/player.aseprite`.
2. Export a PNG to the matching game folder, e.g. `assets/graphics/sprites/characters/player_run.png`.
3. Commit both files, so anyone can re-export later.

The subfolders here mirror `assets/graphics/`, so source files are easy to find.
