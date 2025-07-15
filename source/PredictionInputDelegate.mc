import Toybox.WatchUi;
import Toybox.Lang;

class PredictionInputDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKeyEvent(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER) {
            // Go back to main view
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        } else if (key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
            // Navigate to map view
            WatchUi.pushView(new MapView(), new MapInputDelegate(), WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }

    function onTap(evt) {
        // Handle tap events
        var coords = evt.getCoordinates();
        System.println("Prediction tap at: " + coords[0] + ", " + coords[1]);
        return true;
    }

} 