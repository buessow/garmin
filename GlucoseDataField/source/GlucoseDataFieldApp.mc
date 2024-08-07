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
  private var fit as GlucoseFitContributor?;

  (:background)
  function initialize() {
    AppBase.initialize();
    Log.i(TAG, "initialize with GmwServer");
    server = new Shared.GmwServer();
    server.wait = true;
  }

  (:background)
  function getServiceDelegate() as [ System.ServiceDelegate ] {
    Log.i(TAG, "getServiceDelegate");
    return [ new Shared.GlucoseServiceDelegate(server, 111 * 60) ];
  }

  function onBackgroundData(result) as Void {
    Log.i(TAG, "onBackgroundData " + result);
    BackgroundScheduler.registered = false;
    if (data == null) {
      data = new Shared.Data();
    }
    if (view == null) {
      view = new LabelView(data, method(:onTimerStop));
    }
    view.heartRateCollector.reset();
    server.onBackgroundData(result, data);
    view.onNewGlucose();
    if (data.hasValue() && fit != null) {
      fit.onGlucose(data.glucoseBuffer.getLastValue());
    }
    BackgroundScheduler.backgroundComplete(data.glucoseBuffer.getLastDateSec());
  }

  function onStart(state as Lang.Dictionary or Null) as Void {
  }

  function onStop(state as Lang.Dictionary or Null) as Void {
  }

  function onTimerStop() as Void {
    if (fit != null) {
      fit.onTimerStop();
    }
  }

  function getInitialView() as [ Ui.Views ] or [ Ui.Views, Ui.InputDelegates ] {
    Properties.setValue("Device", System.getDeviceSettings().partNumber + "_DF");
    Properties.setValue("AppVersion", "df_" + BuildInfo.VERSION);

    data = new Shared.Data();
    view = new LabelView(data, method(:onTimerStop));
    server.init2();
    fit = new GlucoseFitContributor(view, data.hasValue() ? data.glucoseBuffer.getLastValue() : null);
    Background.registerForPhoneAppMessageEvent();
    BackgroundScheduler.registerTemporalEventIfConnectedIn(new Time.Duration(2));

    Log.i(TAG, "getInitialView - done");
    return [ view ];
  }
}
