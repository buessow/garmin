import Toybox.Lang;

using Shared;
using Shared.Log;
using Shared.Util;
using Toybox.Application.Properties;
using Toybox.System;
using Toybox.WatchUi as Ui;

class GlucoseWatchFaceSettings extends Ui.View {
    private var menu as Ui.Menu2 = new Ui.Menu2({});
    private var input = new Input();

    function initialize() {
      Ui.View.initialize();
      menu.setTitle(Rez.Strings.SettingsTitle);
      menu.addItem(new Ui.ToggleMenuItem(
          Rez.Strings.AppearanceTitle,
          Rez.Strings.AppearanceDark,
          :menuAppearance,
          Properties.getValue("Appearance") == 0,
          {}));
      menu.addItem(new Ui.MenuItem(Rez.Strings.VersionTitle, BuildInfo.VERSION, :menuVersion, {}));
      menu.addItem(new Ui.MenuItem(Rez.Strings.BuildTimeTitle, BuildInfo.BUILD_TIME, :menuBuildTime, {}));
    }
    
    function get() as [ Ui.Views, Ui.InputDelegates ] {
      return [menu, input];
    }

    class Input extends Ui.Menu2InputDelegate {
        function initialize() {
          Ui.Menu2InputDelegate.initialize();
        }

        function onSelect(item as Ui.MenuItem) as Void {
          switch (item.getId()) {
            case :menuAppearance:
              var dark = (item as Ui.ToggleMenuItem).isEnabled();
              Properties.setValue("Appearance", dark ? 0 : 1);
              Application.getApp().onSettingsChanged();
              return;
            case :menuVersion:
            case :menuBuildTime:  
              Ui.popView(Ui.SLIDE_IMMEDIATE);
              return;
          }
        }

        function onBack() as Void {
          Ui.popView(Ui.SLIDE_IMMEDIATE);
        }
    }
}