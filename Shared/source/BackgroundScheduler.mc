import Toybox.Lang;

using Toybox.Application.Properties;
using Toybox.Background;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;

module Shared {
module BackgroundScheduler {
  const TAG = "BackgroundScheduler";

  const IMMEDIATE_SCHEDULING_DELAY = 0;

  // How often are we allowed to schedule background events. 5 min.
  const MIN_SCHEDULE_DELAY = 5 * 60;

  // If next scheduled time is that much after next expected reading
  // skip one reading.
  const ACCEPTABLE_EXTRA_DELAY = 15;

  var registered = false;
  var nextScheduleTimeSec as Number?;
  var schedule = false;

  // The phone doesn't get new readings immediately, so add some
  // slack to avoid that we try to get it just before it's available.
  function extraReadingDelay() as Number {
    return Util.ifNull(Properties.getValue("GlucoseValueWaitSec"), 5) as Number;
  }

  // Frequency at which the CGM provides glucose readings. The default is 5 min.
  function readingFrequency() as Number {
    return Data.getGlucoseValueFrequencySeq();
  }

  // Computes when we expect the next value, usually 5 minutes plus a bit
  // after the last reading.
  function getNextValueTimeSec(nowSec, lastGlucoseTimeSec) as Number? {
    if (lastGlucoseTimeSec == null) { return null; }

    var missedReadings = (nowSec - lastGlucoseTimeSec) / readingFrequency().toDouble();
    if (missedReadings > 6.0) {
      return null;
    } else {
      return (lastGlucoseTimeSec
          + Math.ceil(missedReadings) * readingFrequency()).toNumber()
          + extraReadingDelay();
    }
  }

  // Computes the next time we should schedule a server lookup.
  //
  // @Param nowSec: Toybox.Lang.Integer
  //        Current time in seconds since the epoch
  // @Param lastGlucoseTimeSec: Toybox.Lang.Integer
  //        Time of last glucose reading in seconds since the epoch.
  // @Param lastRunTime: Toybox.Lang.Integer
  //        Last time the background task run in secdonds since the
  //        epoch.
  // @Returns Toybox.Lang.Integer
  //          Time we should run the background task next in seconds
  //          since the epoch.
  function getNextRunTime(
      nowSec as Number,
      lastGlucoseTimeSec as Number?,
      lastRunTimeSec as Number?) as Number {
    var nextRunTimeSec = lastRunTimeSec == null
                       ? nowSec + IMMEDIATE_SCHEDULING_DELAY
                       : lastRunTimeSec + MIN_SCHEDULE_DELAY;

    if (lastGlucoseTimeSec == null) {
      Log.i(TAG, "now: " + Util.timeSecToString(nowSec) +
                 " last run: " + Util.timeSecToString(lastRunTimeSec) +
                 " earliest run: " + Util.timeSecToString(nextRunTimeSec));
      return nextRunTimeSec;
    }

    var nextValueSec = getNextValueTimeSec(nowSec, lastGlucoseTimeSec);
    Log.i(TAG, "now: " + Util.timeSecToString(nowSec) +
               " last run: " + Util.timeSecToString(lastRunTimeSec) +
               " earliest run: " + Util.timeSecToString(nextRunTimeSec) +
               " last value: " + Util.timeSecToString(lastGlucoseTimeSec) +
               " expect value: " + Util.timeSecToString(nextValueSec));

    if (nextValueSec == null) {
      // We don't know when the next reading happens, so run as soon as
      // possible.
      return nextRunTimeSec;
    }

    if (nextValueSec < nextRunTimeSec) {
      // We expect next value before we can run background process.
      // Compute how much extra delay we get if we schedule at earliest
      // time.
      var extraDelaySec = nextRunTimeSec - nextValueSec;
      // We might miss several readings, e.g. if we get a reading per minute.
      // Compute the time of the most recent reading before nextRunTimeSec.
      var freq = readingFrequency().toDouble();
      extraDelaySec -= (Math.floor(extraDelaySec / freq) * freq).toNumber();
      if (extraDelaySec < ACCEPTABLE_EXTRA_DELAY) {
        // We would access the next value ACCEPTABLE_EXTRA_DELAY sec
	      // after it's available. That should be acceptable.
        return nextRunTimeSec;
      } else {
        // Skip glucose readings and get the next immediately, so
        // that we're better synchronized with the CGM schedule. For 5 minute
        // frequency like Dexcom G6, this would be always another 5min.
        return nextValueSec +
            (Math.ceil((nextRunTimeSec - nextValueSec) / freq) * freq).toNumber();
      }

    } else {
      // We expect next value later than last run time, so we can simply
      // schedule at that time.
      return nextValueSec;
    }
  }

  function scheduleTime(nowSec as Number, lastGlucoseTimeSec as Number?) as Number {
    var lastRunTime = Background.getLastTemporalEventTime();
    var nextRunTimeSec = getNextRunTime(
        nowSec,
        lastGlucoseTimeSec,
        lastRunTime == null ? null : lastRunTime.value());
    Log.i(TAG, "last run " + Util.momentToString(lastRunTime) +
        ", run background at " + Util.timeSecToString(nextRunTimeSec));
    nextRunTimeSec = Util.max(nowSec+2, nextRunTimeSec);
    return nextRunTimeSec;
  }

  function backgroundComplete(lastDateSec as Number?) as Void {
    registered = false;
    nextScheduleTimeSec = scheduleTime(Util.nowSec(), lastDateSec);
  }

  function schedule2(lastDateSec, scheduleWithinSec) {
    var nowSec = Util.nowSec();
    if (!schedule) {
      if (lastDateSec == null || nowSec - lastDateSec > 660) {
        tryRegisterTemporalEventIn(new Time.Duration(2));
      }
      return;
    }
    if (registered && nextScheduleTimeSec != null && nowSec - nextScheduleTimeSec < 10) {
      return;
    }
    if (nextScheduleTimeSec == null) {
      nextScheduleTimeSec = scheduleTime(nowSec, lastDateSec);
    }
    var regTime = Background.getTemporalEventRegisteredTime();
    if (nextScheduleTimeSec <= nowSec + scheduleWithinSec) {
      if(System.getDeviceSettings().phoneConnected && regTime == null) {
        nextScheduleTimeSec = Util.max(nextScheduleTimeSec, nowSec + 1);
        Log.i(TAG, "schedule temporal event at " + Util.timeSecToString(nextScheduleTimeSec));
        try {
          Background.registerForTemporalEvent(new Time.Moment(nextScheduleTimeSec as Number));
          registered = true;
        } catch (e) {
          Log.e(TAG, e.getErrorMessage());
          e.printStackTrace();
          nextScheduleTimeSec += 5 * 60;
        }
      }
    }
  }

  function tryRegisterTemporalEventIn(d as Time.Duration) as Void {
    tryRegisterTemporalEventAt(Time.now().add(d));
  }

  function tryRegisterTemporalEventAt(t as Time.Moment) as Void {
    var nowSec = Util.nowSec();
    if (nowSec % 10 != 0) { return; }
    Log.i(TAG, "try schedule event at " + Util.momentToString(t));
    if (Background.getTemporalEventRegisteredTime() != null) { return; }
    var lastSec = Background.getLastTemporalEventTime().value();
    Log.i(TAG, "try schedule last " + Util.timeSecToString(lastSec));
    if (t.value() - lastSec < 5 * 60) { return; }
    try {
      Background.registerForTemporalEvent(t);
      nextScheduleTimeSec = t.value();
      Log.i(TAG, "scheduled event at " + Util.momentToString(t));
    } catch (e) {
      Log.e(TAG, e.getErrorMessage());
      e.printStackTrace();
    }
  }

  // Returns in how much time the next server request is scheduled.
  // Value is returned as formatted string of min:sec or just min,
  // if it's larger than 10min or smaller than -10min.
  //
  // @Returns Toybox.Lang.String
  function getRequestTimeStr() {
    if (nextScheduleTimeSec == null) {
      return "_:__";
    }
    var t = Util.max(nextScheduleTimeSec - Util.nowSec(), 0);
    var min = t / 60;
    var sec = t % 60;
    if (min < 10) {
      return min.toString() + ":" + sec.format("%02d");
    } else {
      return min.toString();
    }
  }

  function registerTemporalEventIfConnectedIn(d) {
    var runTime = Time.now().add(d);
    return registerTemporalEventIfConnectedAt(runTime);
  }

  function registerTemporalEventIfConnectedAt(runTime) {
    try {
      var lastRunTime = Background.getLastTemporalEventTime();
      if (System.getDeviceSettings().phoneConnected &&
          (lastRunTime == null ||
           runTime.value() - lastRunTime.value() > 5 * 60)) {
        if (!registered) {
          registered = true;
          Background.registerForTemporalEvent(runTime);
          Log.i(TAG, "registered event at " + Util.momentToString(runTime));
        }
        return true;
      } else {
        Log.i(TAG, "skip registered event last " + Util.momentToString(lastRunTime));
      }
    } catch (e) {
      Log.e(TAG, "ex: " + e.getErrorMessage());
      e.printStackTrace();
    }
    nextScheduleTimeSec = null;
    return false;
  }
}
}
