import Toybox.Lang;

using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.FitContributor;
using Toybox.WatchUi as Ui;

(:fitContributor)
class GlucoseFitContributor {
  private static const TAG = "GlucoseFitContributor";
  private var glucoseField as FitContributor.Field;
  private var glucoseMinField as FitContributor.Field;
  private var glucoseMaxField as FitContributor.Field;
  private var glucoseMmollField as FitContributor.Field;
  private var glucoseMmollMinField as FitContributor.Field;
  private var glucoseMmollMaxField as FitContributor.Field;
  private var glucoseMin = null;
  private var glucoseMax = 0;

  function initialize(view as Ui.DataField, glucose as Number?) {
    glucoseField = view.createField(
        "blood glucose", 1, Toybox.FitContributor.DATA_TYPE_SINT16,
        {:units => "mg/dl", :mesgType => Toybox.FitContributor.MESG_TYPE_RECORD });
    glucoseMinField = view.createField(
        "blood glucose min", 2, Toybox.FitContributor.DATA_TYPE_SINT16,
        {:units => "mg/dl", :mesgType => Toybox.FitContributor.MESG_TYPE_SESSION });
    glucoseMaxField = view.createField(
        "blood glucose max", 3, Toybox.FitContributor.DATA_TYPE_SINT16,
        {:units => "mg/dl", :mesgType => Toybox.FitContributor.MESG_TYPE_SESSION });
    glucoseMmollField = view.createField(
        "blood glucose", 4, Toybox.FitContributor.DATA_TYPE_FLOAT,
        {:units => "mmol/l", :mesgType => Toybox.FitContributor.MESG_TYPE_RECORD });
    glucoseMmollMinField = view.createField(
        "blood glucose min", 5, Toybox.FitContributor.DATA_TYPE_FLOAT,
        {:units => "mmol/l", :mesgType => Toybox.FitContributor.MESG_TYPE_SESSION });
    glucoseMmollMaxField = view.createField(
        "blood glucose max", 6, Toybox.FitContributor.DATA_TYPE_FLOAT,
        {:units => "mmol/l", :mesgType => Toybox.FitContributor.MESG_TYPE_SESSION });
    if (glucose == null) {
      glucoseField.setData(0);
      glucoseMinField.setData(0);
      glucoseMaxField.setData(0);
      glucoseMmollField.setData(0);
      glucoseMmollMinField.setData(0);
      glucoseMmollMaxField.setData(0);
    } else {
      glucoseField.setData(glucose);
      glucoseMinField.setData(glucose);
      glucoseMaxField.setData(glucose);
      glucoseMmollField.setData(glucose / 18.0);
      glucoseMmollMinField.setData(glucose / 18.0);
      glucoseMmollMaxField.setData(glucose / 18.0);
      glucoseMin = glucose;
      glucoseMax = glucose;
    }
  }

  function onGlucose(glucose as Number?) as Void {
    if (glucoseField != null && glucose != null) {
      Log.i(TAG, "glucoseField.setData " + glucose);
      glucoseField.setData(glucose);
      glucoseMmollField.setData(glucose / 18.0);
      if (glucoseMin == null || glucose < glucoseMin) {
        glucoseMin = glucose;
      }
      if (glucose > glucoseMax) {
        glucoseMax = glucose;
      }
    }
  }

  function onTimerStop() as Void {
    Log.i(TAG, "onTimestop glucoseMin=" + Util.ifNull(glucoseMin, 0) + " glucoseMax=" + glucoseMax);
    if (glucoseMinField != null && glucoseMin != null) {
      glucoseMinField.setData(glucoseMin);
      glucoseMmollMinField.setData(glucoseMin / 18.0);
    }
    if (glucoseMaxField != null && glucoseMax > 0) {
      glucoseMaxField.setData(glucoseMax);
      glucoseMmollMaxField.setData(glucoseMax / 18.0);
    }
    glucoseMin = null;
    glucoseMax = 0;
  }
}