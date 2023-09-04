using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.Time;

module TestLib {
module Assert {

class AssertionFailed extends Lang.Exception {
  var msg;
  function initialize(msg, args) {
    Exception.initialize();
    me.msg = Lang.format(msg, args);
  }

  function getErrorMessage() {
    return msg;
  }
}

function toString(o) {
  return o == null ? "null" : ("'" + o.toString() + "'");
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


function arrayEquals(a1, a2) {
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
    return actual == null;
  }

  if (expect instanceof Lang.Array && actual instanceof Lang.Array) {
    if (arrayEquals(expect, actual)) {
      return true;
    } else {
      throw new AssertionFailed(
        "expected: [$1$] actual: [$2$]",
        [join(",", expect), join(",", actual)]);
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
  return false;
}
}
}