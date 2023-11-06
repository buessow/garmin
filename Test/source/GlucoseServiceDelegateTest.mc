import Toybox.Lang;

using TestLib.Assert;
using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Lang;
using Toybox.Communications as Comm;

class TestServer {
  var url;
  var wait = true;
  function initialize(url) {
    me.url = url;
  }
}

class FakeCommunication extends Shared.GlucoseServiceDelegate {
  private static const TAG1 = "FakeCommunication";
  var url as String? = null;
  var parameters;
  var options;
  var results as Array<Dictionary<String, String> or Number>;
  var i as Number = 0;

  function initialize(results as Array<Dictionary<String, String> or Number>) {
    me.results = results;
  }

  function makeWebRequest(url, parameters, options, callback) {
    Log.i(TAG1, "makeWebRequest");
    me.url = url;
    me.parameters = parameters;
    me.options = options;
    var result = results[i];
    if (result instanceof Dictionary) {
      callback.invoke(200, result);
    } else {
      callback.invoke(result, null);
    }
    i++;
  }
}

class Receiver {
  var result as Dictionary<String, Object> or Null = null;

  function onResult(result as Dictionary<String, Object>) as Void {
    me.result = result;
  }
}

(:test)
class GlucoseServiceDelegateTest {

  private static function clearProperties() {
    Properties.setValue("Device", null);
    Properties.setValue("HeartRateStartSec", null);
    Properties.setValue("HeartRateLastSec", null);
    Properties.setValue("HeartRateAvg", null);
    Properties.setValue("AAPSKey", null);
  }

  (:test)
  function onBloodGlucoseHTTP200(log) {
    GlucoseServiceDelegateTest.clearProperties();
    Util.testNowSec = 1000;
    Properties.setValue("Device", "Test23");
    Properties.setValue("HeartRateStartSec", 880L);
    Properties.setValue("HeartRateLastSec", 1000L);
    Properties.setValue("HeartRateAvg", 112);
    Properties.setValue("AAPSKey", "");

    var server = new Shared.GmwServer();
    server.wait = true;
    var comm = new FakeCommunication([{"foo" => "bar"}]);
    var gsd = new Shared.GlucoseServiceDelegate(server, 10);
    gsd.makeWebRequest = comm.method(:makeWebRequest);
    
    var recv = new Receiver();
    gsd.requestBloodGlucose(recv.method(:onResult));

    Assert.equal("http://127.0.0.1:28891/get", comm.url);
    Assert.equal(
        { "hrEnd" => 1000, "hr" => 112, "hrStart" => 880, "device" => "Test23", "from" => 990, 
          "wait" => 15, "manufacturer" => "garmin", "test" => false, "key" => ""}, 
        comm.parameters);
    Assert.equal({ :method => Comm.HTTP_REQUEST_METHOD_GET}, comm.options);
    Assert.equal(200, recv.result["httpCode"]);
    Assert.equal(null, recv.result["errorMessage"]);
    Assert.equal(1000, recv.result["startTimeSec"]);
    Assert.equal("bar", recv.result["foo"]);

    return true;
  }

  (:test)
  function onBloodGlucoseHTTP400(log) {
    GlucoseServiceDelegateTest.clearProperties();

    Util.testNowSec = 1000;
    Application.getApp().clearProperties();
    Properties.setValue("Device", "Test23");
    Properties.setValue("AAPSKey", "k1");
    var server = new Shared.GmwServer();
    var comm = new FakeCommunication([400]);
    var gsd = new Shared.GlucoseServiceDelegate(server, 10);
    gsd.makeWebRequest = comm.method(:makeWebRequest);
    
    var recv = new Receiver();
    gsd.requestBloodGlucose(recv.method(:onResult));

    Assert.equal("http://127.0.0.1:28891/get", comm.url);
    Assert.equal(
        {"device" => "Test23", "test" => false, "manufacturer" => "garmin", "from" => 990, "key" => "k1"}, 
        comm.parameters);
    Assert.equal({ :method => Comm.HTTP_REQUEST_METHOD_GET}, comm.options);
    Assert.equal(400, recv.result["httpCode"]);
    Assert.equal("HTTP400", recv.result["errorMessage"]);
    Assert.equal(1000, recv.result["startTimeSec"]);

    return true;
  }

  (:test)
  function postCarbs(log) {
    GlucoseServiceDelegateTest.clearProperties();
    
    Util.testNowSec = 1000;
    Application.getApp().clearProperties();
    Properties.setValue("Device", "Test23");
    Properties.setValue("AAPSKey", "k2");

    var server = new Shared.GmwServer();
    var comm = new FakeCommunication([{}]);
    var gsd = new Shared.GlucoseServiceDelegate(server, 10);
    gsd.makeWebRequest = comm.method(:makeWebRequest);
    
    var recv = new Receiver();
    gsd.postCarbs(25, recv.method(:onResult));

    Assert.equal("http://127.0.0.1:28891/carbs", comm.url);
    Assert.equal(
        { "carbs" => 25, "device" => "Test23", "test" => false, "manufacturer" => "garmin", "key" => "k2"}, 
        comm.parameters);
    Assert.equal({ :method => Comm.HTTP_REQUEST_METHOD_GET}, comm.options);
    Assert.equal(200, recv.result["httpCode"]);
    Assert.equal(null, recv.result["errorMessage"]);
    Assert.equal(1000, recv.result["startTimeSec"]);

    return true;
  }

  (:test)
  function connectPump(log) {
    GlucoseServiceDelegateTest.clearProperties();
    Util.testNowSec = 1000;
    Application.getApp().clearProperties();
    Properties.setValue("Device", "Test23");
    Properties.setValue("AAPSKey", "k2");

    var server = new Shared.GmwServer();
    var comm = new FakeCommunication([{}]);
    var gsd = new Shared.GlucoseServiceDelegate(server, 10);
    gsd.makeWebRequest = comm.method(:makeWebRequest);
    
    var recv = new Receiver();
    gsd.connectPump(30, recv.method(:onResult));

    Assert.equal("http://127.0.0.1:28891/connect", comm.url);
    Assert.equal(
        { "device" => "Test23", "disconnectMinutes" => 30, "manufacturer" => "garmin", "test" => false, "key" => "k2"}, 
        comm.parameters);
    Assert.equal({ :method => Comm.HTTP_REQUEST_METHOD_GET}, comm.options);
    Assert.equal(200, recv.result["httpCode"]);
    Assert.equal(null, recv.result["errorMessage"]);
    Assert.equal(1000, recv.result["startTimeSec"]);

    return true;
  }
}