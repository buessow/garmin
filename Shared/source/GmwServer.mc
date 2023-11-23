using Toybox.Lang;
using Toybox.Time;

module Shared {
(:background, :glance)
class GmwServer extends BaseServer {
  hidden const TAG = "GmwServer";
  const url = "http://127.0.0.1:28891/";
  const parameters;
  var wait = false;

  function initialize() {
    BaseServer.initialize();
  }

  function init2() {
    BackgroundScheduler.registerTemporalEventIfConnectedIn(new Time.Duration(2));
    BackgroundScheduler.schedule = true;
  }
}}
