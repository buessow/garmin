import Toybox.Lang;

using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.Time;

module TestLib {
module Assert {

class AssertionFailed extends Exception {
  var msg;
  function initialize(msg, args) {
    Exception.initialize();
    me.msg = format(msg, args);
  }

  function getErrorMessage() {
    return msg;
  }
}

function toString(o) {
  return o == null ? "null" : ("'" + o.toString() + "'");
}

function join(sep as String, array as Array<String>) as String {
  var s = "";
  var theSep = "";
  for (var i = 0; i < array.size(); i++) {
    var v = array[i] instanceof Char ? array[i].toNumber() : array[i];
    s = s + theSep + v;
    theSep = sep;
  }
  return s;
}

function dictSubset(d1 as Dictionary, d2 as Dictionary) as Boolean {
  var keys = d1.keys();
  for (var i = 0; i < keys.size(); i++) {
    var key = keys[i];
    var v1 = d1.get(key).toString();
    var v2 = d2.hasKey(key) ? d2.get(key).toString() : "NULL";
    if (!v1.equals(v2)) { 
      Sys.println("Mismatch for '" + key + "'" + " '" + v1 + "' != '" + v2 + "'");
      return false; 
    }
  }
  return true;
}

function dictEquals(d1 as Dictionary, d2 as Dictionary) as Boolean {
  return dictSubset(d1, d2) && dictSubset(d2, d1);
}

function arrayEquals(a1 as Array<Object>, a2 as Array<Object>) as Boolean {
  if (a1.size() != a2.size()) {
    return false;
  }
  for (var i = 0; i < a1.size(); i++) {
    if (!a1[i].equals(a2[i])) {
      return false;
    }
  }
  return true;
}

function equal(expect, actual) {
  if (expect == null) {
    if (actual == null) { 
      return true;
    } else {
      throw new AssertionFailed("expected: NULL actual '$1$'", [actual]);
    }
  }

  if (expect instanceof Array && actual instanceof Array) {
    if (arrayEquals(expect, actual)) {
      return true;
    } else {
      throw new AssertionFailed(
        "expected: [$1$] actual: [$2$]",
        [join(",", expect), join(",", actual)]);
    }
  } else if (expect instanceof Dictionary and actual instanceof Dictionary) {
    if (dictEquals(expect, actual)) {
      return true;
    }
  } else if (expect.equals(actual)) {
    return true;
  }
  if (expect instanceof Time.Duration && actual instanceof Time.Duration &&
      expect.value() == actual.value()) {
    return true;
  }
  if (expect instanceof Time.Duration) {
    expect = expect.value();
  }
  if (actual instanceof Time.Duration) {
    actual = actual.value();
  }
  if (expect instanceof Time.Moment && actual instanceof Time.Moment &&
      expect.value() == actual.value()) {
    return true;
  }
  if (expect instanceof Time.Moment) {
    expect = expect.value();
  }
  if (actual instanceof Time.Moment) {
    actual = actual.value();
  }

  throw new AssertionFailed("expected: '$1$' actual: '$2$'", [
    expect == null ? "NULL" : expect.toString(),
    actual == null ? "NULL" : actual.toString()]);
}
}
}