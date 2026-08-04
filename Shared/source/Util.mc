import Toybox.Lang;

using Toybox.Math;
using Toybox.Time;

module Shared {
(:background, :glance)
module Util {
  var testNowSec as Number? = null;

  const EARTH_RADIUS_METER = 6371e3;

  // Great-circle distance between two geo positions given in degrees.
  function distanceMeter(
      lat1 as Float or Double, lon1 as Float or Double,
      lat2 as Float or Double, lon2 as Float or Double) as Float {
    var lat1R = Math.toRadians(lat1);
    var lon1R = Math.toRadians(lon1);
    var lat2R = Math.toRadians(lat2);
    var lon2R = Math.toRadians(lon2);
    var deltaLatR = lat2R - lat1R;
    var deltaLonR = lon2R - lon1R;
    var a = Math.sin(deltaLatR / 2) * Math.sin(deltaLatR / 2) +
        Math.cos(lat1R) * Math.cos(lat2R) *
        Math.sin(deltaLonR / 2) * Math.sin(deltaLonR / 2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return EARTH_RADIUS_METER * c;
  }

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
    if (s == null) { return false; }
    if (suffix == null || suffix.length == 0) { return true; }
    return (s.substring(s.length() - suffix.length(), s.length()) as String).equals(suffix);
  }

  function ifNull(a as Object?, b as Object) as Object {
    return a == null ? b : a;
  }

  function ifNullNumber(a as Number?, b as Number) as Number {
    return a == null ? b : a;
  }

  function ifNullFloat(a as Float?, b as Float) as Float {
    return a == null ? b : a;
  }

  (:exclude)
  function join(sep as String, array as Array<String>) as String {
    var s = "";
    var theSep = "";
    for (var i = 0; i < array.size(); i++) {
      s = s + theSep + array[i];
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
    return info.year.format("%04d") + "-" + (info.month as Number).format("%02d") + "-" +
           info.day.format("%02d") + "T" +
           info.hour.format("%02d") + ":" + info.min.format("%02d") + ":" +
           info.sec.format("%02d");
  }
}
}
