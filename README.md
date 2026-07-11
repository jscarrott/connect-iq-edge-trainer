# Edge Trainer

A Garmin Connect IQ watch app for **edge lifting** (finger-strength block
pulls / no-hang lifting). It guides you through timed lift and rest
intervals, buzzes on every transition so you never have to look at a clock
mid-lift, and records the session to your watch as a strength-training
activity that syncs to Garmin Connect.

## Features

- Configurable protocol, all on-device (no phone needed):
  - sets, lifts per set
  - lift duration, rest between lifts, rest between sets
  - load in kg and edge type (6-30 mm, pinch, sloper)
  - optional alternating left/right hand labelling per lift
- 10 s "get ready" countdown, then a big colour-coded timer:
  green **LIFT**, blue **REST**, with a 3-2-1 vibration heads-up before
  each lift and distinct buzzes for lift start / lift end.
- Records a native activity (Training / Strength) with a lap per set;
  live heart rate is shown during the workout.
- Press DOWN during a rest to mark the last lift **failed** (press again
  to undo); when the workout ends you're asked for an **RPE** (BACK skips
  it), then the activity is saved.
- Pause (press START), or press BACK for **Resume / Finish & save /
  Discard**.
- Settings persist between sessions.

Defaults: 4 sets x 6 lifts, 10 s on / 20 s off, 2 min between sets,
20 kg on a 20 mm edge.

## How sessions are recorded

Each workout is saved as a **Training / Strength** activity. The activity
name embeds the setup, e.g. `Edge Lift 20 mm 24.0kg`, and each set is a
lap. On top of the standard data (duration, HR, calories), these Connect
IQ developer fields are written into the session record of the FIT file:

| Field             | Type    | Notes                        |
|-------------------|---------|------------------------------|
| `edge_type`       | string  | e.g. "20 mm", "Pinch"        |
| `weight`          | float   | kg                           |
| `lifts_completed` | uint16  | total lifts finished         |
| `lifts_failed`    | uint16  | lifts you marked failed      |
| `rpe`             | float   | post-workout effort, 1-10    |

The name is always visible in Garmin Connect; the developer fields live
in the FIT file and are readable by FIT tools (Garmin Connect only
displays developer fields nicely for store-published apps, so for a
sideloaded build treat the activity name as the primary label).

## Controls

| Screen   | Input          | Action                          |
|----------|----------------|---------------------------------|
| Start    | START / tap    | begin workout                   |
| Start    | MENU           | open settings                   |
| Workout  | START / tap    | pause / resume                  |
| Workout  | BACK           | pause menu (resume/save/discard)|
| Workout  | DOWN (in rest) | mark last lift failed / undo    |
| RPE      | UP / DOWN      | adjust, START saves, BACK skips |
| Picker   | UP / DOWN      | change value                    |
| Picker   | START          | confirm                         |

## Building

1. Install the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
   via the SDK Manager, plus the **Monkey C** VS Code extension (it handles
   device downloads and your developer key).
2. Open this folder in VS Code, run **Monkey C: Build for Device** (or
   press F5 to run in the simulator).

   Command line equivalent:

   ```sh
   monkeyc -f monkey.jungle -d fenix7 -y developer_key.der -o bin/EdgeTrainer.prg
   ```

3. Sideload: copy `bin/EdgeTrainer.prg` to the watch's `GARMIN/APPS`
   folder over USB.

Supported devices are listed in `manifest.xml` (fenix 6 Pro/7,
epix 2 / epix 2 Pro, Forerunner 255/265/745/945/955/965, venu 2/3,
vivoactive 4/5, Instinct 2). Add or remove `<iq:product>` entries as you like — the app
uses only API level 3.2 features.

## Project layout

```
manifest.xml              app id, devices, permissions
monkey.jungle             build configuration
source/
  EdgeTrainerApp.mc       app entry point
  WorkoutConfig.mc        persisted settings
  WorkoutEngine.mc        interval state machine + activity recording
  StartView.mc            launch screen
  WorkoutView.mc          live workout screen + pause menu
  SettingsMenu.mc         on-device settings menu
  NumberPickerView.mc     +/- value picker
resources/                strings and launcher icon
```
