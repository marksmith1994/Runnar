import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Time;
import Toybox.Activity;
import Toybox.Application;

class RunnarView extends WatchUi.View {
    var dataManager = null;
    var timer = null;
    var autoPauseWarningShown = false;

    function initialize() {
        View.initialize();
        dataManager = RunnarDataManager.getInstance();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
        // Start timer to update every second
        timer = Sys.createTimer(method(:onTimer), RunnarDataManager.UPDATE_INTERVAL_MS, true);
        
        // Set up callbacks
        dataManager.setDataUpdateCallback(method(:onDataUpdate));
        dataManager.setStateChangeCallback(method(:onStateChange));
    }

    function onHide() as Void {
        if (timer != null) {
            Sys.cancelTimer(timer);
            timer = null;
        }
        dataManager.setDataUpdateCallback(null);
        dataManager.setStateChangeCallback(null);
    }

    function onTimer() {
        dataManager.updateData();
    }

    function onDataUpdate() {
        WatchUi.requestUpdate();
    }

    function onStateChange() {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        var layout = getLayout();
        
        // Update main metrics
        layout.getView("HeartRate").setText("HR: " + dataManager.heartRate);
        layout.getView("Time").setText("Time: " + dataManager.getFormattedTime());
        layout.getView("Distance").setText("Dist: " + RunnarUtils.formatDistance(dataManager.distance) + " km");
        
        // Add state indicator and enhanced metrics
        var stateColor = getStateColor();
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        
        // Draw state indicator
        var centerX = dc.getWidth() / 2;
        var topY = 10;
        dc.drawText(centerX, topY, Graphics.FONT_SMALL, dataManager.getStateString(), Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw additional metrics
        var bottomY = dc.getHeight() - 30;
        var metricsText = "Pace: " + dataManager.getCurrentPace() + "/km";
        if (dataManager.calories > 0) {
            metricsText += " | " + dataManager.calories + " cal";
        }
        dc.drawText(centerX, bottomY, Graphics.FONT_SMALL, metricsText, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Show auto-pause warning if needed
        if (dataManager.autoPauseWarningShown && dataManager.activityState == RunnarDataManager.STATE_RUNNING) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            var warningY = bottomY - 20;
            dc.drawText(centerX, warningY, Graphics.FONT_SMALL, "Auto-pause in 3s", Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Show auto-pause status
        if (RunnarDataManager.AUTO_PAUSE_ENABLED) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var statusY = topY + 20;
            dc.drawText(centerX, statusY, Graphics.FONT_SMALL, "Auto-pause: ON", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function getStateColor() {
        switch (dataManager.activityState) {
            case RunnarDataManager.STATE_RUNNING:
                return Graphics.COLOR_GREEN;
            case RunnarDataManager.STATE_PAUSED:
                return Graphics.COLOR_YELLOW;
            case RunnarDataManager.STATE_STOPPED:
                return Graphics.COLOR_RED;
            default:
                return Graphics.COLOR_WHITE;
        }
    }
} 