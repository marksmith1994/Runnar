import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

class LapView extends WatchUi.View {
    var dataManager = null;
    var currentLapIndex = 0;

    function initialize() {
        View.initialize();
        dataManager = RunnarDataManager.getInstance();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.LapLayout(dc));
    }

    function onShow() as Void {
        // Set up callback for data updates
        dataManager.setDataUpdateCallback(method(:onDataUpdate));
    }

    function onHide() as Void {
        // Remove callback
        dataManager.setDataUpdateCallback(null);
    }

    function onDataUpdate() {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        var layout = getLayout();
        layout.getView("Title").setText("Lap Information");
        
        // Show current lap info
        if (dataManager.currentLap != null) {
            var lapText = "Current: " + RunnarUtils.formatDistance(dataManager.currentLap["distance"]) + " km";
            layout.getView("CurrentLap").setText(lapText);
            
            var timeText = "Time: " + RunnarUtils.formatTimeLong(dataManager.currentLap["time"]);
            layout.getView("LapTime").setText(timeText);
            
            if (dataManager.currentLap["pace"] > 0) {
                var paceText = "Pace: " + RunnarUtils.formatTime(dataManager.currentLap["pace"]) + "/km";
                layout.getView("LapPace").setText(paceText);
            }
        }
        
        // Show completed laps
        var completedLaps = dataManager.laps.size();
        if (completedLaps > 0) {
            var lastLap = dataManager.laps[completedLaps - 1];
            var lastLapText = "Last: " + RunnarUtils.formatDistance(lastLap["distance"]) + " km";
            layout.getView("LastLap").setText(lastLapText);
            
            var lastTimeText = "Time: " + RunnarUtils.formatTimeLong(lastLap["time"]);
            layout.getView("LastTime").setText(lastTimeText);
            
            if (lastLap["pace"] > 0) {
                var lastPaceText = "Pace: " + RunnarUtils.formatTime(lastLap["pace"]) + "/km";
                layout.getView("LastPace").setText(lastPaceText);
            }
        }
        
        // Draw lap count
        var centerX = dc.getWidth() / 2;
        var bottomY = dc.getHeight() - 20;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var lapCountText = "Total Laps: " + completedLaps;
        dc.drawText(centerX, bottomY, Graphics.FONT_SMALL, lapCountText, Graphics.TEXT_JUSTIFY_CENTER);
    }
} 