import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

class PredictionView extends WatchUi.View {
    var dataManager = null;

    function initialize() {
        View.initialize();
        dataManager = RunnarDataManager.getInstance();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.PredictionLayout(dc));
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
        layout.getView("Title").setText("Finish Predictions");
        layout.getView("FiveK").setText("5K: " + dataManager.getFiveKPrediction());
        layout.getView("TenK").setText("10K: " + dataManager.getTenKPrediction());
        
        // Enhanced pace information
        var paceText = "Current: " + dataManager.getCurrentPace() + "/km";
        if (dataManager.averagePace > 0) {
            paceText += " | Avg: " + dataManager.getAveragePace() + "/km";
        }
        layout.getView("Pace").setText(paceText);
        
        // Draw additional metrics
        var centerX = dc.getWidth() / 2;
        var bottomY = dc.getHeight() - 20;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var additionalInfo = "";
        if (dataManager.calories > 0) {
            additionalInfo += "Cal: " + dataManager.calories;
        }
        if (dataManager.elevation > 0) {
            if (additionalInfo.length() > 0) {
                additionalInfo += " | ";
            }
            additionalInfo += "Elev: " + dataManager.elevation.format("%.0f") + "m";
        }
        if (additionalInfo.length() > 0) {
            dc.drawText(centerX, bottomY, Graphics.FONT_SMALL, additionalInfo, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
} 