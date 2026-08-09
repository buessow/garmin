import Toybox.Lang;

using Shared.Log;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.System;
using Toybox.WatchUi as Ui;

class RoadbookApp extends Application.AppBase {
  private static const TAG = "RoadbookApp";
  private var view as RoadbookView?;

  function initialize() {
    AppBase.initialize();
  }

  function onStart(state as Lang.Dictionary or Null) as Void {
  }

  function onStop(state as Lang.Dictionary or Null) as Void {
  }

  function getInitialView() as [ Ui.Views ] or [ Ui.Views, Ui.InputDelegates ] {
    // Properties.setValue is disallowed from a background-process context (this app declares the
    // Background permission so Shared.HttpClient/Util/Log can be reused, even though it never
    // actually runs a background service) - getInitialView, unlike onStart, only runs foreground.
    Properties.setValue("Device", System.getDeviceSettings().partNumber);
    Properties.setValue("AppVersion", "rb_" + BuildInfo.VERSION);
    Log.i(TAG, "Passcode='" + Properties.getValue("Passcode") + "' ServerUrl='" +
        Properties.getValue("ServerUrl") + "'");
    view = new RoadbookView();
    return [ view, new InputHandler(view) ];
  }
}
