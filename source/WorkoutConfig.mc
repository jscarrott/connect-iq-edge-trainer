import Toybox.Application;
import Toybox.Lang;

// Edge choices offered in settings and written into the activity.
const EDGE_TYPES = ["6 mm", "8 mm", "10 mm", "12 mm", "15 mm", "18 mm",
    "20 mm", "25 mm", "30 mm", "Pinch", "Sloper"];

// Indices into a block array: [sets, lifts, weight kg]
const BLOCK_SETS = 0;
const BLOCK_REPS = 1;
const BLOCK_WEIGHT = 2;

// Persisted workout settings for an edge-lifting session.
// The workout plan is an ordered list of blocks; each block is
// [sets, lifts per set, weight kg], so building pyramids like
// 2x12@40, 1x8@55, 1x4@65, 1x4@70 are first-class.
class WorkoutConfig {

    var blocks as Array = [
        [2, 12, 40.0],
        [1, 8, 55.0],
        [1, 4, 65.0],
        [1, 4, 70.0]
    ];
    var workSecs as Number = 10;    // duration of each lift
    var repRestSecs as Number = 20; // rest between lifts
    var setRestSecs as Number = 120;// rest between sets
    var edgeIdx as Number = 6;      // index into EDGE_TYPES, default 20 mm
    var alternateHands as Boolean = false; // label lifts L/R alternately

    function initialize() {
        load();
    }

    function edgeName() as String {
        return EDGE_TYPES[edgeIdx] as String;
    }

    function totalSets() as Number {
        var n = 0;
        for (var i = 0; i < blocks.size(); i++) {
            n += blocks[i][BLOCK_SETS] as Number;
        }
        return n;
    }

    function maxWeight() as Float {
        var w = 0.0;
        for (var i = 0; i < blocks.size(); i++) {
            var bw = blocks[i][BLOCK_WEIGHT] as Float;
            if (bw > w) {
                w = bw;
            }
        }
        return w;
    }

    // "2 x 12 @ 40.0 kg"
    function blockLabel(i as Number) as String {
        var b = blocks[i];
        return b[BLOCK_SETS] + " x " + b[BLOCK_REPS] + " @ "
            + (b[BLOCK_WEIGHT] as Float).format("%.1f") + " kg";
    }

    function removeBlock(i as Number) as Void {
        if (blocks.size() <= 1) {
            return;
        }
        var nb = [];
        for (var j = 0; j < blocks.size(); j++) {
            if (j != i) {
                nb.add(blocks[j]);
            }
        }
        blocks = nb;
    }

    function addBlock() as Void {
        var last = blocks[blocks.size() - 1];
        blocks.add([last[BLOCK_SETS], last[BLOCK_REPS], last[BLOCK_WEIGHT]]);
    }

    function load() as Void {
        workSecs    = _num("workSecs", workSecs);
        repRestSecs = _num("repRestSecs", repRestSecs);
        setRestSecs = _num("setRestSecs", setRestSecs);
        edgeIdx     = _num("edgeIdx", edgeIdx);
        if (edgeIdx < 0 || edgeIdx >= EDGE_TYPES.size()) {
            edgeIdx = 6;
        }
        var alt = Application.Storage.getValue("alternateHands");
        if (alt instanceof Boolean) {
            alternateHands = alt;
        }
        var b = Application.Storage.getValue("blocks");
        if (b instanceof Array && b.size() > 0) {
            var ok = true;
            for (var i = 0; i < b.size(); i++) {
                var e = b[i];
                if (!(e instanceof Array) || e.size() != 3
                        || !(e[BLOCK_SETS] instanceof Number)
                        || !(e[BLOCK_REPS] instanceof Number)) {
                    ok = false;
                    break;
                }
            }
            if (ok) {
                blocks = b;
                for (var i = 0; i < blocks.size(); i++) {
                    blocks[i][BLOCK_WEIGHT] =
                        (blocks[i][BLOCK_WEIGHT] as Numeric).toFloat();
                }
            }
        }
    }

    function save() as Void {
        Application.Storage.setValue("blocks", blocks);
        Application.Storage.setValue("workSecs", workSecs);
        Application.Storage.setValue("repRestSecs", repRestSecs);
        Application.Storage.setValue("setRestSecs", setRestSecs);
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
