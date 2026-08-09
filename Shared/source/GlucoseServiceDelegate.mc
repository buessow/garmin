import Toybox.Lang;

using Toybox.Application.Properties;
using Toybox.Background;
using Toybox.Communications as Comm;
using Toybox.System;

module Shared {

(:background, :glance, :glucose)
class GlucoseServiceDelegate extends System.ServiceDelegate {
  private static const TAG = "GlucoseServiceDelegate";
  private var key = Properties.getValue("AAPSKey");
  private var glucoseValueIntervalSec as Number;
  private var httpClient as HttpClient;
  private var waitSec as Number? = null;

  // Initializes a new instance.
  //
  // @Param url (String)
  //        URL of the request.
  // @Param glucoseValueIntervalSec (Number) for how much time should we retrieve glucose values.
  // @Param waitSec (Number) how long should the server wait to get a new glucose value.
  function initialize(url as String, glucoseValueIntervalSec as Number, waitSec as Number?) {
    System.ServiceDelegate.initialize();
    me.glucoseValueIntervalSec = glucoseValueIntervalSec;
    me.waitSec = waitSec;
    // Same wording for both: for the glucose apps the server is AAPS on the phone, so a 404 and a
    // failure to reach it at all point at the same fix. The timeout case used to be hard-coded to
    // this string inside HttpClient, which meant every other app showed it too.
    me.httpClient = new HttpClient(
        url, "enable Garmin in AAPS config", "enable Garmin in AAPS config");
  }

  function onTemporalEvent() as Void {
    key = Properties.getValue("AAPSKey");
    requestBloodGlucose(
        new Method(Toybox.Background, :exit)
            as (Method(result as Dictionary<String, Object>) as Void));
  }

  private function populateHeartRateHistory(parameters as Dictionary<String, String>) as Void {
    try {
      var nowSec = Util.nowSec();
      var startSec = Properties.getValue("HeartRateStartSec");
      var lastSec = Properties.getValue("HeartRateLastSec");
      var avg = Properties.getValue("HeartRateAvg");
      if (startSec != null && lastSec != null && avg != null &&
          avg > 0 && nowSec - lastSec < 300) {
        Log.i(TAG, "HR " + avg);
        parameters["hr"] = avg.toString();
        parameters["hrStart"] = startSec.toString();
        parameters["hrEnd"] = lastSec.toString();
      }
    } catch (e) {
      e.printStackTrace();
    }
  }

  function requestBloodGlucose(callback as Method(result as Dictionary<String, Object>) as Void) as Void {
    var parameters = {};
    if (waitSec != null) {
      parameters["wait"] = waitSec.toString();
    }
    parameters["from"] = Util.nowSec() - glucoseValueIntervalSec;
    parameters["key"] = key;
    populateHeartRateHistory(parameters);
    httpClient.get("get", callback, parameters);
  }


  function postCarbs(
      carbs as Number,
      callback as Method(result as Dictionary<String, Object>) as Void) {
    httpClient.get("carbs", callback, {"carbs" => carbs.toString()});
  }

  function connectPump(
      disconnectMinutes as Number,
      callback as Method(result as Dictionary<String, Object>) as Void) {
    httpClient.get("connect", callback, { "disconnectMinutes" => disconnectMinutes.toString()});
  }

 function handlePhoneAppMessage(msg as Comm.PhoneAppMessage) as Void {
    if (msg != null && msg has :data && msg.data != null) {
      Log.i(TAG, "handlePhoneAppMessage " + msg.data);
    } else {
      Log.i(TAG, "ignore message, no data");
    }
  }

  function onPhoneAppMessage(msg as Comm.PhoneAppMessage) as Void {
    onPhoneAppMessage2(
        msg,
        new Method(Toybox.Background, :exit)
            as (Method(result as Dictionary<String, Object>) as Void));
  }

  function onPhoneAppMessage2(
    msg as Comm.PhoneAppMessage,
    callback as Method(result as Dictionary<String, Object>) as Void) as Void {
    try {
      var msgData = msg.data instanceof Dictionary
          ? (msg.data as Dictionary<Object, Object>)
          : { "message" => msg.data };
      msgData["channel"] = "phoneApp";
      key = msgData["key"];

      callback.invoke(msgData);
    } catch (e) {
      Log.e(TAG, "onPhoneAppMessage ex: " + (e == null ? "NULL" : e.getErrorMessage()));
      if (e != null) {
        e.printStackTrace();
      }
    }
  }
}}
