import Toybox.Lang;

using Toybox.Application.Properties;
using Toybox.Background;
using Toybox.Communications as Comm;
using Toybox.System;

module Shared {

(:background, :glance)
class GlucoseServiceDelegate extends System.ServiceDelegate {
  private static const TAG = "GlucoseServiceDelegate";
  private var server as GmwServer;
  private var startTime as Number?;
  private var methodName as String?;
  private var callback as (Method(result as Dictionary<String, Object>) as Void)?;
  var makeWebRequest = new Method(Comm, :makeWebRequest);
  private var key = Properties.getValue("AAPSKey");
  private var glucoseValueIntervalSec as Number;

  private function getErrorMessage(code as Number) as String {
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
      case -300: return "Enable Garmin in AAPS config";
      case -400: return "inv resp body";
      case -401: return "inv resp header";
      case -402: return "resp too large";
      case -403: return "resp oom";
      case -1000: return "storage full";
      case -1001: return "sec conn req";
      case -1002: return "bad content type";
      case -1003: return "req cancelled";
      case -1004: return "conn dropped";
      case 404: return "enable Garmin in AAPS config";
      default:
        if (code > 0) {
          return "HTTP" + code;
        } else {
          return "unknown error";
        }
    }
  }

  // Initializes a new instance.
  //
  // @Param url (String)
  //        URL of the request.
  // @Param parameters (Dictionary)
  //        Request/URL parameters. These will be added to the URL
  //        with ? & delemiters.
  function initialize(server as GmwServer, glucoseValueIntervalSec as Number) {
    System.ServiceDelegate.initialize();
    me.glucoseValueIntervalSec = glucoseValueIntervalSec;
    me.server = server;
  }

  function onTemporalEvent() as Void {
    key = Properties.getValue("AAPSKey");
    requestBloodGlucose(new Method(Toybox.Background, :exit));
  }

  private function populateHeartRateHistory(parameters as Dictionary<String, String>) as Void {
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
  }

  private function putIfNotNull(d as Dictionary<String, Object>, k as String, v as Object?) as Void {
    if (v == null) {
      d.remove(k);
    } else {
      d.put(k, v);
    }
  }

  private function get(
      methodName as String, 
      callback as Method(result as Dictionary<String, Object>) as Void, 
      parameters as Dictionary<String, String>) as Void {
    me.methodName = methodName;
    me.callback = callback;
    startTime = Util.nowSec();
    var url = server.url + methodName;
    putIfNotNull(parameters, "device", Properties.getValue("Device"));
    parameters["manufacturer"] = "garmin";
    parameters["test"] = Util.stringEndsWith(parameters["device"], "Sim").toString();
    parameters["key"] = key;
    var stats = System.getSystemStats();
    Log.i(TAG, 
        methodName + " url: " + url + " params: " + parameters
        + " mem avail: " + stats.freeMemory + " mem total: " + stats.totalMemory);
    try {
      makeWebRequest.invoke(
	        url,
	        parameters,
	        { :method => Comm.HTTP_REQUEST_METHOD_GET },
	        method(:onResult));
    } catch (e) {
      e.printStackTrace();
    }
  }

  function requestBloodGlucose(callback as Method(result as Dictionary<String, Object>) as Void) as Void {
    var parameters = {};
    if (server has :wait && server.wait) {
      parameters["wait"] = "15";
    }
    parameters["from"] = Util.nowSec() - glucoseValueIntervalSec;
    populateHeartRateHistory(parameters);
    get("get", callback, parameters);
  }

  function onResult(code as Number, obj) as Void {
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

  private function onResultImpl(
      code as Number, 
      obj, 
      method as String, 
      callback as Method(result as Dictionary<String, Object>) as Void) {
    var result = obj instanceof Dictionary ? obj : { "message" => obj };
    result["httpCode"] = code;
    if (code != 200) {
      Log.i(TAG, "set error " + getErrorMessage(code));
      result["errorMessage"] = getErrorMessage(code);
    }
    result["startTimeSec"] = startTime;
    result["channel"] = "http";
    result["key"] = key;
    
    if (callback != null) {
      callback.invoke(result);
    }
  }

  function postCarbs(
      carbs as Number, 
      callback as Method(result as Dictionary<String, Object>) as Void) {
    get("carbs", callback, {"carbs" => carbs.toString()});
  }

  function connectPump(
      disconnectMinutes as Number, 
      callback as Method(result as Dictionary<String, Object>) as Void) {
    get("connect", callback, { "disconnectMinutes" => disconnectMinutes.toString()});
  }

 function handlePhoneAppMessage(msg as Comm.PhoneAppMessage) as Void {
    if (msg != null && msg has :data && msg.data != null) {
      Log.i(TAG, "handlePhoneAppMessage " + msg.data);
    } else {
      Log.i(TAG, "ignore message, no data");
    }
  }

  function onPhoneAppMessage(msg as Comm.PhoneAppMessage) as Void {
    try {
      msg.data["channel"] = "phoneApp";
      Log.i(TAG, "onPhoneAppMessage " + msg.data);
      
      var timestamp = msg.data["timestamp"];
      if (Util.nowSec() - timestamp > 60) {
        key = msg.data["key"];
        requestBloodGlucose(new Method(Toybox.Background, :exit));
      } else {
        Background.exit(msg.data);
      }
    } catch (e) {
      Log.e(TAG, "onPhoneAppMessage ex: " + (e == null ? "NULL" : e.getErrorMessage()));
      if (e != null) {
        e.printStackTrace();
      }
    }
  }
}}
