using Shared.Util;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;

(:glance)
module Shared {
class Data {
  hidden static const TAG = "Data";
  var glucoseBuffer = new Shared.DateValues(null, 24);   // never null
  var glucoseUnit as GlucoseUnit = mgdl;
  var errorMessage;
  var requestTimeSec;
  var remainingInsulin;
  var temporaryBasalRate;
  var profile = "D";
  var connected = true;
  var comServer = false;
  hidden var fakeMode = false;

   enum GlucoseUnit {
     unknown = 0,
     mgdl = 1,
     mmoll = 2,
   }

  function initialize() {
    try {
      restoreValues();
    } catch (e) {
      Log.i(TAG, "restored failed: " + e.getErrorMessage());
    }
  }

  hidden function restoreValues() {
    Log.i(TAG, "restoreValues()");
    var glucoseBufferStr = Util.ifNull(
        Application.getApp().getProperty("GlucoseBuffer5"), "");
    if (glucoseBufferStr.length() > 0) {
      glucoseBuffer.fromHexString(glucoseBufferStr);
      var dateSec = glucoseBuffer.getDateSec(glucoseBuffer.size()-1);
      if (Util.abs(Time.now().value() - dateSec) > 3600) {
        Log.i(TAG, "stored value too old " + Util.timeSecToString(dateSec));
        glucoseBuffer.fromHexString("");  // clear
      } else {
        remainingInsulin =
            Application.getApp().getProperty("RemainingInsulin");
        temporaryBasalRate =
            Application.getApp().getProperty("TemporaryBasalRate");
        profile = Application.getApp().getProperty("BasalProfile");
        Log.i(TAG, "restored " + glucoseBuffer.get(glucoseBuffer.size() - 1));
      }
    }
    if (glucoseBuffer.size() == 0) {
      Log.i(TAG, "no glucose stored");
      errorMessage = "no value";
    }
    var glucoseUnitStr = Application.getApp().getProperty("GlucoseUnit");
    glucoseUnit = glucoseUnitStr == "mmoll" ? mmoll : mgdl;
  }

  // Returns true iff we have a blood glucose reading.
  function hasValue() as Lang.Boolean {
    return glucoseBuffer.size() > 0 && (Util.nowSec() - glucoseBuffer.getLastDateSec()) < 16 * 60;
  }

  function setProfile(profile) {
    Application.getApp().setProperty("BasalProfile", profile);
    me.profile = profile;
  }

  function setTemporaryBasalRate(tbr) {
    temporaryBasalRate = tbr;
    Application.getApp().setProperty("TemporaryBasalRate", tbr);
  }

  function getBasalCorrectionStr() {
    if (fakeMode) { return "S10%"; }
    if (temporaryBasalRate == null || profile == null) {
      return  "-";
    }
    var s;
    if (temporaryBasalRate < 1) {
      s = (temporaryBasalRate * 100).format("%0.0f") + "%";
    } else {
      s = " " + temporaryBasalRate.format("%0.1f");
    }
    if (!"D".equals(profile)) {
      s = profile + s;
    }
    return s;
  }

  function setRemainingInsulin(remainingInsulin) {
    me.remainingInsulin = remainingInsulin;
    Application.getApp().setProperty("RemainingInsulin", remainingInsulin);
  }

  function getRemainingInsulinStr() {
    if (remainingInsulin == null) {
      return "iob -";
    }
    return "iob " + remainingInsulin.format("%0.1f");
  }

  // Returns the last glucose reading formatted in the selected
  // unit.
  //
  // @Returns Toybox.Lang.String
  function getGlucoseStr() {
    if (fakeMode) { return "5.6"; }
    if (!hasValue()) { return "-"; }
    switch (glucoseUnit) {
      case mgdl:
	return glucoseBuffer.getLastValue().toString();
      case mmoll:
	var glucose = glucoseBuffer.getLastValue() / 18.0;
	return glucose < 10.0
	     ? glucose.format("%0.1f")
	     : glucose.format("%0.0f");
    }
    return null;
  }

  function getGlucoseUnitStr() {
    if (hasValue()) {
      return glucoseUnit == mgdl ? "mgdl" : "mmoll";
    } else {
      return "";
    }
  }

  function setGlucoseUnit(glucoseUnit as GlucoseUnit) as Void {
    me.glucoseUnit = glucoseUnit;
    Application.getApp().setProperty("GlucoseUnit", getGlucoseUnitStr());
  }

  function getGlucoseTimeStr() {
    if (fakeMode) { return "3:14"; }
    if (hasValue()) {
       return "_:__";
     } else {
      var info = Calendar.info(
          new Time.Moment(glucoseBuffer.getLastDateSec()), Time.FORMAT_MEDIUM);
      var hourDisplay = System.getDeviceSettings().is24Hour ? 24 : 12;
      return (info.hour % hourDisplay).toString() + ":" + info.min.format("%02d");
    }
  }

  hidden function formatMinute(t) {
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
  function getGlucoseAgeStr() {
    if (fakeMode) { return "3:14"; }
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
      return last.deltaPerMinute(glucoseBuffer.get(glucoseBuffer.size() - 2));
    } else {
      return null;    
    }
  }

  // Gets the how much the blood glucose has been changing per
  // minute as a formatted string.
  //
  // @Returns Toybox.Lang.String
  function getGlucoseDeltaPerMinuteStr() {
    if (fakeMode) { return "-0.05"; }
    if (!hasValue()) {
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

  // Set the last readings.
  //
  // @Param glucoseBuffer: Shared.DeltaVarEncodedBuffer
  function setGlucose(glucoseBuffer) {
    Log.i(TAG, "setGlucose");
    if (glucoseBuffer != null && glucoseBuffer.size() > 0) {
      me.glucoseBuffer = glucoseBuffer;
      errorMessage = null;
      Log.i(TAG, "lastGlucose: " + glucoseBuffer.get(glucoseBuffer.size() - 1));
      Application.getApp().setProperty(
          "GlucoseBuffer5", glucoseBuffer.toHexString());

    } else {
      me.glucoseBuffer.clear();
      errorMessage = "no value";
    }
  }
}}
