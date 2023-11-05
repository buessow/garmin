import Toybox.Lang;

using Toybox.Application.Properties;
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
    var values = Shared.DeltaVarEncoder.decodeBase64(2, msg["encodedGlucose"] as String);
    data.glucoseBuffer = new DateValues(values, values.size() / 2);

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
    var channel = result["channel"];
    if ("http".equals(channel)) {
      onHttpData(result, data);
    } else if ("phoneApp".equals(channel)) {
      onPhoneAppData(result, data);
    }
    Log.i(TAG, "onBackgroundData done " + channel);
  }

  function onHttpData(
      result as Dictionary<String, Object> or Null, 
      data as Data) as Void {
    var code = result["httpCode"];
    Log.i(TAG, "onBackgroundData " + Util.ifNull(code, -1).toString());
    var key = result["key"];
    if (key != null && !key.equals(Properties.getValue("AAPSKey"))) {
      Log.i(TAG, "Got key '" + key + "'");
      Properties.setValue("AAPSKey", key);
    }
    data.requestTimeSec = result["startTimeSec"];
    try {
      if (code == 200) {
        onData(result, data);
        if (glucoseField != null && data.hasValue()) {
          glucoseField.setData(data.glucoseBuffer.getLastValue());
        }
      } else {
        data.errorMessage = result["errorMessage"];
      }
    } catch (e) {
      Log.e(TAG, "ex ");
      e.printStackTrace();
      data.errorMessage = e.getErrorMessage();
    }
  }

  function onPhoneAppData(
      result as Dictionary<String, Object> or Null, 
      data as Data) as Void {
    var key = result["key"];
    Log.i(TAG, "Got key '" + key + "'");
    Properties.setValue("AAPSKey", key);
    if (result.hasKey("encodedGlucose")) {
      onData(result, data);
    }
    if (glucoseField != null && data.hasValue()) {
      glucoseField.setData(data.glucoseBuffer.getLastValue());
    }
  }
}
}
