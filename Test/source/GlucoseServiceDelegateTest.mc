import Toybox.Lang;

using TestLib.Assert;
using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Lang;
using Toybox.Communications as Comm;

// Stands in for Toybox.Communications.makeWebRequest, not for a GlucoseServiceDelegate - it used
// to extend one without ever calling its initialize, which left the parent's fields unset and
// broke as soon as that constructor gained parameters.
class FakeCommunication {
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

  // See DataTest.clearProperty: Properties.ValueType has no Null, so the literal null that used to
  // be passed here is a type error - a nullable variable still clears the property.
  private static function clearProperty(key as String) as Void {
    var none = null as String?;
    Properties.setValue(key, none);
  }

  private static function clearProperties() {
    clearProperty("Device");
    clearProperty("HeartRateStartSec");
    clearProperty("HeartRateLastSec");
    clearProperty("HeartRateAvg");
    clearProperty("AAPSKey");
  }

  // The delegate is built the way production builds it - GmwServer.createServiceDelegate passes
  // its own url/interval/waitSec - so the tests keep exercising that wiring instead of a
  // constructor call of their own that could drift from it again.
  private static function newDelegate(
      comm as FakeCommunication, waitSec as Number?) as Shared.GlucoseServiceDelegate {
    var server = new Shared.GmwServer(10);
    server.waitSec = waitSec;
    var gsd = server.createServiceDelegate();
    gsd.httpClient.makeWebRequest = comm.method(:makeWebRequest);
    return gsd;
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
    Properties.setValue("AppVersion", "3");

    var comm = new FakeCommunication([{"foo" => "bar"}]);
    var gsd = GlucoseServiceDelegateTest.newDelegate(comm, 15);

    var recv = new Receiver();
    gsd.requestBloodGlucose(recv.method(:onResult));

    Assert.equal("http://127.0.0.1:28891/get", comm.url);
    Assert.equal(
        { "hrEnd" => 1000, "hr" => 112, "hrStart" => 880, "device" => "Test23", "from" => 990, 
          "wait" => 15, "manufacturer" => "garmin", "key" => "", "version" => "3"}, 
        comm.parameters);
    Assert.equal({ :method => Comm.HTTP_REQUEST_METHOD_GET}, comm.options);
    Assert.equal(200, recv.result["httpCode"]);
    Assert.equal(null, recv.result["errorMessage"]);
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
    Properties.setValue("AppVersion", "3");
    var comm = new FakeCommunication([400]);
    var gsd = GlucoseServiceDelegateTest.newDelegate(comm, null);

    var recv = new Receiver();
    gsd.requestBloodGlucose(recv.method(:onResult));

    Assert.equal("http://127.0.0.1:28891/get", comm.url);
    Assert.equal(
        {"device" => "Test23", "manufacturer" => "garmin", "from" => 990, "key" => "k1", "version" => "3"}, 
        comm.parameters);
    Assert.equal({ :method => Comm.HTTP_REQUEST_METHOD_GET}, comm.options);
    Assert.equal(400, recv.result["httpCode"]);
    Assert.equal("HTTP400", recv.result["errorMessage"]);

    return true;
  }

  (:test)
  function postCarbs(log) {
    GlucoseServiceDelegateTest.clearProperties();
    
    Util.testNowSec = 1000;
    Application.getApp().clearProperties();
    Properties.setValue("Device", "Test23");
    Properties.setValue("AAPSKey", "k2");
    Properties.setValue("AppVersion", "3");

    var comm = new FakeCommunication([{}]);
    var gsd = GlucoseServiceDelegateTest.newDelegate(comm, null);

    var recv = new Receiver();
    gsd.postCarbs(25, recv.method(:onResult));

    Assert.equal("http://127.0.0.1:28891/carbs", comm.url);
    Assert.equal(
        { "carbs" => 25, "device" => "Test23", "manufacturer" => "garmin", "key" => "k2", "version" => "3"}, 
        comm.parameters);
    Assert.equal({ :method => Comm.HTTP_REQUEST_METHOD_GET}, comm.options);
    Assert.equal(200, recv.result["httpCode"]);
    Assert.equal(null, recv.result["errorMessage"]);

    return true;
  }

  (:test)
  function connectPump(log) {
    GlucoseServiceDelegateTest.clearProperties();
    Util.testNowSec = 1000;
    Application.getApp().clearProperties();
    Properties.setValue("Device", "Test23");
    Properties.setValue("AAPSKey", "k2");
    Properties.setValue("AppVersion", "3");

    var comm = new FakeCommunication([{}]);
    var gsd = GlucoseServiceDelegateTest.newDelegate(comm, null);

    var recv = new Receiver();
    gsd.connectPump(30, recv.method(:onResult));

    Assert.equal("http://127.0.0.1:28891/connect", comm.url);
    Assert.equal(
        { "device" => "Test23", "disconnectMinutes" => 30, "manufacturer" => "garmin", "key" => "k2", "version" => "3"}, 
        comm.parameters);
    Assert.equal({ :method => Comm.HTTP_REQUEST_METHOD_GET}, comm.options);
    Assert.equal(200, recv.result["httpCode"]);
    Assert.equal(null, recv.result["errorMessage"]);

    return true;
  }
}