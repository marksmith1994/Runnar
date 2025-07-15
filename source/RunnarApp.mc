import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class RunnarApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        // Initialize data manager
        var dataManager = RunnarDataManager.getInstance();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        // Clean up data manager
        var dataManager = RunnarDataManager.getInstance();
        dataManager.stopActivity();
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new RunnarView(), new RunnarInputDelegate() ];
    }
} 