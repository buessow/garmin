using Shared.Log;
using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;

(:glance)
class NearPeaksGlanceView extends Ui.GlanceView {
  hidden const TAG = "NearPeaksGlanceView";

  function initialize() {
    Ui.GlanceView.initialize();
    Log.i(TAG, "initialize");
  }

  function onLayout(dc) {
    Log.i(TAG, "onLayout");
    setLayout(Rez.Layouts.GlanceLayout(dc));
  }

  function onUpdate(dc) {
  }
}
