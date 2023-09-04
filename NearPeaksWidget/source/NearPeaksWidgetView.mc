using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.Graphics as Gfx;
using Toybox.Math;
using Toybox.Position;
using Toybox.WatchUi as Ui;

class NearPeaksWidgetView extends Ui.View {
  // Example coordinates: 46.94393405536843,8.754258155822754 
  hidden const TAG = "NearPeaksWidgetView";
  hidden var lookup = new OverpassLookup();
  var peaks;


  function initialize() {
    Log.i(TAG, "initialize");
    View.initialize();
    Position.enableLocationEvents(
        { :acquisitionType => Position.LOCATION_ONE_SHOT,
	  :constellation => [
	      Position.CONSTELLATION_GPS,
	      Position.CONSTELLATION_GLONASS,
	      Position.CONSTELLATION_GALILEO],
	  :mode => Position.POSITIONING_MODE_NORMAL
	}, method(:onPosition));
  }

  function onLayout(dc) {
    Log.i(TAG, "onLayout");
    setLayout(Rez.Layouts.MainLayout(dc));
    getPeaksAtCurrentPosition();
  }

  function onUpdate(dc) {
    try {
      View.onUpdate(dc);
    } catch (e) {
      Log.e(TAG, e.getErrorMessage());
      e.printStackTrace();
    }
  }

  function getPeaksAtCurrentPosition() {
    Log.i(TAG, "getPeaksAtCurrentPosition");
    onPosition(Position.getInfo());
  }

  hidden function formatLatLon(lat, lon) {
    return Lang.format("($1$,$2$)", [lat.format("%.2f"), lon.format("%.2f")]);
  }

  function onPosition(posInfo) {
    Log.i(TAG, "onPosition");
    if (posInfo == null || posInfo.position == null || posInfo.when == null) {
      Log.i(TAG, "getPeaksAtCurrentPosition no position");
      return;
    }
    var latlonR = posInfo.position.toRadians();
    var lat = Math.toDegrees(latlonR[0]);
    var lon = Math.toDegrees(latlonR[1]);
    Log.i(TAG, "onPosition " + formatLatLon(lat, lon) + " " + posInfo.accuracy);
    if (Util.abs(lat) > 90 || Util.abs(lon) >= 180) {
      Log.i(TAG, "getPeaksAtCurrentPosition no fix?");
      return;
    }
    Log.i(TAG, "onPosition " + formatLatLon(lat, lon));
    View.findDrawableById("PositionLabel").setText(formatLatLon(lat, lon));
    View.findDrawableById("PeaksText").setText("loading ...");
    View.findDrawableById("ElevationText").setText("");
    lookup.getPeaks(lat, lon, method(:showPeaks), method(:showFail));
  }

  function showFail(code) {
    View.findDrawableById("PeaksText").setText("fail " + code);
  }

  function showPeaks(peaks) {
    me.peaks = peaks;
    var s1 = "";
    var s2 = "";
    for (var i = 0; i < peaks.size(); i++) {
      s1 += peaks[i][:name].substring(0, 15) + "\n";
      s2 += Util.ifNull(peaks[i][:elevation], "-") + "\n";
    }
    View.findDrawableById("PeaksText").setText(s1);
    View.findDrawableById("ElevationText").setText(s2);
    Ui.requestUpdate();
  }
}
