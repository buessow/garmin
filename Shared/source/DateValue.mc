module Shared {
class DateValue {
  var dateSec;
  var value;

  function initialize(dateSec, value) {
    me.dateSec = dateSec;
    me.value = value;
  }

  function deltaPerMinute(dv) {
    if (dv == null || dv.dateSec == dateSec) {
      return 0.0;
    }
    var deltaPerSec = (dv.value.toFloat() - value.toFloat()) /
        (dv.dateSec.toFloat() - dateSec.toFloat());
    return 60.0 * deltaPerSec;
  }

  function toString() {
    return Util.epochToString(dateSec) + "@" + value.format("%d");
  }
}
}
