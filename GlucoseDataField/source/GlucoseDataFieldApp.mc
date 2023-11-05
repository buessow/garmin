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
  private const TAG = "GlucoseDataFieldApp";
  private var server as Shared.GmwServer or Null;
  private var view as LabelView?;
  private var data as Shared.Data?;

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
    return [ new Shared.GlucoseServiceDelegate(server, 111 * 60) ];
  }

  function onBackgroundData(result) as Void {
    Log.i(TAG, "onBackgroundData " + result);
    BackgroundScheduler.registered = false;
    if (data == null) {
      data = new Shared.Data();
    }
    view.heartRateCollector.reset();
    server.onBackgroundData(result, data);
    view.onNewGlucose();
    BackgroundScheduler.backgroundComplete(data.glucoseBuffer.getLastDateSec());
  }

  function onStart(state as Lang.Dictionary or Null) as Void {
  }

  function onStop(state as Lang.Dictionary or Null) as Void {
  }

  function getInitialView() as Lang.Array<Ui.Views or Ui.InputDelegates> or Null {
    Properties.setValue("Device", System.getDeviceSettings().partNumber + "_DF");
    data = new Shared.Data();
    view = new LabelView(data);
    server.init2();
    Background.registerForPhoneAppMessageEvent();
    BackgroundScheduler.registerTemporalEventIfConnectedIn(new Time.Duration(2));

    Log.i(TAG, "getInitialView - done");
    return [ view ];
  }
}
