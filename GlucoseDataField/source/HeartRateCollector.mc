using Toybox.Activity;
using Toybox.Application;
using Toybox.Math;

module Shared {
class HeartRateCollector {
  hidden const TAG = "HeartRateCollector";
  hidden var startSec;
  hidden var lastSec;
  hidden var avg;

  function initialize() {
    var now = Util.nowSec();
    var app = Application.getApp();
    startSec = Util.ifNull(app.getProperty("HeartRateFirstSec"), 0);
    if (now - startSec > 300) {
      startSec = Util.nowSec();
      lastSec = startSec;
      avg = 0.0;
    } else {
      lastSec = Util.ifNull(app.getProperty("HeartRateLastSec"), 0);
      avg = Util.ifNull(app.getProperty("HeartRateAvg"), 0);
      Log.i(TAG, "restored " + avg + " from " + (now - lastSec) + "s");
    }
  }

  function sample() {
    var info = Activity.getActivityInfo();
    var hr = info == null ? null : info.currentHeartRate;
    var nowSec = Util.nowSec();
    if (hr != null && hr > 0 && nowSec > startSec) {
      record(nowSec, hr.toFloat());
    }
  }

  function record(dateSec, hr) {
    avg = ((lastSec - startSec) * avg + (dateSec - lastSec) * hr) / (dateSec - startSec);
    lastSec = dateSec;
    if (dateSec - startSec > 60 &&
        BackgroundScheduler.nextScheduleTimeSec - dateSec < 5 &&
	avg > 10 && avg < 300) {
      store();
    }
  }

  function reset() {
    startSec = Util.nowSec();
    lastSec = startSec;
    avg = 0;
  }

  function store() {
    var app = Application.getApp();
    app.setProperty("HeartRateStartSec", startSec);
    app.setProperty("HeartRateLastSec", lastSec);
    app.setProperty("HeartRateAvg", Math.round(avg).toNumber());
    var nowSec = Util.nowSec();
    Log.i(TAG, "store [" + (nowSec - startSec) + "," + (nowSec - lastSec) + "] " + avg);
  }
}}
