import Toybox.Lang;

using Shared;
using Shared.Log;
using Toybox.Application.Properties;

// Wraps Shared.HttpClient to call GET /device/roadbook and parse the response into a flat
// array of town dictionaries: {:name, :distanceMeter, :place, :larger}. "larger" marks the
// response's nextLargerTown, merged into the same row if it's already among nextTowns.
//
// Also surfaces the uploaded course as {:name, :lengthMeter, :ascentMeter}, and the server's own
// "status" string. lat/lon are optional: omitting them asks for the course only, which is the one
// request that works before the device has a GPS fix.
class RoadbookClient {
  private static const TAG = "RoadbookClient";

  private var httpClient as Shared.HttpClient;
  private var requestPending as Boolean = false;
  private var callback as (Method(
      towns as Array, course as Dictionary?, status as String?,
      errorMessage as String?) as Void)?;

  function initialize() {
    // NOT "no course uploaded": a bare 404 only says the server answered and the path wasn't
    // there, which after the next-towns -> roadbook rename most likely means an old server or a
    // wrong ServerUrl. The server sends status "no course uploaded" in the body when that is
    // genuinely the reason, and onResult below prefers it - so this label is only ever seen when
    // we have no idea, and it should not claim to know.
    httpClient = new Shared.HttpClient(
        Properties.getValue("ServerUrl") as String, "bad server URL", "cannot reach server");
  }

  function isRequestPending() as Boolean {
    return requestPending;
  }

  function requestRoadbook(
      lat as Double?, lon as Double?,
      callback as Method(
          towns as Array, course as Dictionary?, status as String?,
          errorMessage as String?) as Void) as Void {
    if (requestPending) {
      return;
    }
    requestPending = true;
    me.callback = callback;
    var parameters = {
        "passcode" => Properties.getValue("Passcode") as String,
        "count" => (Properties.getValue("Count") as Number).toString(),
        "bufferMeter" => (Properties.getValue("BufferMeter") as Number).toString(),
        "offCourseMeter" => (Properties.getValue("OffCourseMeter") as Number).toString() };
    if (lat != null && lon != null) {
      parameters["lat"] = lat.format("%.6f");
      parameters["lon"] = lon.format("%.6f");
    }
    httpClient.get("roadbook", method(:onResult), parameters);
  }

  function onResult(result as Dictionary<String, Object>) as Void {
    requestPending = false;
    var cb = callback;
    if (cb == null) {
      return;
    }
    var code = result["httpCode"] as Number;
    var serverStatus = result["status"];
    if (code != 200) {
      Log.i(TAG, "onResult failed " + code + " " + serverStatus);
      // The server names the reason ("unknown passcode", "no course uploaded", ...), which beats
      // HttpClient's generic per-code label - but Garmin doesn't always hand us the body on an
      // error code, so keep the label as a fallback.
      var message = serverStatus instanceof String
          ? serverStatus as String
          : (result["errorMessage"] as String);
      cb.invoke([] as Array, null, null, message);
      return;
    }

    var course = null;
    var c = result["course"];
    if (c != null) {
      var cd = c as Dictionary;
      // :ascentMeter stays untyped - the GPX may have had no elevation data, so it can be null.
      // :durationSecond likewise: the server only predicts when it has a stored elevation profile
      // for the course, and older uploads have none. Unlike the row durations this one covers the
      // whole course from its start, not the part still ahead of the rider.
      course = {
          :name => cd["name"] as String,
          :lengthMeter => cd["lengthMeter"] as Number,
          :ascentMeter => cd["ascentMeter"],
          :durationSecond => cd["durationSecond"] };
    }

    var towns = [] as Array;
    var nextTowns = result["nextTowns"] as Array;
    for (var i = 0; i < nextTowns.size(); i++) {
      var t = nextTowns[i] as Dictionary;
      // :durationSecond is the predicted riding time from the rider's current position to this
      // row, excluding stops - so it is only meaningful together with the distance in the same
      // response. Untyped: null whenever the course has no stored elevation profile.
      towns.add({
          :name => t["name"] as String,
          :distanceMeter => t["distanceMeter"] as Number,
          :durationSecond => t["durationSecond"],
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
            :durationSecond => lt["durationSecond"],
            :place => lt["place"],
            :larger => true });
      }
    }

    // Passes and high points go into the same array as the towns and the whole thing is sorted by
    // distance, so the rider reads one list of what's coming rather than two. :name is null when
    // the server found no matching summit/col - TownTable labels those by altitude.
    var nextPeaks = result["nextPeaks"];
    if (nextPeaks != null) {
      var peaks = nextPeaks as Array;
      for (var i = 0; i < peaks.size(); i++) {
        var p = peaks[i] as Dictionary;
        towns.add({
            :name => p["name"],
            :distanceMeter => p["distanceMeter"] as Number,
            :durationSecond => p["durationSecond"],
            :altitudeMeter => p["altitudeMeter"] as Number,
            :place => null,
            :larger => false,
            :peak => true });
      }
      sortByDistance(towns);
    }

    Log.i(TAG, "onResult " + towns.size() + " rows, status " + serverStatus);
    cb.invoke(towns, course, serverStatus instanceof String ? serverStatus as String : null, null);
  }

  // Insertion sort: the list is at most a couple of dozen rows and already nearly ordered (both
  // sources arrive sorted), so this beats hauling in anything cleverer.
  private function sortByDistance(rows as Array) as Void {
    for (var i = 1; i < rows.size(); i++) {
      var row = rows[i] as Dictionary;
      var distance = row[:distanceMeter] as Number;
      var j = i - 1;
      while (j >= 0 && ((rows[j] as Dictionary)[:distanceMeter] as Number) > distance) {
        rows[j + 1] = rows[j];
        j--;
      }
      rows[j + 1] = row;
    }
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
