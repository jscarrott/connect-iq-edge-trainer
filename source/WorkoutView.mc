import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Live workout screen: big countdown, phase label, set/rep progress, HR.
class WorkoutView extends WatchUi.View {

    private var _engine as WorkoutEngine;

    function initialize(engine as WorkoutEngine) {
        View.initialize();
        _engine = engine;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var h = dc.getHeight();

        if (_engine.state == WorkoutEngine.STATE_DONE) {
            _drawDone(dc, cx, h);
            return;
        }

        var hand = _engine.handLabel();
        var label;
        var color;
        var subLabel = null;
        if (_engine.state == WorkoutEngine.STATE_PREP) {
            label = "GET READY";
            color = Graphics.COLOR_YELLOW;
        } else if (_engine.state == WorkoutEngine.STATE_WORK) {
            label = (hand != null) ? "LIFT " + hand : "LIFT";
            color = Graphics.COLOR_GREEN;
        } else {
            label = (_engine.state == WorkoutEngine.STATE_SET_REST)
                ? "SET REST" : "REST";
            color = Graphics.COLOR_BLUE;
            if (hand != null) {
                subLabel = "Next: " + hand;
            }
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 12 / 100, Graphics.FONT_MEDIUM, label,
            Graphics.TEXT_JUSTIFY_CENTER);

        // Countdown, mm:ss for long rests, plain seconds otherwise
        var t = _engine.remaining;
        var timeStr;
        if (t >= 60) {
            timeStr = (t / 60) + ":" + (t % 60).format("%02d");
        } else {
            timeStr = t.toString();
        }
        dc.drawText(cx, h * 28 / 100, Graphics.FONT_NUMBER_THAI_HOT, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER);

        if (_engine.lastLiftFailed) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 52 / 100, Graphics.FONT_XTINY, "LAST: FAILED",
                Graphics.TEXT_JUSTIFY_CENTER);
        } else if (subLabel != null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 52 / 100, Graphics.FONT_XTINY, subLabel,
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var progress = "Set " + _engine.currentSet + "/" + _engine.totalSets
            + "  Rep " + _engine.currentRep + "/" + _engine.repsThisSet();
        dc.drawText(cx, h * 62 / 100, Graphics.FONT_SMALL, progress,
            Graphics.TEXT_JUSTIFY_CENTER);

        var hr = _engine.heartRate();
        var bottom = _engine.config.edgeName() + "  "
            + _engine.currentWeight().format("%.1f") + "kg";
        if (hr != null) {
            bottom += "  " + hr + "bpm";
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 74 / 100, Graphics.FONT_SMALL, bottom,
            Graphics.TEXT_JUSTIFY_CENTER);

        if (_engine.paused) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 86 / 100, Graphics.FONT_SMALL, "PAUSED",
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function _drawDone(dc as Dc, cx as Number, h as Number) as Void {
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 16 / 100, Graphics.FONT_LARGE, "DONE!",
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var summary = _engine.config.edgeName() + "  top "
            + _engine.config.maxWeight().format("%.1f") + " kg";
        dc.drawText(cx, h * 36 / 100, Graphics.FONT_SMALL, summary,
            Graphics.TEXT_JUSTIFY_CENTER);
        var lifts = _engine.completedLifts + " lifts";
        if (_engine.failedLifts > 0) {
            lifts += ", " + _engine.failedLifts + " failed";
        }
        lifts += "  " + _engine.volumeKg.format("%.0f") + " kg vol";
        dc.drawText(cx, h * 48 / 100, Graphics.FONT_SMALL, lifts,
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var note = _engine.saved ? "Activity saved" : "Not saved";
        dc.drawText(cx, h * 60 / 100, Graphics.FONT_SMALL, note,
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 76 / 100, Graphics.FONT_XTINY, "BACK to exit",
            Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class WorkoutDelegate extends WatchUi.BehaviorDelegate {

    private var _engine as WorkoutEngine;

    function initialize(engine as WorkoutEngine) {
        BehaviorDelegate.initialize();
        _engine = engine;
    }

    function onSelect() as Boolean {
        _engine.togglePause();
        return true;
    }

    // DOWN during a rest marks the last lift failed (press again to undo).
    function onNextPage() as Boolean {
        _engine.toggleLastLiftFailed();
        return true;
    }

    function onBack() as Boolean {
        if (_engine.state == WorkoutEngine.STATE_DONE) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else {
            _engine.pause();
            var menu = new WatchUi.Menu2({:title => "Paused"});
            menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
            menu.addItem(new WatchUi.MenuItem("Finish & save", null, :finish, null));
            menu.addItem(new WatchUi.MenuItem("Discard", null, :discard, null));
            WatchUi.pushView(menu, new PauseMenuDelegate(_engine), WatchUi.SLIDE_UP);
        }
        return true;
    }
}

class PauseMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _engine as WorkoutEngine;

    function initialize(engine as WorkoutEngine) {
        Menu2InputDelegate.initialize();
        _engine = engine;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :resume) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            _engine.resume();
        } else if (id == :finish) {
            // pop the menu first: finish() pushes the RPE picker on top
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            _engine.finish();
        } else if (id == :discard) {
            _engine.discard();
            // pop the menu and the workout view
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _engine.resume();
    }
}
