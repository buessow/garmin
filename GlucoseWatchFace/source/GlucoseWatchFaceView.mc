using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Shared.Util;
using Toybox.Application;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Lang;
using Toybox.WatchUi as Ui;

class GlucoseWatchFaceView extends Ui.WatchFace {
  hidden static const TAG = "GlucoseWatchFaceView";
  hidden const MINUTE_WIDTH = 4;

  var data as Shared.Data;
  var graph as Shared.Graph?;

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

  function updateSettings() {
    Log.i(TAG, "update settings");
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

  hidden function setViewLabel(view, text) {
    view.setText(text);
  }

  hidden function setLabel(id, text) {
    setViewLabel(View.findDrawableById(id), text);
  }

  hidden function minuteToArcDegree(min) {
    return 90 - 6 * min;
  }

  hidden function drawAtMin(dc, min, color) {
    dc.setColor(color, Gfx.COLOR_BLACK);
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
    var now = Time.now();
    var nowInfo = Calendar.info(now, Time.FORMAT_MEDIUM);
    var hourDisplay = System.getDeviceSettings().is24Hour ? 24 : 12;
    setLabel("DateLabel", nowInfo.day.toString() + " " + nowInfo.month.toString());
    var dx = 0;
    if (nowInfo.hour % 10 == 1) { dx = dx + 3; }
    if (nowInfo.min / 10 == 1) { dx = dx + 3; }
    var minuteView = findDrawableById("MinuteLabel");
    minuteView.locX = minuteView.locX - dx;
    setLabel("HourLabel", (nowInfo.hour % hourDisplay).toString());
    setLabel("MinuteLabel", nowInfo.min.format("%02d"));

    setLabel("GlucoseLabel", data.getGlucoseStr());
    setLabel("Data1Label", data.getGlucoseDeltaPerMinuteStr());
    setLabel("Data2Label", data.getRemainingInsulinStr());
    setLabel("Data3Label", data.getGlucoseAgeStr());
    if (data.errorMessage == null) {
      setLabel("Data4Label", data.getBasalCorrectionStr());
      setLabel("MessageLabel", "");
    } else {
      setLabel("Data4Label", "");
      setLabel("MessageLabel", data.errorMessage);
    }
    View.onUpdate(dc);
    minuteView.locX = minuteView.locX + dx;


    //drawTimerMin(dc, now.value());
  }
}
