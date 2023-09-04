using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Toybox.Application;
using Toybox.Background;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi as Ui;

class GlucoseDataFieldApp extends Application.AppBase {
  hidden const TAG = "GlucoseDataFieldApp";
  hidden var server;
  hidden var view;
  hidden var comServer;

  function initialize() {
    AppBase.initialize();
    if (Application.getApp().getProperty("Device") == null) {
      Application.getApp().setProperty(
          "Device", System.getDeviceSettings().partNumber + "_DF");
    }
    if (UserProfile.getProfile().height.toLong() % 2 == 0) {
      Log.i(TAG, "initialize with ComServer");
      server = new Shared.ComServer();
      //server = new Shared.FakeServer();
      comServer = true;
    } else {
      Log.i(TAG, "initialize with GmwServer");
      server = new Shared.GmwServer();
      server.wait = true;
      comServer = false;
    }
  }

  (:background)
  function getServiceDelegate() {
    Log.i(TAG, "getServiceDelegate");
    return [ server.getServiceDelegate() ];
  }

  function onBackgroundData(result) {
    BackgroundScheduler.registered = false;
    if (view == null) {
      view = new GlucoseDataFieldView();
      view.data.comServer = comServer;
    }
    view.heartRateCollector.reset();
    server.onBackgroundData(result, view.data);
    BackgroundScheduler.backgroundComplete(view.data.glucoseBuffer.getLastDateSec());
  }

  function onStart(state) {
  }

  function onStop(state) {
  }

  function getInitialView() {
    view = new GlucoseDataFieldView();
    view.data.comServer = comServer;
    server.init2();
    BackgroundScheduler.registerTemporalEventIfConnectedIn(new Time.Duration(2));

    Log.i(TAG, "getInitialView - done");
    return [ view ];
  }
}
