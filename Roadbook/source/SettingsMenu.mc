import Toybox.Lang;

using Toybox.Application.Properties;
using Toybox.WatchUi as Ui;

// In-app settings screen, opened via InputHandler.onMenu(). AppBase.getSettingsView() only
// applies to watch faces and data fields (not watch-app, what this is), so there's no
// system-provided settings entry point here - this has to be self-built and self-triggered.
class SettingsMenu extends Ui.Menu2 {
  private var passcodeItem as Ui.MenuItem;
  private var serverUrlItem as Ui.MenuItem;
  private var countItem as Ui.MenuItem;
  private var bufferMeterItem as Ui.MenuItem;
  private var versionItem as Ui.MenuItem;

  function initialize() {
    Menu2.initialize({ :title => "Settings" });
    passcodeItem = new Ui.MenuItem(
        "Passcode", Properties.getValue("Passcode") as String, :passcode, {});
    serverUrlItem = new Ui.MenuItem(
        "Server URL", Properties.getValue("ServerUrl") as String, :serverUrl, {});
    countItem = new Ui.MenuItem(
        "Towns to show", formatCount(Properties.getValue("Count") as Number), :count, {});
    bufferMeterItem = new Ui.MenuItem(
        "Search radius", formatMeter(Properties.getValue("BufferMeter") as Number), :bufferMeter,
        {});
    // Read-only: it has no :onSelect case, so selecting it falls through the switch and does
    // nothing. Shows the manifest version, matching the "version" parameter sent on every request.
    versionItem = new Ui.MenuItem("Version", BuildInfo.VERSION, :version, {});
    addItem(passcodeItem);
    addItem(serverUrlItem);
    addItem(countItem);
    addItem(bufferMeterItem);
    addItem(versionItem);
  }

  function refreshPasscode() as Void {
    passcodeItem.setSubLabel(Properties.getValue("Passcode") as String);
    updateItem(passcodeItem, 0);
  }

  function refreshServerUrl() as Void {
    serverUrlItem.setSubLabel(Properties.getValue("ServerUrl") as String);
    updateItem(serverUrlItem, 1);
  }

  function refreshCount() as Void {
    countItem.setSubLabel(formatCount(Properties.getValue("Count") as Number));
    updateItem(countItem, 2);
  }

  function refreshBufferMeter() as Void {
    bufferMeterItem.setSubLabel(formatMeter(Properties.getValue("BufferMeter") as Number));
    updateItem(bufferMeterItem, 3);
  }

  private function formatCount(count as Number) as String {
    return count.toString() + " towns";
  }

  private function formatMeter(meter as Number) as String {
    return meter.toString() + " m";
  }
}

class SettingsMenuDelegate extends Ui.Menu2InputDelegate {
  private var menu as SettingsMenu;
  private var view as RoadbookView;

  function initialize(menu as SettingsMenu, view as RoadbookView) {
    Ui.Menu2InputDelegate.initialize();
    me.menu = menu;
    me.view = view;
  }

  function onSelect(item as Ui.MenuItem) as Void {
    switch (item.getId()) {
      case :passcode:
        Ui.pushView(
            new Ui.TextPicker(Properties.getValue("Passcode") as String),
            new PropertyTextPickerDelegate("Passcode", method(:onPasscodeChanged)),
            Ui.SLIDE_UP);
        return;
      case :serverUrl:
        Ui.pushView(
            new Ui.TextPicker(Properties.getValue("ServerUrl") as String),
            new PropertyTextPickerDelegate("ServerUrl", method(:onServerUrlChanged)),
            Ui.SLIDE_UP);
        return;
      case :count:
        Ui.pushView(
            new ChoiceMenu("Towns to show", [2, 4, 6, 8, 10], "towns"),
            new ChoiceMenuDelegate("Count", method(:onCountChanged)),
            Ui.SLIDE_UP);
        return;
      case :bufferMeter:
        Ui.pushView(
            new ChoiceMenu("Search radius", [250, 500, 1000, 2000], "m"),
            new ChoiceMenuDelegate("BufferMeter", method(:onBufferMeterChanged)),
            Ui.SLIDE_UP);
        return;
    }
  }

  function onPasscodeChanged() as Void {
    menu.refreshPasscode();
  }

  function onServerUrlChanged() as Void {
    menu.refreshServerUrl();
  }

  function onCountChanged() as Void {
    menu.refreshCount();
  }

  function onBufferMeterChanged() as Void {
    menu.refreshBufferMeter();
  }

  function onBack() as Void {
    view.refresh();
    Ui.popView(Ui.SLIDE_DOWN);
  }
}
