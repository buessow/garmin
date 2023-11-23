import Toybox.Lang;

module Shared {
class DateValues {
  var data as Array<Number>;
  var start = 0;
  var count = 0;

  (:glance)
  function initialize(
      values as Array<Number>?, 
      size as Number) {
    if (values == null) {
      data = new [2*size];
    } else {
      data = values;
      count = 2 * size;
    }
  }

  function medianDeltaSec() as Number? {
    if (size() < 2) {
      return null;
    }
    var deltas = new [Util.min(20, size()) - 1];
    for (var i = 0; i < deltas.size(); i++) {
      var j = i + (size() - 1 - deltas.size());
      deltas[i] = getDateSec(j+1) - getDateSec(j);
    }
    Arrays.qsort(deltas);
    return deltas[deltas.size() / 2];
  }

  function medianDeltaMinute() as Number? {
    var sec = medianDeltaSec();
    if (sec == null) {
      return null;
    }
    return ((sec / 60.0) + 0.5).toNumber();
  }

  (:glance)
  function size() as Number {
    return count / 2;
  }

  (:glance)
  function clear() as Void {
    start = 0;
    count = 0;
  }

  (:glance)
  function ensureSize(minSize as Number) as Void {
    if (minSize > data.size()) {
      resize(minSize);
    }
  }

  (:glance)
  function resize(newSize as Number) as Void {
    if (newSize == data.size()) {
      return;
    }
    var newData = new [2 * newSize];
    var newCount = Util.min(count, 2 * newSize);
    var s = start + count - newCount;
    for (var i = 0; i < newCount; i++) {
      newData[i] = data[(i + s) % data.size()];
    }
    data = newData;
    start = 0;
    count = newCount;
  }

  (:glance)
  private function add1(value) as Void {
    if (value == null) {
      throw new InvalidValueException("null");
    }
    if (data.size() == count) {
      data[start] = value;
      start = (start + 1) % data.size();
    } else {
      data[(start + count) % data.size()] = value;
      count++;
    }
  }

  (:glance)
  private function get1(i) as Number {
    return data[(start + i) % data.size()];
    // if (i < size()) {
    //   var v = data[(start + i) % data.size()];
    //   if (v == null) {
    //     throw new InvalidValueException("i=" + i);
    //   }
    //   return v;
    // } else {
    //   throw new ValueOutOfBoundsException("i=" + i + " size=" + size());
    // }
  }

  (:glance)
  function truncateTo(first) as Void {
    start = (start + 2 * first) % data.size();
    count -= 2 * first;
  }

  (:glance)
  function add(dateValue) {
    add1(dateValue.dateSec);
    add1(dateValue.value);
  }

  (:glance)
  function toHexString() as String {
    var s = "";
    for (var i = 0; i < count; i++) {
      s += get1(i).format("%08x");
    }
    return s;
  }

  (:glance)
  function fromHexString(s as String) as Void {
    start = 0;
    count = 0;
    for (var i = 0; i < s.length() / 8; i++) {
      add1(s.substring(8*i, 8*(i+1)).toNumberWithBase(16));
    }
  }

  (:glance)
  function get(i) as DateValue {
    return new DateValue(getDateSec(i), getValue(i));
  }

  (:glance)
  function getDateSec(i) as Number {
    return get1(2 * i);
  }

  (:glance)
  function getValue(i) as Number {
    return get1(2 * i + 1);
  }

  (:glance)
  function getLastDateSec() as Number? {
    return size() == 0 ? null : getDateSec(size() - 1);
  }

  (:glance)
  function getLastValue() as Number? {
    return size() == 0 ? null : getValue(size() - 1);
  }
}}
