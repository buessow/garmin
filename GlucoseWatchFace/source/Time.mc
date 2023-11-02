import Toybox.Lang;

using Shared.Log;
using Shared.PartNumbers;
using Shared.Util;
using Toybox.Application.Properties;
using Toybox.Graphics as Gfx;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;

// Drawable that shows the current time as hour and minute, using the 
// given position and fonts. This class supports device specific overrides
// of certain parameters using the "timeOverrides" jsonData property.
class Time extends Ui.Drawable {
  private static const TAG = "Time";
  private var hourFont as Gfx.FontDefinition;
  private var minuteFont as Gfx.FontDefinition;
  private var minuteY as Number;
  private var hourMinuteSpace as Number;
  private var addMinuteY as Number = 0;
  
  function initialize(params as Dictionary) {
    Drawable.initialize(params);
    Log.i(TAG, "initialized " + params);
    addMinuteY = Util.ifNull(params.get(:addMinuteY), 0);

    var device = PartNumbers.map[System.getDeviceSettings().partNumber];
    var overrides = Application.loadResource(Rez.JsonData.timeOverrides);
    var deviceOverrides = overrides["deviceOverrides"];
    for (var i = 0; i < deviceOverrides.size(); i++) {
      var override = deviceOverrides[i];
      if (override["devices"].indexOf(device) != -1) {
        Log.i(TAG, "override " + device + " " + override);
        addMinuteY += Util.ifNull(override["addMinuteY"], 0);
        setLocation(
            Util.ifNull(override["locX"], locX),
            Util.ifNull(override["locY"], locY));
      }
    }
    hourFont = params.get(:hourFont) as Gfx.FontDefinition;
    minuteFont = params.get(:minuteFont) as Gfx.FontDefinition;
    hourMinuteSpace = params.get(:hourMinuteSpace) as Number;
    minuteY = locY 
        + Gfx.getFontDescent(hourFont) 
        - Gfx.getFontDescent(minuteFont) 
        + addMinuteY;
  }

  function draw(dc as Gfx.Dc) as Void {
    if (Properties.getValue("Appearance") == 1) {
      dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    } else {
      dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    }

    var now = Time.now();
    var nowInfo = Calendar.info(now, Time.FORMAT_MEDIUM);
    var hour = nowInfo.hour;
    var minute = nowInfo.min;
    // hour = nowInfo.sec % 24;
    // minute = nowInfo.sec % 60;
    
    var hourStr;
    if (System.getDeviceSettings().is24Hour) {
      hourStr = hour.format("%d");
    } else {
      var h = hour % 12;
      hourStr = (h == 0 ? 12 : h).format("%d");
    } 
    var minuteStr = minute.format("%02d");

    dc.drawText(locX, locY, hourFont, hourStr, Gfx.TEXT_JUSTIFY_RIGHT);
    dc.drawText(locX + hourMinuteSpace, minuteY, minuteFont, minuteStr, Gfx.TEXT_JUSTIFY_LEFT);
  }
}