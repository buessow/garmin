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
  hidden var comServer;

  function initialize() {
    Log.i(TAG, "initialize");
    AppBase.initialize();
    if (UserProfile.getProfile().height.toLong() % 2 == 0) {
      Log.i(TAG, "initialize with ComServer");
      //server = new Shared.FakeServer();
      server = new Shared.ComServer();
      comServer = true;
    } else {
      Log.i(TAG, "initialize with GmwServer");
      server = new Shared.GmwServer();
      server.wait = true;
      comServer = false;
    }
    if (Application.getApp().getProperty("Device") == null) {
      Application.getApp().setProperty(
          "Device", System.getDeviceSettings().partNumber + "_WF");
    }
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
	data.comServer = comServer;
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
    server.init2();
    Log.i(TAG, "getInitialView");
    if (data == null) {
      data = new Shared.Data();
      data.comServer = comServer;
    }
    view = new GlucoseWatchFaceView(data);
    return [ view ];
  }

  function onSettingsChanged() {
    view.updateSettings();
    Ui.requestUpdate();
  }
}
