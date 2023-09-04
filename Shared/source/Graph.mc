using Shared.Log;
using Shared.Util;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time;
using Toybox.WatchUi as Ui;

module Shared {
class Graph extends Ui.Drawable {
  hidden const TAG = "Graph";
  hidden const TIME_RANGE_SEC = 120 * 60;
  hidden const GLUCOSE_BAR_WIDTH_SEC = 5 * 60;
  hidden const HR_SAMPLING_PERIOD_SEC = 5 * 60;
  hidden const VALUE_COUNT = TIME_RANGE_SEC / GLUCOSE_BAR_WIDTH_SEC;
  hidden const MIN_HEART_RATE = 30;
  hidden const MAX_HEART_RATE = 160;
  hidden const GLUCOSE_BAR_PADDING = 2;
  hidden var glucoseBarWidth;
  hidden var INITIAL_X_OFFSET = 6;
  hidden var INITIAL_WIDTH = 240 - 2 * INITIAL_X_OFFSET;

  hidden var firstValueIdx = 0;
  hidden var xOffset = 3;
  hidden var yOffset = 120;
  hidden var width;
  hidden var height = 86;
  hidden var glucoseBuffer;
  hidden var maxGlucose;
  hidden var circular;
  var isMmolL;

  function initialize(params) {
    Log.i(TAG, "initialize");
    Drawable.initialize(params);
    me.circular = Sys.getDeviceSettings().screenShape == Sys.SCREEN_SHAPE_ROUND;
    me.INITIAL_X_OFFSET = params.get(:x).toNumber();
    me.yOffset = params.get(:y).toNumber();
    me.INITIAL_WIDTH = params.get(:width).toNumber();
    me.width = INITIAL_WIDTH;
    me.height = params.get(:height).toNumber();
  }

  function setReadings(glucoseBuffer) {
    Log.i(TAG, "setReadings " + glucoseBuffer.size() + " values");
    me.glucoseBuffer = glucoseBuffer;
    var startSec = Util.nowSec() - TIME_RANGE_SEC;
    maxGlucose = 180;
    firstValueIdx = 0;
    for (var i = 0; i < glucoseBuffer.size(); i++) {
      if (glucoseBuffer.getDateSec(i) >= startSec) {
        if (glucoseBuffer.getValue(i) > maxGlucose) {
          maxGlucose = glucoseBuffer.getValue(i);
        }
      } else {
        firstValueIdx++;
      }
    }
    var leftOffset = 0;
    var rightOffset = 0;
    if (firstValueIdx < glucoseBuffer.size()) {
      leftOffset = getBorderOffset(glucoseBuffer.getValue(firstValueIdx));
      rightOffset = getBorderOffset(glucoseBuffer.getLastValue());
    }
    xOffset = INITIAL_X_OFFSET + leftOffset;
    width = INITIAL_WIDTH - leftOffset - rightOffset;
    var totalPadding = GLUCOSE_BAR_PADDING * (VALUE_COUNT - 1);
    glucoseBarWidth = Math.ceil((width - totalPadding) / VALUE_COUNT);
    var totalBarWidth = glucoseBarWidth * VALUE_COUNT + totalPadding;
    xOffset = xOffset - Util.max(0, totalBarWidth - width);
    Log.i(
	TAG, 
	"graph dimensions: " + { 
	    "leftOffset"=>leftOffset,
	    "rightOffset"=> rightOffset, 
	    "width" => width, 
	    "glucoseBarWidth" => glucoseBarWidth,
	    "VALUE_COUNT" => VALUE_COUNT});
  }

  hidden function getBorderOffset(value) {
    if (!circular) { return 0; }
    var y = Util.min(height, getYForGlucose(value));
    var r = INITIAL_WIDTH / 2;
    var o = r - Math.sqrt(r*r - y*y);  // Pythagoras' theorem
    return Math.ceil(o);
  }

  hidden function getX(startSec, dateSec) {
    var rel = (dateSec - startSec) / GLUCOSE_BAR_WIDTH_SEC * (GLUCOSE_BAR_PADDING + glucoseBarWidth);
    return rel;
  }

  hidden function getYForGlucose(glucose) {
    return height * (maxGlucose - glucose) / (maxGlucose - 40);
  }

  hidden function getYForHR(hr) {
    return height * (MAX_HEART_RATE - hr) / (MAX_HEART_RATE - MIN_HEART_RATE);
  }

  hidden function formatValue(value) {
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

  hidden function drawValue(dc, startSec, i) {
    var x = getX(startSec, glucoseBuffer.getDateSec(i));
    var y = getYForGlucose(glucoseBuffer.getValue(i));
    var justification;

    if (i < firstValueIdx + 3) {
      justification = Gfx.TEXT_JUSTIFY_LEFT;
    } else if (i > glucoseBuffer.size() - 3) {
      justification = Gfx.TEXT_JUSTIFY_RIGHT;
      x += glucoseBarWidth - 5;
    } else {
      justification = Gfx.TEXT_JUSTIFY_CENTER;
      x += glucoseBarWidth / 2;
    }

    if (y > height / 2) {
      y -= 25;
    }

    dc.drawText(
        xOffset + x, yOffset + y,
        Gfx.FONT_TINY,
        formatValue(glucoseBuffer.getValue(i)),
        justification);
  }

  hidden function drawGlucose(dc, startSec) {
    if (glucoseBuffer == null || glucoseBuffer.size() <= firstValueIdx) {
      return;
    }
    for (var i = firstValueIdx; i < glucoseBuffer.size(); i++) {
      var x = getX(startSec, glucoseBuffer.getDateSec(i));
      var w = (x + glucoseBarWidth).toNumber() - x.toNumber();
      var y = getYForGlucose(glucoseBuffer.getValue(i));
      var h = height - y;
//      Log.i(TAG, "draw " + glucoseBuffer.getValue(i)
//          + " x=" + x + " y=" + y + " h=" + h);
      dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_BLACK);
      dc.fillRectangle(xOffset + x, yOffset + y, w, h);
      dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_BLACK);
      dc.fillRectangle(xOffset + x, yOffset + y, w, 3);
    }
  }

  hidden const MAJOR_X_AXIS_SEC = 60 * 60;
  hidden const MINOR_X_AXIS_SEC = 30 * 60;
  hidden function drawTimeAxis(dc, startSec) {
    dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.setPenWidth(2);
    dc.drawLine(xOffset, yOffset, xOffset + width, yOffset);
    dc.drawLine(xOffset, yOffset + height, xOffset + width, yOffset + height);
    dc.setPenWidth(GLUCOSE_BAR_PADDING);
    for (var dateSec = (startSec-1) / MINOR_X_AXIS_SEC * MINOR_X_AXIS_SEC;
         dateSec < startSec + TIME_RANGE_SEC;
         dateSec += MINOR_X_AXIS_SEC) {
      var y = dateSec % MAJOR_X_AXIS_SEC == 0 ? 0 : 15;
      var x = getX(startSec, dateSec);
      dc.drawLine(
          x + xOffset - GLUCOSE_BAR_PADDING, yOffset + height + 5,
          x + xOffset - GLUCOSE_BAR_PADDING, yOffset + height);
      dc.drawLine(
          x + xOffset - GLUCOSE_BAR_PADDING, yOffset + 15,
          x + xOffset - GLUCOSE_BAR_PADDING, yOffset);
    }
  }

  hidden function drawHeartRate(dc, startSec, nowSec) {
    if (!(Toybox has :SensorHistory)) {
      return;
    }
    var it = SensorHistory.getHeartRateHistory({
        :period => new Time.Duration(TIME_RANGE_SEC),
        :order => SensorHistory.ORDER_OLDEST_FIRST });
    var val;
    do {
      val = it.next();
      if (val == null) {
        Log.i(TAG, "no heart rate values");
        return;
      }
    } while (val.data == null );
    var prevX = getX(startSec, val.when.value());
    var prevY = getYForHR(val.data);
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
    dc.setPenWidth(2);
    var count = 0;
    var sum = 0;
    var minute = val.when.value() / 60;
    var minuteSum = val.data;
    var minuteCount = 1;
    for (val = it.next(); val != null; val = it.next()) {
      if (val.data == null) {
        continue;
      }
      minuteCount++;
      minuteSum += val.data;
      if (val.when.value() / 60 == minute) {
        continue;
      }
      if (val.when.value() + HR_SAMPLING_PERIOD_SEC > nowSec) {
        count += minuteCount;
        sum += minuteSum;
      }
      var x = getX(startSec, 60  * minute);
      var y = getYForHR(minuteSum / minuteCount);
//      Log.i(TAG, "draw HR " + val.data
//               + " prevX=" + prevX + " prevY=" + prevY
//               + " x=" + x + " y=" + y);
      dc.drawLine(xOffset + prevX, yOffset + prevY, xOffset + x, yOffset + y);
      prevX = x;
      prevY = y;
      minute = val.when.value() / 60;
      minuteCount = 0;
      minuteSum = 0;
    }
    if (count > 0) {
      Application.getApp().setProperty("HeartRateLastSec", nowSec);
      Application.getApp().setProperty(
          "HeartRateStartSec", nowSec - HR_SAMPLING_PERIOD_SEC);
      Application.getApp().setProperty("HeartRateAvg", sum / count);
    }
  }

  function drawMinMax(dc, startSec) {
    if (glucoseBuffer == null || glucoseBuffer.size() <= firstValueIdx) {
      return;
    }
    var minIdx = 0;
    var maxIdx = 0;
    for (var i = firstValueIdx; i < glucoseBuffer.size(); i++) {
      if (glucoseBuffer.getValue(minIdx) > glucoseBuffer.getValue(i)) {
        minIdx = i;
      } else if (glucoseBuffer.getValue(maxIdx) < glucoseBuffer.getValue(i)) {
        maxIdx = i;
      }
    }
    dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
    drawValue(dc, startSec, minIdx);
    drawValue(dc, startSec, maxIdx);
  }


  function draw(dc) {
    // Draw white background
    // dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
    // dc.fillRectangle(INITIAL_X_OFFSET, yOffset, INITIAL_WIDTH, height);

    if (glucoseBuffer == null) {
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

    drawTimeAxis(dc, startSec);
    drawGlucose(dc, startSec);
    drawHeartRate(dc, startSec, nowSec);
    drawMinMax(dc, startSec);
  }
}}
