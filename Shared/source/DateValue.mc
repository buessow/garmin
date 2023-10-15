import Toybox.Lang;

module Shared {
class DateValue {
  var dateSec as Number;
  var value as Number;

  function initialize(dateSec as Number, value as Number) {
    me.dateSec = dateSec;
    me.value = value;
  }

  function deltaPerMinute(dv as DateValue?) as Float {
    if (dv == null || dv.dateSec == dateSec) {
      return 0.0;
    }
    var deltaPerSec = (dv.value.toFloat() - value.toFloat()) /
        (dv.dateSec.toFloat() - dateSec.toFloat());
    return 60.0 * deltaPerSec;
  }

  function toString() as String {
    return Util.epochToString(dateSec) + "@" + value.format("%d");
  }
}
}
