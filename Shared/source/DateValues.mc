using Toybox.Lang;

module Shared {
(:glance)
class DateValues {
  var data;
  var start = 0;
  var count = 0;

  function initialize(values, size) {
    if (values == null) {
      data = new [2*size];
    } else {
      data = values;
      count = size;
    }
  }

  function size() {
    return count / 2;
  }

  function clear() {
    start = 0;
    count = 0;
  }

  hidden function add1(value) {
    if (value == null) {
      throw new Lang.InvalidValueException("null");
    }
    if (data.size() == count) {
      data[start] = value;
      start = (start + 1) % data.size();
    } else {
      data[(start + count) % data.size()] = value;
      count++;
    }
  }

  hidden function get1(i) {
    if (i < 2 * size()) {
      var v = data[(start + i) % data.size()];
      if (v == null) {
        throw new Lang.InvalidValueException("i=" + i);
      }
      return v;
    } else {
      throw new Lang.ValueOutOfBoundsException("i=" + i + " size=" + size());
    }
  }

  function truncateTo(first) {
    start = (start + 2 * first) % data.size();
    count -= 2 * first;
  }

  function add(dateValue) {
    add1(dateValue.dateSec);
    add1(dateValue.value);
  }

  function toHexString() {
    var s = "";
    for (var i = 0; i < count; i++) {
      s += get1(i).format("%08x");
    }
    return s;
  }

  function fromHexString(s) {
    start = 0;
    count = 0;
    for (var i = 0; i < s.length() / 8; i++) {
      add1(s.substring(8*i, 8*(i+1)).toNumberWithBase(16));
    }
  }

  function get(i) {
    return new DateValue(getDateSec(i), getValue(i));
  }

  function getDateSec(i) {
    return get1(2 * i);
  }

  function getValue(i) {
    return get1(2 * i + 1);
  }

  function getLastDateSec() {
    return size() == 0 ? null : getDateSec(size() - 1);
  }

  function getLastValue() {
    return size() == 0 ? null : getValue(size() - 1);
  }
}}
