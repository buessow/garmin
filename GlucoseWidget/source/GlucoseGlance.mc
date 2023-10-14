using Shared.Log;
using Shared.Util;
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;

(:glance)
class GlucoseGlance extends Ui.GlanceView {
  hidden static const TAG = "GlucoseGlance";
  hidden var data;


  function initialize(data) {
    Ui.GlanceView.initialize();
    Log.i(TAG, "initialize");
    me.data = data;
  }

  function onLayout(dc) {
  }
  
  function onGlucose() {
    Log.i(TAG, "onGlucose");
    Ui.requestUpdate();
  }

  function drawText2(dc, x, y, str1, font1, str2, font2) {
    dc.drawText(x, y, font1, str1, Gfx.TEXT_JUSTIFY_LEFT);
    var dim1 = dc.getTextDimensions(str1, font1);
    var dim2 = dc.getTextDimensions(str2, font2);
    var x2 = x + dim1[0] + 2;
    var y2 = y + (dim1[1] - dim2[1]) / 2;
    dc.drawText(x2, y2, font2, str2, Gfx.TEXT_JUSTIFY_LEFT);
  }

  function onUpdate(dc) {
    dc.clear();
    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    // Uncomment next line for layout debugging.
    // dc.drawRectangle(0, 0, dc.getWidth()-1, dc.getHeight()-1);
    var fontHeight = dc.getFontHeight(Gfx.FONT_GLANCE);
    var xMargin = 12;
    var yMargin = 2;
    dc.drawText(
	xMargin,
	0, 
	Gfx.FONT_GLANCE,
	"GLUCOSE",
	Gfx.TEXT_JUSTIFY_LEFT);
    drawText2(
	dc,
	xMargin,
	fontHeight,
	data.getGlucoseStr(),
	Gfx.FONT_GLANCE_NUMBER,
	data.getGlucoseUnitStr(),
	Gfx.FONT_GLANCE);
    var xValue = 110;
    dc.drawText(
	xValue, 
	dc.getHeight() - 2 * fontHeight - yMargin, 
	Gfx.FONT_GLANCE, 
        data.getGlucoseDeltaPerMinute() != null ? data.getGlucoseDeltaPerMinuteStr() : "",
	Gfx.TEXT_JUSTIFY_LEFT);
    dc.drawText(
	xValue, 
	dc.getHeight() - fontHeight - yMargin,
	Gfx.FONT_GLANCE, 
	data.getRemainingInsulinStr(),
	Gfx.TEXT_JUSTIFY_LEFT);
  }
}
