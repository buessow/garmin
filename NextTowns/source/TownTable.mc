import Toybox.Lang;

using Toybox.Graphics as Gfx;

// Renders the town list as a simple two-column table: name left-aligned, distance right-aligned.
// Draws directly from dc dimensions rather than layout XML, since the app spans six screen
// families (240x320 to 480x800) and computing row count/positions once here is simpler than
// maintaining six near-identical layout.xml files.
class TownTable {
  private const MARGIN = 6;
  private const HEADER_FONT = Gfx.FONT_SYSTEM_SMALL;
  private const ROW_FONT = Gfx.FONT_SYSTEM_TINY;
  private const FOOTER_FONT = Gfx.FONT_SYSTEM_XTINY;
  private const DISTANCE_COLUMN_WIDTH = 60;

  function draw(
      dc as Gfx.Dc, towns as Array, course as Dictionary?, statusText as String?,
      footerText as String?) as Void {
    var width = dc.getWidth();
    var height = dc.getHeight();

    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
    dc.clear();

    var y = MARGIN;
    dc.drawText(width / 2, y, HEADER_FONT, "Next Towns", Gfx.TEXT_JUSTIFY_CENTER);
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
      dc.drawText(width / 2, y, ROW_FONT, summary, Gfx.TEXT_JUSTIFY_CENTER);
      y += dc.getFontHeight(ROW_FONT) + 4;
    }

    if (statusText != null && statusText.length() > 0) {
      dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
      dc.drawText(width / 2, y, ROW_FONT, statusText, Gfx.TEXT_JUSTIFY_CENTER);
      y += dc.getFontHeight(ROW_FONT) + 4;
    }

    var footerHeight = footerText != null ? dc.getFontHeight(FOOTER_FONT) + MARGIN : 0;
    var rowHeight = dc.getFontHeight(ROW_FONT) + 6;
    var availableHeight = height - y - footerHeight - MARGIN;
    var maxRows = availableHeight > 0 ? availableHeight / rowHeight : 0;
    var rowCount = towns.size() < maxRows ? towns.size() : maxRows;

    var nameWidth = width - MARGIN * 2 - DISTANCE_COLUMN_WIDTH;
    for (var i = 0; i < rowCount; i++) {
      var town = towns[i] as Dictionary;
      var larger = town[:larger] == true;
      var peak = town[:peak] == true;
      dc.setColor(
          peak ? Gfx.COLOR_BLUE : (larger ? Gfx.COLOR_YELLOW : Gfx.COLOR_WHITE),
          Gfx.COLOR_TRANSPARENT);
      var name;
      if (peak) {
        // The altitude is the point of a high-point row, and the only label it has when the
        // server couldn't match a named col or summit to it.
        var altitude = (town[:altitudeMeter] as Number) + " m";
        var peakName = town[:name];
        name = peakName == null ? altitude : (peakName as String) + " " + altitude;
      } else {
        name = town[:name] as String;
      }
      if (larger) {
        name = name.toUpper();
      }
      dc.drawText(
          MARGIN, y, ROW_FONT, truncate(dc, name, ROW_FONT, nameWidth), Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(
          width - MARGIN, y, ROW_FONT, formatDistance(town[:distanceMeter] as Number),
          Gfx.TEXT_JUSTIFY_RIGHT);
      y += rowHeight;
    }

    if (footerText != null) {
      dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
      dc.drawText(
          width / 2, height - footerHeight, FOOTER_FONT, footerText, Gfx.TEXT_JUSTIFY_CENTER);
    }
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

  private function formatDistance(distanceMeter as Number) as String {
    if (distanceMeter < 1000) {
      return distanceMeter + " m";
    }
    return (distanceMeter / 1000.0).format("%.1f") + " km";
  }
}
