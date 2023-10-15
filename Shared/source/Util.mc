import Toybox.Lang;

using Toybox.Time;

module Shared {
(:background, :glance)
module Util {
  var testNowSec as Number? = null;

  (:background)
  function nowSec() as Number {
    if (testNowSec == null) {
      return Time.now().value();
    } else {
      return testNowSec;
    }
  }

  function max(a as Number, b as Number) as Number {
    return a < b ? b : a;
  }

  function min(a as Number, b as Number) as Number {
    return a < b ? a : b;
  }

  function abs(a as Number) as Number {
    return a < 0 ? -a : a;
  }

  function epochToString(sec as Number) as String {
    return momentToString(new Toybox.Time.Moment(sec));
  }

  function stringEndsWith(s as String?, suffix as String?) as Boolean {
    return s != null && (
      suffix == null || suffix.length() == 0 ||
      s.substring(s.length() - suffix.length(), s.length()).equals(suffix));
  }

  function ifNull(a, b) {
    return a == null ? b : a;
  }

  function join(sep as String, array as Array<String>) as String {
    var s = "";
    var theSep = "";
    for (var i = 0; i < array.size(); i++) {
      var v = array[i] instanceof Lang.Char ? array[i].toNumber() : array[i];
      s = s + theSep + v;
      theSep = sep;
    }
    return s;
  }

  function timeSecToString(sec as Number?) as String {
    return sec == null ? "NULL" : momentToString(new Time.Moment(sec));
  }

  function momentToString(m as Time.Moment?) as String {
    if (m == null) {
      return "NULL";
    }
    var info = Time.Gregorian.info(m, Time.FORMAT_SHORT);
    return info.year.format("%04d") + "-" + info.month.format("%02d") + "-" +
           info.day.format("%02d") + "T" +
           info.hour.format("%02d") + ":" + info.min.format("%02d") + ":" +
           info.sec.format("%02d");
  }
}
}
