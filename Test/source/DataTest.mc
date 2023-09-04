using TestLib.Assert;
using Toybox.Time;
using Shared;
using Shared.Util;

(:Test)
class DataTest {
  (:test)
  function noValueSet(log) {
    try {
      var d = new Shared.Data();
      Assert.equal(false, d.hasValue());
      Assert.equal("-", d.getGlucoseStr());
      Assert.equal(Shared.Data.mgdl, d.glucoseUnit);
      Assert.equal("_:__", d.getGlucoseAgeStr());
      Assert.equal("+_.__", d.getGlucoseDeltaPerMinuteStr());
      Assert.equal("no value", d.errorMessage);
      Assert.equal("iob -", d.getRemainingInsulinStr());
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
    return true;
  }

  (:test)
  function singleValueMgdl(log) {
    try {
      Util.testNowSec = 1010;
      var buffer = new Shared.DateValues(null, 10);
      buffer.add(new Shared.DateValue(1000, 123));
      var d = new Shared.Data();
      d.setGlucose(buffer);
      d.setRemainingInsulin(3.366);

      Assert.equal(true, d.hasValue());
      Assert.equal("123", d.getGlucoseStr());
      Assert.equal(Shared.Data.mgdl, d.glucoseUnit);
      Assert.equal("0:10", d.getGlucoseAgeStr());
      Assert.equal("+_.__", d.getGlucoseDeltaPerMinuteStr());
      Assert.equal(null, d.errorMessage);
      Assert.equal("iob 3.4", d.getRemainingInsulinStr());
      return true;
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  function glucoseFallingMgdl(log) {
    try {
      var buffer = new Shared.DateValues(null, 10);
      buffer.add(new Shared.DateValue(880, 133));
      buffer.add(new Shared.DateValue(1000, 123));
      var d = new Shared.Data();
      d.setGlucose(buffer);

      Assert.equal("-5.0", d.getGlucoseDeltaPerMinuteStr());
      return true;
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  function glucoseRaisingMgdl(log) {
    try {
      var buffer = new Shared.DateValues(null, 10);
      buffer.add(new Shared.DateValue(880, 133));
      buffer.add(new Shared.DateValue(1000, 153));
      var d = new Shared.Data();
      d.requestTimeSec = 1100;
      d.setGlucose(buffer);

      Assert.equal("+10.0", d.getGlucoseDeltaPerMinuteStr());
      return true;
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  function fallingMmoll(log) {
    try {
      Util.testNowSec = 1010;
      var buffer = new Shared.DateValues(null, 10);
      buffer.add(new Shared.DateValue(880, 100));
      buffer.add(new Shared.DateValue(1000, 120));
      var d = new Shared.Data();
      d.requestTimeSec = 1100;
      d.setGlucose(buffer);
      d.setGlucoseUnit(Shared.Data.mmoll);

      Assert.equal(true, d.hasValue());
      Assert.equal("6.7", d.getGlucoseStr());
      Assert.equal(Shared.Data.mmoll, d.glucoseUnit);
      Assert.equal("0:10", d.getGlucoseAgeStr());
      Assert.equal("+0.56", d.getGlucoseDeltaPerMinuteStr());
      Assert.equal(null, d.errorMessage);
      return true;
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }
}
