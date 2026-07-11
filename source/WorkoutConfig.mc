import Toybox.Application;
import Toybox.Lang;

// Persisted workout settings for an edge-lifting session.
class WorkoutConfig {

    var sets as Number = 4;         // number of sets
    var reps as Number = 6;         // lifts per set
    var workSecs as Number = 10;    // duration of each lift
    var repRestSecs as Number = 20; // rest between lifts
    var setRestSecs as Number = 120;// rest between sets
    var weightKg as Float = 20.0;   // load on the edge, informational

    function initialize() {
        load();
    }

    function load() as Void {
        sets        = _num("sets", sets);
        reps        = _num("reps", reps);
        workSecs    = _num("workSecs", workSecs);
        repRestSecs = _num("repRestSecs", repRestSecs);
        setRestSecs = _num("setRestSecs", setRestSecs);
        var w = Application.Storage.getValue("weightKg");
        if (w instanceof Float || w instanceof Number) {
            weightKg = w.toFloat();
        }
    }

    function save() as Void {
        Application.Storage.setValue("sets", sets);
        Application.Storage.setValue("reps", reps);
        Application.Storage.setValue("workSecs", workSecs);
        Application.Storage.setValue("repRestSecs", repRestSecs);
        Application.Storage.setValue("setRestSecs", setRestSecs);
        Application.Storage.setValue("weightKg", weightKg);
    }

    private function _num(key as String, dflt as Number) as Number {
        var v = Application.Storage.getValue(key);
        if (v instanceof Number) {
            return v;
        }
        return dflt;
    }
}
