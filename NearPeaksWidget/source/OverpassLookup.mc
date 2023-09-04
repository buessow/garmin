using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Position;
using Toybox.Communications as Comm;

class OverpassLookup {
  hidden const TAG = "OverpassLookup";
  hidden const url = "https://lz4.overpass-api.de/api/interpreter";
  hidden const queryTempl = 
      "[out:json];node [natural=peak](around:5000,$1$,$2$);out;";

  function getPeaks(lat, lon, success, fail) {
    var query = Lang.format(queryTempl, [lat, lon]);
    Log.i(TAG, "getPeaks '" + query + "'");

    Comm.makeWebRequest(
        url,
	{ "data" => query },
	{ :method => Comm.HTTP_REQUEST_METHOD_POST,
	  :context => {
	      :lat => lat, :lon => lon, :success => success, :fail => fail },
	},
	method(:onOverpassResult));
  }

  function distanceLess(d1, d2) {
    return d1[:distance] < d2[:distance];
  }

  function onOverpassResult(code, obj, context) {
    Log.i(TAG, "onOverpassResult " + code);
    if (code != 200) {
      Log.e(TAG, "onOverpassResult failed " + code);
      if (context[:fail] != null) {
	fail.invoke(code);
      }
      return;
    }
    Log.i(TAG, "result " + obj["generator"]);
    var eles = obj["elements"];
    Log.i(TAG, eles.size() + " results");
    var result = [];
    for (var i = 0; i < eles.size(); i++) {
      var el = eles[i];
      if (!el.hasKey("tags")) { break; }
      var d = distance(context[:lat], context[:lon], el["lat"], el["lon"]);
      var p = {
	  :name => eles[i]["tags"]["name"], 
	  :elevation => eles[i]["tags"]["ele"], 
	  :distance => d};
      if (p[:name] != null) {
	result.add(p);
      }
    }
    Shared.Arrays.qsort(result, method(:distanceLess));
    for (var i = 0; i < Util.min(20, result.size()); i++) {
      var p = result[i];
      Log.i(TAG, "e " + p[:name] + " " + p[:elevation] + " " + p[:distance]);
    }
    context[:success].invoke(result);
  }

  // Computes the distance between two geo position given in degrees.
  hidden function distance(lat1, lon1, lat2, lon2) {
    return distanceRadian(
        Math.toRadians(lat1), 
	Math.toRadians(lon1),
	Math.toRadians(lat2),
	Math.toRadians(lon2));
  }

  // Computes the distance between two geo position given in radians.
  hidden function distanceRadian(lat1R, lon1R, lat2R, lon2R) {
    var R = 6371e3; // meters
    var deltaLatR = lat2R - lat1R;
    var deltaLonR = lon2R - lon1R;
    var a = Math.sin(deltaLatR / 2) * Math.sin(deltaLatR / 2) +
	    Math.cos(lat1R) * Math.cos(lat2R) *
	    Math.sin(deltaLonR / 2) * Math.sin(deltaLonR / 2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

    return R * c;
  }

}
