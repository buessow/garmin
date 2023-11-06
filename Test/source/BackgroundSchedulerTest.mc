using Shared;
using Shared.Util;
using Shared.BackgroundScheduler;
using TestLib.Assert;
using Toybox.Application.Properties;
using Toybox.Time;

(:test)
class BackgroundSchedulerTest {

  (:test)
  function noValueNeverRun(log) {
    var now = 1000;
    var next = BackgroundScheduler.getNextRunTime(now, null, null);
    Assert.equal(now + BackgroundScheduler.IMMEDIATE_SCHEDULING_DELAY, next);
    return true;
  }

  (:test)
  function valueNeverRun(log) {
    try {
      Properties.setValue("GlucoseValueFrequencySec", 300);
      var now = 30 * 60;
      var value = now - 2*60;
      var expect = value
          + BackgroundScheduler.readingFrequency()
          + BackgroundScheduler.extraReadingDelay();
      var next = BackgroundScheduler.getNextRunTime(now, value, null);
      Assert.equal(Util.epochToString(expect), Util.epochToString(next));
    } catch (e) { 
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
    return true;
  }

  (:test)
  function noValueRan(log) {
    try {
      var now = 1000;
      var ran = now - 2*60;
      var next = BackgroundScheduler.getNextRunTime(now, null, ran);
      Assert.equal(ran + BackgroundScheduler.MIN_SCHEDULE_DELAY, next);
      return true;
    } catch (e) {
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  function valueRanAcceptableDelay(log) {
    Properties.setValue("GlucoseValueFrequencySec", 300);
    try {
      var now = 1000;
      var val = now - 5*60;
      var ran = val 
          + BackgroundScheduler.ACCEPTABLE_EXTRA_DELAY 
          + BackgroundScheduler.extraReadingDelay() - 1;
      var next = BackgroundScheduler.getNextRunTime(now, val, ran);
      Assert.equal(ran + BackgroundScheduler.MIN_SCHEDULE_DELAY, next);
    } catch (e) {
      e.printStackTrace();
      throw e;
    }
    return true;
  }

  (:test)
  function valueRanInacceptableDelay(log) {
    var now = 300;
    var val = now - 5*60;
    var ran = val 
        + BackgroundScheduler.ACCEPTABLE_EXTRA_DELAY 
        + BackgroundScheduler.extraReadingDelay() + 1;
    var next = BackgroundScheduler.getNextRunTime(now, val, ran);
    Assert.equal(
        val + 2*BackgroundScheduler.readingFrequency()
            + BackgroundScheduler.extraReadingDelay(),
        next);
    return true;
  }

  (:test)
  function valueRanMinutelyFreq(log) {
    Properties.setValue("GlucoseValueFrequencySec", 60);
    try {
      var now = 300;
      var val = now - 3*60;
      var ran = val + 10;
      var next = BackgroundScheduler.getNextRunTime(now, val, ran);
      Assert.equal(
          val + BackgroundScheduler.MIN_SCHEDULE_DELAY + 10,
          next);
    } finally {
      Properties.setValue("GlucoseValueFrequencySec", 300);
    }
    return true;
  }

  (:test)
  function valueRanMinutelyFreqExtraWait(log) {
    Properties.setValue("GlucoseValueWaitSec", 5);
    Properties.setValue("GlucoseValueFrequencySec", 60);
    try {
      var now = 300;
      var val = 120;
      var ran = 140;
      var next = BackgroundScheduler.getNextRunTime(now, val, ran);
      Assert.equal(120 + 300 + 60 + 5, next);
    } finally {
      Properties.setValue("GlucoseValueFrequencySec", 300);
    }
    return true;
  }

  (:test)
  function valueRan3MinutelyFreq(log) {
    Properties.setValue("GlucoseValueFrequencySec", 180);
    try {
      var now = 300;
      var val = now - 3*60;
      var ran = val + BackgroundScheduler.extraReadingDelay() + 1;
      var next = BackgroundScheduler.getNextRunTime(now, val, ran);
      Assert.equal(
          val + 2*BackgroundScheduler.readingFrequency()
              + BackgroundScheduler.extraReadingDelay(),
          next);
    } catch (e) {
      e.printStackTrace();
      throw e;
    } finally {
      Properties.setValue("GlucoseValueFrequencySec", 300);
    }
    return true;
  }

  (:test)
  function valueRanLongAgo(log) {
    try {
      var now = 1000;
      var val = now - 45*60;
      var ran = now - 1*60;
      var next = BackgroundScheduler.getNextRunTime(now, val, ran);
      Assert.equal(
          ran + BackgroundScheduler.MIN_SCHEDULE_DELAY,
          next);
      return true;
    } catch (e) {
      e.printStackTrace();
      throw e;
    }
  }
}
