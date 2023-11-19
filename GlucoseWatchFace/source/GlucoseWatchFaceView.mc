import Toybox.Lang;

using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Shared.Util;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Lang;
using Toybox.WatchUi as Ui;

class GlucoseWatchFaceView extends Ui.WatchFace {
  private static const TAG = "GlucoseWatchFaceView";
  private const MINUTE_WIDTH = 4;

  var data as Shared.Data;
  var graph as Shared.Graph?;
  private var fgColor = Gfx.COLOR_BLACK;
  private var bgColor = Gfx.COLOR_WHITE;

  function initialize(data as Shared.Data) {
    WatchFace.initialize();
    me.data = data;
  }

  function onLayout(dc as Gfx.Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));

    graph = findDrawableById("DateValueGraph") as Shared.Graph;
    graph.isMmolL = data.glucoseUnit == Shared.Data.mmoll;
    graph.setReadings(data.glucoseBuffer);

    updateSettings();
    Ui.requestUpdate();
  }

  private function setVisible(id as String, visible as Boolean) as Void {
    var drawable = View.findDrawableById(id);
    if (drawable != null) {
      drawable.setVisible(visible);
    }
  }

  function updateSettings() {
    Log.i(TAG, "update settings '" + Properties.getValue("Appearance") + "'");
    var light = Properties.getValue("Appearance") == 1;
    setVisible("BackgroundDark", !light);
    setVisible("BackgroundLight", light);
    if (light) {
      graph.setAppearanceLight();
      fgColor = Gfx.COLOR_BLACK;
      bgColor = Gfx.COLOR_WHITE;
    } else {
      graph.setAppearanceDark();
      fgColor = Gfx.COLOR_WHITE;
      bgColor = Gfx.COLOR_BLACK;
    }
  }

  function onEnterSleep() {
    Ui.requestUpdate();
  }

  function onExitSleep() {
    Ui.requestUpdate();
  }

  function setReadings() {
    graph.isMmolL = data.glucoseUnit == Shared.Data.mmoll;
    graph.setReadings(data.glucoseBuffer);
    Ui.requestUpdate();
  }

  function onShow() {
  }

  hidden function setViewLabelAndColor(view, text) {
    view.setColor(fgColor);
    view.setText(text);
  }

  hidden function setViewLabel(view, text) {
    view.setText(text);
  }

  hidden function setLabel(id, text) {
    setViewLabelAndColor(View.findDrawableById(id), text);
  }

  hidden function minuteToArcDegree(min) {
    return 90 - 6 * min;
  }

  hidden function drawAtMin(dc, min, color) {
    dc.setColor(color, bgColor);
    dc.setPenWidth(MINUTE_WIDTH);
    dc.drawArc(
        dc.getWidth() / 2 - 0.5, dc.getHeight() / 2  - 0.5,
        dc.getWidth() / 2 - MINUTE_WIDTH,
        Gfx.ARC_CLOCKWISE,
        minuteToArcDegree(min),
        minuteToArcDegree(min + 1) + 1);
  }

  hidden function drawTimerMin(dc, now) {
    var nowMin = now / 60;
    var glucoseMin = !data.hasValue()
                   ? nowMin
                   : (data.glucoseBuffer.getLastDateSec() / 60);
    glucoseMin = Util.max(glucoseMin, nowMin - 59);
    for (var min = glucoseMin; min < nowMin; min++) {
      drawAtMin(dc, min % 60, Gfx.COLOR_RED);
    }
    drawAtMin(dc, nowMin % 60, Gfx.COLOR_YELLOW);

    var nextRequestMin = glucoseMin;
    if (nowMin < nextRequestMin) {
      for (var min = nowMin + 1; min <= nextRequestMin; min++) {
        drawAtMin(dc, min % 60, Gfx.COLOR_GREEN);
      }
    }
  }

  function onPartialUpdate(dc) {
    BackgroundScheduler.schedule2(data.glucoseBuffer.getLastDateSec(), 5);
    setLabel("Data3Label", data.getGlucoseAgeStr());
  }

  function onUpdate(dc) {
    try {
      onUpdateImpl(dc);
    } catch (e) {
      Log.e(TAG, "ex: " + e.getErrorMessage());
      e.printStackTrace();
    }
  }

  hidden function onUpdateImpl(dc) {
    BackgroundScheduler.schedule2(data.glucoseBuffer.getLastDateSec(), 5);
    dc.setColor(bgColor, fgColor);
    dc.drawRectangle(0, 0, dc.getWidth(), dc.getHeight());
    var now = Time.now();
    var nowInfo = Calendar.info(now, Time.FORMAT_MEDIUM);
    setLabel("DateLabel", nowInfo.day.toString() + " " + nowInfo.month.toString());

    setLabel("GlucoseLabel", data.getGlucoseStr());
    setLabel("Data1Label", data.getGlucoseDeltaPerMinuteStr());
    setLabel("Data2Label", data.getRemainingInsulinStr());
    setLabel("Data3Label", data.getGlucoseAgeStr());
    if (data.errorMessage == null) {
      setLabel("Data4Label", data.getBasalCorrectionStr());
      setViewLabel(View.findDrawableById("MessageLabel"), "");
    } else {
      setLabel("Data4Label", "");
      setViewLabel(View.findDrawableById("MessageLabel"), data.errorMessage);
    }
    View.onUpdate(dc);
  }
}
