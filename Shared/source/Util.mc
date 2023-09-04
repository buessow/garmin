using Toybox.Lang as Lang;
using Toybox.Time;

module Shared {
(:background)
module Util {
  var testNowSec;
  var testNowSecIdx = 0;

  (:background)
  function nowSec() {
    if (testNowSec == null) {
      return Time.now().value();
    } else if (testNowSec instanceof Lang.Number) {
      return testNowSec;
    } else {
      var i = Util.min(testNowSecIdx, testNowSec.size()-1);
      testNowSecIdx++;
      return testNowSec[i];
    }
  }

  function max(a, b) {
    return a < b ? b : a;
  }

  function min(a, b) {
    return a < b ? a : b;
  }

  function abs(a) {
    return a < 0 ? -a : a;
  }

  function epochToString(sec) {
    return momentToString(new Toybox.Time.Moment(sec));
  }

  function stringEndsWith(s, suffix) {
    return s != null && (
      suffix == null || suffix.length() == 0 ||
      s.substring(s.length() - suffix.length(), s.length()).equals(suffix));
  }

//  function find(a, cmp) {
//    return find2(a, cmp, 0, a.size());
//  }

  function ifNull(a, b) {
    return a == null ? b : a;
  }

  function join(sep, array) {
    var s = "";
    var theSep = "";
    for (var i = 0; i < array.size(); i++) {
      var v = array[i] instanceof Lang.Char ? array[i].toNumber() : array[i];
      s = s + theSep + v;
      theSep = sep;
    }
    return s;
  }

//  function find2(a, cmp, start, count) {
//    count = min(a.size() - start, count);
//    if (count <= 0) { return null; }
//    var o = a[start];
//    for (var i = start+1; i < start+count; i++) {
//      if (cmp.invoke(a[i], o)) {
//        o = a[i];
//      }
//    }
//    return o;
//  }
//
  function timeSecToString(sec) {
    return sec == null ? "NULL" : momentToString(new Time.Moment(sec));
  }

  function momentToString(m) {
    if (m == null) {
      return "NULL";
    }
    var info = Toybox.Time.Gregorian.info(m, Toybox.Time.FORMAT_SHORT);
    return info.year.format("%04d") + "-" + info.month.format("%02d") + "-" +
           info.day.format("%02d") + "T" +
           info.hour.format("%02d") + ":" + info.min.format("%02d") + ":" +
           info.sec.format("%02d");
  }
}
}
