# Pinch Test

A small test scene for Suber-Out's launch control. **Pinch** your thumb and index finger, **pull your hand back**, and **let go**. Rico stretches toward your hand while you pull, then launches the opposite way. Hand tracking runs inside Godot through the GDMP plugin (Google MediaPipe), so there's no extra program to start.

No camera? **Hold the left mouse button** to pinch, drag back, and let go.

- Scene: `scenes/tests/pinch_test.tscn` (open it, then click Run Current Scene or press ⌘R / F6)
- Test logic: `scripts/tests/pinch_test.gd`
- Reusable hand tracker: `scripts/hand_tracking/hand_tracker.gd`
- Plugin: `addons/GDMP/` (macOS Apple Silicon + Intel, Windows)

---

## Run it on your Mac, step by step

1. **Get Godot 4.7** (4.4 or newer works) from <https://godotengine.org/download/macos/>. Open the downloaded file and drag **Godot** into **Applications**.
2. **Get the project.** Use GitHub Desktop or `git clone`; don't use "Download ZIP" on the website. macOS blocks plugin files that come from a ZIP (see Troubleshooting).
   - **First time:** in GitHub Desktop, choose File > Clone Repository > URL, paste `https://github.com/landen-finkel-engineering/Suber-Out.git`, and click Clone.
   - **Already cloned:** click **Fetch origin**, then **Pull origin**.
3. **Open it in Godot.** Start Godot, click **Import**, go into the `Suber-Out` folder, pick `project.godot`, and click **Import & Edit**. The first import takes a little while because the plugin is large. If Godot asks to restart, let it.
4. **Run it.** Double-click `scenes/tests/pinch_test.tscn` in FileSystem, then click **Run Current Scene** (clapperboard ▶, top right) or press **⌘ R**.
5. **Allow the camera.** macOS asks whether Godot can use the camera. Click **Allow**.
6. **Wait for the hand model.** The first run downloads the hand model (about 8 MB), so you need internet once. The bottom of the screen says *"Camera on (...). Show your hand!"* when it's ready.
7. **Play.** Hold your hand up so the camera sees it. Pinch, pull back, and let go.

---

## What's on screen

| Where | What it shows |
|---|---|
| Top left | **INPUT** (HAND or MOUSE), **PINCH** (finger gap ÷ hand size; below 0.30 counts as pinched), Rico's state, pull length, your last launch, and bounce/delivery counts |
| Top right | Your mirrored camera view with the tracked hand in green. The line between thumb and index finger turns **yellow** when you're pinching. The white box is the part of the camera view that covers the whole game screen. |
| Bottom | Tracker status, plus the keys |

**Keys:** `R` resets Rico · `C` shows/hides the camera view · `M` switches between hand and mouse

---

## Tuning the feel

Click the **PinchTest** node (top of the Scene panel), and every setting appears in the Inspector with a description. Click **HandTracker** for the tracking settings.

| Setting | What it changes |
|---|---|
| PinchTest > Launch > **Max Pull / Launch Power** | How far you can pull, and how hard Rico flies |
| PinchTest > Launch > **Release Lookback** | Your aim is taken this many seconds before you let go, because opening your fingers wiggles your hand. Raise it if shots go off-target as you release. |
| PinchTest > Grabbing > **Must Pinch Near Rico** | Off: pinching anywhere grabs Rico. On: you have to pinch on him. |
| PinchTest > Grabbing > **Hand Area** | The part of the camera view mapped to the screen. A smaller area means less arm movement. |
| PinchTest > Stretch Look > **Max Stretch / Max Squash** | How rubbery Rico looks while you pull |
| HandTracker > **Pinch On / Pinch Off Ratio** | How tight a pinch has to be to grab, and how wide you have to open to let go |
| HandTracker > **Smoothing** | Less jitter but more lag (higher), or snappier but shakier (lower) |

Changes made in the Inspector apply the next time you run.

---

## Troubleshooting

- **The bottom says "No camera found, or not allowed".** Open System Settings > Privacy & Security > Camera, turn on **Godot**, then quit and reopen Godot.
- **The bottom says "Couldn't download hand model".** You need internet the first time. To skip the download, put `hand_landmarker.task` in `assets/models/`. You can download it [here](https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/hand_landmarker.task).
- **The bottom says "Hand tracking plugin didn't load" / macOS says "libGDMP.macos.dylib" can't be opened.** This happens when the project came from a ZIP download. Fix it in Terminal, replacing the path with where your folder actually is:
  ```bash
  xattr -dr com.apple.quarantine ~/Documents/Suber-Out
  ```
  Then restart Godot.
- **The hand is tracked but the cursor feels cramped or too twitchy.** Adjust **Hand Area** and **Smoothing** (see above).
- **Exported game (not the editor) can't use the camera.** In the macOS export settings, turn on Codesign > Entitlements > Camera, and fill in Privacy > Camera Usage Description.

---

## Using the tracker in the real game

`HandTracker` is a normal node. Add it to any scene and read `hand_visible`, `hand_position` (0-1), `is_pinching` and `pinch_ratio`, or connect to its `pinch_started` / `pinch_ended` signals. `scripts/tests/pinch_test.gd` shows the whole pinch, pull, release flow, including the mouse fallback and the release-lookback trick.

To put the normal main scene back: Project > Project Settings > Application > Run > Main Scene.
