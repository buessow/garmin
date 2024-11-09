import Toybox.Lang;

using Shared.Util;
using Toybox.Application.Properties;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;

module Shared {
class Data {
  private static const TAG = "Data";
  var glucoseBuffer as Shared.DateValues = new Shared.DateValues(null, 30);
  var glucoseUnit as GlucoseUnit = mgdl;
  var lowGlucoseMark as Number?;
  var highGlucoseMark as Number?;
  var errorMessage as String?;
  var remainingInsulin as Float?;
  var remainingBasalInsulin as Float?;
  var temporaryBasalRate as Float?;
  var profile as String?;
  var connected as Boolean = true;
  private var fakeMode as FakeMode = normal;

  enum FakeMode {
    normal = 1,
    fakeValues = 2,
    fakeError = 3,
  }

   enum GlucoseUnit {
     mgdl = 1,
     mmoll = 2,
   }

  (:glance)
  function initialize() {
    try {
      restoreValues();
      if (fakeMode == fakeValues) {
        lowGlucoseMark = 60;
        highGlucoseMark = 130;
        var now = Util.nowSec();
        glucoseBuffer.clear();
        for (var i = 0; i < 24; i++) {
          glucoseBuffer.add(new DateValue(now - 300*(23-i) - 120, i==23 ? 150 : 100));
        }
      } else if (fakeMode == fakeError) {
        errorMessage = "Enable Garmin in AAPS config";
      }
    } catch (e) {
      Log.i(TAG, "restored failed: " + e.getErrorMessage());
    }
  }

  private function restoreValues() {
    var glucoseBufferStr = Util.ifNull(Properties.getValue("GlucoseValues"), "") as String;
    if (glucoseBufferStr.length() > 0) {
      glucoseBuffer.fromHexString(glucoseBufferStr);
      var dateSec = glucoseBuffer.getDateSec(glucoseBuffer.size()-1);
      if (Util.abs(Util.nowSec() - dateSec) > 3600) {
        Log.i(TAG, "stored value too old " + Util.timeSecToString(dateSec));
        glucoseBuffer.clear();
      } else {
        remainingInsulin = Properties.getValue("RemainingInsulin");
        remainingBasalInsulin = Properties.getValue("RemainingBasalInsulin");
        temporaryBasalRate = Properties.getValue("TemporaryBasalRate");
        lowGlucoseMark = Properties.getValue("LowGlucoseMark");
        highGlucoseMark = Properties.getValue("HighGlucoseMark");
        profile = Properties.getValue("BasalProfile");
        Log.i(TAG, "restored "+ glucoseBuffer.size() + " " + glucoseBuffer.get(glucoseBuffer.size() - 1) + " target: " + lowGlucoseMark);
      }
    }
    if (!hasValue()) {
      Log.i(TAG, "no glucose stored");
      errorMessage = "no value";
    }
    var glucoseUnitStr = Properties.getValue("GlucoseUnit");
    glucoseUnit = "mmoll".equals(glucoseUnitStr) ? mmoll : mgdl;

    if (fakeMode == fakeValues) {
      Properties.setValue("GlucoseValueFrequencySec", 300);
    }
  }

  // Returns true iff we have a blood glucose reading.
  function hasValue() as Boolean {
    return fakeMode == fakeValues
        || glucoseBuffer.size() > 0 && (Util.nowSec() - glucoseBuffer.getLastDateSec()) < 16 * 60;
  }

  function setProfile(profile as String?) as Void {
    Properties.setValue("BasalProfile", profile);
    me.profile = profile;
  }

  function setTemporaryBasalRate(tbr as Float?) as Void {
    temporaryBasalRate = tbr;
    Properties.setValue("TemporaryBasalRate", tbr);
  }

  function getBasalCorrectionStr() as String {
    if (fakeMode != normal) { return "S10%"; }
    var tbr = Util.ifNullFloat(temporaryBasalRate, 1.0);
    var s;
    if (tbr < 1.0) {
      s = (tbr * 100).format("%0.0f") + "%";
    } else {
      s = " " + tbr.format("%0.1f");
    }
    if (profile != null && !"D".equals(profile)) {
      s = profile + s;
    }
    return s;
  }

  function setRemainingInsulin(remainingInsulin as Float?, remainingBasalInsulin as Float?) as Void {
    me.remainingInsulin = remainingInsulin;
    me.remainingBasalInsulin = remainingBasalInsulin;
    Properties.setValue("RemainingInsulin", remainingInsulin);
    Properties.setValue("RemainingBasalInsulin", remainingBasalInsulin);
  }

  function getRemainingInsulinStr() as String {
    if (remainingInsulin == null) {
      return "iob -";
    }
    var r = remainingInsulin;
    if (Properties.getValue("ShowTotalRemainingInsulin") and remainingBasalInsulin != null) {
      r += remainingBasalInsulin;
    }
    return "iob " + r.format("%0.1f");
  }

  function setGlucoseRange(low as Number?, high as Number?) as Void {
    lowGlucoseMark = low;
    highGlucoseMark = high;
    Properties.setValue("LowGlucoseMark", lowGlucoseMark);
    Properties.setValue("HighGlucoseMark", highGlucoseMark);
  }

  // Returns the last glucose reading formatted in the selected
  // unit.
  //
  // @Returns Toybox.Lang.String
  function getGlucoseStr() as String {
    var glucose = null;
    if (fakeMode == fakeValues) {
      glucose = (Util.nowSec() % 30)*10 + Util.nowSec() % 11;
    } else {
      if (!hasValue()) { return "-"; }
      glucose = glucoseBuffer.getLastValue();
    }
    switch (glucoseUnit) {
      case mgdl:
	      return glucose.toString();
      case mmoll:
        glucose = glucose / 18.0;
        return glucose < 10.0
            ? glucose.format("%0.1f")
            : glucose.format("%0.0f");
    }
    return "";  // unreachable
  }

  function getGlucoseUnitStr() as String {
    if (hasValue()) {
      return glucoseUnit == mmoll ? "mmoll" : "mgdl";
    } else {
      return "";
    }
  }

  function setGlucoseUnit(glucoseUnit as GlucoseUnit) as Void {
    me.glucoseUnit = glucoseUnit;
    Properties.setValue("GlucoseUnit", getGlucoseUnitStr());
  }

  function getGlucoseTimeStr() as String {
    if (fakeMode != normal) { return "3:14"; }
    if (hasValue()) {
       return "_:__";
     } else {
      var info = Calendar.info(
          new Time.Moment(glucoseBuffer.getLastDateSec()), Time.FORMAT_MEDIUM);
      var hourDisplay = System.getDeviceSettings().is24Hour ? 24 : 12;
      return (info.hour % hourDisplay).toString() + ":" + info.min.format("%02d");
    }
  }

  private function formatMinute(t as Number?) as String {
    if (t == null) { return ""; }
    var min = t / 60;
    var sec = Util.abs(t) % 60;
    if (t < 600) {
      return min.toString() + ":" + sec.format("%02d");
    } else {
      return min.toString();
    }
  }

  // Gets how old the last blood glucose reading is as a formatted
  // string of the form min:sec or only min if it's longer than
  // 10min ago.
  //
  // @Returns Toybox.Lang.String
  function getGlucoseAgeStr() as String {
    if (fakeMode != normal) { return "3:14"; }
    if (!hasValue() || getGlucoseAgeSec() > 26 * 60) {
      return "_:__";
    }
    var t = getGlucoseAgeSec();
    return formatMinute(t);
  }

  function getNextScheduleDelaySec() {
     return BackgroundScheduler.nextScheduleTimeSec == null ? null :
       BackgroundScheduler.nextScheduleTimeSec - Util.nowSec();
  }

  function getGlucoseAgeSec() {
    return !hasValue() ? null : (Util.nowSec() - glucoseBuffer.getLastDateSec());
  }

  function getNextScheduleDelayStr() {
    return formatMinute(getNextScheduleDelaySec());
  }

  function getGlucoseDeltaPerMinute() {
    if (glucoseBuffer.size() > 1) {
      var last = glucoseBuffer.get(glucoseBuffer.size() - 1);
      var secs = Properties.getValue("GlucoseDeltaSec") as Number;
      return last.deltaPerSec(glucoseBuffer.get(glucoseBuffer.size() - 2), secs);
    } else {
      return null;
    }
  }

  // Gets how much the blood glucose has been changing per
  // minute as a formatted string.
  //
  // @Returns Toybox.Lang.String
  function getGlucoseDeltaPerMinuteStr() as String {
    if (fakeMode == fakeValues) { return "-0.05"; }
    if (!hasValue() || fakeMode != normal) {
      return "+_.__";
    }
    var deltaPerMinute = getGlucoseDeltaPerMinute();
    if (deltaPerMinute != null) {
      switch (glucoseUnit) {
        case mmoll: return (deltaPerMinute / 18.0).format("%+0.2f");
        case mgdl: return deltaPerMinute.format("%+0.1f");
      }
      return "";
    } else {
      return "+_.__";
    }
  }

  // Notify that glucoseBuffer was updated.
  function updateGlucose(glucoseBuffer as DateValues) as Void {
    if (fakeMode == fakeValues) { return; }
    me.glucoseBuffer = glucoseBuffer;
    var hex = glucoseBuffer.toHexString();
    var last = glucoseBuffer.getLastValue();
    Properties.setValue("GlucoseValues", hex);
    var glucoseFrequencySec = Properties.getValue("GlucoseValueFrequencyOverrideSec") as Number;
    if (glucoseFrequencySec == 0) {
      glucoseFrequencySec = 60 * (Util.ifNull(glucoseBuffer.medianDeltaMinute(), 300) as Number);
    }
    Log.i(TAG,
      "updateGlucose " + glucoseBuffer.size() + " values, " +
      "last " + (last==null?"NULL":last) + " freq " + glucoseFrequencySec);
    if (glucoseFrequencySec != null && glucoseFrequencySec > 0) {
      Properties.setValue("GlucoseValueFrequencySec", glucoseFrequencySec);
    }
    onError(last == null ? "no value" : null);
  }

  function onError(errorMessage as String?) as Void {
    if (fakeMode == normal) {
      me.errorMessage = errorMessage;
    }
  }
}}
