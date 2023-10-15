using Toybox.Application;
using Toybox.Time;

module Shared {
  (:background)
  class FakeServer extends BaseServer {
    function initialize() {
      BaseServer.initialize();
    }

    function init2() {
      Application.getApp().onBackgroundData(null);
    }

    function getServiceDelegate() {
      return null;
    }

    function onBackgroundData(result, data) {
      var now = Time.now();
      var delay = 10*60;
      var last = now.value() - delay;
      var valueCount = 24;
      var valueFreq = 5 * 60;
      var glucose = 180;
      var glucose0= glucose - 20;
      data.glucoseBuffer.add(new Shared.DateValue(last - (valueCount-1) * valueFreq, glucose));
      for (var i = last - (valueCount-2) * valueFreq; i < last; i += valueFreq) {
        data.glucoseBuffer.add(new Shared.DateValue(i, glucose0));
      }
      data.glucoseBuffer.add(new Shared.DateValue(last, glucose));
      data.updateGlucose();
      data.setGlucoseUnit(Data.mmoll);
      data.setTemporaryBasalRate(0.4);
      data.setProfile("S");
    }
  }
}
