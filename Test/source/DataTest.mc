using TestLib.Assert;
using Toybox.Application.Properties;
using Toybox.Time;
using Shared;
using Shared.Util;

(:Test)
class DataTest {
    private static function clearProperties() {
      Properties.setValue("GlucoseValues", null);
      Properties.setValue("RemainingInsulin", null);
      Properties.setValue("TemporaryBasalRate", null);
      Properties.setValue("BasalProfile", null);
      Properties.setValue("GlucoseUnit", null);      
    }

  (:test)
  function restore(log) {
    try {
      DataTest.clearProperties();
      Util.testNowSec = 1000;

      var d = new Shared.Data();
      d.glucoseBuffer.add(new Shared.DateValue(1000, 90));
      d.updateGlucose(d.glucoseBuffer);
      d.setRemainingInsulin(4.1, 0.0);
      d.setTemporaryBasalRate(0.9);
      d.setProfile("P");
      d.setGlucoseUnit(Shared.Data.mmoll);
      Assert.equal("mmoll", d.getGlucoseUnitStr());

      var d1 = new Shared.Data();
      Assert.equal(true, d1.hasValue());
      Assert.equal("iob 4.1", d1.getRemainingInsulinStr());
      Assert.equal("P90%", d1.getBasalCorrectionStr());
      Assert.equal("mmoll", d1.getGlucoseUnitStr());

    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    } finally {
      DataTest.clearProperties();
    }
    return true;
  }

  (:test)
  function noValueSet(log) {
    try {
      DataTest.clearProperties();
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
      DataTest.clearProperties();
      Util.testNowSec = 1010;
      var d = new Shared.Data();
      d.glucoseBuffer.add(new Shared.DateValue(1000, 123));
      d.updateGlucose(d.glucoseBuffer);
      d.setRemainingInsulin(3.366, 0.0);

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
      DataTest.clearProperties();
      Util.testNowSec = 1000;
      var d = new Shared.Data();
      d.glucoseBuffer.add(new Shared.DateValue(880, 133));
      d.glucoseBuffer.add(new Shared.DateValue(1000, 123));
      d.updateGlucose(d.glucoseBuffer);

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
      DataTest.clearProperties();
      Util.testNowSec = 1000;
      var d = new Shared.Data();
      d.glucoseBuffer.add(new Shared.DateValue(880, 133));
      d.glucoseBuffer.add(new Shared.DateValue(1000, 153));
      d.updateGlucose(d.glucoseBuffer);

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
    DataTest.clearProperties();
    Util.testNowSec = 1010;
    var d = new Shared.Data();
    d.glucoseBuffer.add(new Shared.DateValue(880, 100));
    d.glucoseBuffer.add(new Shared.DateValue(1000, 120));
    d.updateGlucose(d.glucoseBuffer);

    d.setGlucoseUnit(Shared.Data.mmoll);

    Assert.equal(true, d.hasValue());
    Assert.equal("6.7", d.getGlucoseStr());
    Assert.equal(Shared.Data.mmoll, d.glucoseUnit);
    Assert.equal("0:10", d.getGlucoseAgeStr());
    Assert.equal("+0.56", d.getGlucoseDeltaPerMinuteStr());
    Assert.equal(null, d.errorMessage);
    return true;
  }
}
