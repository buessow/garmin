import Toybox.Lang;

using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;

module Shared {
(:background, :glance)
module Log {
  function log(severity as String, tag as String, message as String) as Void {
    var timeInfo = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    Sys.println(Lang.format(
        "$1$ $2$-$3$-$4$T$5$:$6$:$7$ $8$ - $9$",
        [ severity,
          timeInfo.year.format("%02d"),
          (timeInfo.month as Number).format("%02d"),
          timeInfo.day.format("%02d"),
          timeInfo.hour.format("%02d"),
          timeInfo.min.format("%02d"),
          timeInfo.sec.format("%02d"),
          tag, message ]));
  }

  public function v(tag as String, message as String) as Void {
    log("V", tag, message);
  }

  public function i(tag as String, message as String) as Void {
    log("I", tag, message);
  }

  public function e(tag as String, message as String) as Void {
    log("E", tag, message);
  }
}}
