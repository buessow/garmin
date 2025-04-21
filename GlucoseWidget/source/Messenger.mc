import Toybox.Lang;

using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.Communications as Comm;
using Toybox.Time as Time;
using Toybox.Timer as Timer;
using Toybox.WatchUi as Ui;

class Messenger {
  private static const TAG = "Messenger";
  private static const ALERT_INTERVAL_SEC = 60;

  private const server = new Shared.GmwServer(900);
  private var delegate as Shared.GlucoseServiceDelegate = server.createServiceDelegate();
  var data;
  var view;
  private var lastBloodGlucoseSec = 0;
  private var onGlucose;
  var onCarbsStart;
  var onCarbsDone;
  var onConnectDone;

  (:glance)
  function initialize(data, onGlucose) {
    Log.i(TAG, "init");
    me.data = data;
    me.onGlucose = onGlucose;
    Comm.registerForPhoneAppMessages(method(:onPhoneAppMessage) as Comm.PhoneMessageCallback);
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
    delegate.requestBloodGlucose(method(:onGlucoseResult));
  }

  function onGlucoseResult(result as Dictionary<String, Object>) as Void {
    try {
      Log.i(TAG, "onResult " + result["channel"] + " " + result);
      server.onBackgroundData(result, data);
      if (data.hasValue()) {
        onGlucose.invoke();
        lastBloodGlucoseSec = data.glucoseBuffer.getLastDateSec();
        Complications.updateComplication(
          0,
          { :value => data.getGlucoseStr(),
            :unit => " " + data.getGlucoseUnitStr() }
        );
      }
    } catch (e) {
      e.printStackTrace();
    }
  }

  function onPhoneAppMessage(msg as Comm.PhoneAppMessage) as Void {
    delegate.onPhoneAppMessage2(msg, method(:onGlucoseResult));
  }

  function postCarbs(carbs as Number) {
    delegate.postCarbs(carbs, method(:onPostCarbsResult));
    if (onCarbsStart != null) {
      onCarbsStart.invoke(carbs);
    }
  }

  function onPostCarbsResult(result as Dictionary<String, Object>) as Void {
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

  function onConnectResult(result as Dictionary<String, Object>) as Void {
    if (result["httpCode"] == 200 && onConnectDone != null) {
      data.connected = result["connected"];
      onConnectDone.invoke();
    }
  }
}
