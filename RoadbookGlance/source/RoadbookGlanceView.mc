import Toybox.Lang;

using Toybox.Application.Storage;
using Toybox.Graphics as Gfx;
using Toybox.Time;
using Toybox.Timer;
using Toybox.WatchUi as Ui;

// The glance strip: how much riding is left to the end of the course.
//
// Glance mode gets ~32KB, so this deliberately touches nothing from Shared or the full app - just
// Storage, Graphics and Time. Everything it draws comes from three values the full view cached on
// its last successful roadbook response (see RoadbookView.cacheForGlance).
//
// The stored figure is a prediction made at a known moment, so the remaining time is recomputed
// here rather than redisplayed: it counts down in real time between openings of the full app. The
// arrival clock beside it is the fixed half of the pair - it does not move as time passes, which
// is what makes it worth showing next to a number that does.
class RoadbookGlanceView extends Ui.GlanceView {
  // The system recommends keeping glance updates under 1Hz. Ten seconds is the coarsest tick that
  // still keeps the minutes figure honest, since it can never be more than one tick stale.
  private const UPDATE_SEC = 10;
  // Past this the cached prediction is too old to mean anything - the rider has almost certainly
  // ridden on, or stopped, since it was made.
  private const STALE_SEC = 4 * 60 * 60;

  private var timer as Timer.Timer = new Timer.Timer();

  // The glance image is built from what (:glance) marks plus what it reaches, so the constructor
  // carries the annotation rather than the class - the shape GlucoseGlance already uses here.
  (:glance)
  function initialize() {
    GlanceView.initialize();
  }

  function onShow() as Void {
    // On devices the SDK calls "Background UI Update" this achieves nothing - requestUpdate() is
    // documented as having no effect there, and the system refreshes the glance when it becomes
    // visible and at most every 30s. Harmless on those, and on the roomier devices it gives the
    // 10s countdown asked for.
    timer.start(method(:onTimer), UPDATE_SEC * 1000, true);
  }

  function onHide() as Void {
    timer.stop();
  }

  function onTimer() as Void {
    Ui.requestUpdate();
  }

  function onUpdate(dc as Gfx.Dc) as Void {
    dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
    dc.clear();

    var width = dc.getWidth();
    var height = dc.getHeight();
    var smallHeight = dc.getFontHeight(Gfx.FONT_SYSTEM_XTINY);

    var remaining = remainingSec();
    if (remaining == null) {
      // Nothing cached, too old to trust, or the predicted arrival has passed. Says the app's name
      // rather than a number, because any number here would be invented.
      dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
      dc.drawText(
          0, height / 2, Gfx.FONT_SYSTEM_TINY, "Roadbook",
          Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
      return;
    }

    var name = Storage.getValue("GlanceDestinationName");
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.drawText(
        0, 0, Gfx.FONT_SYSTEM_XTINY, name == null ? "Roadbook" : name as String,
        Gfx.TEXT_JUSTIFY_LEFT);

    // The glance strip is a different height on each of the eight devices, so the figure takes the
    // largest font that still leaves the name its line rather than a size picked for one screen.
    var valueFont = Gfx.FONT_SYSTEM_MEDIUM;
    if (smallHeight + dc.getFontHeight(valueFont) > height) {
      valueFont = Gfx.FONT_SYSTEM_TINY;
    }
    var valueHeight = dc.getFontHeight(valueFont);
    var valueY = height - valueHeight;

    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    dc.drawText(
        0, valueY, valueFont, formatHoursMinutes(remaining as Number) + " left",
        Gfx.TEXT_JUSTIFY_LEFT);

    // The arrival clock is the fixed half of the pair - it does not move while the figure beside it
    // counts down - so it is worth the corner. Centred on the value's line, as in the full app.
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.drawText(
        width, valueY + (valueHeight - smallHeight) / 2, Gfx.FONT_SYSTEM_XTINY,
        formatClock(Time.now().value() + (remaining as Number)), Gfx.TEXT_JUSTIFY_RIGHT);
  }

  // Null when nothing was ever cached, when the cache is too old to trust, or once the predicted
  // arrival has passed - in all three cases there is no honest number to show.
  private function remainingSec() as Number? {
    var cached = Storage.getValue("GlanceRemainingSec");
    var at = Storage.getValue("GlanceUpdatedAtSec");
    if (cached == null || at == null) {
      return null;
    }
    var elapsed = Time.now().value() - (at as Number);
    if (elapsed < 0 || elapsed > STALE_SEC) {
      return null;
    }
    var remaining = (cached as Number) - elapsed;
    return remaining > 0 ? remaining : null;
  }

  private function formatHoursMinutes(second as Number) as String {
    var minute = (second + 30) / 60;
    return (minute / 60) + ":" + (minute % 60).format("%02d");
  }

  private function formatClock(epochSec as Number) as String {
    var info = Time.Gregorian.info(new Time.Moment(epochSec), Time.FORMAT_SHORT);
    return info.hour + ":" + info.min.format("%02d");
  }
}
