using Shared.Log;
using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class TestFace extends Ui.WatchFace {
  function initialize() {
    WatchFace.initialize();
  }
  function onUpdate(dc) {
  }
}

class Main extends App.AppBase {
  hidden const TAG = "Main";

  function initialize() {
    AppBase.initialize();
  }

  function getInitialView() {
    return [ new TestFace() ];
  }
}
