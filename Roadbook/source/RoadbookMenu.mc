import Toybox.Lang;

using Toybox.WatchUi as Ui;

// The widget's Menu-button entry point. Settings used to open directly; keeping it as a nested
// item leaves the three route-POI views one button press away without losing any configuration.
class RoadbookMenu extends Ui.Menu2 {
  function initialize() {
    Menu2.initialize({ :title => "Roadbook" });
    addItem(new Ui.MenuItem("Water", null, :water, {}));
    addItem(new Ui.MenuItem("Toilet", null, :toilet, {}));
    addItem(new Ui.MenuItem("Restaurant/bar/bakery", null, :food, {}));
    addItem(new Ui.MenuItem("Settings", null, :settings, {}));
  }
}

class RoadbookMenuDelegate extends Ui.Menu2InputDelegate {
  private var view as RoadbookView;

  function initialize(view as RoadbookView) {
    Ui.Menu2InputDelegate.initialize();
    me.view = view;
  }

  function onSelect(item as Ui.MenuItem) as Void {
    switch (item.getId()) {
      case :water:
        view.showPoi("water", "Water");
        Ui.popView(Ui.SLIDE_DOWN);
        return;
      case :toilet:
        view.showPoi("toilet", "Toilets");
        Ui.popView(Ui.SLIDE_DOWN);
        return;
      case :food:
        view.showPoi("food", "Restaurant/bar/bakery");
        Ui.popView(Ui.SLIDE_DOWN);
        return;
      case :settings:
        var settings = new SettingsMenu();
        Ui.pushView(settings, new SettingsMenuDelegate(settings), Ui.SLIDE_UP);
        return;
    }
  }

  function onBack() as Void {
    view.refresh();
    Ui.popView(Ui.SLIDE_DOWN);
  }
}
