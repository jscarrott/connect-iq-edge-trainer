import Toybox.Lang;
import Toybox.WatchUi;

// On-device settings: each row opens a number picker, edge type opens a
// list, alternate hands is a toggle.
module Settings {
    function pushMenu(config as WorkoutConfig) as Void {
        var menu = new WatchUi.Menu2({:title => "Settings"});
        menu.addItem(new WatchUi.MenuItem("Sets", config.sets.toString(), :sets, null));
        menu.addItem(new WatchUi.MenuItem("Lifts per set", config.reps.toString(), :reps, null));
        menu.addItem(new WatchUi.MenuItem("Lift time", config.workSecs + " s", :workSecs, null));
        menu.addItem(new WatchUi.MenuItem("Rest between lifts", config.repRestSecs + " s", :repRestSecs, null));
        menu.addItem(new WatchUi.MenuItem("Rest between sets", config.setRestSecs + " s", :setRestSecs, null));
        menu.addItem(new WatchUi.MenuItem("Weight", config.weightKg.format("%.1f") + " kg", :weightKg, null));
        menu.addItem(new WatchUi.MenuItem("Edge", config.edgeName(), :edge, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Alternate hands", null, :altHands,
            config.alternateHands, null));
        WatchUi.pushView(menu, new SettingsMenuDelegate(config, menu), WatchUi.SLIDE_LEFT);
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _config as WorkoutConfig;
    private var _menu as WatchUi.Menu2;

    function initialize(config as WorkoutConfig, menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        _config = config;
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :sets) {
            _pick(item, "Sets", _config.sets.toFloat(), 1.0, 12.0, 1.0, "");
        } else if (id == :reps) {
            _pick(item, "Lifts per set", _config.reps.toFloat(), 1.0, 30.0, 1.0, "");
        } else if (id == :workSecs) {
            _pick(item, "Lift time", _config.workSecs.toFloat(), 3.0, 60.0, 1.0, " s");
        } else if (id == :repRestSecs) {
            _pick(item, "Rest between lifts", _config.repRestSecs.toFloat(), 5.0, 300.0, 5.0, " s");
        } else if (id == :setRestSecs) {
            _pick(item, "Rest between sets", _config.setRestSecs.toFloat(), 30.0, 600.0, 15.0, " s");
        } else if (id == :weightKg) {
            _pick(item, "Weight", _config.weightKg, 0.0, 150.0, 0.5, " kg");
        } else if (id == :edge) {
            var menu = new WatchUi.Menu2({:title => "Edge"});
            for (var i = 0; i < EDGE_TYPES.size(); i++) {
                menu.addItem(new WatchUi.MenuItem(EDGE_TYPES[i] as String, null, i, null));
            }
            WatchUi.pushView(menu, new EdgeMenuDelegate(_config, item),
                WatchUi.SLIDE_LEFT);
        } else if (id == :altHands && item instanceof WatchUi.ToggleMenuItem) {
            _config.alternateHands = item.isEnabled();
            _config.save();
        }
    }

    private function _pick(item as WatchUi.MenuItem, title as String,
            value as Float, min as Float, max as Float, step as Float,
            unit as String) as Void {
        var picker = new NumberPickerView(title, value, min, max, step, unit);
        WatchUi.pushView(picker,
            new NumberPickerDelegate(picker, method(:onPicked), item),
            WatchUi.SLIDE_LEFT);
    }

    // Called by the picker delegate when a value is confirmed.
    function onPicked(item as WatchUi.MenuItem, value as Float) as Void {
        var id = item.getId();
        if (id == :sets) {
            _config.sets = value.toNumber();
            item.setSubLabel(_config.sets.toString());
        } else if (id == :reps) {
            _config.reps = value.toNumber();
            item.setSubLabel(_config.reps.toString());
        } else if (id == :workSecs) {
            _config.workSecs = value.toNumber();
            item.setSubLabel(_config.workSecs + " s");
        } else if (id == :repRestSecs) {
            _config.repRestSecs = value.toNumber();
            item.setSubLabel(_config.repRestSecs + " s");
        } else if (id == :setRestSecs) {
            _config.setRestSecs = value.toNumber();
            item.setSubLabel(_config.setRestSecs + " s");
        } else if (id == :weightKg) {
            _config.weightKg = value;
            item.setSubLabel(_config.weightKg.format("%.1f") + " kg");
        }
        _config.save();
    }
}

// Picks one of EDGE_TYPES; the menu item id is the array index.
class EdgeMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _config as WorkoutConfig;
    private var _parentItem as WatchUi.MenuItem;

    function initialize(config as WorkoutConfig, parentItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _config = config;
        _parentItem = parentItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof Number) {
            _config.edgeIdx = id;
            _config.save();
            _parentItem.setSubLabel(_config.edgeName());
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
