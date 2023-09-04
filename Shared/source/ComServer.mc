using Toybox.Lang;
using Toybox.Time;

module Shared {
(:background)
class ComServer extends BaseServer {
  hidden const TAG = "ComServer";

  function initialize() {
    BaseServer.initialize();
  }

  function init2() {
    BackgroundScheduler.registerTemporalEventIfConnectedIn(new Time.Duration(2));
    Background.registerForPhoneAppMessageEvent();
  }

  function getServiceDelegate() {
    return new CommunicationDelegate(me);
  }
}}
