import Toybox.Application;
import Toybox.Lang;

// Indices into a history entry array.
const H_TIME = 0;   // epoch seconds
const H_EDGE = 1;   // index into EDGE_TYPES
const H_TOP = 2;    // heaviest completed lift, kg
const H_E1RM = 3;   // best estimated 1RM (Epley), kg
const H_TUT = 4;    // time under tension, seconds
const H_VOL = 5;    // volume, kg
const H_LIFTS = 6;  // lifts completed
const H_FAILS = 7;  // lifts marked failed
const H_RPE = 8;    // effort 1-10, or -1 if skipped

const H_MAX_ENTRIES = 60;

// Compact per-session summaries persisted on the watch, newest last.
module HistoryLog {

    function add(entry as Array) as Void {
        var hist = get();
        hist.add(entry);
        if (hist.size() > H_MAX_ENTRIES) {
            hist = hist.slice(hist.size() - H_MAX_ENTRIES, null);
        }
        Application.Storage.setValue("history", hist);
    }

    function get() as Array {
        var h = Application.Storage.getValue("history");
        if (h instanceof Array) {
            return h;
        }
        return [];
    }
}
