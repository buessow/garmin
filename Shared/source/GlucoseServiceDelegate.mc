using Toybox.Background;
using Toybox.Communications as Comm;
using Toybox.Lang;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Time;

module Shared {

(:background, :glance)
class GlucoseServiceDelegate extends System.ServiceDelegate {
  static const TAG = "GlucoseServiceDelegate";
  hidden var server;
  hidden var startTime;
  hidden var methodName;
  hidden var callback;

  hidden function getErrorMessage(code) {
    switch (code) {
      case -1: return "BLE error";
      case -2: return "BLE timeout/h";
      case -3: return "BLE timeout/s";
      case -4: return "BLE no data";
      case -5: return "BLE cancel";
      case -101: return "BLE queue full";
      case -102: return "BLE too large";
      case -103: return "BLE send error";
      case -104: return "BLE no conn";
      case -200: return "inv req header";
      case -201: return "inv req body";
      case -202: return "inv req method";
      case -300: return "net timeout";
      case -400: return "inv resp body";
      case -401: return "inv resp header";
      case -402: return "resp too large";
      case -403: return "resp oom";
      case -1000: return "storage full";
      case -1001: return "sec conn req";
      case -1002: return "bad content type";
      case -1003: return "req cancelled";
      case -1004: return "conn dropped";
      default:
        if (code > 0) {
          return "HTTP";
        } else {
          return "unknown error";
        }
    }
  }

  // Initializes a new instance.
  //
  // @Param url (Toybox.Lang.String)
  //        URL of the request.
  // @Param parameters (Toybox.Lang.Dictionary)
  //        Request/URL parameters. These will be added to the URL
  //        with ? & delemiters.
  function initialize(server) {
    System.ServiceDelegate.initialize();
    me.server = server;
  }

  function onTemporalEvent() {
    Comm.registerForPhoneAppMessages(null);
    requestBloodGlucose(new Lang.Method(Background, :exit));
  }

  hidden function populateHeartRateHistory(parameters) {
    var nowSec = Util.nowSec();
    var startSec = Application.getApp().getProperty("HeartRateStartSec");
    var lastSec = Application.getApp().getProperty("HeartRateLastSec");
    var avg = Application.getApp().getProperty("HeartRateAvg");
    if (startSec != null && lastSec != null && avg != null &&
        avg > 0 && nowSec - lastSec < 300) {
      Log.i(TAG, "HR " + avg);
      parameters["hr"] = avg.toString();
      parameters["hrStart"] = startSec.toString();
      parameters["hrEnd"] = lastSec.toString();
    }
  }

  hidden function post(methodName, callback, parameters) {
    me.methodName = methodName;
    me.callback = callback;
    startTime = Util.nowSec();
    var url = server.url + methodName;
    parameters["device"] = Application.getApp().getProperty("Device");
    parameters["manufacturer"] = "garmin";
    parameters["test"] =  Util.stringEndsWith(parameters["device"], "Sim");

    var stats = System.getSystemStats();
    Log.i(TAG, 
        methodName + " url: " + url + " params: " + parameters
        + " mem avail: " + stats.freeMemory 
	+ " mem total: " + stats.totalMemory);
    try {
      Comm.makeWebRequest(
	  url,
	  parameters,
	  { :method => Communications.HTTP_REQUEST_METHOD_GET },
	  method(:onResult));
    } catch (e) {
      e.printStackTrace();
    }
  }

  function requestBloodGlucose(callback) {
    var parameters = {};
    if (server.wait) {
      parameters["wait"] = "15";
    }
    populateHeartRateHistory(parameters);
    post("get", callback, parameters);
  }

  function onResult(code as Lang.Number, obj as Lang.Dictionary) as Void {
    code = code == null ? 0 : code;
    try {
      onResultImpl(code, obj, methodName, callback);
    } catch (e) {
      Log.e(TAG, "ex: " + (e == null ? "NULL" : e.getErrorMessage()));
      if (e != null) {
        e.printStackTrace();
      }
    }
  }

  hidden function onResultImpl(code, obj, method, callback) {
    Log.i(TAG, method + " " + code + " obj: " + (obj == null ? "NULL" : obj));

    var result = obj instanceof Dictionary ? obj : { "message" => obj };
    result["httpCode"] = code;
    if (code != 200) {
      result["errorMessage"] = getErrorMessage(code);
    }
    result["startTimeSec"] = startTime;
    if (callback != null) {
      callback.invoke(result);
    }
  }

  function postCarbs(carbs, callback) {
    post("carbs", callback, {"carbs" => carbs});
  }

  function connectPump(disconnectMinutes, callback) {
    post("connect", callback, { "disconnectMinutes" => disconnectMinutes });
  }
}}
