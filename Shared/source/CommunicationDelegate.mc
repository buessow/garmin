using Shared.Log;
using Toybox.Communications as Comm;
using Toybox.Lang;
using Toybox.System as Sys;

module Shared {

(:background)
class CommunicationDelegate extends Sys.ServiceDelegate {
  static const TAG = "CommunicationDelegate";
  hidden var server as BaseServer or Null = null;
  hidden var data as Lang.Dictionary<Lang.String, Lang.Object> or Null = null;


  function initialize(server) {
    Sys.ServiceDelegate.initialize();
    me.server = server;
  }

  hidden function getNumber(
      data as Lang.Dictionary<Lang.String, Lang.Object> or Null, 
      key as Lang.String) as Lang.Number or Null {
    if (data == null) { return null; }
    var value = data[key];
    if (value != null && value instanceof Lang.Number) {
      return value;
    } else {
      return null;
    }
  }

  hidden function setData(msg as Comm.PhoneAppMessage) as Void {
    if (msg != null && msg has :data && msg.data != null) {
      var tsOld = getNumber(data, "timestamp");
      var tsNew = getNumber(msg.data, "timestamp");
      if (tsOld == null || (tsNew != null && tsOld < tsNew)) {
	      data = msg.data;
	      Log.i(TAG, "setData " + data);
      }
    } else {
      Log.i(TAG, "ignore message, no data");
    }
  }

  function onPhoneAppMessage(msg as Comm.PhoneAppMessage) as Void {
    try {
      Log.i(TAG, "onPhoneAppMessage");
      data = null;
      setData(msg);
      Communications.registerForPhoneAppMessages(method(:onNextMessage));
      handleNewData();
    } catch (e) {
      Log.e(TAG, "onPhoneAppMessage ex: " + (e == null ? "NULL" : e.getErrorMessage()));
      if (e != null) {
        e.printStackTrace();
      }
    }
  }

  hidden function handleNewData() {
    if (data == null) {
      Background.exit(null);
    }
    var cmd = data["command"];
    if ("ping".equals(cmd)) {
      Log.i(TAG, "onPhoneAppMessage sending 'pong'");
      Comm.transmit({ "command" => "pong" }, {}, new Listener(null));
      Background.exit(null);
    } else if ("glucose".equals(cmd)) {
      data["httpCode"] = 200;
      sendHeartRate(data);
    } else {
      Background.exit(null);
    }
  }

  function onNextMessage(msg as Comm.PhoneAppMessage) as Void {
    try {
      Log.i(TAG, "onNextMessage");
      setData(msg);
    } catch (e) {
      Log.e(TAG, "onNextMessage ex: " + (e == null ? "NULL" : e.getErrorMessage()));
      if (e != null) {
        e.printStackTrace();
      }
    }
  }

  function onTemporalEvent() {
    Log.i(TAG, "onTemporalEvent");
    data = null;
    Communications.registerForPhoneAppMessages(method(:onNextMessage));
    if (data == null) {
      requestBloodGlucose();
    } else {
      handleNewData();
    }
  }

  hidden function populateHeartRateHistory(msg as Lang.Dictionary<Lang.String, Lang.Object>) as Void {
    var nowSec = Util.nowSec();
    var startSec = Application.getApp().getProperty("HeartRateStartSec");
    var lastSec = Application.getApp().getProperty("HeartRateLastSec");
    var avg = Application.getApp().getProperty("HeartRateAvg");
    if (startSec != null && lastSec != null && avg != null &&
        avg > 0 && nowSec - lastSec < 300) {
      Log.i(TAG, "HR " + avg);
      msg["hr"] = avg;
      msg["hrStart"] = startSec;
      msg["hrEnd"] = lastSec;
    }
  }

  hidden function requestBloodGlucose() {
    Log.i(TAG, "requestBloodGlucose");
    Comm.transmit({ "command" => "get_glucose" }, {}, new Listener(null));
  }

  hidden function sendHeartRate(exitData) {
    var msg = { 
	      "command" => "heartrate",
        "device" => Application.getApp().getProperty("Device"),
        "manufacturer" => "garmin",
    };
    populateHeartRateHistory(msg);
    Log.i(TAG, "sendHeartRate " + msg);
    Comm.transmit(msg, {}, new Listener(exitData));
  }

  class Listener extends Comm.ConnectionListener {
    hidden var exitData;
    function initialize(exitData) {
      Comm.ConnectionListener.initialize();
      me.exitData = exitData;
    }
    function onComplete() {
      Log.i(CommunicationDelegate.TAG, "onComplete");
      Background.exit(exitData);
    }
    function onError() {
      Log.i(CommunicationDelegate.TAG, "onError: send to app failed");
      Background.exit(exitData);
    }
  }
}
}
