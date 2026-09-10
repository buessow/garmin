import Toybox.Lang;

using Shared.Log;
using Toybox.Activity;
using Toybox.Application.Properties;
using Toybox.Communications as Comm;
using Toybox.PersistedContent;
using Toybox.System;

// Loads the rider's current atweb course onto the device as a native Garmin course, by asking the
// system to import a FIT file rather than parsing it here: makeWebRequest with
// :responseType => HTTP_RESPONSE_CONTENT_TYPE_FIT downloads the response and stores it in the
// device's persisted content, handing back a PersistedContent.Iterator over what it created.
// Edge devices take FIT; GPX is the outdoor-handheld format.
//
// The import does not happen while an activity is recording. That is not documented anywhere in
// the Connect IQ API - it was established by running this against the server twice, and the same
// request that imports a course when the timer is stopped silently imports nothing when it is
// running. Hence the timer check below: the rider gets told to stop the timer instead of spending
// a BLE transfer on a file the system will discard.
class CourseDownload {
  private static const TAG = "CourseDownload";

  private var report as Method(line as String) as Void;
  private var onImported as Method() as Void;
  // The name the roadbook header shows for the current course, which the server also writes into
  // the FIT file - so it identifies the copy a new download should replace. Null before the first
  // roadbook response has arrived, in which case nothing is replaced.
  private var courseName as String?;

  function initialize(
      courseName as String?,
      report as Method(line as String) as Void,
      onImported as Method() as Void) {
    me.courseName = courseName;
    me.report = report;
    me.onImported = onImported;
  }

  function start() as Void {
    if (isRecording()) {
      // See the class comment - the transfer would succeed and the import would be dropped.
      Log.i(TAG, "refusing to download while recording");
      report.invoke("stop timer to load course");
      return;
    }

    // Before the request: a failed download then leaves the rider with neither copy, but the
    // alternative is two courses of the same name and no way to tell which is current.
    removePrevious();

    var url = (Properties.getValue("ServerUrl") as String) + "course.fit";
    Log.i(TAG, "GET " + url);
    report.invoke("downloading course...");
    try {
      Comm.makeWebRequest(
          url,
          { "passcode" => Properties.getValue("Passcode") as String },
          {
            :method => Comm.HTTP_REQUEST_METHOD_GET,
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_FIT,
            :fileDownloadProgressCallback => method(:onProgress)
          },
          method(:onResult));
    } catch (e) {
      Log.e(TAG, "makeWebRequest threw: " + e.getErrorMessage());
      report.invoke("could not download course");
    }
  }

  function onProgress(totalBytesTransferred as Number, fileSize as Number?) as Void {
    Log.i(TAG, "progress " + totalBytesTransferred + "/" + (fileSize == null ? "?" : fileSize));
  }

  // data is typed Dictionary or String or PersistedContent.Iterator or Null. With a FIT
  // responseType a successful import gives the Iterator; the other shapes all mean it didn't land.
  function onResult(
      responseCode as Number,
      data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
    if (responseCode != 200) {
      Log.e(TAG, "failed, code " + responseCode);
      // The endpoint returns a binary body, so unlike the roadbook request there is no server
      // message to show - only the code, which HttpClient's labels don't cover here.
      report.invoke(responseCode == 404
          ? "no course uploaded"
          : (responseCode == 401 ? "bad passcode" : "download failed " + responseCode));
      return;
    }
    if (!(data instanceof PersistedContent.Iterator)) {
      // Also what an unsupported file type looks like, per the Connect IQ docs, so the message
      // stays vague on purpose rather than guessing which it was.
      Log.e(TAG, "200 but nothing imported: " + (data == null ? "NULL" : data.toString()));
      report.invoke("course not accepted");
      return;
    }

    var count = 0;
    var firstName = null;
    var item = (data as PersistedContent.Iterator).next();
    while (item != null) {
      count++;
      var name = item.getName();
      Log.i(TAG, "imported id " + item.getId() + " '" + name + "'");
      if (firstName == null) {
        firstName = name;
      }
      item = (data as PersistedContent.Iterator).next();
    }

    if (count == 0) {
      Log.e(TAG, "empty iterator - nothing imported");
      report.invoke("course not accepted");
      return;
    }
    Log.i(TAG, "imported " + count + " item(s)");
    // The name the device stored, not the one asked for, so a later startImported() looks for what
    // is actually there.
    courseName = firstName as String;
    onImported.invoke();
  }

  // Drops the previous import of *this* course, so downloading it again replaces it rather than
  // leaving the rider to pick the newest of several identically named courses. Courses this app
  // imported for a different route are left alone - having ridden one of those is a good reason to
  // still have it. getAppCourses only ever returns this app's own, so nothing the rider loaded
  // through Garmin Connect is at risk either way.
  private function removePrevious() as Void {
    var name = courseName;
    if (name == null) {
      return;
    }
    try {
      var courses = PersistedContent.getAppCourses();
      var item = courses.next();
      while (item != null) {
        // next() before remove(): removing the item the iterator is standing on would otherwise
        // leave it with nowhere to advance to.
        var next = courses.next();
        if (name.equals(item.getName())) {
          Log.i(TAG, "replacing previous '" + item.getName() + "' id " + item.getId());
          item.remove();
        }
        item = next;
      }
    } catch (e) {
      // Not fatal: a stale duplicate is better than refusing to download.
      Log.e(TAG, "could not remove previous course: " + e.getErrorMessage());
    }
  }

  // Hands the imported course to Garmin's native navigation. Launching persisted content is not
  // importing it, so unlike the download this is not restricted while the timer runs - the same
  // reason POI waypoint navigation works mid-ride. exitTo() shows its own confirmation dialog and
  // then quits this app, so the rider is never taken out of the roadbook without being asked.
  function startImported() as Void {
    var name = courseName;
    if (name == null) {
      report.invoke("no course loaded");
      return;
    }
    try {
      var found = null;
      var courses = PersistedContent.getAppCourses();
      var item = courses.next();
      while (item != null) {
        if (name.equals(item.getName())) {
          found = item;
          break;
        }
        item = courses.next();
      }
      if (found == null) {
        Log.e(TAG, "no imported course named '" + name + "'");
        report.invoke("course not found");
        return;
      }
      Log.i(TAG, "starting course '" + name + "' id " + found.getId());
      System.exitTo((found as PersistedContent.Course).toIntent());
    } catch (e) {
      Log.e(TAG, "could not start course: " + e.getErrorMessage());
      report.invoke("could not start course");
    }
  }

  private function isRecording() as Boolean {
    var info = Activity.getActivityInfo();
    if (info == null || info.timerState == null) {
      return false;
    }
    return info.timerState == Activity.TIMER_STATE_ON;
  }
}
