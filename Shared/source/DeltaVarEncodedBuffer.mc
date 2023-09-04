using Toybox.Lang;
using Toybox.StringUtil as StringUtil;

module Shared {
/*
(:background)
class DeltaVarEncodedBuffer {
  hidden const TAG = "DeltaVarEncodedBuffer";
  hidden var data;
  hidden var start = 0;
  hidden var end = 0;
  var lastValues;

  function initialize(capacity, entrySize) {
    if (capacity > 0) {
      data = new [capacity]b;
    }
    lastValues = new [entrySize];
    for (var i = 0; i < entrySize; i++) {
      lastValues[i] = 0;
    }
  }

  // Initialize from raw values (delta var encoded) given as base64
  // string. Call right after initialize.
  function setRawBase64(dataBase64) {
    start = 0;
    for (var i = 0; i < lastValues.size(); i++) {
      lastValues[i] = 0;
    }
    var d = StringUtil.convertEncodedString(
        dataBase64,
        { :fromRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
          :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY });
    end = d.size();
    if (data == null || data.size() <= d.size()) {
      data = d;
    } else {
      for (var i = 0; i < end; i++) {
        data[i] = d[i];
      }
    }
    var i = 0;
    while (start < end) {
      lastValues[i % lastValues.size()] += readFirstDelta();
      i++;
    }
    start = 0;
  }

  function toRawBase64() {
    return StringUtil.convertEncodedString(
        data.slice(start, end),
        { :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
          :toRepresentation => StringUtil.REPRESENTATION_STRING_BASE64 });
  }

  function setRaw(lastValues, data, byteSize) {
    me.data = data;
    me.lastValues = lastValues;
    me.start = 0;
    me.end = byteSize;
  }

  hidden function zigzagEncode (i) {
    return (i >> 31) ^ (i << 1);
  }

  hidden function zigzagDecode (i) {
    // emulate >>> 1
    var x = (i >> 1) & 0x7fffffff;
    return x ^ (-1 * (i & 1));
  }

  function empty() {
    return start == end;
  }

  function capacity() {
    return data.size();
  }

  function remaining() {
    if (end < start) {
      return start - end;
    } else {
      return capacity() + start - end;
    }
  }

  function fill() {
    return 1 - remaining().toFloat() / capacity();
  }

  function byteSize() {
    return capacity() - remaining();
  }

  hidden function currentPosition() {
    return end;
  }

  function add1(value) {
    addI(value, 0);
  }

  function add2(value0, value1) {
    addI(value0, 0);
    addI(value1, 1);
  }

  hidden function addI(value, i) {
    var delta = value - lastValues[i];
    addVarEncoded(delta);
    lastValues[i] = value;
  }

  function deleteTo(pos) {
    if (start < pos) {
      start = pos;
      if (start == end) {
        for (var i = 0; i < lastValues.size(); i++) {
          lastValues[i] = 0;
        }
      }
    }
  }

  hidden function addVarEncoded(value) {
    value = zigzagEncode(value.toLong());
    while (true) {
      if (value > 127) {
        set((value & 0x7f) | 0x80);
        value = value >> 7;
      } else {
        set(value);
        break;
      }
    }
  }

  function removeFirst() {
    for (var i = 0; i < lastValues.size(); i++) {
      readFirstDelta();
    }
  }

  hidden function set(byte) {
    if (remaining() == 0) {
      removeFirst();
    }

    var wi = end % data.size();
    data[wi] = byte.toNumber();
    end++;
  }

  hidden function get(pos) {
    var wi = pos % data.size();
    return data[wi];
  }

//  hidden function hexToNum(char) {
//    if (char >= '0' && char <= '9') {
//      return char.toNumber() - '0'.toNumber();
//    } else if (char >= 'a' && char <= 'f') {
//      return 10 + char.toNumber() - 'a'.toNumber();
//    } else if (char >= 'A' && char <= 'F') {
//      return 10 + char.toNumber() - 'A'.toNumber();
//    } else {
//      throw new Lang.InvalidValueException(char.toString());
//    }
//  }
//
//  function fromEncodedString(str) {
//    var chars = str.toCharArray();
//    start = 0;
//    end = 0;
//    lastValues = [];
//    var i;
//    for (i = 0; i < chars.size(); i += 2) {
//      if (chars[i] == ',') {
//        break;
//      }
//      var b = (hexToNum(chars[i]) << 4) + hexToNum(chars[i+1]);
//      set(b);
//    }
//    i++;
//    for (; i < chars.size(); i += 9) {
//      lastValues.add(str.substring(i, i+8).toNumberWithBase(0x10));
//    }
//  }
//
//  function toEncodedString() {
//    var chars = new [2*byteSize()];
//    for (var i = start; i < end; i++) {
//      var b = get(i).format("%02x").toCharArray();
//      chars[2*(i-start)] = b[0];
//      chars[2*(i-start)+1] = b[1];
//    }
//    var s = StringUtil.charArrayToString(chars);
//    for (var i = 0; i < lastValues.size(); i++) {
//      s = s + "," + lastValues[i].format("%08x");
//    }
//    return s;
//  }

  function toArray() {
    var a = [];
    var currentStart = start;
    while (true) {
      var value = readFirstDelta();
      if (value == null) {
        break;
      }
      a.add(value);
    }
    start = currentStart;
    var values = [].addAll(lastValues);
    var valuesIdx = values.size() - 1;
    for (var i = a.size() - 1; i >= 0; i--) {
      var v = a[i];
      a[i] = values[valuesIdx];
      values[valuesIdx] = values[valuesIdx] - v;
      valuesIdx = (valuesIdx + 1) % values.size();
    }    return a;
  }

  function toArrayTail(n) {
    var a = toArrayTailDeltas(n);
    var l = [].addAll(lastValues);
    for (var i = a.size() - 1; i >= 0; i--) {
      var delta = a[i];
      var entryIdx = i % l.size();
      a[i] = l[entryIdx];
      l[entryIdx] = a[i] - delta;
    }
    return a;
  }

  function toArrayTailDeltas(n) {
    if (start == end) { return null; }

    var a = new [lastValues.size() * n];
    var pos = end-1;
    var i = a.size() - 1;
    var value = get(pos);
    while (pos > start && i >= 0) {
      pos--;
      var b = get(pos);
      if (b < 128) {
        a[i] = zigzagDecode(value);
        i--;
        value = b;
      } else {
        value = value << 7;
        value = value | (b & 0x7f);
      }
    }
    if (i >= 0) {
      a[i] = zigzagDecode(value);
    }
    return i > 0 ? a.slice(i, a.size()) : a;
  }

  function readFirstDelta() {
    if (start == end) { return null; }

    var value = 0L;
    var i = 0;
    while (true) {
      var byte = get(start);
      // Log.i("enc", "read=" + byte + " r2=" + (byte&0x7f));
      start++;
      value = value | ((byte & 0x7f) << i);
      if ((byte & 0x80) == 0) {
         break;
      }
      i = i + 7;
    }
    // Log.i("enc", "zz=" + value +" z=" + value.toNumber() + " delta=" + zigzagDecode(value) + " s=" + start);

    return zigzagDecode(value).toNumber();
  }
}
*/
}
