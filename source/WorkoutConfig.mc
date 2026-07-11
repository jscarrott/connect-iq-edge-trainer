import Toybox.Application;
import Toybox.Lang;

// Edge choices offered in settings and written into the activity.
const EDGE_TYPES = ["6 mm", "8 mm", "10 mm", "12 mm", "15 mm", "18 mm",
    "20 mm", "25 mm", "30 mm", "Pinch", "Sloper"];

// Persisted workout settings for an edge-lifting session.
class WorkoutConfig {

    var sets as Number = 4;         // number of sets
    var reps as Number = 6;         // lifts per set
    var workSecs as Number = 10;    // duration of each lift
    var repRestSecs as Number = 20; // rest between lifts
    var setRestSecs as Number = 120;// rest between sets
    var weightKg as Float = 20.0;   // load on the edge
    var edgeIdx as Number = 6;      // index into EDGE_TYPES, default 20 mm
    var alternateHands as Boolean = false; // label lifts L/R alternately

    function initialize() {
        load();
    }

    function edgeName() as String {
        return EDGE_TYPES[edgeIdx] as String;
    }

    function load() as Void {
        sets        = _num("sets", sets);
        reps        = _num("reps", reps);
        workSecs    = _num("workSecs", workSecs);
        repRestSecs = _num("repRestSecs", repRestSecs);
        setRestSecs = _num("setRestSecs", setRestSecs);
        edgeIdx     = _num("edgeIdx", edgeIdx);
        if (edgeIdx < 0 || edgeIdx >= EDGE_TYPES.size()) {
            edgeIdx = 6;
        }
        var w = Application.Storage.getValue("weightKg");
        if (w instanceof Float || w instanceof Number) {
            weightKg = w.toFloat();
        }
        var alt = Application.Storage.getValue("alternateHands");
        if (alt instanceof Boolean) {
            alternateHands = alt;
        }
    }

    function save() as Void {
        Application.Storage.setValue("sets", sets);
        Application.Storage.setValue("reps", reps);
        Application.Storage.setValue("workSecs", workSecs);
        Application.Storage.setValue("repRestSecs", repRestSecs);
        Application.Storage.setValue("setRestSecs", setRestSecs);
        Application.Storage.setValue("weightKg", weightKg);
        Application.Storage.setValue("edgeIdx", edgeIdx);
        Application.Storage.setValue("alternateHands", alternateHands);
    }

    private function _num(key as String, dflt as Number) as Number {
        var v = Application.Storage.getValue(key);
        if (v instanceof Number) {
            return v;
        }
        return dflt;
    }
}
