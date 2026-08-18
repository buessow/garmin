import Toybox.Lang;

using Shared.Log;
using Shared.RoadbookRefreshPolicy;
using Shared.Util;
using Toybox.Graphics as Gfx;
using Toybox.Position;
using Toybox.Timer;
using Toybox.WatchUi as Ui;

class RoadbookView extends Ui.View {
  private static const TAG = "RoadbookView";
  private static const WAITING_FOR_GPS_STATUS = "waiting for GPS...";

  private var client as RoadbookClient = new RoadbookClient();
  private var table as TownTable = new TownTable();
  private var retryTimer as Timer.Timer = new Timer.Timer();

  private var towns as Array = [] as Array;
  private var course as Dictionary? = null;
  private var statusText as String = WAITING_FOR_GPS_STATUS;
  private var updatedAgoSec as Number?;

  private var currentPos as [Double, Double]?;
  private var lastQueryPos as [Double, Double]?;
  private var lastFailedTimeSec as Number?;
  private var showingArrival as Boolean = TownTable.showsArrival(Util.nowSec());

  function initialize() {
    View.initialize();
  }

  function onShow() as Void {
    var options = {
        :acquisitionType => Position.LOCATION_CONTINUOUS,
        :mode => Position.POSITIONING_MODE_NORMAL };
    // Position.CONSTELLATION_* is deprecated in favor of :configuration (CIQ 3.3.6+), and at
    // least one System 6 device in the simulator rejects :constellations outright at runtime
    // ("Unsupported configuration option") despite it still type-checking - so prefer
    // :configuration when available and only fall back to :constellations on older devices,
    // per the documented Position.enableLocationEvents fallback pattern.
    if (Position has :hasConfigurationSupport) {
      if ((Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5) &&
          Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5)) {
        options[:configuration] = Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5;
      } else if ((Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1) &&
          Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1)) {
        options[:configuration] = Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1;
      } else if ((Position has :CONFIGURATION_GPS) &&
          Position.hasConfigurationSupport(Position.CONFIGURATION_GPS)) {
        options[:configuration] = Position.CONFIGURATION_GPS;
      }
    } else if (Position has :CONSTELLATION_GLONASS) {
      options[:constellations] = [ Position.CONSTELLATION_GPS, Position.CONSTELLATION_GLONASS ];
    }
    Position.enableLocationEvents(options, method(:onPosition));

    // onPosition only runs alongside a GPS fix, which may never come (indoors, or before the
    // first fix while GPS is still acquiring) - without this, a failed request would then never
    // get retried at all. A 1s tick is frequent enough to honour RETRY_DELAY_SEC closely without
    // being a meaningful battery/CPU cost.
    retryTimer.start(method(:onRetryTimer), 1000, true);

    // Fetch the course straight away, without waiting for a fix. Getting a GPS lock can take a
    // while (or never happen indoors), and until then a broken passcode, an unreachable server and
    // a missing course all look identical to "waiting for GPS...". This request tells them apart.
    client.requestRoadbook(null, null, method(:onTowns));
  }

  function onHide() as Void {
    Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    retryTimer.stop();
  }

  // Catches the case onPosition can't: a failed request with no GPS fix to piggyback the retry
  // on. Falls through to refresh(), which already knows how to retry with or without a position.
  function onRetryTimer() as Void {
    // The table alternates arrival time and time-to-go in one column, and nothing else would
    // redraw between server responses - so the tick that already runs for retries drives the flip
    // too, rather than a second timer. Only requests an update when it actually changes.
    var arrival = TownTable.showsArrival(Util.nowSec());
    if (arrival != showingArrival) {
      showingArrival = arrival;
      Ui.requestUpdate();
    }

    var failed = lastFailedTimeSec;
    if (failed != null && Util.nowSec() - failed >= RoadbookRefreshPolicy.RETRY_DELAY_SEC) {
      refresh();
    }
  }

  function onUpdate(dc as Gfx.Dc) as Void {
    View.onUpdate(dc);
    table.draw(dc, towns, course, statusText, footerText());
  }

  // Bypasses both the movement threshold and the failure backoff below - used by InputHandler
  // for a manual refresh. Without a fix it still re-queries the course, so a manual retry reports
  // a real error instead of silently doing nothing.
  function refresh() as Void {
    var pos = currentPos;
    if (pos != null) {
      requestTowns(pos[0], pos[1]);
    } else if (!client.isRequestPending()) {
      client.requestRoadbook(null, null, method(:onTowns));
    }
  }

  function onPosition(posInfo as Position.Info) as Void {
    if (posInfo == null || posInfo.position == null) {
      return;
    }
    var latLon = posInfo.position.toDegrees();
    var lat = latLon[0];
    var lon = latLon[1];
    if (lat > 90 || lat < -90 || lon >= 180 || lon <= -180) {
      // No fix yet - some simulators/devices report (0,0) or out-of-range sentinels.
      return;
    }
    currentPos = latLon;

    if (RoadbookRefreshPolicy.shouldRequestTowns(
        lastQueryPos, lastFailedTimeSec, Util.nowSec(), lat, lon)) {
      requestTowns(lat, lon);
    }
  }

  private function requestTowns(lat as Double, lon as Double) as Void {
    if (client.isRequestPending()) {
      return;
    }
    Log.i(TAG, "requestTowns " + lat + "," + lon);
    lastQueryPos = [lat, lon];
    statusText = "loading...";
    Ui.requestUpdate();
    client.requestRoadbook(lat, lon, method(:onTowns));
  }

  function onTowns(
      newTowns as Array, newCourse as Dictionary?, newStatus as String?,
      errorMessage as String?) as Void {
    if (errorMessage != null) {
      lastFailedTimeSec = Util.nowSec();
      statusText = errorMessage;
      towns = [] as Array;
      // Keep the last known course: a dropped connection doesn't mean it's gone, and leaving the
      // header up makes clear the error is about this request, not the setup.
      Ui.requestUpdate();
      return;
    }

    lastFailedTimeSec = null;
    if (newCourse != null) {
      course = newCourse;
    }
    if (newStatus != null && newStatus.equals("no position")) {
      // Reply to the course-only request - it says nothing about the towns, so leave them alone.
      // The status does need resetting though: a request that failed before this one succeeded
      // may have left an error message sitting here, which a later success has to clear even
      // though there's still nothing more specific than "waiting for GPS..." to say instead.
      statusText = WAITING_FOR_GPS_STATUS;
      Ui.requestUpdate();
      return;
    }

    updatedAgoSec = Util.nowSec();
    towns = newTowns;
    if (newStatus != null) {
      statusText = newStatus;
    } else {
      statusText = newTowns.size() == 0 ? "no upcoming towns" : "";
    }
    Ui.requestUpdate();
  }

  private function footerText() as String? {
    var sec = updatedAgoSec;
    if (sec == null) {
      return null;
    }
    var ageMin = (Util.nowSec() - sec) / 60;
    return "updated " + (ageMin < 1 ? "<1m" : ageMin.toString() + "m") + " ago";
  }
}
