import Toybox.Lang;

using Toybox.Application.Properties;
using Toybox.FitContributor;
using Toybox.WatchUi as Ui;

module Shared {
class BaseServer {
  private const TAG = "BaseServer";

  (:background, :glance)
  function initialize() {
  }

  function onData(msg as Dictionary<String, Object>, data as Data) as Void{
    var values = Shared.DeltaVarEncoder.decodeBase64(2, msg["encodedGlucose"] as String);
    data.glucoseBuffer = new DateValues(values, values.size() / 2);

    data.updateGlucose();
    data.setRemainingInsulin(msg["remainingInsulin"] as Float?, msg["remainingBasalInsulin"] as Float?);
    data.setTemporaryBasalRate(msg["temporaryBasalRate"] as Float?);
    data.setProfile(msg["profile"] as String?);
    if (msg["glucoseUnit"] != null && "mmoll".equals(msg["glucoseUnit"])) {
      data.setGlucoseUnit(Data.mmoll); 
    } else {
      data.setGlucoseUnit(Data.mgdl);
    }

    if (msg["connected"] instanceof Boolean) {
      data.connected = msg["connected"] as Boolean;
    }
  }

  function onBackgroundData(
      result as Dictionary<String, Object> or Null, 
      data as Data) as Void {
    if (result == null) {
      Log.e(TAG, "onBackgroundData NULL result");
      data.onError("null result");
      return;
    }
    if (!(result instanceof Dictionary)) {
      Log.e(TAG, "onBackgroundData bad result type " +  result.toString());
      data.onError("bad result type");
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
    try {
      if (code == 200) {
        onData(result, data);
      } else {
        data.onError(result["errorMessage"]);
      }
    } catch (e) {
      Log.e(TAG, "ex ");
      e.printStackTrace();
      data.onError(e.getErrorMessage());
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
  }
}
}
