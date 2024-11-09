import Toybox.Lang;

using Shared.Log;

module Shared {
class Override {
  private static const TAG = "Override";
  var overrides as Dictionary<String, Object> = {} as Dictionary<String, Object>;

  function initialize() {
    var partNumber = System.getDeviceSettings().partNumber;
    var deviceId = PartNumbers.map[partNumber];
    var allOverrides = {} as Dictionary<String, Object>;
    if (Rez has :JsonData && Rez.JsonData has :overrides) {
      allOverrides = Application.loadResource(Rez.JsonData.overrides) as Dictionary<String, Object>;
    } else {
      return;
    }
    var deviceOverrides = allOverrides["devices"] as Array;
    Log.i(TAG, "looking for override " + partNumber + " " + deviceId + " " + deviceOverrides);

    if (deviceOverrides == null) {
      return;
    }

    for (var i = 0; i < deviceOverrides.size(); i++) {
      var o = deviceOverrides[i] as Dictionary<String, Array<String>>;
      if (o["deviceIds"].indexOf(deviceId) != -1) {
        Log.i(TAG, "override " + deviceId + " " + o);
        me.overrides = o;
        break;
      }
    }
  }

  function getInt(className as String, key as String, defaultValue as Number) as Number {
    if (overrides[className] == null) { //} || overrides[className][key] == null) {
      return defaultValue;
    }
    var value = overrides[className][key] as Number;
    return value == null ? defaultValue : value;
  }

  function get(key as String) as Dictionary<String, Object> {
    return overrides[key] as Dictionary<String, Object>;
  }
}
}