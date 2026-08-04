import Toybox.Lang;

using Toybox.WatchUi as Ui;

// Overrides the BehaviorDelegate *behaviours* rather than raw keys: edge1030 has no enter key at
// all (only start/lap/menu/esc) and edge530 is button-only with no touchscreen, so neither
// onSelect nor onTap alone covers every target - together they do. onMenu opens Settings instead:
// there's no system-provided settings entry point for a widget (AppBase.getSettingsView() only
// applies to watch faces/data fields), so this is the self-built substitute.
class InputHandler extends Ui.BehaviorDelegate {
  private var view as NextTownsView;

  function initialize(view as NextTownsView) {
    Ui.BehaviorDelegate.initialize();
    me.view = view;
  }

  function onSelect() as Boolean {
    view.refresh();
    return true;
  }

  function onTap(clickEvent as Ui.ClickEvent) as Boolean {
    view.refresh();
    return true;
  }

  function onMenu() as Boolean {
    var menu = new SettingsMenu();
    Ui.pushView(menu, new SettingsMenuDelegate(menu, view), Ui.SLIDE_UP);
    return true;
  }
}
