using Shared.RoadbookRefreshPolicy;
using TestLib.Assert;

(:test)
class RoadbookRefreshPolicyTest {

  (:test)
  function firstFixAlwaysRequests(log) {
    Assert.equal(true, RoadbookRefreshPolicy.shouldRequestTowns(null, null, 1000, 47.0, 8.0));
    return true;
  }

  (:test)
  function noRetryBeforeTheDistanceThreshold(log) {
    var queried = [47.0, 8.0];
    // ~900m north - short of REFRESH_DISTANCE_METER (1000m).
    Assert.equal(
        false, RoadbookRefreshPolicy.shouldRequestTowns(queried, null, 1000, 47.0081, 8.0));
    return true;
  }

  (:test)
  function requestsOnceThePastTheDistanceThreshold(log) {
    var queried = [47.0, 8.0];
    // ~1110m north - past REFRESH_DISTANCE_METER (1000m).
    Assert.equal(
        true, RoadbookRefreshPolicy.shouldRequestTowns(queried, null, 1000, 47.01, 8.0));
    return true;
  }

  (:test)
  function noRetryBeforeTheFailureDelayElapses(log) {
    var queried = [47.0, 8.0];
    // Still at the same spot - a distance-based check alone would never retry here.
    Assert.equal(
        false, RoadbookRefreshPolicy.shouldRequestTowns(queried, 1000, 1004, 47.0, 8.0));
    return true;
  }

  (:test)
  function retriesOnceTheFailureDelayElapses(log) {
    var queried = [47.0, 8.0];
    Assert.equal(
        true, RoadbookRefreshPolicy.shouldRequestTowns(queried, 1000, 1005, 47.0, 8.0));
    return true;
  }

  (:test)
  function retryIgnoresDistanceEvenWhenPastTheRefreshThreshold(log) {
    var queried = [47.0, 8.0];
    // Past REFRESH_DISTANCE_METER, but the failure delay hasn't elapsed yet - a failure must not
    // be masked by the rider having also moved far enough for a normal refresh.
    Assert.equal(
        false, RoadbookRefreshPolicy.shouldRequestTowns(queried, 1000, 1002, 47.01, 8.0));
    return true;
  }
}
