import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

class MapView extends WatchUi.View {
    var dataManager = null;
    var mapBounds = null;

    function initialize() {
        View.initialize();
        dataManager = RunnarDataManager.getInstance();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MapLayout(dc));
    }

    function onShow() as Void {
        // Set up callbacks for position updates
        dataManager.setPositionUpdateCallback(method(:onPositionUpdate));
        dataManager.setDataUpdateCallback(method(:onDataUpdate));
    }

    function onHide() as Void {
        // Remove callbacks
        dataManager.setPositionUpdateCallback(null);
        dataManager.setDataUpdateCallback(null);
    }

    function onPositionUpdate() {
        // Update map bounds when new position is added
        mapBounds = RunnarUtils.calculateMapBounds(dataManager.trackPoints);
        WatchUi.requestUpdate();
    }

    function onDataUpdate() {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        var layout = getLayout();
        layout.getView("MapTitle").setText("Running Route");
        
        if (dataManager.trackPoints.size() == 0) {
            layout.getView("MapInfo").setText("Waiting for GPS...");
            return;
        }
        
        layout.getView("MapInfo").setText("Points: " + dataManager.trackPoints.size());
        
        // Draw the map
        drawMap(dc);
    }

    function drawMap(dc as Dc) {
        if (dataManager.trackPoints.size() < 2 || mapBounds == null) {
            return;
        }
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var mapWidth = width - (2 * RunnarUtils.MAP_MARGIN);
        var mapHeight = height - (2 * RunnarUtils.MAP_MARGIN) - RunnarUtils.MAP_LABEL_HEIGHT;
        
        // Calculate scale
        var scale = RunnarUtils.calculateMapScale(mapBounds, mapWidth, mapHeight);
        
        // Draw track points
        dc.setColor(RunnarUtils.COLOR_TRACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        
        for (var i = 1; i < dataManager.trackPoints.size(); i++) {
            var prevCoords = RunnarUtils.convertToScreenCoords(
                dataManager.trackPoints[i-1], 
                mapBounds, 
                scale, 
                RunnarUtils.MAP_MARGIN
            );
            var currCoords = RunnarUtils.convertToScreenCoords(
                dataManager.trackPoints[i], 
                mapBounds, 
                scale, 
                RunnarUtils.MAP_MARGIN
            );
            
            dc.drawLine(prevCoords["x"], prevCoords["y"], currCoords["x"], currCoords["y"]);
        }
        
        // Draw start point
        if (dataManager.startPosition != null) {
            var startCoords = RunnarUtils.convertToScreenCoords(
                dataManager.startPosition, 
                mapBounds, 
                scale, 
                RunnarUtils.MAP_MARGIN
            );
            
            dc.setColor(RunnarUtils.COLOR_START, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(startCoords["x"], startCoords["y"], 4);
        }
        
        // Draw current position
        if (dataManager.currentPosition != null) {
            var currCoords = RunnarUtils.convertToScreenCoords(
                dataManager.currentPosition, 
                mapBounds, 
                scale, 
                RunnarUtils.MAP_MARGIN
            );
            
            dc.setColor(RunnarUtils.COLOR_CURRENT, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(currCoords["x"], currCoords["y"], 4);
        }
    }
} 