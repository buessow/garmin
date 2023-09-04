using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;

class GlucoseWidgetView extends Ui.View {
  hidden static const TAG = "GlucoseWidgetView";
  hidden var graph;
  hidden var data;
  var connected;

  function initialize(data) {
    View.initialize();
    me.data = data;
  }

  function onLayout(dc) {
    setLayout(Rez.Layouts.MainLayout(dc));
    graph = findDrawableById("DateValueGraph");
  }

  function onGlucose() {
    if (data.glucoseBuffer != null and graph != null) {
      graph.setReadings(data.glucoseBuffer);
      graph.isMmolL = data.glucoseUnit == Shared.Data.mmoll;
      findDrawableById("GlucoseLabel").setText(data.getGlucoseStr());
      findDrawableById("GlucoseDelta").setText(data.getGlucoseDeltaPerMinuteStr());
      findDrawableById("InsulinOnBoard").setText(data.getRemainingInsulinStr());
      findDrawableById("GlucoseAge").setText(data.getGlucoseAgeStr());
      findDrawableById("BasalCorrection").setText(data.getBasalCorrectionStr());
    }
  }

  function connecting() {
    Log.i(TAG, "connecting");
    data.connected = null;
    Ui.requestUpdate();
  }

  function setCarbs(carbs) {
    findDrawableById("Carbs").setText(carbs.toString());
    Ui.requestUpdate();
  }

  function postCarbsStart(carbs) {
    var view = findDrawableById("PostCarbsResultLabel");
    if (view != null) {
      view.setColor(Gfx.COLOR_BLUE);
      view.setText("sending " + carbs + "g ...");
    }
  }

  function postCarbsDone(success, message) {
    var view = findDrawableById("PostCarbsResultLabel");
    if (view == null) { return; }
    if (success) {
      view.setColor(Gfx.COLOR_GREEN);
      view.setText("carbs done");
    } else {
      view.setColor(Gfx.COLOR_RED);
      view.setText("carbs failed: " + message);
    }
    Ui.requestUpdate();
  }

  function onUpdate(dc) {
    try {
      View.onUpdate(dc);
      findDrawableById("GlucoseAge").setText(data.getGlucoseAgeStr());
      if (Rez.Drawables has :Connected) {
	connected = data.connected;
	var c = new Rez.Drawables.Connected();
	dc.setColor(
	    connected == null ? Gfx.COLOR_YELLOW :
	    connected ? Gfx.COLOR_GREEN : Gfx.COLOR_RED,
	    Gfx.COLOR_TRANSPARENT);
	c.draw(dc);
      }
    } catch (e) {
      Log.e(TAG, e.getErrorMessage());
      e.printStackTrace();
    }
  }
}
