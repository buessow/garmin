import Toybox.Lang;

using Shared.Util;

module Shared {
module RoadbookRefreshPolicy {
  // How far the rider has to move since the last successful query before requesting again.
  const REFRESH_DISTANCE_METER = 1000.0;

  // How long to wait after a failed request before retrying, regardless of movement.
  const RETRY_DELAY_SEC = 5;

  // Whether RoadbookView should send a new request for the rider's current position.
  //   lastQueryPos: position of the last request sent (successful or not), null if none yet.
  //   lastFailedTimeSec: Util.nowSec() at the last failed reply, null if the last reply succeeded.
  //   nowSec: Util.nowSec() for the caller's current position fix.
  function shouldRequestTowns(
      lastQueryPos as [Float or Double, Float or Double]?, lastFailedTimeSec as Number?,
      nowSec as Number, lat as Float or Double, lon as Float or Double) as Boolean {
    if (lastQueryPos == null) {
      return true;
    }
    if (lastFailedTimeSec != null) {
      return nowSec - lastFailedTimeSec >= RETRY_DELAY_SEC;
    }
    return Util.distanceMeter(lastQueryPos[0], lastQueryPos[1], lat, lon) >= REFRESH_DISTANCE_METER;
  }
}
}
