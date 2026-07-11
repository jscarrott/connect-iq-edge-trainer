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
  - load in kg (shown on screen so you can log what you lifted)
- 10 s "get ready" countdown, then a big colour-coded timer:
  green **LIFT**, blue **REST**, with a 3-2-1 vibration heads-up before
  each lift and distinct buzzes for lift start / lift end.
- Records a native activity (Training / Strength) with a lap per set;
  live heart rate is shown during the workout.
- Pause (press START), or press BACK for **Resume / Finish & save /
  Discard**.
- Settings persist between sessions.

Defaults: 4 sets x 6 lifts, 10 s on / 20 s off, 2 min between sets, 20 kg.

## Controls

| Screen   | Input          | Action                          |
|----------|----------------|---------------------------------|
| Start    | START / tap    | begin workout                   |
| Start    | MENU           | open settings                   |
| Workout  | START / tap    | pause / resume                  |
| Workout  | BACK           | pause menu (resume/save/discard)|
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

Supported devices are listed in `manifest.xml` (fenix 6 Pro/7, epix 2,
Forerunner 255/265/745/945/955/965, venu 2/3, vivoactive 4/5,
Instinct 2). Add or remove `<iq:product>` entries as you like — the app
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
