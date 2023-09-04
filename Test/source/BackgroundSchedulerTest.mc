using Shared;
using Shared.BackgroundScheduler;
using TestLib.Assert;
using Toybox.Time;

(:test)
class BackgroundSchedulerTest {

  (:test)
  function noValueNeverRun(log) {
    try {
      var now = 1000;
      var next = BackgroundScheduler.getNextRunTime(now, null, null);
      Assert.equal(now + BackgroundScheduler.IMMEDIATE_SCHEDULING_DELAY, next);
    } catch (e) {
      log.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
    return true;
  }

  (:test)
  function valueNeverRun(log) {
    try {
      var now = 30 * 60;
      var value = now - 2*60;
      var expect = value
          + BackgroundScheduler.READING_FREQUENCY
          + BackgroundScheduler.EXTRA_READING_DELAY;
      var next = BackgroundScheduler.getNextRunTime(now, value, null);
      Assert.equal(expect.toLong(), next);
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
    try {
      var now = 1000;
      var val = now - 5*60;
      var ran = val 
          + BackgroundScheduler.ACCEPTABLE_EXTRA_DELAY 
	  + BackgroundScheduler.EXTRA_READING_DELAY - 1;
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
    try {
      var now = 1000l;
      var val = now - 5*60;
      var ran = val 
          + BackgroundScheduler.ACCEPTABLE_EXTRA_DELAY 
	  + BackgroundScheduler.EXTRA_READING_DELAY;
      var next = BackgroundScheduler.getNextRunTime(now, val, ran);
      Assert.equal(
          val + BackgroundScheduler.READING_FREQUENCY
              + BackgroundScheduler.NEXT_READING_DELAY,
          next);
    } catch (e) {
      e.printStackTrace();
      throw e;
    }
      return true;
  }

  (:test)
  function valueRanLongAgo(log) {
    try {
      var now = 1000l;
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
