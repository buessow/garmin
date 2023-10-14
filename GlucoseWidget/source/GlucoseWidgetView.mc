using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
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

  hidden function findTextById(id as Lang.String) as Ui.Text {
    return findDrawableById(id) as Ui.Text;
  }

  function onLayout(dc) {
    setLayout(Rez.Layouts.MainLayout(dc));
    graph = findDrawableById("DateValueGraph");
  }

  function onGlucose() {
    if (data.glucoseBuffer != null and graph != null) {
      graph.setReadings(data.glucoseBuffer);
      graph.isMmolL = data.glucoseUnit == Shared.Data.mmoll;
      findTextById("GlucoseLabel").setText(data.getGlucoseStr());
      findTextById("GlucoseDelta").setText(data.getGlucoseDeltaPerMinuteStr());
      findTextById("InsulinOnBoard").setText(data.getRemainingInsulinStr());
      findTextById("GlucoseAge").setText(data.getGlucoseAgeStr());
      findTextById("BasalCorrection").setText(data.getBasalCorrectionStr());
    }
  }

  function connecting() {
    Log.i(TAG, "connecting");
    data.connected = null;
    Ui.requestUpdate();
  }

  function setCarbs(carbs) {
    findTextById("Carbs").setText(carbs.toString());
    Ui.requestUpdate();
  }

  function postCarbsStart(carbs) {
    var view = findTextById("PostCarbsResultLabel");
    if (view != null) {
      view.setColor(Gfx.COLOR_BLUE);
      view.setText("sending " + carbs + "g ...");
    }
  }

  function postCarbsDone(success, message) {
    var view = findTextById("PostCarbsResultLabel");
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

  hidden function updateConnected(dc as Gfx.Dc, connected as Lang.Boolean) as Void {
  }

  (:showConnected)
  hidden function updateConnected(dc as Gfx.Dc, connected as Lang.Boolean) as Void {
    connected = data.connected;
    var c = new Rez.Drawables.Connected();
    dc.setColor(
	connected == null ? Gfx.COLOR_YELLOW :
	connected ? Gfx.COLOR_GREEN : Gfx.COLOR_RED,
	Gfx.COLOR_TRANSPARENT);
    c.draw(dc);
  }

  function onUpdate(dc) {
    try {
      View.onUpdate(dc);
      findTextById("GlucoseAge").setText(data.getGlucoseAgeStr());
      updateConnected(dc, data.connected);
    } catch (e) {
      Log.e(TAG, e.getErrorMessage());
      e.printStackTrace();
    }
  }
}
