import Toybox.Lang;

using Toybox.Application.Properties;
using Toybox.Background;
using Toybox.Communications as Comm;
using Toybox.System;

module Shared {

(:background, :glance)
class HttpClient {
  private static const TAG = "HttpClient";
  private var url as String;
  private var methodName as String?;
  private var callback as (Method(result as Dictionary<String, Object>) as Void)?;
  var makeWebRequest = new Method(Comm, :makeWebRequest);
  private var httpCode404 as String;

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
      case 404: return httpCode404;
      default:
        if (code > 0) {
          return "HTTP" + code;
        } else {
          return "error " + code;
        }
    }
  }

  // Initializes a new instance.
  //
  // @Param url (String)
  //        Base URL of the request.
  function initialize(url as String, httpCode404 as String) {
    me.url = url;
    me.httpCode404 = httpCode404;
  }

  private function putIfNotNull(d as Dictionary<String, String>, k as String, v as String?) as Void {
    if (v == null) {
      d.remove(k);
    } else {
      d.put(k, v);
    }
  }

  public function get(
      methodName as String,
      callback as Method(result as Dictionary<String, Object>) as Void,
      parameters as Dictionary<String, String>) as Void {
    me.methodName = methodName;
    me.callback = callback;
    var url = me.url + methodName;
    putIfNotNull(parameters, "device", Properties.getValue("Device"));
    parameters["manufacturer"] = "garmin";
    parameters["version"] = Properties.getValue("AppVersion");
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
    result["channel"] = "http";
    if (code != 200) {
      Log.i(TAG, "set error " + getErrorMessage(code));
      result["errorMessage"] = getErrorMessage(code);
    }

    if (callback != null) {
      callback.invoke(result);
    }
  }
}}
