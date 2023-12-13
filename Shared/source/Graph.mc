import Toybox.Lang;

using Shared.Log;
using Shared.Util;
using Toybox.Application.Properties;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time;
using Toybox.WatchUi as Ui;

module Shared {
(:graph)
class Graph extends Ui.Drawable {
  private const TAG = "Graph";
  private const TIME_RANGE_SEC = 120 * 60;
  private const HR_SAMPLING_PERIOD_SEC = 5 * 60;
  private const MIN_GLUCOSE = 40;
  private const MIN_HEART_RATE = 30;
  private const MAX_HEART_RATE = 160;
  private const MINOR_X_AXIS_SEC = 30 * 60;

  private var glucoseBarWidthSec as Number = 5 * 60;
  private var glucoseBarPadding as Number = 2;
  private var initialXOffset as Number;
  private var initialWidth as Number;
  private var glucoseBarWidth as Number = 0;
  private var firstValueIdx as Number = 0;
  private var xOffset as Number = 3;
  private var yOffset as Number = 120;
  var height as Number = 86;
  private var glucoseBuffer as Shared.DateValues = new Shared.DateValues(null, 2);
  private var maxGlucose as Number = 0;
  private var circular as Boolean;
  var isMmolL as Boolean?;
  var lowGlucoseMark as Number?;
  var highGlucoseMark as Number?;

  private var bgColor as Number = Gfx.COLOR_BLACK;
  private var hrColor as Number = Gfx.COLOR_WHITE;
  private var axisColor as Number = Gfx.COLOR_LT_GRAY;
  private var lowGlucoseColor = 0;
  private var lowGlucoseHighlightColor = 0;
  private var normalGlucoseColor = 0;
  private var normalGlucoseHighlightColor = 0;
  private var highGlucoseColor = 0;
  private var highGlucoseHighlightColor = 0;
  private var glucoseRangeColor = 0;

  function initialize(params as  { :x as Number, :identifier as Object, :locX as Numeric, :locY as Numeric, :width as Numeric, :height as Numeric, :visible as Boolean }) {
    Drawable.initialize(params);
    me.circular = Sys.getDeviceSettings().screenShape == Sys.SCREEN_SHAPE_ROUND;
    me.initialXOffset = params.get(:x) as Number;
    me.yOffset = (params.get(:y) as Number) + 8;
    me.initialWidth = params.get(:width) as Number;
    me.width = initialWidth;
    me.height = (params.get(:height) as Number) - 8;
    setAppearanceLight();
  }

  function valueCount() as Number {
    return TIME_RANGE_SEC / glucoseBarWidthSec; 
  }

  function setAppearanceLight() as Void {
    bgColor = Gfx.COLOR_WHITE;
    axisColor = Gfx.COLOR_LT_GRAY;
    hrColor = Gfx.COLOR_DK_GRAY;
    lowGlucoseColor = Gfx.COLOR_RED;
    lowGlucoseHighlightColor = Gfx.COLOR_DK_RED;
    normalGlucoseColor = 0x55FF55;
    normalGlucoseHighlightColor = Gfx.COLOR_DK_GREEN;
    highGlucoseColor = 0xFFFF55;
    highGlucoseHighlightColor = 0xFFFF00;
    glucoseRangeColor = Gfx.COLOR_LT_GRAY;
  }

  function setAppearanceDark() as Void {
    bgColor = Gfx.COLOR_BLACK;
    axisColor = Gfx.COLOR_DK_GRAY;
    hrColor = Gfx.COLOR_LT_GRAY;
    lowGlucoseColor = Gfx.COLOR_DK_RED;
    lowGlucoseHighlightColor = Gfx.COLOR_RED;
    normalGlucoseColor = Gfx.COLOR_DK_GREEN;
    normalGlucoseHighlightColor = Gfx.COLOR_GREEN;
    highGlucoseColor = Gfx.COLOR_YELLOW;
    highGlucoseHighlightColor = 0xFFFFAA;
    glucoseRangeColor = Gfx.COLOR_DK_GRAY;
  }

  private function computeFirstIndex(startSec as Number) as Void {
    firstValueIdx = 0;
    for (var i = 0; i < glucoseBuffer.size(); i++) {
      if (glucoseBuffer.getDateSec(i) < startSec) {
        firstValueIdx++;
      } else {
        return;
      }
    }
  }

  private function computeMaxGlucose() as Void {
    maxGlucose = 180;
    for (var i = firstValueIdx; i < glucoseBuffer.size(); i++) {
      maxGlucose = Util.max(maxGlucose, glucoseBuffer.getValue(i)) as Number;
    }
  }

  private function computeOffsetAndWidth() as Void {
    var rightOffset = 0;
    if (firstValueIdx < glucoseBuffer.size()) {
      rightOffset = getBorderOffset(glucoseBuffer.getLastValue());
    }
    
    var w = initialWidth - rightOffset;
    var valueWidth = Math.ceil((w + glucoseBarPadding) / valueCount().toDouble()).toNumber();
    glucoseBarWidth = valueWidth - glucoseBarPadding;
    if (glucoseBarWidth <= glucoseBarPadding) {
      glucoseBarWidth += glucoseBarPadding;
      glucoseBarPadding = 0;
      glucoseBarWidth = Util.max(1, glucoseBarWidth);
    }
    var width = valueWidth * valueCount() - glucoseBarPadding;
    xOffset = initialXOffset + w - width - 1;

    Log.i(
        TAG, 
        "graph: " + { 
            "rightOffset" => rightOffset, 
            "xOffset" => xOffset,
            "width" => width, 
            "glucoseBarWidth" => glucoseBarWidth,
            "glucoseBarPadding" => glucoseBarPadding,
            "valueCount" => valueCount(),
            "height" => height});
  }

  function setReadings(glucoseBuffer as Shared.DateValues) as Void {
    glucoseBarWidthSec = Properties.getValue("GlucoseValueFrequencySec") as Number;
    glucoseBarPadding = glucoseBarWidthSec < 300 ? 0 : 2;
    me.glucoseBuffer = glucoseBuffer;

    var startSec = glucoseBuffer.size() > 0 ? glucoseBuffer.getLastDateSec() : Util.nowSec();
    startSec += glucoseBarWidthSec * ((Util.nowSec() - startSec) / glucoseBarWidthSec);
    startSec -= TIME_RANGE_SEC;
    computeFirstIndex(startSec);
    computeMaxGlucose();
    computeOffsetAndWidth();
  }

  private function getBorderOffset(value as Number) as Number {
    if (!circular) { return 0; }
    var y = Util.min(height, getYForGlucose(value));
    var r = initialWidth / 2;
    var o = r - Math.sqrt(r*r - y*y);  // Pythagoras' theorem
    Log.i(TAG, "gbo " + {"y" => y, "r" => r, "o" => o});
    return Math.ceil(o).toNumber() + glucoseBarWidth / 2;
  }

  private function getX(startSec as Number, dateSec as Number) as Number {
    var rel = (dateSec - startSec) / glucoseBarWidthSec * (glucoseBarPadding + glucoseBarWidth);
    return rel;
  }

  private function getYForGlucose(glucose as Number) as Number {
    return height * (maxGlucose - glucose) / (maxGlucose - MIN_GLUCOSE);
  }

  private function getYForHR(hr as Number) as Number {
    return height * (MAX_HEART_RATE - hr) / (MAX_HEART_RATE - MIN_HEART_RATE);
  }

  private function formatValue(value as Number) as String {
    if (isMmolL) {
      var valMmolL = value / 18.0;
      if (valMmolL < 10.0) {
        return valMmolL.format("%0.1f");
      } else {
        return valMmolL.format("%0.0f");
      }
    } else {
      return value.toLong().toString();
    }
  }

  private function drawRectangle(
      dc as Gfx.Dc, color as Number, 
      x as Number, y as Number, w as Number, h as Number) as Void {
    dc.setColor(color, Gfx.COLOR_TRANSPARENT);
    dc.fillRectangle(xOffset + x, yOffset + y, w, h);
  }

  private function useLowHighGlucoseMarks() as Boolean {
    return Properties.getValue("ShowTargetGlucoseInGraph") &&
        Util.ifNullNumber(lowGlucoseMark, 0) >= MIN_GLUCOSE &&
        Util.ifNullNumber(highGlucoseMark, 0) > lowGlucoseMark;
  }

  private function drawGlucose(dc as Gfx.Dc, startSec as Number) as Void {
    if (glucoseBuffer == null) {
      return;
    }
    if (useLowHighGlucoseMarks()) {
      drawGlucoseLowHigh(dc, startSec);
    } else {
      drawGlucoseBasic(dc, startSec);
    }
  }

  private function drawGlucoseBasic(dc as Gfx.Dc, startSec as Number) as Void {
    for (var i = firstValueIdx; i < glucoseBuffer.size(); i++) {
      var gl = glucoseBuffer.getValue(i);
      var x = getX(startSec, glucoseBuffer.getDateSec(i));
      var y = getYForGlucose(gl);
      drawRectangle(dc, Gfx.COLOR_DK_BLUE, x, y, glucoseBarWidth, height - y);
      drawRectangle(dc, Gfx.COLOR_BLUE, x, y, glucoseBarWidth, 3);
    }
  }

  private function drawGlucoseLowHigh(dc as Gfx.Dc, startSec as Number) as Void {
    var yLow = getYForGlucose(lowGlucoseMark);
    var yHigh = getYForGlucose(highGlucoseMark);

    var x = 0;
    for (var i = firstValueIdx; i < glucoseBuffer.size(); i++) {
      x = getX(startSec, glucoseBuffer.getDateSec(i));
      var gl = glucoseBuffer.getValue(i);
      var y = getYForGlucose(gl);

      drawRectangle(dc, glucoseRangeColor, x, yHigh, glucoseBarWidth, 1);
      drawRectangle(dc, glucoseRangeColor, x, yLow, glucoseBarWidth, -1);

      var hlColor = highGlucoseHighlightColor;
      if (gl < lowGlucoseMark) {
        drawRectangle(dc, lowGlucoseColor, x, y, glucoseBarWidth, height - y);
        hlColor = lowGlucoseHighlightColor;
      } else if (gl < highGlucoseMark) {
        drawRectangle(dc, lowGlucoseColor, x, yLow, glucoseBarWidth, height - yLow);
        drawRectangle(dc, normalGlucoseColor, x, y, glucoseBarWidth, yLow - y);
        hlColor = normalGlucoseHighlightColor;
      } else {
        drawRectangle(dc, lowGlucoseColor, x, yLow, glucoseBarWidth, height - yLow);
        drawRectangle(dc, normalGlucoseColor, x, yHigh, glucoseBarWidth, yLow - yHigh);
        drawRectangle(dc, highGlucoseColor, x, y, glucoseBarWidth, yHigh - y);
      }
      drawRectangle(dc, hlColor, x, y, glucoseBarWidth, 3);
    }
    while (x < initialWidth) {
      x += glucoseBarWidth + glucoseBarPadding;
      drawRectangle(dc, glucoseRangeColor, x, yHigh, glucoseBarWidth, yHigh + 1);
      drawRectangle(dc, glucoseRangeColor, x, yLow, glucoseBarWidth, yLow + 1);
    }
  }

  private function drawTimeAxis(dc as Gfx.Dc, startSec as Number) as Void {
    dc.setColor(axisColor, Gfx.COLOR_TRANSPARENT);
    dc.setPenWidth(2);
    dc.drawLine(0, yOffset, initialWidth, yOffset);
    dc.drawLine(xOffset, yOffset + height, xOffset + width, yOffset + height);
    var lineWidth = Util.max(2, glucoseBarPadding);
    dc.setPenWidth(lineWidth);
    for (var dateSec = (startSec-1) / MINOR_X_AXIS_SEC * MINOR_X_AXIS_SEC;
         dateSec < startSec + TIME_RANGE_SEC;
         dateSec += MINOR_X_AXIS_SEC) {
      var x = getX(startSec, dateSec);
      dc.drawLine(
          x + xOffset - lineWidth, yOffset + height + 5,
          x + xOffset - lineWidth, yOffset + height);
      dc.drawLine(
          x + xOffset - lineWidth, yOffset + 15,
          x + xOffset - lineWidth, yOffset);
    }
  }

  private function drawHeartRate(dc as Gfx.Dc, startSec as Number, nowSec as Number) as Void {
    if (!(Toybox has :SensorHistory)) {
      return;
    }
    var it = SensorHistory.getHeartRateHistory({
        :period => new Time.Duration(TIME_RANGE_SEC),
        :order => SensorHistory.ORDER_OLDEST_FIRST });

    dc.setColor(hrColor, bgColor);
    dc.setPenWidth(2);

    var lastValue = null;
    var samplingMinute = 0;
    var samplingSum = 0;
    var samplingCnt = 0;
    var sampling5Sum = 0;
    var sampling5Cnt = 0;
    for (var val = it.next(); val != null; val = it.next()) {
      if (val.data == null) { continue; }
      var minute = val.when.value() / 60;

      if (val.when.value() - nowSec < HR_SAMPLING_PERIOD_SEC) {
        sampling5Sum += val.data.toNumber();
        sampling5Cnt += 1;
      }

      if (minute == samplingMinute) {
        samplingSum += val.data.toNumber();
        samplingCnt += 1;
        continue;
      } 
      if (samplingCnt > 0) {
        var value = new DateValue(60 * samplingMinute, samplingSum / samplingCnt);
        if (lastValue == null || value.dateSec - (lastValue as DateValue).dateSec > 180) {
          lastValue = new DateValue(60 * (samplingMinute - 1), value.value);
        }
        drawHeartRateLine(dc, startSec, lastValue, value);
        lastValue = value;
      }

      samplingMinute = minute;
      samplingSum = val.data.toNumber();
      samplingCnt = 1;
    }

    if (sampling5Cnt > 0) {
      Properties.setValue("HeartRateStartSec", nowSec - HR_SAMPLING_PERIOD_SEC);
      Properties.setValue("HeartRateLastSec", nowSec);
      Properties.setValue("HeartRateAvg", sampling5Sum / sampling5Cnt);
    } else {
      Properties.setValue("HeartRateStartSec", null);
      Properties.setValue("HeartRateLastSec", null);
      Properties.setValue("HeartRateAvg", null);
    }
  }

  private function drawHeartRateLine(
      dc as Gfx.Dc, startSec as Number,
      dv1 as DateValue,dv2 as DateValue) as Void {
    var x1 = getX(startSec, dv1.dateSec);
    var y1 = getYForHR(dv1.value);
    var x2 = getX(startSec, dv2.dateSec);
    var y2 = getYForHR(dv2.value);
    dc.drawLine(xOffset + x1, yOffset + y1, xOffset + x2, yOffset + y2);
  }

  private function drawValue(dc as Gfx.Dc, startSec as Number, i as Number) as Void {
    var x = getX(startSec, glucoseBuffer.getDateSec(i));
    var y = getYForGlucose(glucoseBuffer.getValue(i));
    var justification;

    if (i < firstValueIdx + 3) {
      justification = Gfx.TEXT_JUSTIFY_LEFT;
    } else if (i > glucoseBuffer.size() - 3) {
      justification = Gfx.TEXT_JUSTIFY_RIGHT;
      x += glucoseBarWidth;
    } else {
      justification = Gfx.TEXT_JUSTIFY_CENTER;
      x += glucoseBarWidth / 2;
    }

    dc.drawText(
        xOffset + x, yOffset + y - 18,
        Gfx.FONT_XTINY,
        formatValue(glucoseBuffer.getValue(i)),
        justification);
  }

  private function getColorForValue(glucose as Number) as Number {
    if (useLowHighGlucoseMarks()) {
      return glucose < lowGlucoseMark ? lowGlucoseHighlightColor
          : glucose <= highGlucoseMark ? normalGlucoseHighlightColor
          : highGlucoseHighlightColor;
    } else {
      return glucoseRangeColor;
    }
  }

  private function drawMinMax(dc as Gfx.Dc, startSec as Number) as Void {
    if (glucoseBuffer == null || glucoseBuffer.size() <= firstValueIdx) {
      return;
    }
    var minIdx = firstValueIdx;
    var maxIdx = firstValueIdx;
    for (var i = firstValueIdx; i < glucoseBuffer.size(); i++) {
      if (glucoseBuffer.getValue(minIdx) >= glucoseBuffer.getValue(i)) {
        minIdx = i;
      }
      if (glucoseBuffer.getValue(maxIdx) <= glucoseBuffer.getValue(i)) {
        maxIdx = i;
      }
    }
    dc.setColor(getColorForValue(glucoseBuffer.getValue(minIdx)), Gfx.COLOR_TRANSPARENT);
    drawValue(dc, startSec, minIdx);
    dc.setColor(getColorForValue(glucoseBuffer.getValue(maxIdx)), Gfx.COLOR_TRANSPARENT);
    drawValue(dc, startSec, maxIdx);
  }

  function draw(dc as Gfx.Dc) as Void {
    glucoseBarWidthSec = Properties.getValue("GlucoseValueFrequencySec") as Number;
    glucoseBarPadding = glucoseBarWidthSec < 300 ? 0 : 2;
    if (glucoseBuffer.size() == 0) {
      return;
    }
    var nowSec = Util.nowSec();
    var startSec = nowSec - TIME_RANGE_SEC;
    if (firstValueIdx < glucoseBuffer.size()) {
      glucoseBuffer.getDateSec(firstValueIdx);
      if (nowSec - TIME_RANGE_SEC < startSec - 300) {
        startSec = nowSec - TIME_RANGE_SEC;
      }
    }

    if (circular) {
      drawTimeAxis(dc, startSec);
    }
    drawGlucose(dc, startSec);
    drawHeartRate(dc, startSec, nowSec);
    drawMinMax(dc, startSec);
  }
}}
