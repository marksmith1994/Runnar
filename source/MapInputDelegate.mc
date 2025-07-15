import Toybox.WatchUi;
import Toybox.Lang;

class MapInputDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKeyEvent(evt) {
        var key = evt.getKey();
        if (key == WatchUi.KEY_ENTER) {
            // Go back to main view
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }

    function onTap(evt) {
        // Handle tap events
        var coords = evt.getCoordinates();
        System.println("Map tap at: " + coords[0] + ", " + coords[1]);
        return true;
    }

} 