import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Launch screen: shows the configured protocol, START begins the
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
        dc.drawText(cx, h * 15 / 100, Graphics.FONT_MEDIUM, "Edge Trainer",
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var line1 = _config.sets + " sets x " + _config.reps + " lifts";
        var line2 = _config.workSecs + "s on / " + _config.repRestSecs + "s off";
        var line3 = (_config.setRestSecs / 60.0).format("%.1f") + " min between sets";
        var line4 = _config.weightKg.format("%.1f") + " kg";
        dc.drawText(cx, h * 32 / 100, Graphics.FONT_SMALL, line1, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 44 / 100, Graphics.FONT_SMALL, line2, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 56 / 100, Graphics.FONT_SMALL, line3, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 68 / 100, Graphics.FONT_SMALL, line4, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 82 / 100, Graphics.FONT_XTINY, "START to go - MENU for setup",
            Graphics.TEXT_JUSTIFY_CENTER);
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
