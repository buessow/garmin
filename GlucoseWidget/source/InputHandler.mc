using Shared.Log;
using Shared.Util;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.Timer;
using Toybox.WatchUi as Ui;

class InputHandler extends Ui.BehaviorDelegate {
  const TAG = "InputHandler";
  var messenger;
  var carbs = 0;
  var connectMenutItem = null;
  hidden var timer;

  function initialize(messenger) {
    Ui.BehaviorDelegate.initialize();
    me.messenger = messenger;
    me.timer = new Timer.Timer();
  }

  function onSelect() {
    Log.i(TAG, "onSelect");
    return Ui.BehaviorDelegate.onSelect();
  }

  function onConnect() {
    Log.i(TAG, "onConnect " + messenger.data.connected);
    if (connectMenutItem != null) {
      connectMenutItem.setEnabled(messenger.data.connected);
      Ui.requestUpdate();
    }
  }

  function onPlus5() {
    Log.i(TAG, "+5g");
    addCarbs(5);
    return true;
  }

  function onPlus10() {
    Log.i(TAG, "+10g");
    addCarbs(10);
  }

  function onPlus20() {
    Log.i(TAG, "+20g");
    addCarbs(20);
    return true;
  }

  function onReset() {
    Log.i(TAG, "reset");
    addCarbs(-carbs);
    return true;
  }

  function onDone() {
    Log.i(TAG, "done");
    onSave();
    Log.i(TAG, "done2");
    return true;
  }

  function onSave() {
    Log.i(TAG, "save");
    var postCarbs = carbs;
    addCarbs(-carbs);
    if (postCarbs > 0) {
      messenger.postCarbs(postCarbs);
    }
    return true;
  }

  hidden function addCarbs(amount) {
    carbs += amount;
    if (carbs > 0) {
      timer.stop();
      timer.start(method(:onSave), 20000, false);
    }
    messenger.view.setCarbs(carbs);
  }

  hidden function createMenu() {
    var version = BuildInfo.VERSION;
    var title = Util.stringEndsWith(version, "pre") ? "A " + version : "Action";
    var menu = new Ui.Menu2({:title => title});
    if (messenger.data.connected != null) {
      connectMenutItem = new Ui.ToggleMenuItem(
          "connected",
          "pump status",
          :connect,
          messenger.data.connected,
          {});
      menu.addItem(connectMenutItem);
    }
    for (var i = 5; i <= 60; i += 5) {
      menu.addItem(new Ui.MenuItem(
          "eat " + i.toString() + "g",
          "carbohydrates",
          i,
          {}));
    }
    return menu;
  }

  hidden function createCarbMenu() {
    var menu = new Ui.Menu2({:title => "Carbohydrates"});
    for (var i = 5; i <= 60; i += 5) {
      menu.addItem(new Ui.MenuItem(
	  "eat " + i.toString() + "g",
	  "carbohydrates",
	   i,
	  {}));
    }
    return menu;
  }

  class BolusMenuDelegate extends Ui.Menu2InputDelegate {
    hidden var messenger;
    function initialize(messenger) {
      Ui.Menu2InputDelegate.initialize();
      me.messenger = messenger;
    }
    function onSelect(item) {
      Log.i("BolusMenuDelegate", "action" + item.toString());
      if (item.getId() == :connect) {
        messenger.connectPump((item as Ui.ToggleMenuItem).isEnabled() ? 0 : 30);
      } else if (item.getId() instanceof Lang.Number) {
        messenger.postCarbs(item.getId());
      	Ui.popView(Ui.SLIDE_IMMEDIATE);
      }
    }

    function onBack() {
      Ui.popView(Ui.SLIDE_IMMEDIATE);
    }
  }

  function getViewAndDelegate() {
    return [ createMenu(), new BolusMenuDelegate(messenger) ];
  }

  function onKey(ev) {
    if (ev.getKey() == Ui.KEY_ENTER) {
      Ui.pushView(
          createMenu(),
          new BolusMenuDelegate(messenger),
          Ui.SLIDE_IMMEDIATE);
      return true;
    } else if (ev.getKey() == Ui.KEY_UP) {
      Log.i(TAG, "connect " + Util.ifNull(messenger.data.connected, "NULL"));
      if (messenger.data.connected != null) {
        var delay = messenger.data.connected ? 30 :0;
        messenger.connectPump(delay);
      }
    } else if (ev.getKey() == Ui.KEY_DOWN) {
      Ui.pushView(
          createCarbMenu(),
          new BolusMenuDelegate(messenger),
          Ui.SLIDE_DOWN);
    }

    return false;
  }
}
