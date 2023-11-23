import Toybox.Lang;

module Shared {
class DateValue {
  var dateSec as Number;
  var value as Number;

  (:glance)
  function initialize(dateSec as Number, value as Number) {
    me.dateSec = dateSec;
    me.value = value;
  }

  function deltaPerSec(dv as DateValue?, sec as Number) as Float {
    if (dv == null || dv.dateSec == dateSec) {
      return 0.0;
    }
    var dval = dv.value - value;
    var dsec = dv.dateSec - dateSec;
    return sec.toFloat() * dval.toFloat() / dsec.toFloat();
  }

  function toString() as String {
    return Util.epochToString(dateSec) + "@" + value.format("%d");
  }
}
}
