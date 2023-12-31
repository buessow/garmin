import Toybox.Lang;

using Toybox.StringUtil as StringUtil;

module Shared {
module DeltaVarEncoder {

  (:glance)
  function zigzagEncode (i as Long) as Long {
    return (i >> 31) ^ (i << 1);
  }

  (:glance)
  function zigzagDecode (i as Long) as Long {
    // emulate >>> 1
    var x = (i >> 1) & 0x7fffffff;
    return x ^ (-1 * (i & 1));
  }

  (:glance)
  function get(data as ByteArray, pos as Number) {
    var wi = pos % data.size();
    return data[wi];
  }

  (:glance)
  function readDelta(
      data as ByteArray, 
      posRef as Array<Number>) as Number or Null {
    if (posRef[0] == data.size()) { return null; }

    var value = 0L;
    var i = 0;
    while (true) {
      var byte = get(data, posRef[0]);
      // Log.i("enc", "read=" + byte + " r2=" + (byte&0x7f));
      posRef[0]++;
      value = value | ((byte & 0x7f) << i);
      if ((byte & 0x80) == 0) {
         break;
      }
      i = i + 7;
    }
    // Log.i("enc", "zz=" + value +" z=" + value.toNumber() + " delta=" + zigzagDecode(value) + " s=" + start);

    return zigzagDecode(value).toNumber();
  }

  (:glance)
  function decodeBase64(entrySize as Number, dataBase64 as String) 
      as Array<Number> {
    var a = [] as Array<Number>;
    if (dataBase64 == null || dataBase64.length() == 0) {
      return a;
    }
    var lastValues = new [entrySize];
    for (var i = 0; i < entrySize; i++) {
      lastValues[i] = 0;
    }
    var data = StringUtil.convertEncodedString(
        dataBase64,
        { :fromRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
          :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY }) as ByteArray;

    var posRef = [0];
    var i = 0;
    while (true) {
      var value = readDelta(data, posRef);
      if (value == null) {
        break;
      }
      lastValues[i] = value + lastValues[i];
      a.add(lastValues[i]);
      i = (i + 1) % lastValues.size();
    }

    return a;
  }
}}
