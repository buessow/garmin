using TestLib.Assert;
using Shared;
using Shared.Log;
using Shared.Util;

class TestServer {
  var url;
  var parameters;
  function initialize(url, parameters) {
    me.url = url;
    me.parameters = parameters;
  }
}

class FakeGlucoseServiceDelegate extends Shared.GlucoseServiceDelegate {
  hidden static const TAG1 = "FakeGlucoseServiceDelegate";
  var result;
  var url1;
  var parameters1;
  var options;
  var resultCodes;
  var i = 0;

  function initialize(url, parameters) {
    GlucoseServiceDelegate.initialize(new TestServer(url, parameters));
    callback = method(:testExit);
  }

  function makeWebRequest1(url, parameters, options, callback) {
    Log.i(TAG1, "makeWebRequest");
    me.url1 = url;
    me.parameters1 = parameters;
    me.options = options;
    i++;
    callback.invoke(
        resultCodes[(i-1) % resultCodes.size()],
        {"foo" => "bar"});
  }

  function testExit(result) {
    Log.i(TAG1, "exit");
    me.result = result;
  }
}

(:test)
class GlucoseServiceDelegateTest {
  (:test)
  function onTemporalEvent(log) {
    try {
      var gsd = new FakeGlucoseServiceDelegate("http://foo", {"x"=>11});
      gsd.resultCodes = [200];
      gsd.onTemporalEvent();
      Assert.equal("http://foo", gsd.url1);
      Assert.equal(11, gsd.parameters1["x"]);
      Assert.equal(200, gsd.result["httpCode"]);
      return true;
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  function onSleepEvent(log) {
    try {
      var gsd = new FakeGlucoseServiceDelegate("http://foo", {"x"=>11});
      gsd.resultCodes = [200];
      gsd.onSleepEvent();
      Assert.equal("http://foo", gsd.url1);
      Assert.equal(11, gsd.parameters1["x"]);
      Assert.equal(200, gsd.result["httpCode"]);
      return true;
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  function onWakeEvent(log) {
    try {
      var gsd = new FakeGlucoseServiceDelegate("http://foo", {"x"=>11});
      gsd.resultCodes = [200];
      gsd.onWakeEvent();
      Assert.equal("http://foo", gsd.url1);
      Assert.equal(11, gsd.parameters1["x"]);
      Assert.equal(200, gsd.result["httpCode"]);
      return true;
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  function onBloodGlucoseHTTP200(log) {
    try {
      Util.testNowSec = 1000;
      var gsd = new FakeGlucoseServiceDelegate("http://foo", {});
      gsd.resultCodes = [200];
      gsd.onTemporalEvent();
      gsd.onBloodGlucose(200, { "foo" => "bar" });
      Assert.equal(1, gsd.attempts);
      Assert.equal(true, gsd.result != null);
      Assert.equal(200, gsd.result["httpCode"]);
      Assert.equal(null, gsd.result["errorMessage"]);
      Assert.equal(1000, gsd.result["startTimeSec"]);
      //Assert.equal(true, gsd.result["message"] instanceof Lang.Dictionary);
      Assert.equal("bar", gsd.result["foo"]);

      return true;
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

//  (:test)
//  function onBloodGlucoseHTTP400(log) {
//    try {
//      Util.testNowSecIdx = 0;
//      Util.testNowSec = [1000, 1000, 1010, 1025, 1030, 1050];
//      var gsd = new FakeGlucoseServiceDelegate("http://foo", {});
//      gsd.retry = true;
//      gsd.resultCodes = [400];
//      gsd.onTemporalEvent();
//      Assert.equal(2, gsd.attempts);
//      Assert.equal(true, gsd.result != null);
//      Assert.equal(400, gsd.result["httpCode"]);
//      Assert.equal("HTTP", gsd.result["errorMessage"]);
//      Assert.equal(1000, gsd.result["startTimeSec"]);
//
//      return true;
//    } catch (e) {
//      log.error(e.getErrorMessage());
//      e.printStackTrace();
//      throw e;
//    }
//  }
//
//  (:test)
//  function onBloodGlucoseHTTP400And200(log) {
//    try {
//      Util.testNowSecIdx = 0;
//      Util.testNowSec = [1000, 1000, 1010, 1020, 1030, 1050];
//      var gsd = new FakeGlucoseServiceDelegate("http://foo", {});
//      gsd.retry = true;
//      gsd.resultCodes = [400, 200];
//      gsd.onTemporalEvent();
//      Assert.equal(2, gsd.attempts);
//      Assert.equal(true, gsd.result != null);
//      Assert.equal(200, gsd.result["httpCode"]);
//      Assert.equal("HTTP", gsd.result["errorMessage"]);
//      Assert.equal(1000, gsd.result["startTimeSec"]);
//
//      return true;
//    } catch (e) {
//      log.error(e.getErrorMessage());
//      e.printStackTrace();
//      throw e;
//    }
//  }

}