using Shared.Log;
using Shared.Util;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.Timer;
using Toybox.WatchUi as Ui;

class InputHandler extends Ui.BehaviorDelegate {
  const TAG = "InputHandler";
  var view;

  function initialize(view) {
    Ui.BehaviorDelegate.initialize();
    me.view = view;
  }

  hidden function createMenu() {
    var menu = new Ui.Menu2({:title => "Peaks"});
    for (var i = 0; i < view.peaks.size(); i++) {
      var peak = view.peaks[i];
      var elev = peak[:elevation];
      menu.addItem(new Ui.MenuItem(
        peak[:name],
	elev == null ? null : (elev + "m"),
	null,
	{}));
    }
    return menu;
  }

  function onKey(ev) {
    if (ev.getKey() == Ui.KEY_ENTER) {
      if (view.peaks == null) {
	view.getPeaksAtCurrentPosition();
      } else {
        Ui.pushView(
	  createMenu(),
	  new MenuDelegate(),
	  Ui.SLIDE_IMMEDIATE);
      }
      return true;
    }

    return false;
  }

  class MenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
      Ui.Menu2InputDelegate.initialize();
    }

    function onBack() {
      Ui.popView(Ui.SLIDE_IMMEDIATE);
    }
    
    function onSelect(item) {
    }

    function onWrap(key) {
      return true;
    }
  }
}
