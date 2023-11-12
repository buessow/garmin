import Toybox.Lang;

using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Shared.Util;
using Toybox.Application;
using Toybox.Background;
using Toybox.Time;
using Toybox.WatchUi as Ui;

(:background)
class GlucoseWatchFaceApp extends Application.AppBase {
  private var TAG = "GlucoseWatchFaceApp";
  private var data;
  private var server;
  private var view;

  function initialize() {
    Log.i(TAG, "initialize");
    AppBase.initialize();
    server = new Shared.GmwServer();
    server.wait = true;
  }

  function getServiceDelegate() {
    return [ new Shared.GlucoseServiceDelegate(server, 2 * 3600 - 9 * 60) ];
  }

  function onBackgroundData(result) {
    try {
      Log.i(TAG, "onBackgroundData " + result);
      if (data == null) {
        data = new Shared.Data();
      }
      server.onBackgroundData(result, data);
      BackgroundScheduler.backgroundComplete(data.glucoseBuffer.getLastDateSec());
      if (view != null) {
        view.setReadings();
      }
    } catch (e) {
      e.printStackTrace();
      Log.i(TAG, "onBackgroundData " + Util.ifNull(e.getErrorMessage(), "NULL"));
    }
  }

  function onStart(state) as Void {
    Log.i(TAG, "onStart");
  }

  function onStop(state) as Void {
    Log.i(TAG, "onStop");
  }

  function getInitialView() as Array<Ui.Views or Ui.InputDelegates> or Null {
    Background.registerForPhoneAppMessageEvent();
    Properties.setValue("Device", System.getDeviceSettings().partNumber + "_WF");
    server.init2();
    Log.i(TAG, "getInitialView");
    if (data == null) {
      data = new Shared.Data();
    }
    view = new GlucoseWatchFaceView(data);
    return [ view ];
  }

  function getSettingsView() as Array<Ui.Views or Ui.InputDelegates> or Null{
    Log.i(TAG, "getSettingsView");
    return new GlucoseWatchFaceSettings().get();
  }

  function onSettingsChanged() {
    view.updateSettings();
    Ui.requestUpdate();
  }
}
