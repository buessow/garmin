using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.SensorHistory;
using Toybox.Time;

module Shared {
class HeartRateCollector {
  hidden static const TAG = "HeartRateCollector";
  hidden static const PERIOD_MIN = 120;
  hidden static const SAMPLING_MIN = 3;

  hidden var lastUpdateSecs;
  hidden var values = new Shared.DateValues(null, PERIOD_MIN / SAMPLING_MIN);

  function initialize() {
    lastUpdateSecs = 60 * ((Util.nowSec() / 60).toLong() - PERIOD_MIN);
    Log.i(TAG, "set lastUpdateSecs to " + Util.timeSecToString(lastUpdateSecs));
  }

  function update() {
    var now = Util.nowSec();
    if (now <= lastUpdateSecs + 60 * SAMPLING_MIN) {
      return;
    }
    var d = Util.min(now - lastUpdateSecs, 60 * ((now / 60).toLong() - PERIOD_MIN));
    var duration = new Time.Duration(d.toNumber());
    var it = SensorHistory.getHeartRateHistory({
      :period => duration,
      :order => SensorHistory.ORDER_OLDEST_FIRST });
    var minute = lastUpdateSecs / 60;
    var count = 0;
    var total = 0;

    for (var val = it.next(); val != null; val = it.next()) {
      if (val.data == null) {
        continue;
      }
      var currentMin = (val.when.value() / 60).toLong();
      if (currentMin > minute + SAMPLING_MIN && count > 0) {
//        Log.i(TAG, "add count=" + count.toString() + " avg=" +
//              total/count + " " + Util.timeSecToString(minute*60));
        values.add(new Shared.DateValue(minute*60, total/count));
        minute = currentMin;
        count = 0;
        total = 0;
      }
      if (val.data != null) {
        count++;
        total += val.data;
      }
    }
    if (count > 0) {
      values.add(new Shared.DateValue(minute*60, total/count));
    }
    lastUpdateSecs = (Util.nowSec() / 60).toLong() * 60;
  }

  function getValues() {
    update();
    return values;
  }
}
}