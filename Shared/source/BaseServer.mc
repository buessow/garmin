import Toybox.Lang;

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

  function onData(
      msg as Dictionary<String, Object>, 
      data as Data) as Void{
    data.glucoseBuffer.clear();
    var values = Shared.DeltaVarEncoder.decodeBase64(2, msg["encodedGlucose"] as String);
    for (var i = 0; i < values.size(); i += 2) {
      var dv = new Shared.DateValue(values[i], values[i+1]);
      data.glucoseBuffer.add(dv);
    }
    data.updateGlucose();
    data.setRemainingInsulin(msg["remainingInsulin"] as Float?);
    data.setTemporaryBasalRate(msg["temporaryBasalRate"] as Float?);
    data.setProfile(msg["profile"] as String?);
    switch (msg["glucoseUnit"]) {
      case "mmoll": data.setGlucoseUnit(Data.mmoll); break;
      default: data.setGlucoseUnit(Data.mgdl); break;
    }
    data.connected = msg["connected"];
    Log.i(TAG, "remaining: "  + data.remainingInsulin.toString());
  }

  function onBackgroundData(
      result as Dictionary<String, Object> or Null, 
      data as Data) as Void {
    if (result == null) {
      Log.e(TAG, "onBackgroundData NULL result");
      data.errorMessage = "null result type";
      return;
    }
    if (!(result instanceof Dictionary)) {
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
