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
// Time-to-go and arrival time share one column, alternating every TIME_TOGGLE_SEC, because giving
// each its own column left too little width for a pass name plus its altitude on the 246px Edges.
// The leading "+" is what tells them apart - "+0:12" is a span, "9:01" is a clock reading - so a
// glance that catches only one of the two still reads correctly.
class TownTable {
  private const MARGIN = 6;
  private const HEADER_FONT = Gfx.FONT_SYSTEM_SMALL;
  private const ROW_FONT = Gfx.FONT_SYSTEM_TINY;
  private const FOOTER_FONT = Gfx.FONT_SYSTEM_XTINY;
  private const DISTANCE_COLUMN_WIDTH = 60;
  // Wide enough for either of the alternating pair ("+1:47", "10:47").
  private const TIME_COLUMN_WIDTH = 46;
  // Slow enough to read at a glance on a bike, quick enough that the other value is never far off.
  static const TIME_TOGGLE_SEC = 3;

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

    // The time column costs name width, so only reserve it when the server actually predicted
    // something: it sends no durations at all for a course uploaded before elevation profiles were
    // kept, and those riders keep the old full-width layout. Scans every town rather than only the
    // ones that fit, so the column doesn't appear and vanish as the visible row count changes.
    var timeWidth = 0;
    for (var i = 0; i < towns.size(); i++) {
      if ((towns[i] as Dictionary)[:durationSecond] != null) {
        timeWidth = TIME_COLUMN_WIDTH;
        break;
      }
    }

    // Read once for the whole table rather than per row, so every arrival time on screen is
    // anchored to the same instant - otherwise a redraw spanning a second boundary could show two
    // rows a minute apart that are really the same.
    var nowSec = Util.nowSec();
    // Read once for the whole table too, so a redraw can't show arrival on one row and time-to-go
    // on the next.
    var showArrival = showsArrival(nowSec);

    var nameWidth = width - MARGIN * 2 - DISTANCE_COLUMN_WIDTH - timeWidth;
    for (var i = 0; i < towns.size(); i++) {
      var town = towns[i] as Dictionary;
      var larger = town[:larger] == true;
      var peak = town[:peak] == true;
      var name;
      if (peak) {
        // The altitude is the point of a high-point row, and the only label it has when the
        // server couldn't match a named col or summit to it. No unit: a bare number next to a pass
        // name reads as an altitude, and the column is short of width as it is.
        var altitude = "" + (town[:altitudeMeter] as Number);
        var peakName = town[:name];
        name = peakName == null ? altitude : (peakName as String) + " " + altitude;
      } else {
        name = town[:name] as String;
      }
      if (larger) {
        name = name.toUpper();
      }

      // Wrapping rather than shrinking the font: these are read at a glance while riding, and the
      // time columns leave a peak row like "Grimselpass 2164" too little width on the 246px Edges.
      // The break lands between name and altitude, which is where it reads best anyway.
      var lines = wrapName(dc, name, nameWidth);
      var thisHeight = lines.size() > 1 ? rowHeight + lineHeight : rowHeight;
      if (y + thisHeight > limitY) {
        break;
      }

      dc.setColor(
          peak ? Gfx.COLOR_BLUE : (larger ? Gfx.COLOR_YELLOW : Gfx.COLOR_WHITE),
          Gfx.COLOR_TRANSPARENT);
      dc.drawText(MARGIN, y, ROW_FONT, lines[0], Gfx.TEXT_JUSTIFY_LEFT);
      if (lines.size() > 1) {
        dc.drawText(MARGIN, y + lineHeight, ROW_FONT, lines[1], Gfx.TEXT_JUSTIFY_LEFT);
      }
      // Distance then time, on the first line of a wrapped row. A row can be missing its duration
      // while others have one, so the distance column keeps its place either way instead of
      // sliding right.
      dc.drawText(
          width - MARGIN - timeWidth, y, ROW_FONT,
          formatDistance(town[:distanceMeter] as Number), Gfx.TEXT_JUSTIFY_RIGHT);
      var durationSecond = town[:durationSecond];
      if (durationSecond != null) {
        var second = durationSecond as Number;
        dc.drawText(
            width - MARGIN, y, ROW_FONT,
            showArrival ? formatClock(nowSec + second) : "+" + formatHoursMinutes(second),
            Gfx.TEXT_JUSTIFY_RIGHT);
      }
      y += thisHeight;
    }

    if (footerText != null) {
      dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
      dc.drawText(
          width / 2, height - footerHeight, FOOTER_FONT, footerText, Gfx.TEXT_JUSTIFY_CENTER);
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

  // Which half of the pair is showing. Derived from the clock rather than a counter, so TownTable
  // keeps no state and RoadbookView can spot the flip with the same call.
  static function showsArrival(nowSec as Number) as Boolean {
    return (nowSec / TIME_TOGGLE_SEC) % 2 == 0;
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

  private function formatDistance(distanceMeter as Number) as String {
    if (distanceMeter < 1000) {
      return distanceMeter + " m";
    }
    return (distanceMeter / 1000.0).format("%.1f") + " km";
  }
}
