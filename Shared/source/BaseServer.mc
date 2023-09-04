using Toybox.Attention;
using Toybox.FitContributor as Fit;

module Shared {

(:background)
class BaseServer {
  private const TAG = "BaseServer";
  hidden var glucoseField;

  function initialize() {
  }

  function initGlucoseField(view) {
    glucoseField = view.createField(
        "Glucose", 243, Fit.DATA_TYPE_SINT32,
        {:units => "mgdl", :mesgType => Fit.MESG_TYPE_RECORD });
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

  function alert(result) {
    if (result == null) {
      return;
    }
    var values = Shared.DeltaVarEncoder.decodeBase64(2, msg["encodedGlucose"]);
    if (values.size() < 4) {
      return;
    }
    var now = Time.now();
    var v0 = new Shared.DateValue(values[values.size()-3], values[values.size()-2]);
    var v1 = new Shared.DateValue(values[values.size()-1], values[values.size()-0]);
    if (v1.value >= 60 && v1.value > v0.value) {
      //return;
    }
    if (Attention has :vibrate) {
      var vibeData = [
        new Attention.VibeProfile(50, 2000),
        new Attention.VibeProfile(0, 2000),
        new Attention.VibeProfile(50, 2000),
        new Attention.VibeProfile(0, 2000),
        new Attention.VibeProfile(50, 2000)];
      Log.i(TAG, "vibrate");
      Attention.vibrate(vibeData);
    }
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
	Log.i(TAG, "onBackgroundData error " + data.errorMessage);
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
