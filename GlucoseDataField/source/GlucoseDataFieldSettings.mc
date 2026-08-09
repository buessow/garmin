import Toybox.Lang;

using Toybox.Application.Properties;
using Toybox.WatchUi as Ui;

// Formats an interval property for a menu label. 0 means "let the app work it out" wherever it is
// offered, hence the name instead of "0 s".
function formatIntervalSec(sec as Number) as String {
  return sec == 0 ? "auto" : sec.toString() + " s";
}

// On-device settings, returned by GlucoseDataFieldApp.getSettingsView(). Implementing that method
// is what makes the app appear under Settings > Connect IQ Data Fields on the Edge (and in the
// data field's settings on watches); a settings.xml alone is only editable in Garmin Connect.
//
// It carries the same settings as settings.xml, except the AAPS key, which stays read-only here:
// editing text needs a Ui.TextPicker, which the button-only Edge units don't have. The key is
// pushed by the phone (GmwServer.onPhoneAppMessage) anyway, so it's shown just to check it arrived.
class GlucoseDataFieldSettings extends Ui.Menu2 {
  // Presets offered for the interval settings, in seconds, like the property names and the phone
  // settings. 0 in the override means the interval is derived from the readings received. The
  // current value is shown even when it isn't one of these - the phone can set anything.
  const DELTA_SEC = [ 30, 60, 120, 300 ] as Array<Number>;
  const OVERRIDE_SEC = [ 0, 60, 120, 300, 600 ] as Array<Number>;
  const WAIT_SEC = [ 5, 10, 15, 30, 60 ] as Array<Number>;

  // Positions in the menu, needed by updateItem() when a sub label changes. findItemById() would
  // avoid them but only exists from API 3.4, and the manifest still allows 3.3.1.
  private const DELTA_INDEX = 2;
  private const OVERRIDE_INDEX = 3;
  private const WAIT_INDEX = 4;

  private var deltaItem as Ui.MenuItem;
  private var overrideItem as Ui.MenuItem;
  private var waitItem as Ui.MenuItem;

  function initialize() {
    Menu2.initialize({ :title => Rez.Strings.SettingsTitle });
    deltaItem = new Ui.MenuItem(
        Rez.Strings.GlucoseDeltaSecTitle, intervalLabel("GlucoseDeltaSec", 60), :delta, {});
    overrideItem = new Ui.MenuItem(
        Rez.Strings.GlucoseValueFrequencyOverrideSecTitle,
        intervalLabel("GlucoseValueFrequencyOverrideSec", 0), :override, {});
    waitItem = new Ui.MenuItem(
        Rez.Strings.GlucoseValueWaitSecTitle, intervalLabel("GlucoseValueWaitSec", 5), :wait, {});

    // Both display settings default to on, see Shared/resources/settings/properties.xml.
    addItem(new Ui.ToggleMenuItem(
        Rez.Strings.ShowTotalRemainingInsulin, null, :showTotalRemainingInsulin,
        getBoolean("ShowTotalRemainingInsulin"), {}));
    addItem(new Ui.ToggleMenuItem(
        Rez.Strings.ShowTargetGlucoseInGraph, null, :showTargetGlucoseInGraph,
        getBoolean("ShowTargetGlucoseInGraph"), {}));
    addItem(deltaItem);
    addItem(overrideItem);
    addItem(waitItem);
    // Read-only from here on: the delegate has no case for these ids, so selecting them does
    // nothing. The reading interval is what the app derived from the last readings.
    addItem(new Ui.MenuItem(
        Rez.Strings.GlucoseValueFrequencySecTitle,
        intervalLabel("GlucoseValueFrequencySec", 300), :frequency, {}));
    addItem(new Ui.MenuItem(Rez.Strings.AAPSKeyTitle, keyLabel(), :key, {}));
    addItem(new Ui.MenuItem(Rez.Strings.VersionTitle, BuildInfo.VERSION, :version, {}));
    addItem(new Ui.MenuItem(Rez.Strings.BuildTimeTitle, BuildInfo.BUILD_TIME, :buildTime, {}));
  }

  function refreshDelta() as Void {
    deltaItem.setSubLabel(intervalLabel("GlucoseDeltaSec", 60));
    updateItem(deltaItem, DELTA_INDEX);
  }

  function refreshOverride() as Void {
    overrideItem.setSubLabel(intervalLabel("GlucoseValueFrequencyOverrideSec", 0));
    updateItem(overrideItem, OVERRIDE_INDEX);
  }

  function refreshWait() as Void {
    waitItem.setSubLabel(intervalLabel("GlucoseValueWaitSec", 5));
    updateItem(waitItem, WAIT_INDEX);
  }

  private function intervalLabel(propertyKey as String, defaultSec as Number) as String {
    var value = Properties.getValue(propertyKey);
    return formatIntervalSec(value instanceof Number ? value : defaultSec);
  }

  private function keyLabel() as String {
    var key = Properties.getValue("AAPSKey");
    return key instanceof String && !key.equals("") ? key : "not set";
  }

  private function getBoolean(propertyKey as String) as Boolean {
    var value = Properties.getValue(propertyKey);
    return value instanceof Boolean ? value : true;
  }
}

class GlucoseDataFieldSettingsDelegate extends Ui.Menu2InputDelegate {
  private var menu as GlucoseDataFieldSettings;

  function initialize(menu as GlucoseDataFieldSettings) {
    Ui.Menu2InputDelegate.initialize();
    me.menu = menu;
  }

  function onSelect(item as Ui.MenuItem) as Void {
    switch (item.getId()) {
      case :showTotalRemainingInsulin:
        Properties.setValue("ShowTotalRemainingInsulin", (item as Ui.ToggleMenuItem).isEnabled());
        return;
      case :showTargetGlucoseInGraph:
        Properties.setValue("ShowTargetGlucoseInGraph", (item as Ui.ToggleMenuItem).isEnabled());
        return;
      case :delta:
        pushIntervalMenu(
            Rez.Strings.GlucoseDeltaSecTitle, menu.DELTA_SEC, "GlucoseDeltaSec",
            menu.method(:refreshDelta));
        return;
      case :override:
        pushIntervalMenu(
            Rez.Strings.GlucoseValueFrequencyOverrideSecTitle, menu.OVERRIDE_SEC,
            "GlucoseValueFrequencyOverrideSec", menu.method(:refreshOverride));
        return;
      case :wait:
        pushIntervalMenu(
            Rez.Strings.GlucoseValueWaitSecTitle, menu.WAIT_SEC, "GlucoseValueWaitSec",
            menu.method(:refreshWait));
        return;
    }
  }

  function onBack() as Void {
    Ui.popView(Ui.SLIDE_IMMEDIATE);
  }

  private function pushIntervalMenu(
      title as ResourceId,
      choices as Array<Number>,
      propertyKey as String,
      onChanged as Method() as Void) as Void {
    Ui.pushView(
        new IntervalMenu(title, choices), new IntervalMenuDelegate(propertyKey, onChanged),
        Ui.SLIDE_UP);
  }
}

// A Menu2 of preset intervals, used instead of a Ui.NumberPicker: NumberPicker only offers
// domain-specific modes (distance, weight, time, ...) with no plain seconds mode, and picking from
// a short list is quicker on a bike computer than dialling in an exact value.
class IntervalMenu extends Ui.Menu2 {
  function initialize(title as ResourceId, choices as Array<Number>) {
    Menu2.initialize({ :title => title });
    for (var i = 0; i < choices.size(); i++) {
      addItem(new Ui.MenuItem(formatIntervalSec(choices[i]), null, choices[i], {}));
    }
  }
}

class IntervalMenuDelegate extends Ui.Menu2InputDelegate {
  private var propertyKey as String;
  private var onChanged as Method() as Void;

  function initialize(propertyKey as String, onChanged as Method() as Void) {
    Ui.Menu2InputDelegate.initialize();
    me.propertyKey = propertyKey;
    me.onChanged = onChanged;
  }

  function onSelect(item as Ui.MenuItem) as Void {
    Properties.setValue(propertyKey, item.getId() as Number);
    onChanged.invoke();
    Ui.popView(Ui.SLIDE_DOWN);
  }

  function onBack() as Void {
    Ui.popView(Ui.SLIDE_DOWN);
  }
}
