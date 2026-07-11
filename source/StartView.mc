import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Launch screen: shows the configured plan, START begins the
// workout, MENU (or long press) opens settings.
class StartView extends WatchUi.View {

    private var _config as WorkoutConfig;

    function initialize(config as WorkoutConfig) {
        View.initialize();
        _config = config;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 10 / 100, Graphics.FONT_MEDIUM, "Edge Trainer",
            Graphics.TEXT_JUSTIFY_CENTER);

        // Plan blocks, one per line (first 4, then "+N more")
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var n = _config.blocks.size();
        var shown = (n > 4) ? 3 : n;
        var y = 24;
        for (var i = 0; i < shown; i++) {
            dc.drawText(cx, h * y / 100, Graphics.FONT_SMALL,
                _config.blockLabel(i), Graphics.TEXT_JUSTIFY_CENTER);
            y += 9;
        }
        if (n > shown) {
            dc.drawText(cx, h * y / 100, Graphics.FONT_SMALL,
                "+" + (n - shown) + " more blocks", Graphics.TEXT_JUSTIFY_CENTER);
            y += 9;
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var timing = _config.workSecs + "s on / " + _config.repRestSecs + "s off";
        dc.drawText(cx, h * (y + 2) / 100, Graphics.FONT_XTINY, timing,
            Graphics.TEXT_JUSTIFY_CENTER);
        var edge = _config.edgeName();
        if (_config.alternateHands) {
            edge += "  L/R";
        }
        dc.drawText(cx, h * (y + 11) / 100, Graphics.FONT_XTINY, edge,
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(cx, h * 86 / 100, Graphics.FONT_XTINY,
            "START to go - MENU for setup", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class StartDelegate extends WatchUi.BehaviorDelegate {

    private var _config as WorkoutConfig;

    function initialize(config as WorkoutConfig) {
        BehaviorDelegate.initialize();
        _config = config;
    }

    function onSelect() as Boolean {
        var engine = new WorkoutEngine(_config);
        WatchUi.pushView(new WorkoutView(engine), new WorkoutDelegate(engine),
            WatchUi.SLIDE_LEFT);
        engine.start();
        return true;
    }

    function onMenu() as Boolean {
        Settings.pushMenu(_config);
        return true;
    }
}
