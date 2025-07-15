import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class RunnarInputDelegate extends WatchUi.BehaviorDelegate {
    var dataManager = null;

    function initialize() {
        BehaviorDelegate.initialize();
        dataManager = RunnarDataManager.getInstance();
    }

    function onKeyEvent(evt) {
        var key = evt.getKey();
        
        // Handle activity control
        if (key == WatchUi.KEY_ENTER) {
            handleActivityControl();
            return true;
        } else if (key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
            // Switch to map view
            WatchUi.pushView(new MapView(), new MapInputDelegate(), WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            // Switch to prediction view
            WatchUi.pushView(new PredictionView(), new PredictionInputDelegate(), WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (key == WatchUi.KEY_MENU) {
            // Switch to lap view
            WatchUi.pushView(new LapView(), new LapInputDelegate(), WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }

    function handleActivityControl() {
        switch (dataManager.activityState) {
            case RunnarDataManager.STATE_IDLE:
            case RunnarDataManager.STATE_STOPPED:
                dataManager.startActivity();
                System.println("Activity started");
                break;
            case RunnarDataManager.STATE_RUNNING:
                dataManager.pauseActivity();
                System.println("Activity paused");
                break;
            case RunnarDataManager.STATE_PAUSED:
                dataManager.resumeActivity();
                System.println("Activity resumed");
                break;
        }
    }

    function onTap(evt) {
        // Handle tap events - could be used for lap button
        var coords = evt.getCoordinates();
        System.println("Main view tap at: " + coords[0] + ", " + coords[1]);
        
        // If running, tap could trigger a lap
        if (dataManager.activityState == RunnarDataManager.STATE_RUNNING) {
            dataManager.startNewLap();
            System.println("New lap started");
        }
        
        return true;
    }
} 