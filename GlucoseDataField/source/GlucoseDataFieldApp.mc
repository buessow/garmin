using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Background;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi as Ui;

class GlucoseDataFieldApp extends Application.AppBase {
  hidden const TAG = "GlucoseDataFieldApp";
  hidden var server as Shared.GmwServer or Null;
  hidden var view as GlucoseDataFieldView or Null;

  (:background)
  function initialize() {
    AppBase.initialize();
    Log.i(TAG, "initialize with GmwServer");
    server = new Shared.GmwServer();
    server.wait = true;
  }

  (:background)
  function getServiceDelegate() as Lang.Array<System.ServiceDelegate> {
    Log.i(TAG, "getServiceDelegate");
    return [ server.getServiceDelegate() ];
  }

  function onBackgroundData(result) as Void {
    Log.i(TAG, "onBackgroundData " + result);
    BackgroundScheduler.registered = false;
    if (view == null) {
      view = new GlucoseDataFieldView();
    }
    view.heartRateCollector.reset();
    server.onBackgroundData(result, view.data);
    BackgroundScheduler.backgroundComplete(view.data.glucoseBuffer.getLastDateSec());
  }

  function onStart(state as Lang.Dictionary or Null) as Void {
  }

  function onStop(state as Lang.Dictionary or Null) as Void {
  }

  function getInitialView() as Lang.Array<Ui.Views or Ui.InputDelegates> or Null {
    Properties.setValue("Device", System.getDeviceSettings().partNumber + "_DF");
    view = new GlucoseDataFieldView();
    server.init2();
    BackgroundScheduler.registerTemporalEventIfConnectedIn(new Time.Duration(2));

    Log.i(TAG, "getInitialView - done");
    return [ view ];
  }
}
