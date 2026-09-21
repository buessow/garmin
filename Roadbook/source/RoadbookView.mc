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
  private var pois as Array = [] as Array;
  private var course as Dictionary? = null;
  private var destination as Dictionary? = null;
  private var statusText as String = WAITING_FOR_GPS_STATUS;
  private var updatedAgoSec as Number?;

  private var currentPos as [Double, Double]?;
  private var lastQueryPos as [Double, Double]?;
  private var lastFailedTimeSec as Number?;
  private var courseDownload as CourseDownload? = null;
  // Set while a freshly imported course is waiting to be started, which is what makes Select do
  // that instead of its usual manual refresh. Cleared by the next roadbook response, so the offer
  // never outlives the status line that advertises it.
  private var courseReadyToStart as Boolean = false;
  // Set while a category picked from the menu is still loading, so its POIs open the selection
  // menu as soon as they land rather than stopping at the table behind it. One-shot: the later
  // refreshes that a ride produces must not keep reopening it over whatever the rider is doing.
  private var openPoiMenuWhenLoaded as Boolean = false;
  private var showingArrival as Boolean = TownTable.showsArrival(Util.nowSec());
  private var poiMode as String?;
  private var poiTitle as String = "Roadbook";
  private var lastRequestedPoiMode as String?;

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
    if (currentPos != null) {
      refresh();
    } else {
      lastRequestedPoiMode = null;
      client.requestRoadbook(null, null, null, method(:onRoadbook));
    }
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
    if (poiMode == null) {
      table.draw(dc, towns, course, destination, statusText, footerText(), "Roadbook");
    } else {
      table.draw(dc, pois, null, null, statusText, footerText(), poiTitle);
    }
  }

  // Bypasses both the movement threshold and the failure backoff below - used by InputHandler
  // for a manual refresh. Without a fix it still re-queries the course, so a manual retry reports
  // a real error instead of silently doing nothing.
  function refresh() as Void {
    var pos = currentPos;
    if (pos != null) {
      requestRoadbook(pos[0], pos[1]);
    } else if (!client.isRequestPending()) {
      lastRequestedPoiMode = null;
      client.requestRoadbook(null, null, null, method(:onRoadbook));
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
      requestRoadbook(lat, lon);
    }
  }

  private function requestRoadbook(lat as Double, lon as Double) as Void {
    if (client.isRequestPending()) {
      return;
    }
    Log.i(TAG, "requestRoadbook " + lat + "," + lon + " poi=" + poiMode);
    lastQueryPos = [lat, lon];
    statusText = "loading...";
    Ui.requestUpdate();
    lastRequestedPoiMode = poiMode;
    client.requestRoadbook(lat, lon, poiMode, method(:onRoadbook));
  }

  function onRoadbook(
      newTowns as Array, newPois as Array, newCourse as Dictionary?,
      newDestination as Dictionary?, newStatus as String?, errorMessage as String?) as Void {
    // A menu selection can change mode while the previous HTTP request is still in flight. Do not
    // show that previous screen's empty result under the new heading; immediately request the mode
    // the rider actually selected now that the client is idle again.
    if (currentPos != null && !sameMode(lastRequestedPoiMode, poiMode)) {
      refresh();
      return;
    }
    if (errorMessage != null) {
      lastFailedTimeSec = Util.nowSec();
      courseReadyToStart = false;
      // The error belongs on the table, where it is readable - not behind a menu.
      openPoiMenuWhenLoaded = false;
      statusText = errorMessage;
      towns = [] as Array;
      pois = [] as Array;
      // Destination is rider-relative like the towns, so it goes stale the same way; the course
      // itself is kept - a dropped connection doesn't mean it's gone, and leaving the header up
      // makes clear the error is about this request, not the setup.
      destination = null;
      Ui.requestUpdate();
      return;
    }

    lastFailedTimeSec = null;
    // A fresh roadbook reply overwrites the status line, so the "select to start" offer it was
    // advertising has to go with it - otherwise Select would silently start a course with nothing
    // on screen saying it would.
    courseReadyToStart = false;
    if (newCourse != null) {
      course = newCourse;
    }
    if (newStatus != null && newStatus.equals("no position")) {
      // Reply to the course-only request - it says nothing about the towns or the destination
      // (both are relative to a position we don't have yet), so leave them alone. The status does
      // need resetting though: a request that failed before this one succeeded may have left an
      // error message sitting here, which a later success has to clear even though there's still
      // nothing more specific than "waiting for GPS..." to say instead.
      statusText = WAITING_FOR_GPS_STATUS;
      Ui.requestUpdate();
      return;
    }

    updatedAgoSec = Util.nowSec();
    towns = newTowns;
    pois = newPois;
    destination = newDestination;
    if (newStatus != null) {
      statusText = newStatus;
    } else {
      statusText = poiMode == null
          ? (newTowns.size() == 0 ? "no upcoming towns" : "")
          : (newPois.size() == 0 ? emptyPoiStatus() : "");
    }
    Ui.requestUpdate();

    // Picked from the menu and the reply is in: go straight to the selection menu, which is what
    // the rider is after. Cleared either way - an empty list stays on the table where the status
    // line explains why, and must not leave the menu armed to spring open later in the ride when
    // some water finally comes into range.
    if (openPoiMenuWhenLoaded && poiMode != null) {
      openPoiMenuWhenLoaded = false;
      if (newPois.size() > 0) {
        openPoiNavigationMenu();
      }
    }
  }

  function showPoi(mode as String, title as String) as Void {
    poiMode = mode;
    poiTitle = title;
    lastQueryPos = null;
    statusText = "loading...";
    // The POIs aren't here yet - the request goes out on the next position fix - so the menu can
    // only be opened once the response arrives. See onTowns.
    openPoiMenuWhenLoaded = true;
    Ui.requestUpdate();
  }

  // POI rows are drawn in the compact roadbook table, which has no focusable row controls of its
  // own. Select/tap therefore opens a Menu2 containing the same loaded destinations; selecting one
  // there saves a temporary waypoint and hands it to Garmin's native navigation.
  function openPoiNavigationMenu() as Boolean {
    if (poiMode == null) {
      return false;
    }
    if (pois.size() == 0) {
      refresh();
      return true;
    }
    var menu = new PoiNavigationMenu(pois, poiTitle);
    Ui.pushView(menu, new PoiNavigationMenuDelegate(pois, method(:navigationFailed)), Ui.SLIDE_UP);
    return true;
  }

  function navigationFailed(message as String) as Void {
    statusText = message;
    Ui.requestUpdate();
  }

  // Held in a field because the request is asynchronous and a local would be collected before the
  // response callback runs. Reports through the same status line as navigation failures.
  function downloadCourse() as Void {
    // Passes the name already on screen, which is the same one the server writes into the FIT file
    // - that is how CourseDownload recognises its own earlier import of this course.
    var c = course;
    courseDownload = new CourseDownload(
        c == null ? null : c[:name] as String,
        method(:navigationFailed),
        method(:courseImported));
    (courseDownload as CourseDownload).start();
  }

  function courseImported() as Void {
    courseReadyToStart = true;
    // Deliberately not the course name: this line is drawn centred and untruncated, so a long name
    // would run off the 246px screens. The name is already in the course header above.
    statusText = "select to start course";
    Ui.requestUpdate();
  }

  // Returns whether Select/tap was consumed by starting the course rather than refreshing. Only
  // ever true right after a download, so the button keeps its usual meaning the rest of the time.
  function startImportedCourse() as Boolean {
    if (!courseReadyToStart) {
      return false;
    }
    courseReadyToStart = false;
    var download = courseDownload;
    if (download == null) {
      return false;
    }
    download.startImported();
    return true;
  }

  // Returns whether Back was consumed. At the ordinary roadbook level false lets the system close
  // the widget as before; on a POI screen it first returns to the roadbook and refreshes its data.
  function showRoadbook() as Boolean {
    if (poiMode == null) {
      return false;
    }
    poiMode = null;
    poiTitle = "Roadbook";
    openPoiMenuWhenLoaded = false;
    lastQueryPos = null;
    statusText = "loading...";
    refresh();
    Ui.requestUpdate();
    return true;
  }

  private function sameMode(a as String?, b as String?) as Boolean {
    if (a == null || b == null) {
      return a == null && b == null;
    }
    return a.equals(b);
  }

  private function emptyPoiStatus() as String {
    if (poiMode != null && (poiMode as String).equals("water")) {
      return "no upcoming water";
    }
    if (poiMode != null && (poiMode as String).equals("toilet")) {
      return "no upcoming toilets";
    }
    return "no upcoming food";
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
