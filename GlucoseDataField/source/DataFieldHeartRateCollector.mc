import Toybox.Lang;

using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Shared.Util;
using Toybox.Application.Properties;
using Toybox.Activity;
using Toybox.Math;

class DataFieldHeartRateCollector {
  private const TAG = "HeartRateCollector";
  private var startSec as Number;
  private var lastSec as Number;
  private var avg as Float;

  function initialize() {
    var now = Util.nowSec();
    startSec = Util.ifNull(Properties.getValue("HeartRateStartSec"), 0);
    if (now - startSec > 300) {
      startSec = Util.nowSec();
      lastSec = startSec;
      avg = 0.0;
    } else {
      lastSec = Util.ifNull(Properties.getValue("HeartRateLastSec"), 0);
      avg = Util.ifNull(Properties.getValue("HeartRateAvg"), 0);
      Log.i(TAG, "restored " + avg + " from " + (now - lastSec) + "s");
    }
  }

  function sample() as Void {
    var info = Activity.getActivityInfo();
    var hr = info == null ? null : info.currentHeartRate;
    var nowSec = Util.nowSec();
    if (hr != null && hr > 0 && nowSec > startSec) {
      record(nowSec, hr.toFloat());
    }
  }

  function record(dateSec as Number, hr as Float) as Void {
    avg = ((lastSec - startSec) * avg + (dateSec - lastSec) * hr) / (dateSec - startSec);
    lastSec = dateSec;
    if (dateSec - startSec > 60 &&
        BackgroundScheduler.nextScheduleTimeSec - dateSec < 5 && avg > 10 && avg < 300) {
      store();
    }
  }

  function reset() as Void {
    startSec = Util.nowSec();
    lastSec = startSec;
    avg = 0.0;
  }

  function store() as Void {
    Properties.setValue("HeartRateStartSec", startSec);
    Properties.setValue("HeartRateLastSec", lastSec);
    Properties.setValue("HeartRateAvg", Math.round(avg).toNumber());
    var nowSec = Util.nowSec();
    Log.i(TAG, "store [" + (nowSec - startSec) + "," + (nowSec - lastSec) + "] " + avg);
  }
}
