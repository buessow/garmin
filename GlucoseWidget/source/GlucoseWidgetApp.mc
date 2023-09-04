using Shared;
using Shared.Log;
using Toybox.Application;
using Toybox.System as Sys;

(:background)
class GlucoseWidgetApp extends Application.AppBase {
  hidden const TAG = "GlucoseWidgetApp";
  var data;
  var messenger;
  var view;
  hidden var glanceView;
  hidden var inputHandler;

  function initialize() {
    AppBase.initialize();
    Log.i(TAG, "initialize");
    if (Application.getApp().getProperty("Device") == null) {
      Application.getApp().setProperty(
          "Device", System.getDeviceSettings().partNumber + "_Widget");
    }
  }

  function onGlucose() {
    if (glanceView != null) {
      glanceView.onGlucose();
    }
    if (view != null) {
      view.onGlucose();
    }
    if (inputHandler != null) {
      inputHandler.onConnect();
    }
  }

  function onStart(state) {
  }

  function onStop(state) {
  }

  function getGlanceView() {
    data = new Shared.Data();
    messenger = new Messenger(data, method(:onGlucose));
    Log.i(TAG, "getGlanceView");
    glanceView = new GlucoseGlance(data);
    return [ glanceView ];
  }

  function onConnect() {
    Log.i(TAG, "onConnect() " + data.connected);
    if (view != null) {
      view.onGlucose();
    }
    if (inputHandler != null) {
      inputHandler.onConnect();
    }
  }

  function getInitialView() {
    try {
      data = new Shared.Data();
      messenger = new Messenger(data, method(:onGlucose));
      glanceView = null;
      onConnect();
      messenger.onConnectDone = method(:onConnect);
      var settings = Sys.getDeviceSettings();
      Log.i(TAG, "getInitialView widget");
      if (!(settings has :isGlanceModeEnabled && settings.isGlanceModeEnabled)) {
	view = new GlucoseWidgetView(data);
	messenger.view = view;
	messenger.onCarbsStart = view.method(:postCarbsStart);
	messenger.onCarbsDone = view.method(:postCarbsDone);
	return [ view, new InputHandler(messenger) ];
      } else {
	Log.i(TAG, "getInitialView glance");
	inputHandler = new InputHandler(messenger);
	return inputHandler.getViewAndDelegate();
      }
    } catch (e) {
      Log.e(TAG, e.getErrorMessage());
      e.printStackTrace();
      return null;
    }
  }
}
