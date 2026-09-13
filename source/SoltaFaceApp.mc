import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.WatchUi;

class SoltaFaceApp extends Application.AppBase {

    private var _view as SoltaFaceView?;

    function initialize() {
        AppBase.initialize();
        _view = null;
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new SoltaFaceView();
        _view = view;
        return [ view, new SoltaFaceDelegate(view) ];
    }

    // On-device watch-face settings are invoked by compatible firmware through
    // the system Customize flow. The SDK 9.2 Fenix 5X profile does not expose it.
    function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        var enabled = getAlwaysRunningSeconds();
        return [ new SoltaFaceSettingsMenu(enabled), new SoltaFaceSettingsDelegate() ];
    }

    function onSettingsChanged() as Void {
        notifySettingsChanged();
    }

    function getAlwaysRunningSeconds() as Boolean {
        var value = Properties.getValue("alwaysRunningSeconds");
        return (value instanceof Boolean) ? value : false;
    }

    function setAlwaysRunningSeconds(enabled as Boolean) as Void {
        Properties.setValue("alwaysRunningSeconds", enabled);
        notifySettingsChanged();
    }

    private function notifySettingsChanged() as Void {
        var view = _view;
        if (view != null) {
            view.reloadSettings();
            WatchUi.requestUpdate();
        }
    }

}

function getApp() as SoltaFaceApp {
    return Application.getApp() as SoltaFaceApp;
}
