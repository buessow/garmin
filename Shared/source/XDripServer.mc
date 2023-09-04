using Toybox.Lang;

module Shared {
/*
(:background)
class XDripServer extends BaseServer {
  hidden const TAG = "XDripServer";
  // hidden const url = "http://127.0.0.1:17580/sgv f";
  const url = "https://rmb-cgm.herokuapp.com/api/v1/entries?count=12";
  const parameters = null;

  function initialize() {
    BaseServer.initialize();
  }

  function getServiceDelegate() {
    return new GlucoseServiceDelegate(me);
  }

  function packageResp(obj, glucoseBuffer) {
    var parser = new Shared.CsvParser(obj);
    var lastSec = glucoseBuffer.size() > 0
        ? glucoseBuffer.getDateSec(glucoseBuffer.size()-1)
        : 0;
    var c = [];
    while (parser.more()) {
      var dateMillisStr = parser.next(1);
      var value = parser.next(0);
      parser.nextLine();
      var dateSec = dateMillisStr.substring(0, dateMillisStr.length() - 3).toNumber();
      if (dateSec <= lastSec) {
        break;
      }
      c.add(dateSec);
      c.add(value.toNumber());
    }
    Log.i(TAG, "got " + c.size() + " new readings");
    for (var i = c.size()-2; i >= 0; i -= 2) {
      glucoseBuffer.add(new Shared.DateValue(c[i], c[i+1]));
    }
    return glucoseBuffer;
  }

  function onData(msg, data) {
    if (msg == null || msg.size() == 0 || msg["message"] == null) {
      throw new Lang.InvalidValueException("E:no value");
    }
    packageResp(msg["message"], data.glucoseBuffer);
    data.setGlucose(data.glucoseBuffer);
    data.setRemainingInsulin(null);
    data.setTemporaryBasalRate(null);
  }
}
*/
}
