using Shared.Log;
using Shared.Util;
using Toybox.Lang;
using Toybox.Communications as Comm;
using Toybox.Time as Time;
using Toybox.Timer as Timer;
using Toybox.WatchUi as Ui;

class Messenger {
  hidden static const TAG = "Messenger";
  hidden static const ALERT_INTERVAL_SEC = 60;

  hidden const server = new Shared.GmwServer();
  var data;
  var view;
  hidden var lastBloodGlucoseSec = 0;
  hidden var onGlucose;
  var onCarbsStart;
  var onCarbsDone;
  var onConnectDone;
  private var delegate = new Shared.GlucoseServiceDelegate(server, 900);

  (:glance)
  function initialize(data, onGlucose) {
    Log.i(TAG, "init");
    me.data = data;
    me.onGlucose = onGlucose;
    Comm.registerForPhoneAppMessages(method(:onPhoneAppMessage));
    getGlucose();
    new Timer.Timer().start(method(:onTime), 1000, true);
  }

  function onTime() as Void {
    if (Util.nowSec() % 10 == 0) {
      getGlucose();
    }
    Ui.requestUpdate();
  }

  function getGlucose() {
    delegate.requestBloodGlucose(method(:getGlucoseResult));
  }

  function getGlucoseResult(result) {
    try {
      Log.i(TAG, "onResult " + result["channel"] + " " + result);
      server.onBackgroundData(result, data);
      if (data.hasValue()) {
        onGlucose.invoke();
        lastBloodGlucoseSec = data.glucoseBuffer.getLastDateSec();
      }
    } catch (e) {
      e.printStackTrace();
    }
  }

  function onPhoneAppMessage(msg as Comm.Message) as Void {
    delegate.onPhoneAppMessage2(msg, method(:getGlucoseResult));
  }

  function postCarbs(carbs) {
    delegate.postCarbs(carbs, method(:onPostCarbsResult));
    if (onCarbsStart != null) {
      onCarbsStart.invoke(carbs);
    }
  }

  function onPostCarbsResult(result) {
    if (onCarbsDone != null) {
      onCarbsDone.invoke(result["httpCode"] == 200, result["errorMessage"]);
    }
  }

  function connectPump(disconnectMinutes) {
    if (view != null) {
      view.connecting();
    }
    delegate.connectPump(disconnectMinutes, method(:onConnectResult));
  }

  function onConnectResult(result) {
    if (result["httpCode"] == 200 && onConnectDone != null) {
      data.connected = result["connected"];
      onConnectDone.invoke();
    }
  }
}
