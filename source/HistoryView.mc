import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Browsable log of past sessions, newest first. UP/DOWN to move
// between sessions, BACK to exit.
class HistoryView extends WatchUi.View {

    private var _hist as Array;
    private var _idx as Number = 0; // 0 = newest

    function initialize() {
        View.initialize();
        _hist = HistoryLog.get();
    }

    function older() as Void {
        if (_idx < _hist.size() - 1) {
            _idx += 1;
            WatchUi.requestUpdate();
        }
    }

    function newer() as Void {
        if (_idx > 0) {
            _idx -= 1;
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var h = dc.getHeight();

        if (_hist.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 42 / 100, Graphics.FONT_SMALL,
                "No sessions yet", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var e = _hist[_hist.size() - 1 - _idx];
        var info = Gregorian.info(new Time.Moment(e[H_TIME] as Number),
            Time.FORMAT_MEDIUM);
        var title = info.day + " " + info.month + "  ("
            + (_idx + 1) + "/" + _hist.size() + ")";

        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 10 / 100, Graphics.FONT_SMALL, title,
            Graphics.TEXT_JUSTIFY_CENTER);

        var edgeIdx = e[H_EDGE] as Number;
        var edge = (edgeIdx >= 0 && edgeIdx < EDGE_TYPES.size())
            ? EDGE_TYPES[edgeIdx] as String : "?";

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 22 / 100, Graphics.FONT_SMALL,
            edge + "  top " + (e[H_TOP] as Float).format("%.1f") + " kg",
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 33 / 100, Graphics.FONT_SMALL,
            "e1RM " + (e[H_E1RM] as Float).format("%.1f") + " kg",
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 44 / 100, Graphics.FONT_SMALL,
            "TUT " + e[H_TUT] + " s",
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 55 / 100, Graphics.FONT_SMALL,
            "Vol " + (e[H_VOL] as Float).format("%.0f") + " kg",
            Graphics.TEXT_JUSTIFY_CENTER);

        var lifts = e[H_LIFTS] + " lifts";
        if ((e[H_FAILS] as Number) > 0) {
            lifts += ", " + e[H_FAILS] + " failed";
        }
        var rpe = e[H_RPE] as Float;
        if (rpe >= 0) {
            lifts += "  RPE " + rpe.format("%.1f");
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 66 / 100, Graphics.FONT_XTINY, lifts,
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(cx, h * 82 / 100, Graphics.FONT_XTINY,
            "UP / DOWN to browse", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class HistoryDelegate extends WatchUi.BehaviorDelegate {

    private var _view as HistoryView;

    function initialize(view as HistoryView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.older();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.newer();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
