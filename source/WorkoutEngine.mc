import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Interval state machine for an edge-lifting workout.
// The configured blocks are flattened into a per-set plan
// ([lifts, weight] per set), then run:
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
    var currentSet as Number = 1;   // 1-based, across all blocks
    var totalSets as Number = 1;
    var currentRep as Number = 1;
    var remaining as Number = PREP_SECS;
    var paused as Boolean = false;
    var saved as Boolean = false;
    var completedLifts as Number = 0;
    var failedLifts as Number = 0;
    var lastLiftFailed as Boolean = false;
    var volumeKg as Float = 0.0;    // sum of weight over finished lifts
    var maxLiftedKg as Float = 0.0; // heaviest completed lift
    var bestE1rm as Float = 0.0;    // best Epley estimate across sets

    private var _setPlan as Array = []; // per set: [lifts, weight kg]
    private var _timer as Timer.Timer;
    private var _session as ActivityRecording.Session?;
    private var _fEdge as FitContributor.Field?;
    private var _fMaxWeight as FitContributor.Field?;
    private var _fLifts as FitContributor.Field?;
    private var _fFailed as FitContributor.Field?;
    private var _fRpe as FitContributor.Field?;
    private var _fVolume as FitContributor.Field?;
    private var _fLapWeight as FitContributor.Field?;
    private var _fTut as FitContributor.Field?;
    private var _fE1rm as FitContributor.Field?;

    function initialize(cfg as WorkoutConfig) {
        config = cfg;
        _timer = new Timer.Timer();
        _setPlan = [];
        for (var i = 0; i < cfg.blocks.size(); i++) {
            var b = cfg.blocks[i];
            for (var s = 0; s < (b[BLOCK_SETS] as Number); s++) {
                _setPlan.add([b[BLOCK_REPS], b[BLOCK_WEIGHT]]);
            }
        }
        totalSets = _setPlan.size();
    }

    function repsThisSet() as Number {
        return _setPlan[currentSet - 1][0] as Number;
    }

    function currentWeight() as Float {
        return _setPlan[currentSet - 1][1] as Float;
    }

    function start() as Void {
        var name = "Edge Lift " + config.edgeName() + " top "
            + config.maxWeight().format("%.1f") + "kg";
        _session = ActivityRecording.createSession({
            :name => name,
            :sport => Activity.SPORT_TRAINING,
            :subSport => Activity.SUB_SPORT_STRENGTH_TRAINING
        });
        _createFitFields();
        _session.start();
        state = STATE_PREP;
        remaining = PREP_SECS;
        _timer.start(method(:onTick), 1000, true);
        _buzz(false);
    }

    private function _createFitFields() as Void {
        var s = _session;
        if (s == null) {
            return;
        }
        _fEdge = s.createField("edge_type", 0, FitContributor.DATA_TYPE_STRING,
            {:count => 16, :mesgType => FitContributor.MESG_TYPE_SESSION});
        _fMaxWeight = s.createField("max_weight", 1, FitContributor.DATA_TYPE_FLOAT,
            {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "kg"});
        _fLifts = s.createField("lifts_completed", 2, FitContributor.DATA_TYPE_UINT16,
            {:mesgType => FitContributor.MESG_TYPE_SESSION});
        _fFailed = s.createField("lifts_failed", 3, FitContributor.DATA_TYPE_UINT16,
            {:mesgType => FitContributor.MESG_TYPE_SESSION});
        _fRpe = s.createField("rpe", 4, FitContributor.DATA_TYPE_FLOAT,
            {:mesgType => FitContributor.MESG_TYPE_SESSION});
        _fVolume = s.createField("volume", 5, FitContributor.DATA_TYPE_FLOAT,
            {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "kg"});
        _fLapWeight = s.createField("weight", 6, FitContributor.DATA_TYPE_FLOAT,
            {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "kg"});
        _fTut = s.createField("tut", 7, FitContributor.DATA_TYPE_UINT16,
            {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "s"});
        _fE1rm = s.createField("e1rm", 8, FitContributor.DATA_TYPE_FLOAT,
            {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "kg"});
        if (_fEdge != null) {
            _fEdge.setData(config.edgeName());
        }
        if (_fMaxWeight != null) {
            _fMaxWeight.setData(config.maxWeight());
        }
        if (_fLapWeight != null) {
            _fLapWeight.setData(currentWeight());
        }
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
            lastLiftFailed = false;
            _buzz(true);
        } else if (state == STATE_WORK) {
            completedLifts += 1;
            var w = currentWeight();
            volumeKg += w;
            if (w > maxLiftedKg) {
                maxLiftedKg = w;
            }
            // Epley e1RM from reps completed so far in this set
            var e1rm = w * (1.0 + currentRep / 30.0);
            if (e1rm > bestE1rm) {
                bestE1rm = e1rm;
            }
            if (currentRep < repsThisSet()) {
                currentRep += 1;
                state = STATE_REST;
                remaining = config.repRestSecs;
                _buzz(false);
            } else if (currentSet < totalSets) {
                if (_session != null) {
                    // lap weight applies to the lap being closed
                    if (_fLapWeight != null) {
                        _fLapWeight.setData(currentWeight());
                    }
                    _session.addLap();
                }
                currentSet += 1;
                currentRep = 1;
                if (_fLapWeight != null) {
                    _fLapWeight.setData(currentWeight());
                }
                state = STATE_SET_REST;
                remaining = config.setRestSecs;
                _buzz(false);
            } else {
                finish();
            }
        }
    }

    // Which hand lifts next/now, or null when not alternating.
    // Lift 1, 3, 5... = left; 2, 4, 6... = right.
    function handLabel() as String? {
        if (!config.alternateHands) {
            return null;
        }
        return (currentRep % 2 == 1) ? "LEFT" : "RIGHT";
    }

    // Toggle the made/failed flag on the most recent lift (during rests).
    function toggleLastLiftFailed() as Void {
        if (completedLifts == 0 || state == STATE_WORK || state == STATE_PREP
                || state == STATE_DONE) {
            return;
        }
        lastLiftFailed = !lastLiftFailed;
        failedLifts += lastLiftFailed ? 1 : -1;
        WatchUi.requestUpdate();
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

    // Stop the workout and ask for RPE; the activity is saved by the
    // picker callbacks via saveSession().
    function finish() as Void {
        _timer.stop();
        state = STATE_DONE;
        paused = false;
        if (_session != null) {
            if (_fLapWeight != null) {
                _fLapWeight.setData(currentWeight());
            }
            _session.stop();
            if (_fLifts != null) {
                _fLifts.setData(completedLifts);
            }
            if (_fFailed != null) {
                _fFailed.setData(failedLifts);
            }
            if (_fVolume != null) {
                _fVolume.setData(volumeKg);
            }
            if (_fTut != null) {
                _fTut.setData(completedLifts * config.workSecs);
            }
            if (_fE1rm != null) {
                _fE1rm.setData(bestE1rm);
            }
            _buzz(true);
            var picker = new NumberPickerView("Effort (RPE)", 7.0, 1.0, 10.0,
                0.5, "");
            WatchUi.pushView(picker, new RpePickerDelegate(picker, self),
                WatchUi.SLIDE_UP);
        }
        WatchUi.requestUpdate();
    }

    // Write the FIT file. rpe of null skips the RPE field.
    function saveSession(rpe as Float?) as Void {
        if (_session != null) {
            if (rpe != null && _fRpe != null) {
                _fRpe.setData(rpe);
            }
            _session.save();
            _session = null;
            saved = true;
            HistoryLog.add([Time.now().value(), config.edgeIdx, maxLiftedKg,
                bestE1rm, completedLifts * config.workSecs, volumeKg,
                completedLifts, failedLifts, (rpe != null) ? rpe : -1.0]);
        }
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

// Confirms (or skips) the post-workout effort rating, then saves.
class RpePickerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NumberPickerView;
    private var _engine as WorkoutEngine;

    function initialize(view as NumberPickerView, engine as WorkoutEngine) {
        BehaviorDelegate.initialize();
        _view = view;
        _engine = engine;
    }

    function onPreviousPage() as Boolean {
        _view.increment();
        return true;
    }

    function onNextPage() as Boolean {
        _view.decrement();
        return true;
    }

    function onSelect() as Boolean {
        _engine.saveSession(_view.value);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    // Skipping the rating still saves the activity.
    function onBack() as Boolean {
        _engine.saveSession(null);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
