using Shared;
using Shared.Log;
using Toybox.Application;
using Toybox.System as Sys;

(:background)
class NearPeaksWidgetApp extends Application.AppBase {
  hidden static const TAG = "NearPeaksWidgetApp";
  hidden var view;

  function initialize() {
    Log.i(TAG, "initialize");
    AppBase.initialize();
  }

  function onStart(state) {
  }

  function onStop(state) {
  }

  function getGlanceView() {
    return [ new NearPeaksGlanceView() ];
  }

  function getInitialView() {
    Log.i(TAG, "getInitialView");
    try {
      view = new NearPeaksWidgetView();
      return [ view, new InputHandler(view) ];
    } catch (e) {
      Log.e(TAG, e.getErrorMessage());
      e.printStackTrace();
      return null;
    }
  }
}
