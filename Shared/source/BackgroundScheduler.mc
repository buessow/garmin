import Toybox.Lang;

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

  // Frequency at which Dexcom provides glucose readings. 5 min.
  const READING_FREQUENCY = 5 * 60;

  // The phone doesn't get new readings immediately, so add some
  // slack to avoid that we try to get it just before it's available.
  const EXTRA_READING_DELAY = 5;

  // When do we expect the next glucose reading.
  const NEXT_READING_DELAY = READING_FREQUENCY + EXTRA_READING_DELAY;

  // If next scheduled time is that much after next expected reading
  // skip one reading.
  const ACCEPTABLE_EXTRA_DELAY = EXTRA_READING_DELAY + 15;

  var registered = false;
  var nextScheduleTimeSec as Number?;
  var schedule = false;


  // Computes when we expect the next value, usually 5 minutes plus a bit
  // after the last reading.
  function getNextValueTimeSec(nowSec, lastGlucoseTimeSec) as Number? {
    if (lastGlucoseTimeSec == null) { return null; }

    var missedReadings = (nowSec - lastGlucoseTimeSec) / READING_FREQUENCY.toDouble();
    if (missedReadings > 6.0) {
      return null;
    } else {
      return (lastGlucoseTimeSec + Math.ceil(missedReadings) * READING_FREQUENCY).toNumber() + EXTRA_READING_DELAY;
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
  function getNextRunTime(nowSec, lastGlucoseTimeSec, lastRunTimeSec) {
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
      if (extraDelaySec < ACCEPTABLE_EXTRA_DELAY) {
        // We would access the next value ACCEPTABLE_EXTRA_DELAY sec
	// after it's available. That seems acceptable.
        return nextRunTimeSec;
      } else {
        // Skip one glucose reading and get the next immediately, so
        // that we're better synchronized with Dexcom schedule.
        return nextValueSec + READING_FREQUENCY;
      }

    } else {
      // We expect next value later than last run time, so we can simply
      // schedule at that time.
      return nextValueSec;
    }
  }

  function scheduleTime(nowSec, lastGlucoseTimeSec) {
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

  function backgroundComplete(lastDateSec) {
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
    var regTime = Background.getTemporalEventRegisteredTime();
    if (registered) {
      return;
    }
    if (nextScheduleTimeSec == null) {
      nextScheduleTimeSec = scheduleTime(nowSec, lastDateSec);
    }
    if (nextScheduleTimeSec <= nowSec + scheduleWithinSec) {
      if(System.getDeviceSettings().phoneConnected && regTime == null) {
        nextScheduleTimeSec = Util.max(nextScheduleTimeSec, nowSec + 1);
        Log.i(TAG, "schedule temporal event at " + Util.timeSecToString(nextScheduleTimeSec));
        try {
          registered = true;
          Background.registerForTemporalEvent(new Time.Moment(nextScheduleTimeSec as Number));
        } catch (e) {
          Log.e(TAG, e.getErrorMessage());
          e.printStackTrace();
          nextScheduleTimeSec += 5 * 60;
        }
      }
    }
  }

  function tryRegisterTemporalEventIn(d) {
    tryRegisterTemporalEventAt(Time.now().add(d));
  }

  function tryRegisterTemporalEventAt(t) {
    var nowSec = Util.nowSec();
    if (nowSec % 10 != 0) { return; }
    Log.i(TAG, "try schedule event at " + Util.momentToString(t));
    if (Background.getTemporalEventRegisteredTime() != null) { return; }
    var lastSec = Background.getLastTemporalEventTime().value();
    Log.i(TAG, "try schedule last " + Util.timeSecToString(lastSec));
    if (t.value() - lastSec < 5 * 60) { return; }
    try {
      Background.registerForTemporalEvent(t);
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
