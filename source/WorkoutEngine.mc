import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Interval state machine for an edge-lifting workout.
// PREP -> [WORK -> REST]... -> SET_REST -> ... -> DONE
class WorkoutEngine {

    enum State {
        STATE_PREP,
        STATE_WORK,
        STATE_REST,
        STATE_SET_REST,
        STATE_DONE
    }

    const PREP_SECS = 10;

    var config as WorkoutConfig;
    var state as State = STATE_PREP;
    var currentSet as Number = 1;
    var currentRep as Number = 1;
    var remaining as Number = PREP_SECS;
    var paused as Boolean = false;
    var saved as Boolean = false;

    private var _timer as Timer.Timer;
    private var _session as ActivityRecording.Session?;

    function initialize(cfg as WorkoutConfig) {
        config = cfg;
        _timer = new Timer.Timer();
    }

    function start() as Void {
        _session = ActivityRecording.createSession({
            :name => "Edge Lifting",
            :sport => Activity.SPORT_TRAINING,
            :subSport => Activity.SUB_SPORT_STRENGTH_TRAINING
        });
        _session.start();
        state = STATE_PREP;
        remaining = PREP_SECS;
        _timer.start(method(:onTick), 1000, true);
        _buzz(false);
    }

    function onTick() as Void {
        if (paused || state == STATE_DONE) {
            return;
        }
        remaining -= 1;
        if (remaining <= 0) {
            _advance();
        } else if (remaining <= 3 && state != STATE_WORK) {
            // 3-2-1 heads-up before the next lift
            _tickBuzz();
        }
        WatchUi.requestUpdate();
    }

    private function _advance() as Void {
        if (state == STATE_PREP || state == STATE_REST || state == STATE_SET_REST) {
            state = STATE_WORK;
            remaining = config.workSecs;
            _buzz(true);
        } else if (state == STATE_WORK) {
            if (currentRep < config.reps) {
                currentRep += 1;
                state = STATE_REST;
                remaining = config.repRestSecs;
                _buzz(false);
            } else if (currentSet < config.sets) {
                if (_session != null) {
                    _session.addLap();
                }
                currentSet += 1;
                currentRep = 1;
                state = STATE_SET_REST;
                remaining = config.setRestSecs;
                _buzz(false);
            } else {
                finish();
            }
        }
    }

    function togglePause() as Void {
        if (state == STATE_DONE) {
            return;
        }
        paused = !paused;
        if (_session != null) {
            if (paused) {
                _session.stop();
            } else {
                _session.start();
            }
        }
        WatchUi.requestUpdate();
    }

    function pause() as Void {
        if (!paused && state != STATE_DONE) {
            togglePause();
        }
    }

    function resume() as Void {
        if (paused && state != STATE_DONE) {
            togglePause();
        }
    }

    // Stop the workout and save the activity to the watch.
    function finish() as Void {
        _timer.stop();
        state = STATE_DONE;
        paused = false;
        if (_session != null) {
            _session.stop();
            _session.save();
            _session = null;
            saved = true;
        }
        _buzz(true);
        WatchUi.requestUpdate();
    }

    // Stop the workout and throw the recording away.
    function discard() as Void {
        _timer.stop();
        state = STATE_DONE;
        if (_session != null) {
            _session.stop();
            _session.discard();
            _session = null;
        }
    }

    function heartRate() as Number? {
        var info = Activity.getActivityInfo();
        if (info != null) {
            return info.currentHeartRate;
        }
        return null;
    }

    private function _buzz(long as Boolean) as Void {
        if (Attention has :vibrate) {
            var profile;
            if (long) {
                profile = [new Attention.VibeProfile(100, 600)];
            } else {
                profile = [
                    new Attention.VibeProfile(75, 200),
                    new Attention.VibeProfile(0, 150),
                    new Attention.VibeProfile(75, 200)
                ];
            }
            Attention.vibrate(profile);
        }
        if (Attention has :playTone) {
            Attention.playTone(long ? Attention.TONE_STOP : Attention.TONE_START);
        }
    }

    private function _tickBuzz() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
        }
    }
}
