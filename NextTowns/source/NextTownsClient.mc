import Toybox.Lang;

using Shared;
using Shared.Log;
using Toybox.Application.Properties;

// Wraps Shared.HttpClient to call GET /device/next-towns and parse the response into a flat
// array of town dictionaries: {:name, :distanceMeter, :place, :larger}. "larger" marks the
// response's nextLargerTown, merged into the same row if it's already among nextTowns.
class NextTownsClient {
  private static const TAG = "NextTownsClient";

  private var httpClient as Shared.HttpClient;
  private var requestPending as Boolean = false;
  private var callback as (Method(towns as Array, errorMessage as String?) as Void)?;

  function initialize() {
    httpClient = new Shared.HttpClient(
        Properties.getValue("ServerUrl") as String, "no course uploaded");
  }

  function isRequestPending() as Boolean {
    return requestPending;
  }

  function requestNextTowns(
      lat as Double, lon as Double,
      callback as Method(towns as Array, errorMessage as String?) as Void) as Void {
    if (requestPending) {
      return;
    }
    requestPending = true;
    me.callback = callback;
    httpClient.get("next-towns", method(:onResult), {
        "passcode" => Properties.getValue("Passcode") as String,
        "lat" => lat.format("%.6f"),
        "lon" => lon.format("%.6f"),
        "count" => (Properties.getValue("Count") as Number).toString(),
        "bufferMeter" => (Properties.getValue("BufferMeter") as Number).toString() });
  }

  function onResult(result as Dictionary<String, Object>) as Void {
    requestPending = false;
    var cb = callback;
    if (cb == null) {
      return;
    }
    var code = result["httpCode"] as Number;
    if (code != 200) {
      Log.i(TAG, "onResult failed " + code);
      cb.invoke([] as Array, code == 401 ? "bad passcode" : (result["errorMessage"] as String));
      return;
    }

    var towns = [] as Array;
    var nextTowns = result["nextTowns"] as Array;
    for (var i = 0; i < nextTowns.size(); i++) {
      var t = nextTowns[i] as Dictionary;
      towns.add({
          :name => t["name"] as String,
          :distanceMeter => t["distanceMeter"] as Number,
          :place => t["place"],
          :larger => false });
    }

    var largerTown = result["nextLargerTown"];
    if (largerTown != null) {
      var lt = largerTown as Dictionary;
      var name = lt["name"] as String;
      var existing = findByName(towns, name);
      if (existing != null) {
        existing[:larger] = true;
      } else {
        towns.add({
            :name => name,
            :distanceMeter => lt["distanceMeter"] as Number,
            :place => lt["place"],
            :larger => true });
      }
    }
    Log.i(TAG, "onResult " + towns.size() + " towns");
    cb.invoke(towns, null);
  }

  private function findByName(towns as Array, name as String) as Dictionary? {
    for (var i = 0; i < towns.size(); i++) {
      var town = towns[i] as Dictionary;
      if ((town[:name] as String).equals(name)) {
        return town;
      }
    }
    return null;
  }
}
