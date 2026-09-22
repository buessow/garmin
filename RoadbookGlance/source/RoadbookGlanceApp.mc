import Toybox.Lang;

using Shared.Log;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.System;
using Toybox.WatchUi as Ui;

// Roadbook built for the Edge generation that replaced widgets with glances. Everything the app
// actually does - the roadbook screen, POI menus, course download - is Roadbook's own code, reached
// through RoadbookView and InputHandler below.
//
// Extends AppBase directly rather than RoadbookApp, even though that duplicates getInitialView. In
// glance mode the app object is constructed inside a ~32KB image containing only (:glance) code,
// and a superclass has to resolve there too - dragging RoadbookApp's whole reachable graph, the
// view and HTTP client included, into a space that cannot hold it. Subclassing crashed the app on
// launch; this is the shape GlucoseWidgetApp uses, and it works.
class RoadbookGlanceApp extends Application.AppBase {
  private static const TAG = "RoadbookGlanceApp";
  private var view as RoadbookView?;

  function initialize() {
    AppBase.initialize();
  }

  function onStart(state as Lang.Dictionary or Null) as Void {
  }

  function onStop(state as Lang.Dictionary or Null) as Void {
  }

  // The one thing this build adds. Left unannotated, like GlucoseWidgetApp's: the (:glance) marks
  // go on the constructors the glance image has to reach, not on the app's own methods.
  function getGlanceView() {
    return [ new RoadbookGlanceView() ];
  }

  // Not (:glance), so none of this reaches the glance image - which is the point.
  function getInitialView() as [ Ui.Views ] or [ Ui.Views, Ui.InputDelegates ] {
    // Properties.setValue is disallowed from a background-process context (this app declares the
    // Background permission so Shared.HttpClient/Util/Log can be reused, even though it never
    // actually runs a background service) - getInitialView, unlike onStart, only runs foreground.
    Properties.setValue("Device", System.getDeviceSettings().partNumber);
    Properties.setValue("AppVersion", "rb_" + BuildInfo.VERSION);
    Log.i(TAG, "Passcode='" + Properties.getValue("Passcode") + "' ServerUrl='" +
        Properties.getValue("ServerUrl") + "'");
    view = new RoadbookView();
    return [ view, new InputHandler(view) ];
  }
}
