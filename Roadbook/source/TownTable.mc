import Toybox.Lang;

using Shared.Util;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Time;

// Renders the town list as a table: name left-aligned, then distance, time-to-go and arrival clock
// time right-aligned. Draws directly from dc dimensions rather than layout XML, since the app spans
// six screen families (240x320 to 480x800) and computing row positions once here is simpler than
// maintaining six near-identical layout.xml files.
//
// A name too wide for its column takes a second line rather than a smaller font, so rows vary in
// height and the draw loop fills the available space instead of working from a fixed row count.
//
// Time-to-go carries a leading "+" and the arrival time does not, which is what tells the two
// apart - "+0:12" is a span, "9:01" is a clock reading. Cheaper than a separator glyph on a row
// that already has four columns to fit, and it survives being read at a glance on a bike.
class TownTable {
  private const MARGIN = 6;
  private const HEADER_FONT = Gfx.FONT_SYSTEM_SMALL;
  private const ROW_FONT = Gfx.FONT_SYSTEM_TINY;
  private const FOOTER_FONT = Gfx.FONT_SYSTEM_XTINY;
  private const DISTANCE_COLUMN_WIDTH = 60;
  private const DURATION_COLUMN_WIDTH = 46;
  private const ARRIVAL_COLUMN_WIDTH = 44;
  // Between a pass name and its altitude, and between a distance and its unit - both pairs set the
  // second part in FOOTER_FONT, so they need a little air that a space in one string would not give.
  private const UNIT_GAP = 4;

  function draw(
      dc as Gfx.Dc, towns as Array, course as Dictionary?, statusText as String?,
      footerText as String?) as Void {
    var width = dc.getWidth();
    var height = dc.getHeight();

    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
    dc.clear();

    var y = MARGIN;
    dc.drawText(width / 2, y, HEADER_FONT, "Roadbook", Gfx.TEXT_JUSTIFY_CENTER);
    y += dc.getFontHeight(HEADER_FONT) + 4;

    // The uploaded course this list is based on - two lines, name then length/ascent. Drawn
    // before maxRows is computed below so the town list gives up rows for it rather than
    // overflowing the screen.
    if (course != null) {
      dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
      var courseName = course[:name] as String;
      dc.drawText(
          width / 2, y, ROW_FONT,
          truncate(dc, courseName, ROW_FONT, width - MARGIN * 2), Gfx.TEXT_JUSTIFY_CENTER);
      y += dc.getFontHeight(ROW_FONT);

      var summary = formatDistance(course[:lengthMeter] as Number);
      var ascentMeter = course[:ascentMeter];
      if (ascentMeter != null) {
        summary += "  " + (ascentMeter as Number) + " m up";
      }
      // The whole course from its start, unlike the per-row times, which count from here - so it
      // gets no "+" and no arrival time, neither of which would mean anything mid-ride. The "h"
      // keeps it from reading as a clock time next to the other two figures.
      var courseSecond = course[:durationSecond];
      if (courseSecond != null) {
        summary += "  " + formatHoursMinutes(courseSecond as Number) + " h";
      }
      dc.drawText(width / 2, y, ROW_FONT, summary, Gfx.TEXT_JUSTIFY_CENTER);
      y += dc.getFontHeight(ROW_FONT) + 4;
    }

    if (statusText != null && statusText.length() > 0) {
      dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
      dc.drawText(width / 2, y, ROW_FONT, statusText, Gfx.TEXT_JUSTIFY_CENTER);
      y += dc.getFontHeight(ROW_FONT) + 4;
    }

    var footerHeight = footerText != null ? dc.getFontHeight(FOOTER_FONT) + MARGIN : 0;
    var lineHeight = dc.getFontHeight(ROW_FONT);
    var rowHeight = lineHeight + 6;
    // Rows are no longer a fixed height (a wrapped name takes two lines), so the loop below stops
    // when the next row would cross this instead of precomputing a row count.
    var limitY = height - footerHeight - MARGIN;

    // The two time columns cost name width, so only reserve them when the server actually predicted
    // something: it sends no durations at all for a course uploaded before elevation profiles were
    // kept, and those riders keep the old full-width layout. Scans every town rather than only the
    // ones that fit, so the columns don't appear and vanish as the visible row count changes.
    var durationWidth = 0;
    var arrivalWidth = 0;
    for (var i = 0; i < towns.size(); i++) {
      if ((towns[i] as Dictionary)[:durationSecond] != null) {
        durationWidth = DURATION_COLUMN_WIDTH;
        arrivalWidth = ARRIVAL_COLUMN_WIDTH;
        break;
      }
    }

    // Read once for the whole table rather than per row, so every arrival time on screen is
    // anchored to the same instant - otherwise a redraw spanning a second boundary could show two
    // rows a minute apart that are really the same.
    var nowSec = Util.nowSec();

    var nameWidth =
        width - MARGIN * 2 - DISTANCE_COLUMN_WIDTH - durationWidth - arrivalWidth;
    for (var i = 0; i < towns.size(); i++) {
      var town = towns[i] as Dictionary;
      var larger = town[:larger] == true;
      var peak = town[:peak] == true;
      var name;
      var altitude = null;
      if (peak) {
        var peakName = town[:name];
        if (peakName == null) {
          // With no matched col or summit the altitude is the row's only label, so it stays in the
          // row font - shrinking it would leave the row with nothing legible on it.
          name = "" + (town[:altitudeMeter] as Number);
        } else {
          // Set smaller beside the name, and with no unit: a bare number after a pass name reads as
          // an altitude, and the column is short of width as it is.
          name = peakName as String;
          altitude = "" + (town[:altitudeMeter] as Number);
        }
      } else {
        name = town[:name] as String;
      }
      if (larger) {
        name = name.toUpper();
      }

      // Wrapping rather than shrinking the font: these are read at a glance while riding, and the
      // time columns leave a peak row like "Grimselpass 2164" too little width on the 246px Edges.
      // Measured before drawing, because a two-line row may not fit the space that is left.
      var twoLines = needsTwoLines(dc, name, altitude, nameWidth);
      var thisHeight = twoLines ? rowHeight + lineHeight : rowHeight;
      if (y + thisHeight > limitY) {
        break;
      }

      dc.setColor(
          peak ? Gfx.COLOR_BLUE : (larger ? Gfx.COLOR_YELLOW : Gfx.COLOR_WHITE),
          Gfx.COLOR_TRANSPARENT);
      drawLabel(dc, name, altitude, y, nameWidth, lineHeight, twoLines);
      // Distance, time-to-go, arrival - left to right, on the first line of a wrapped row. A row
      // can be missing its duration while others have one, so each column keeps its place either
      // way instead of sliding right.
      var distanceMeter = town[:distanceMeter] as Number;
      var unit = distanceUnit(distanceMeter);
      var unitRight = width - MARGIN - durationWidth - arrivalWidth;
      // Unit in the smaller font, centred on the number's line rather than sharing its top edge.
      dc.drawText(
          unitRight, y + smallFontDrop(dc, lineHeight), FOOTER_FONT, unit,
          Gfx.TEXT_JUSTIFY_RIGHT);
      dc.drawText(
          unitRight - dc.getTextWidthInPixels(unit, FOOTER_FONT) - UNIT_GAP, y, ROW_FONT,
          distanceValue(distanceMeter), Gfx.TEXT_JUSTIFY_RIGHT);
      var durationSecond = town[:durationSecond];
      if (durationSecond != null) {
        var second = durationSecond as Number;
        dc.drawText(
            width - MARGIN - arrivalWidth, y, ROW_FONT, "+" + formatHoursMinutes(second),
            Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(
            width - MARGIN, y, ROW_FONT, formatClock(nowSec + second), Gfx.TEXT_JUSTIFY_RIGHT);
      }
      y += thisHeight;
    }

    if (footerText != null) {
      dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
      dc.drawText(
          width / 2, height - footerHeight, FOOTER_FONT, footerText, Gfx.TEXT_JUSTIFY_CENTER);
    }
  }

  // Vertical offset that centres FOOTER_FONT text on a ROW_FONT line. drawText takes y as the top
  // edge, so without this a small altitude or unit would hang from the top of the taller line.
  private function smallFontDrop(dc as Gfx.Dc, lineHeight as Number) as Number {
    return (lineHeight - dc.getFontHeight(FOOTER_FONT)) / 2;
  }

  // Whether the label needs a second line. Decided before drawing so the caller can check the row
  // still fits; drawLabel is then told the answer rather than working it out again.
  private function needsTwoLines(
      dc as Gfx.Dc, name as String, altitude as String?, maxWidth as Number) as Boolean {
    if (altitude != null) {
      return dc.getTextWidthInPixels(name, ROW_FONT) + UNIT_GAP +
          dc.getTextWidthInPixels(altitude, FOOTER_FONT) > maxWidth;
    }
    return dc.getTextWidthInPixels(name, ROW_FONT) > maxWidth;
  }

  // Name in ROW_FONT, with a pass altitude in FOOTER_FONT after it - dropping to its own line when
  // the pair is too wide. A pass name long enough to need wrapping on its own is truncated instead,
  // to keep the row at two lines; plain town names still wrap, which is what wrapName is for.
  private function drawLabel(
      dc as Gfx.Dc, name as String, altitude as String?, y as Number, maxWidth as Number,
      lineHeight as Number, twoLines as Boolean) as Void {
    var smallDrop = smallFontDrop(dc, lineHeight);
    if (altitude != null) {
      if (twoLines) {
        dc.drawText(
            MARGIN, y, ROW_FONT, truncate(dc, name, ROW_FONT, maxWidth), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(
            MARGIN, y + lineHeight + smallDrop, FOOTER_FONT, altitude, Gfx.TEXT_JUSTIFY_LEFT);
        return;
      }
      dc.drawText(MARGIN, y, ROW_FONT, name, Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(
          MARGIN + dc.getTextWidthInPixels(name, ROW_FONT) + UNIT_GAP, y + smallDrop, FOOTER_FONT,
          altitude, Gfx.TEXT_JUSTIFY_LEFT);
      return;
    }
    var lines = wrapName(dc, name, maxWidth);
    dc.drawText(MARGIN, y, ROW_FONT, lines[0], Gfx.TEXT_JUSTIFY_LEFT);
    if (lines.size() > 1) {
      dc.drawText(MARGIN, y + lineHeight, ROW_FONT, lines[1], Gfx.TEXT_JUSTIFY_LEFT);
    }
  }

  // One line when the name fits, two when it doesn't - split at the last space that still fits, so
  // "Grimselpass 2164" breaks into "Grimselpass" / "2164". Falls back to truncating when there
  // is no usable space (a single long word, or a first word already too wide).
  private function wrapName(dc as Gfx.Dc, text as String, maxWidth as Number) as Array<String> {
    if (dc.getTextWidthInPixels(text, ROW_FONT) <= maxWidth) {
      return [text];
    }
    var split = lastSpaceThatFits(dc, text, maxWidth);
    if (split < 0) {
      return [truncate(dc, text, ROW_FONT, maxWidth)];
    }
    return [
        text.substring(0, split) as String,
        truncate(dc, text.substring(split + 1, text.length()) as String, ROW_FONT, maxWidth)];
  }

  // Index of the last space whose preceding text still fits, or -1. Prefixes only get wider, so the
  // scan can stop at the first space that doesn't fit.
  private function lastSpaceThatFits(
      dc as Gfx.Dc, text as String, maxWidth as Number) as Number {
    var best = -1;
    for (var i = 0; i < text.length(); i++) {
      if (!(text.substring(i, i + 1) as String).equals(" ")) {
        continue;
      }
      if (dc.getTextWidthInPixels(text.substring(0, i) as String, ROW_FONT) > maxWidth) {
        break;
      }
      best = i;
    }
    return best;
  }

  private function truncate(
      dc as Gfx.Dc, text as String, font as Gfx.FontType, maxWidth as Number) as String {
    if (dc.getTextWidthInPixels(text, font) <= maxWidth) {
      return text;
    }
    var truncated = text;
    while (truncated.length() > 1 &&
        dc.getTextWidthInPixels(truncated + "…", font) > maxWidth) {
      truncated = truncated.substring(0, truncated.length() - 1) as String;
    }
    return truncated + "…";
  }

  // Always H:MM, never "48 min": the minutes form is ambiguous once a "+" marks it as a span, and
  // H:MM lines the time-to-go column up digit-for-digit with the arrival clock beside it.
  private function formatHoursMinutes(second as Number) as String {
    var minute = (second + 30) / 60;
    return (minute / 60) + ":" + (minute % 60).format("%02d");
  }

  // Device-local wall clock, honouring the watch's 12/24-hour setting. Arrival is computed from
  // "now" rather than from when the server answered, so it stays consistent with the "+" span next
  // to it and reads as "when you get there if you set off now" while the rider is stopped.
  private function formatClock(epochSec as Number) as String {
    var info = Time.Gregorian.info(new Time.Moment(epochSec), Time.FORMAT_SHORT);
    var hour = info.hour;
    if (!System.getDeviceSettings().is24Hour) {
      hour = hour % 12;
      if (hour == 0) {
        hour = 12;
      }
    }
    return hour + ":" + info.min.format("%02d");
  }

  // Split from its unit so a row can set the two in different fonts. The course summary line still
  // wants them as one centred string, which is what formatDistance is for.
  private function distanceValue(distanceMeter as Number) as String {
    if (distanceMeter < 1000) {
      return "" + distanceMeter;
    }
    return (distanceMeter / 1000.0).format("%.1f");
  }

  private function distanceUnit(distanceMeter as Number) as String {
    return distanceMeter < 1000 ? "m" : "km";
  }

  private function formatDistance(distanceMeter as Number) as String {
    return distanceValue(distanceMeter) + " " + distanceUnit(distanceMeter);
  }
}
