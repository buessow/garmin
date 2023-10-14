using Toybox.Attention;

module Shared {

(:background)
class BaseServer {
  private const TAG = "BaseServer";
  hidden var glucoseField;

  function initialize() {
  }

  (:fitContributor)
  function initGlucoseField(view) {
    glucoseField = view.createField(
        "Glucose", 243, Toybox.FitContributor.DATA_TYPE_SINT32,
        {:units => "mgdl", :mesgType => Toybox.FitContributor.MESG_TYPE_RECORD });
  }

  function onData(msg, data) {
    data.glucoseBuffer.clear();
    var values = Shared.DeltaVarEncoder.decodeBase64(2, msg["encodedGlucose"]);
    for (var i = 0; i < values.size(); i += 2) {
      var dv = new Shared.DateValue(values[i], values[i+1]);
      data.glucoseBuffer.add(dv);
    }
    data.setGlucose(data.glucoseBuffer);
    data.setRemainingInsulin(msg["remainingInsulin"]);
    data.setTemporaryBasalRate(msg["temporaryBasalRate"]);
    data.setProfile(msg["profile"]);
    switch (msg["glucoseUnit"]) {
      case "mmoll": data.setGlucoseUnit(Data.mmoll); break;
      default: data.setGlucoseUnit(Data.mgdl); break;
    }
    data.connected = msg["connected"];
    Log.i(TAG, "remaining: "  + data.remainingInsulin.toString());
  }

  function onBackgroundData(result, data) {
    if (result == null) {
      Log.e(TAG, "onBackgroundData NULL result");
      data.errorMessage = "null result type";
      return;
    }
    if (!(result instanceof Toybox.Lang.Dictionary)) {
      Log.e(TAG, "onBackgroundData bad result type " +  result.toString());
      data.errorMessage = "bad result type";
      return;
    }
    var code = result["httpCode"];
    Log.i(TAG, "onBackgroundData " + Util.ifNull(code, -1).toString());
    data.requestTimeSec = result["startTimeSec"];
    try {
      if (code == 200) {
        onData(result, data);
        if (glucoseField != null && data.hasValue()) {
          glucoseField.setData(data.glucoseBuffer.getLastValue());
        }
      } else {
        data.errorMessage = result["errorMessage"] + " " + code.toString();
      }
    } catch (e) {
      Log.e(TAG, "ex ");
      e.printStackTrace();
      data.errorMessage = e.getErrorMessage();
    }
    Log.i(TAG, "onBackgroundData done");
  }
}
}
