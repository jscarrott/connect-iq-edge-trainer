import Toybox.Lang;
import Toybox.WatchUi;

// On-device settings. "Workout plan" edits the list of building blocks
// (each block = sets x lifts @ weight); the rest are timing/edge options.
module Settings {
    function pushMenu(config as WorkoutConfig) as Void {
        var menu = new WatchUi.Menu2({:title => "Settings"});
        menu.addItem(new WatchUi.MenuItem("Workout plan",
            config.totalSets() + " sets", :plan, null));
        menu.addItem(new WatchUi.MenuItem("Lift time", config.workSecs + " s", :workSecs, null));
        menu.addItem(new WatchUi.MenuItem("Rest between lifts", config.repRestSecs + " s", :repRestSecs, null));
        menu.addItem(new WatchUi.MenuItem("Rest between sets", config.setRestSecs + " s", :setRestSecs, null));
        menu.addItem(new WatchUi.MenuItem("Edge", config.edgeName(), :edge, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Alternate hands", null, :altHands,
            config.alternateHands, null));
        WatchUi.pushView(menu, new SettingsMenuDelegate(config), WatchUi.SLIDE_LEFT);
    }

    // Block list: one row per block plus "Add block". Rebuilt (via
    // switchToView) after any structural change so row ids stay in
    // sync with block indices.
    function buildPlanMenu(config as WorkoutConfig, planItem as WatchUi.MenuItem)
            as [WatchUi.Menu2, PlanMenuDelegate] {
        var menu = new WatchUi.Menu2({:title => "Workout plan"});
        for (var i = 0; i < config.blocks.size(); i++) {
            menu.addItem(new WatchUi.MenuItem("Block " + (i + 1),
                config.blockLabel(i), i, null));
        }
        menu.addItem(new WatchUi.MenuItem("Add block", null, :add, null));
        return [menu, new PlanMenuDelegate(config, planItem)];
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _config as WorkoutConfig;

    function initialize(config as WorkoutConfig) {
        Menu2InputDelegate.initialize();
        _config = config;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :plan) {
            var md = Settings.buildPlanMenu(_config, item);
            WatchUi.pushView(md[0], md[1], WatchUi.SLIDE_LEFT);
        } else if (id == :workSecs) {
            _pick(item, "Lift time", _config.workSecs.toFloat(), 3.0, 60.0, 1.0, " s");
        } else if (id == :repRestSecs) {
            _pick(item, "Rest between lifts", _config.repRestSecs.toFloat(), 5.0, 300.0, 5.0, " s");
        } else if (id == :setRestSecs) {
            _pick(item, "Rest between sets", _config.setRestSecs.toFloat(), 30.0, 600.0, 15.0, " s");
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
        if (id == :workSecs) {
            _config.workSecs = value.toNumber();
            item.setSubLabel(_config.workSecs + " s");
        } else if (id == :repRestSecs) {
            _config.repRestSecs = value.toNumber();
            item.setSubLabel(_config.repRestSecs + " s");
        } else if (id == :setRestSecs) {
            _config.setRestSecs = value.toNumber();
            item.setSubLabel(_config.setRestSecs + " s");
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

class PlanMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _config as WorkoutConfig;
    private var _planItem as WatchUi.MenuItem; // "Workout plan" row in Settings

    function initialize(config as WorkoutConfig, planItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _config = config;
        _planItem = planItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :add) {
            _config.addBlock();
            _config.save();
            _refresh();
        } else if (id instanceof Number) {
            var menu = new WatchUi.Menu2({:title => "Block " + (id + 1)});
            var b = _config.blocks[id];
            menu.addItem(new WatchUi.MenuItem("Sets",
                (b[BLOCK_SETS] as Number).toString(), :bsets, null));
            menu.addItem(new WatchUi.MenuItem("Lifts",
                (b[BLOCK_REPS] as Number).toString(), :breps, null));
            menu.addItem(new WatchUi.MenuItem("Weight",
                (b[BLOCK_WEIGHT] as Float).format("%.1f") + " kg", :bweight, null));
            if (_config.blocks.size() > 1) {
                menu.addItem(new WatchUi.MenuItem("Delete block", null, :bdelete, null));
            }
            WatchUi.pushView(menu,
                new BlockMenuDelegate(_config, id, item, self), WatchUi.SLIDE_LEFT);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    // Rebuild this menu in place after add/delete and refresh the
    // Settings row's set count.
    function _refresh() as Void {
        _planItem.setSubLabel(_config.totalSets() + " sets");
        var md = Settings.buildPlanMenu(_config, _planItem);
        WatchUi.switchToView(md[0], md[1], WatchUi.SLIDE_IMMEDIATE);
    }
}

class BlockMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _config as WorkoutConfig;
    private var _blockIdx as Number;
    private var _blockItem as WatchUi.MenuItem; // row in the plan menu
    private var _planDelegate as PlanMenuDelegate;

    function initialize(config as WorkoutConfig, blockIdx as Number,
            blockItem as WatchUi.MenuItem, planDelegate as PlanMenuDelegate) {
        Menu2InputDelegate.initialize();
        _config = config;
        _blockIdx = blockIdx;
        _blockItem = blockItem;
        _planDelegate = planDelegate;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var b = _config.blocks[_blockIdx];
        if (id == :bsets) {
            _pick(item, "Sets", (b[BLOCK_SETS] as Number).toFloat(), 1.0, 12.0, 1.0, "");
        } else if (id == :breps) {
            _pick(item, "Lifts", (b[BLOCK_REPS] as Number).toFloat(), 1.0, 30.0, 1.0, "");
        } else if (id == :bweight) {
            _pick(item, "Weight", b[BLOCK_WEIGHT] as Float, 0.0, 150.0, 0.5, " kg");
        } else if (id == :bdelete) {
            _config.removeBlock(_blockIdx);
            _config.save();
            // pop this block menu, then rebuild the plan menu beneath
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            _planDelegate._refresh();
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

    function onPicked(item as WatchUi.MenuItem, value as Float) as Void {
        var id = item.getId();
        var b = _config.blocks[_blockIdx];
        if (id == :bsets) {
            b[BLOCK_SETS] = value.toNumber();
            item.setSubLabel((b[BLOCK_SETS] as Number).toString());
        } else if (id == :breps) {
            b[BLOCK_REPS] = value.toNumber();
            item.setSubLabel((b[BLOCK_REPS] as Number).toString());
        } else if (id == :bweight) {
            b[BLOCK_WEIGHT] = value;
            item.setSubLabel(value.format("%.1f") + " kg");
        }
        _config.save();
        _blockItem.setSubLabel(_config.blockLabel(_blockIdx));
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
