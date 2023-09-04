using Shared.Log;
using Toybox.Communications as Comm;
using Toybox.System as Sys;

module Shared {

(:background)
class CommunicationDelegate extends Sys.ServiceDelegate {
  static const TAG = "CommunicationDelegate";
  hidden var server = null;
  hidden var data = null;


  function initialize(server) {
    Sys.ServiceDelegate.initialize();
    me.server = server;
  }

  hidden function setData(msg) {
    if (msg != null && msg has :data && msg.data != null) {
      if (data == null || 
          Util.ifNull(data["timestamp"], 0) < Util.ifNull(msg.data["timestamp"], 1)) {
	data = msg.data;
	Log.i(TAG, "setData " + data);
      }
    } else {
      Log.i(TAG, "ignore message, no data");
    }
  }

  function onPhoneAppMessage(msg) {
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
      Comm.transmit({ "command" => "pong" }, {}, new Listener());
      Background.exit(null);
    } else if ("glucose".equals(cmd)) {
      data["httpCode"] = 200;
      sendHeartRate(data);
    } else {
      Background.exit(null);
    }
  }

  function onNextMessage(msg) {
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

  hidden function populateHeartRateHistory(msg) {
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
