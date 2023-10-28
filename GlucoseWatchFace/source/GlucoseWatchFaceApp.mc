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
  hidden var TAG = "GlucoseWatchFaceApp";
  hidden var data;
  hidden var server;
  hidden var view;

  function initialize() {
    Log.i(TAG, "initialize");
    AppBase.initialize();
    server = new Shared.GmwServer();
    server.wait = true;
  }

  function getServiceDelegate() {
    return [ server.getServiceDelegate() ];
  }

  function onBackgroundData(result) {
    try {
      Log.i(TAG, "onBackgroundData server=" + (server!=null).toString()
          + " view=" + (view!=null).toString());
      if (data == null) {
        data = new Shared.Data();
      }
      server.onBackgroundData(result, data);
      BackgroundScheduler.backgroundComplete(view.data.glucoseBuffer.getLastDateSec());
      if (view != null) {
        view.setReadings();
      }
    } catch (e) {
      e.printStackTrace();
      Log.i(
          TAG,
          "onBackgroundData " + Util.ifNull(e.getErrorMessage(), "NULL"));
    }
  }

  function onStart(state) {
    Log.i(TAG, "onStart");
  }

  function onStop(state) {
    Log.i(TAG, "onStop");
  }

  function getInitialView() {
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

  function onSettingsChanged() {
    view.updateSettings();
    Ui.requestUpdate();
  }
}
