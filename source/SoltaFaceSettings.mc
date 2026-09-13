import Toybox.Lang;
import Toybox.WatchUi;

class SoltaFaceSettingsMenu extends WatchUi.Menu2 {

    function initialize(enabled as Boolean) {
        Menu2.initialize({ :title => Rez.Strings.AppName });

        var mode = enabled
                ? Rez.Strings.SecondsAlwaysRunning
                : Rez.Strings.SecondsActiveOnly;
        addItem(new WatchUi.ToggleMenuItem(
                Rez.Strings.SecondsMenuLabel,
                mode,
                "alwaysRunningSeconds",
                enabled,
                null));
    }
}

class SoltaFaceSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(menuItem as MenuItem) as Void {
        if (menuItem instanceof ToggleMenuItem) {
            var enabled = menuItem.isEnabled();
            menuItem.setSubLabel(enabled
                    ? Rez.Strings.SecondsAlwaysRunning
                    : Rez.Strings.SecondsActiveOnly);
            getApp().setAlwaysRunningSeconds(enabled);
        }
    }
}
