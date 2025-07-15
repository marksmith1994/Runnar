import Toybox.Lang;
import Toybox.Graphics;

class RunnarUtils {
    // Navigation constants
    static const NAV_MAIN = 0;
    static const NAV_PREDICTION = 1;
    static const NAV_MAP = 2;
    
    // Colors
    static const COLOR_TRACK = Graphics.COLOR_GREEN;
    static const COLOR_START = Graphics.COLOR_BLUE;
    static const COLOR_CURRENT = Graphics.COLOR_RED;
    static const COLOR_TEXT = Graphics.COLOR_WHITE;
    
    // Map constants
    static const MAP_MARGIN = 20;
    static const MAP_LABEL_HEIGHT = 80;
    static const MIN_LAT_LON_RANGE = 0.001;
    
    // Time formatting
    static function formatTime(seconds) {
        if (seconds == null || seconds < 0) {
            return "--:--";
        }
        
        var minutes = (seconds / 60).toFloor();
        var secs = (seconds % 60).toFloor();
        return minutes.format("%02d") + ":" + secs.format("%02d");
    }
    
    static function formatTimeLong(seconds) {
        if (seconds == null || seconds < 0) {
            return "--:--:--";
        }
        
        var hours = (seconds / 3600).toFloor();
        var minutes = ((seconds % 3600) / 60).toFloor();
        var secs = (seconds % 60).toFloor();
        return hours.format("%02d") + ":" + minutes.format("%02d") + ":" + secs.format("%02d");
    }
    
    // Distance formatting
    static function formatDistance(distance) {
        if (distance == null || distance < 0) {
            return "0.00";
        }
        return distance.format("%.2f");
    }
    
    // Map utilities
    static function calculateMapBounds(trackPoints) {
        if (trackPoints.size() == 0) {
            return null;
        }
        
        var minLat = trackPoints[0].toDegrees()[0];
        var maxLat = minLat;
        var minLon = trackPoints[0].toDegrees()[1];
        var maxLon = minLon;
        
        for (var i = 1; i < trackPoints.size(); i++) {
            var point = trackPoints[i].toDegrees();
            if (point[0] < minLat) { minLat = point[0]; }
            if (point[0] > maxLat) { maxLat = point[0]; }
            if (point[1] < minLon) { minLon = point[1]; }
            if (point[1] > maxLon) { maxLon = point[1]; }
        }
        
        return {
            "minLat" => minLat,
            "maxLat" => maxLat,
            "minLon" => minLon,
            "maxLon" => maxLon
        };
    }
    
    static function calculateMapScale(mapBounds, mapWidth, mapHeight) {
        var latRange = mapBounds["maxLat"] - mapBounds["minLat"];
        var lonRange = mapBounds["maxLon"] - mapBounds["minLon"];
        
        if (latRange < MIN_LAT_LON_RANGE) { latRange = MIN_LAT_LON_RANGE; }
        if (lonRange < MIN_LAT_LON_RANGE) { lonRange = MIN_LAT_LON_RANGE; }
        
        return {
            "scaleX" => mapWidth / lonRange,
            "scaleY" => mapHeight / latRange
        };
    }
    
    static function convertToScreenCoords(position, mapBounds, scale, margin) {
        var point = position.toDegrees();
        var x = margin + ((point[1] - mapBounds["minLon"]) * scale["scaleX"]);
        var y = margin + ((mapBounds["maxLat"] - point[0]) * scale["scaleY"]);
        return {"x" => x, "y" => y};
    }
} 