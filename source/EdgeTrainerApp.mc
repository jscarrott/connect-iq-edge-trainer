import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class EdgeTrainerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var config = new WorkoutConfig();
        return [new StartView(config), new StartDelegate(config)];
    }
}
