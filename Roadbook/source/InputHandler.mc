import Toybox.Lang;

using Toybox.WatchUi as Ui;

// Overrides the BehaviorDelegate *behaviours* rather than raw keys: edge1030 has no enter key at
// all (only start/lap/menu/esc) and edge530 is button-only with no touchscreen, so neither
// onSelect nor onTap alone covers every target - together they do. onMenu opens the roadbook's
// POI/settings menu; while a POI category is showing, Back returns to the ordinary roadbook.
class InputHandler extends Ui.BehaviorDelegate {
  private var view as RoadbookView;

  function initialize(view as RoadbookView) {
    Ui.BehaviorDelegate.initialize();
    me.view = view;
  }

  // Checked before the POI menu, and before refresh, because right after a download the status line
  // reads "select to start course" - so for that one press Select has to mean what it says, on a
  // POI screen as much as on the roadbook. The offer is one-shot, so the next press goes back to
  // opening the POI menu or refreshing as usual.
  function onSelect() as Boolean {
    if (view.startImportedCourse()) {
      return true;
    }
    if (view.openPoiNavigationMenu()) {
      return true;
    }
    view.refresh();
    return true;
  }

  function onTap(clickEvent as Ui.ClickEvent) as Boolean {
    if (view.startImportedCourse()) {
      return true;
    }
    if (view.openPoiNavigationMenu()) {
      return true;
    }
    view.refresh();
    return true;
  }

  function onMenu() as Boolean {
    var menu = new RoadbookMenu();
    Ui.pushView(menu, new RoadbookMenuDelegate(view), Ui.SLIDE_UP);
    return true;
  }

  function onBack() as Boolean {
    return view.showRoadbook();
  }
}
