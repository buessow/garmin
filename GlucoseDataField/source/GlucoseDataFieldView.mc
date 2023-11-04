using Shared;
using Shared.BackgroundScheduler;
using Shared.Log;
using Shared.Util;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi as Ui;

(:exclude)
class GlucoseDataFieldView extends Ui.DataField {
  static const TAG = "GlucoseDataFieldView";
  static const SETTINGS_KEYS = [ :large, :medium, :small ];
  static const SETTINGS = {
    :round => {
      :name => "round",
      :labelFont => Gfx.FONT_SYSTEM_SMALL,
      :labelFont => Gfx.FONT_SYSTEM_XTINY,
      :valueFont => Gfx.FONT_NUMBER_MEDIUM,
      :extraFont => Gfx.FONT_SYSTEM_SMALL,
      :errorFont => Gfx.FONT_SYSTEM_XTINY,
      :extraJustified => true,
    },
    :round1 => {
      :name => "round1",
      :labelFont => Gfx.FONT_SYSTEM_XTINY,
      :valueFont => Gfx.FONT_MEDIUM,
      :extraFont => Gfx.FONT_SYSTEM_SMALL,
      :errorFont => Gfx.FONT_SYSTEM_XTINY,
      :extraJustified => true,
    },
    :small => {
      :name => "small",
      :labelFont => Gfx.FONT_SYSTEM_SMALL,
      :valueFont => Gfx.FONT_SYSTEM_NUMBER_MILD,
      :unitFont => Gfx.FONT_SYSTEM_XTINY,
      :extraFont => Gfx.FONT_SYSTEM_TINY,
      :errorFont => Gfx.FONT_SYSTEM_XTINY,
      :extraJustified => true,
    },
    :medium => {
      :name => "medium",
      :labelFont => Gfx.FONT_SYSTEM_SMALL,
      :valueFont => Gfx.FONT_SYSTEM_NUMBER_HOT,
      :unitFont => Gfx.FONT_SYSTEM_XTINY,
      :extraFont => Gfx.FONT_SYSTEM_TINY,
      :errorFont => Gfx.FONT_SYSTEM_XTINY,
      :extraJustified => true,
    },
    :large => {
      :name => "large",
      :labelFont => Gfx.FONT_SYSTEM_SMALL,
      :valueFont => Gfx.FONT_SYSTEM_NUMBER_HOT,
      :unitFont => Gfx.FONT_SYSTEM_TINY,
      :extraFont => Gfx.FONT_SYSTEM_MEDIUM,
      :errorFont => Gfx.FONT_SYSTEM_TINY,
      :extraJustified => false,
      :graph => {
        :x => 0, :y => 0,
        :width => 282, :height => 100,
        :round => false, :valign => :bottom
      },
    },
  };

  var data = new Shared.Data();
  hidden var fgColor;
  hidden var bgColor;
  hidden var extraColor;
  hidden var extraHiColor;
  hidden var extraLoColor;
  hidden var settings;
  hidden var lastDrawnValueSec = 0;
  hidden var width;
  hidden var height;
  hidden var graph;
  hidden var displayRadius;
  hidden var obscurity;
  var heartRateCollector = new DataFieldHeartRateCollector();

  function initialize() {
    Log.i(TAG, "initialize");
    Ui.DataField.initialize();
    displayRadius = System.getDeviceSettings().screenWidth / 2;
  }

  function onLayout(dc) {
  }

  hidden function setColors() {
    if (getBackgroundColor() == Gfx.COLOR_WHITE) {
      fgColor = Gfx.COLOR_BLACK;
      bgColor = Gfx.COLOR_WHITE;
      extraColor = Gfx.COLOR_DK_GRAY;
      extraHiColor = Gfx.COLOR_DK_RED;
      extraLoColor = Gfx.COLOR_DK_BLUE;
    } else {
      fgColor = Gfx.COLOR_WHITE;
      bgColor = Gfx.COLOR_BLACK;
      extraColor = Gfx.COLOR_LT_GRAY;
      extraHiColor = Gfx.COLOR_RED;
      extraLoColor = Gfx.COLOR_BLUE;
    }
  }

  hidden function computeWidth(dc) {
    settings[:valueWidth] = dc.getTextWidthInPixels(
        "300", settings[:valueFont]);
    if (settings[:unitFont] == null) {
      settings[:unitWidth] = 0;
    } else {
      settings[:unitWidth] = dc.getTextWidthInPixels(
          getGlucoseUnitDividend(data.glucoseUnit),
          settings[:unitFont]);
    }
    if (settings[:extraWidth] == null) {
      settings[:extraWidth] = Util.max(
	  dc.getTextWidthInPixels("-0.00 90%", settings[:extraFont]),
	  dc.getTextWidthInPixels("+0.00 1.0", settings[:extraFont]));
    }
  }

  hidden function isRound() {
    return System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND;
  }

  hidden function getSettings(dc) {
    if (isRound()) {
      if (dc.getWidth() > -240) {
	settings = SETTINGS[:round1];
      } else {
	settings = SETTINGS[:round];
      }
      computeWidth(dc);
      return;
    }
    for (var i = 0; i < SETTINGS_KEYS.size(); i++) {
      var key = SETTINGS_KEYS[i];
      settings = SETTINGS[key];
      computeWidth(dc);
      var width = settings[:valueWidth]
                + settings[:unitWidth]
                + settings[:extraWidth];
      var height = Gfx.getFontHeight(settings[:labelFont]) + 1
                 + 3 * Gfx.getFontHeight(settings[:extraFont]);
      if (dc.getWidth() > width && dc.getHeight() > height) {
        return;
      }
    }
    settings = SETTINGS[:small];
  }

  hidden function getGraph(dc, reset) {
    var graph = null;/*
    var graphSettings = settings[:graph];
    if (graphSettings != null) {
      graph = graphSettings[:obj];
      if (graphSettings[:valign] == :bottom) {
        graphSettings[:y] = dc.getHeight() - graphSettings[:height];
      }
      if (graph == null || reset) {
        graph = new Shared.DateValueGraph(settings[:graph]);
        graph.isMmolL = data.glucoseUnit == Shared.Data.mmoll;
        if (data.lastGlucose != null) {
          graph.setReadings(data.glucoseBuffer);
        } else {
          graphSettings[:lastDrawnSec] = 0;
        }
        graphSettings[:obj] = graph;
      }
      if (data.lastGlucose != null &&
          lastDrawnValueSec  < data.lastGlucose.dateSec) {
        graph.setReadings(data.glucoseBuffer);
      }
    }*/
    return graph;
  }

  hidden function getGlucoseUnitDividend(unit) {
    switch (unit) {
      case Shared.Data.mgdl: return "mg";
      case Shared.Data.mmoll: return "mmol";
    }
    return null;
  }

  hidden function getGlucoseUnitDivisor(unit) {
    switch (unit) {
      case Shared.Data.mgdl: return "dl";
      case Shared.Data.mmoll: return "l";
    }
    return null;
  }

  function compute(info) {
  }

  hidden function getFontAscent(dc, fontSymbol) {
    return dc.getFontAscent(settings[fontSymbol]);
  }

  hidden function getFontHeight(dc, fontSymbol) {
    //return dc.getTextDimensions("1", settings[fontSymbol])[1];
    return Gfx.getFontHeight(settings[fontSymbol]);
  }

  hidden function getContentWidth(dc) {
    return dc.getTextDimensions("3.1", settings[:valueFont])[0] + 4
	 + dc.getTextDimensions("+0.4 S10%", settings[:extraFont])[0];
  }

  hidden function getContentHeight(dc) {
    return getFontHeight(dc, :labelFont) + getFontHeight(dc, :valueFont) + 4;
  }

  hidden function getY(dc) {
    if (!isRound()) {
      return 2;
    }
    var h = getContentHeight(dc);
    var y;
    var j = "D";
    switch (obscurity & (OBSCURE_TOP | OBSCURE_BOTTOM)) {
      case OBSCURE_TOP: // justify bottom
        y = dc.getHeight() - h;
	j = "T";
	break;
      case OBSCURE_BOTTOM: // justify top
        y = 2;
	j = "B";
	break;
      default: // justify center
        y = 2;
	break;
    }
    return y;
  }

  hidden function drawDebugRect(dc, x, y, w, h, color) {
    // dc.setColor(color, Gfx.COLOR_TRANSPARENT);
    // dc.drawRectangle(x, y, w, h);
  }

  function drawValueAndExtraRound(dc, y) {
    var valueY = y + 2;
    var w = Util.min(
	getWidthAt(dc, valueY),
	getWidthAt(dc, valueY + getFontAscent(dc, :valueFont)));
    var x = (width - w) / 2;
    drawDebugRect(dc, x, valueY, w, height-y, Gfx.COLOR_RED);
    drawText(dc, x, valueY, :valueFont, data.getGlucoseStr(), :top, Gfx.TEXT_JUSTIFY_LEFT);

    var s;
    if (data.hasValue() &&
        Util.nowSec() - data.glucoseBuffer.getLastDateSec() < 360) {
      s = data.getGlucoseDeltaPerMinuteStr();
    } else {
      s = data.getGlucoseAgeStr();
    }
    if (getContentWidth(dc) < w) {
      s += "  " + data.getBasalCorrectionStr();
    }

    drawText(
        dc, x + w, y, :extraFont, s, :top, Gfx.TEXT_JUSTIFY_RIGHT);
  }

  function drawValue(dc, x, y, w, h) {
    if (data.getGlucoseAgeSec() > 15*60) {
      dc.setColor(Gfx.COLOR_DK_GRAY, bgColor);
    } else {
      dc.setColor(fgColor, bgColor);
    }

    x += (w - settings[:unitWidth]) / 2;
    y += (h - Gfx.getFontHeight(settings[:valueFont])) / 2;
    dc.drawText(
        x, y, settings[:valueFont],
        data.getGlucoseStr(),
        Gfx.TEXT_JUSTIFY_CENTER);

    x += settings[:valueWidth]/2 + 2 + settings[:unitWidth]/2;

    y += getFontAscent(dc, :valueFont);
    y -= getFontAscent(dc, :unitFont);
    y -= 4;
    y -= Gfx.getFontHeight(settings[:unitFont]);
    dc.drawText(
        x, y, settings[:unitFont],
        getGlucoseUnitDividend(data.glucoseUnit),
        Gfx.TEXT_JUSTIFY_CENTER);
    y +=  Gfx.getFontHeight(settings[:unitFont]);
    // dc.drawLine(
    //     x - settings[:unitWidth] / 2, y, x + settings[:unitWidth] / 2, y);
    y += 1;
    dc.drawText(
        x, y, settings[:unitFont],
        getGlucoseUnitDivisor(data.glucoseUnit),
        Gfx.TEXT_JUSTIFY_CENTER);
  }

  function drawError(dc, x, y, w, h) {
    dc.setColor(Gfx.COLOR_RED, bgColor);
    dc.drawText(
        2,
        Gfx.getFontHeight(settings[:labelFont]),
        settings[:errorFont],
        data.errorMessage,
        Gfx.TEXT_JUSTIFY_LEFT);
    dc.setColor(fgColor, bgColor);
  }

  function updateDimension(dc) {
    if (width != dc.getWidth() || height != dc.getHeight() || obscurity != getObscurityFlags()) {
      width = dc.getWidth();
      height = dc.getHeight();
      obscurity = getObscurityFlags();
      return true;
    } else {
      return false;
    }
  }

  function onUpdate(dc) {
    try {
      onUpdateImpl(dc);
    } catch (e) {
      Log.e(TAG, "onUpdate ex: " + (e == null ? "NULL" : e.getErrorMessage()));
      if (e != null) {
        e.printStackTrace();
      }
    }
  }

  hidden function getWidthAt(dc, y) {
    switch (getObscurityFlags()) {
      // Middle data field on round watch.
      case OBSCURE_LEFT | OBSCURE_RIGHT: {
        return dc.getWidth() - 5;
      }
      // Top data field on round watch.
      case OBSCURE_TOP | OBSCURE_LEFT | OBSCURE_RIGHT: {
	var b = displayRadius - y;
	return Math.floor(2 * Math.sqrt(Math.pow(displayRadius, 2) - b*b)).toLong();
      }
      // Bottom data field on round watch.
      case OBSCURE_BOTTOM | OBSCURE_LEFT | OBSCURE_RIGHT: {
	var b = displayRadius - dc.getHeight() + y;
	return Math.floor(2 * Math.sqrt(Math.pow(displayRadius, 2) - b*b)).toLong();
      }
      // Single data field on round watch.
      case OBSCURE_TOP | OBSCURE_BOTTOM | OBSCURE_LEFT | OBSCURE_RIGHT: {
	var b = y < dc.getHeight() / 2 ? (displayRadius - y) : (displayRadius - dc.getHeight() + y);
	return Math.floor(2 * Math.sqrt(Math.pow(displayRadius, 2) - b*b)).toLong();
      }
      default:
        return width;
    }
  }

  hidden function drawText(dc, x, y, fontSymbol, text, vAlign, hAlign) {
    var font = settings[fontSymbol];
    var xy = dc.getTextDimensions(text, font);
    var textY = y;
    if (vAlign == :bottom) { y += dc.getFontAscent(font); }
    var rectX = null;
    switch (hAlign) {
      case Gfx.TEXT_JUSTIFY_LEFT: rectX = x; break;
      case Gfx.TEXT_JUSTIFY_CENTER: rectX = x - xy[0] / 2; break;
      case Gfx.TEXT_JUSTIFY_RIGHT: rectX = x - xy[0]; break;
    }
    drawDebugRect(dc, rectX, y, xy[0], xy[1], Gfx.COLOR_GREEN);
    dc.setColor(fgColor, Gfx.COLOR_TRANSPARENT);
    dc.drawText(x, y, font, text, hAlign);
    return xy;
  }

  hidden function onUpdateImpl(dc) {
    BackgroundScheduler.schedule2(data.glucoseBuffer.getLastDateSec(), 2);
    heartRateCollector.sample();
    setColors();
    var graph;
    if (updateDimension(dc)) {
      getSettings(dc);
      Log.i(TAG, "settings=" + settings[:name] + " width=" + width +
        " height=" + height + " obscurity=" + getObscurityFlags());
      graph = getGraph(dc, true);
    } else {
      graph = getGraph(dc, false);
    }
    dc.setColor(fgColor, bgColor);
    dc.clear();

    var x = dc.getWidth() / 2;
    var y = getY(dc);
    var xy = drawText(
	dc, x, y,
	:labelFont, Ui.loadResource(Rez.Strings.FieldName),
	:top, Gfx.TEXT_JUSTIFY_CENTER);
    var labelHeight = xy[1];
    if (isRound()) {
      drawValueAndExtraRound(dc, y + labelHeight);
    } else {
      drawValueAndExtraRect(dc, labelHeight, graph);
    }
  }

  hidden function drawValueAndExtraRect(dc, y, graph) {
    drawExtra(dc, y);

    var w = dc.getWidth() - settings[:extraWidth];
    var h = dc.getHeight() - y;
    if (graph != null) {
      h -= graph.height;
    }
    if (data.hasValue()) {
      drawValue(dc, 8, y, w, h);
    }
    if (data.errorMessage != null) {
      drawError(dc, 0, y, w, h);
    }

    if (graph != null) {
      graph.draw(dc);
    }
    if (data.hasValue()) {
      lastDrawnValueSec = data.glucoseBuffer.getLastDateSec();
    }
  }

  hidden function drawExtra(dc, labelHeight) {
    var x = dc.getWidth() - 5;
    var dataHeight = dc.getHeight() - labelHeight;
    var tempBasalColor = 
        data.temporaryBasalRate == null ? extraColor :
        data.temporaryBasalRate < 1.0 ? extraLoColor : extraHiColor;
    if (settings[:extraJustified]) {
      drawExtraValue(
          dc, x, labelHeight + 2 * dataHeight / 3 - 2, data.getBasalCorrectionStr(), tempBasalColor);
      drawExtraValue(dc, x, labelHeight + dataHeight / 3 - 1, data.getGlucoseAgeStr(), extraColor);
      if (data.errorMessage == null) {
        drawExtraValue(
            dc, x, labelHeight, data.getGlucoseDeltaPerMinuteStr(), 
            data.getGlucoseDeltaPerMinute() < 0 ? extraLoColor : extraHiColor);
      }
    } else {
      var labelFontHeight = 0; //Gfx.getFontHeight(settings[:labelFont]);
      var fontHeight = Gfx.getFontHeight(settings[:extraFont]);
      drawExtraValue(dc, x, labelFontHeight + 0 * (fontHeight + 2), data.getGlucoseDeltaPerMinuteStr(), extraColor);
      drawExtraValue(dc, x, labelFontHeight + 1 * (fontHeight + 2), data.getGlucoseAgeStr(), extraColor);
      drawExtraValue(dc, x, labelFontHeight + 2 * (fontHeight + 2), data.getBasalCorrectionStr(), tempBasalColor);
    }
  }

  hidden function drawExtraValue(dc, x, y, value, color) {
    dc.setColor(color, Gfx.COLOR_TRANSPARENT);
    dc.drawText(
       x, y-5, settings[:extraFont],
       value,
       Gfx.TEXT_JUSTIFY_RIGHT);
  }
}
