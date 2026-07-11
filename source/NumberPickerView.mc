import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Simple +/- value picker. UP/DOWN (or swipe) adjusts, SELECT confirms,
// BACK cancels.
class NumberPickerView extends WatchUi.View {

    var value as Float;
    var min as Float;
    var max as Float;
    var step as Float;

    private var _title as String;
    private var _unit as String;

    function initialize(title as String, initial as Float, minV as Float,
            maxV as Float, stepV as Float, unit as String) {
        View.initialize();
        _title = title;
        value = initial;
        min = minV;
        max = maxV;
        step = stepV;
        _unit = unit;
    }

    function increment() as Void {
        value += step;
        if (value > max) {
            value = max;
        }
        WatchUi.requestUpdate();
    }

    function decrement() as Void {
        value -= step;
        if (value < min) {
            value = min;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 15 / 100, Graphics.FONT_SMALL, _title,
            Graphics.TEXT_JUSTIFY_CENTER);

        var str;
        if (step >= 1.0 && value.toNumber().toFloat() == value) {
            str = value.toNumber().toString();
        } else {
            str = value.format("%.1f");
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 35 / 100, Graphics.FONT_NUMBER_HOT, str + _unit,
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 72 / 100, Graphics.FONT_XTINY,
            "UP / DOWN to change", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 82 / 100, Graphics.FONT_XTINY,
            "START to confirm", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class NumberPickerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NumberPickerView;
    private var _callback as Method(item as WatchUi.MenuItem, value as Float) as Void;
    private var _item as WatchUi.MenuItem;

    function initialize(view as NumberPickerView,
            callback as Method(item as WatchUi.MenuItem, value as Float) as Void,
            item as WatchUi.MenuItem) {
        BehaviorDelegate.initialize();
        _view = view;
        _callback = callback;
        _item = item;
    }

    // UP key / swipe down
    function onPreviousPage() as Boolean {
        _view.increment();
        return true;
    }

    // DOWN key / swipe up
    function onNextPage() as Boolean {
        _view.decrement();
        return true;
    }

    function onSelect() as Boolean {
        _callback.invoke(_item, _view.value);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
