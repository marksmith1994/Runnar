import Toybox.Lang;
import Toybox.Time;
import Toybox.Sensor;
import Toybox.Activity;
import Toybox.Position;
import Toybox.System;
import Toybox.Attention;

class RunnarDataManager {
    // Constants
    static const MIN_DISTANCE_FOR_PREDICTION = 0.1; // 100m
    static const UPDATE_INTERVAL_MS = 1000;
    static const MAP_UPDATE_INTERVAL_MS = 2000;
    static const FIVE_K_DISTANCE = 5.0;
    static const TEN_K_DISTANCE = 10.0;
    
    // Activity states
    static const STATE_IDLE = 0;
    static const STATE_RUNNING = 1;
    static const STATE_PAUSED = 2;
    static const STATE_STOPPED = 3;
    
    // Auto-pause settings
    static const AUTO_PAUSE_ENABLED = true;
    static const AUTO_PAUSE_SPEED_THRESHOLD = 1.0; // meters per second
    static const AUTO_PAUSE_DELAY = 3000; // 3 seconds
    
    // Singleton instance
    static var instance = null;
    
    // Data properties
    var startTime = null;
    var pauseTime = null;
    var totalPauseTime = 0;
    var heartRate = "--";
    var distance = 0.0;
    var elapsedTime = 0;
    var activeTime = 0;
    var currentPace = 0.0;
    var averagePace = 0.0;
    var calories = 0;
    var elevation = 0.0;
    var trackPoints = [];
    var currentPosition = null;
    var startPosition = null;
    var activityState = STATE_IDLE;
    var laps = [];
    var currentLap = null;
    
    // Auto-pause variables
    var lastPositionTime = null;
    var lastPosition = null;
    var autoPauseTimer = null;
    var autoPauseWarningShown = false;
    
    // Milestone tracking
    var lastMilestoneDistance = 0.0;
    var milestoneDistances = [1.0, 2.0, 3.0, 5.0, 10.0]; // km
    
    // Callbacks
    var onDataUpdateCallback = null;
    var onPositionUpdateCallback = null;
    var onStateChangeCallback = null;
    
    function initialize() {
        reset();
    }
    
    static function getInstance() {
        if (instance == null) {
            instance = new RunnarDataManager();
        }
        return instance;
    }
    
    function reset() {
        startTime = null;
        pauseTime = null;
        totalPauseTime = 0;
        heartRate = "--";
        distance = 0.0;
        elapsedTime = 0;
        activeTime = 0;
        currentPace = 0.0;
        averagePace = 0.0;
        calories = 0;
        elevation = 0.0;
        trackPoints = [];
        currentPosition = null;
        startPosition = null;
        activityState = STATE_IDLE;
        laps = [];
        currentLap = null;
        lastPositionTime = null;
        lastPosition = null;
        autoPauseTimer = null;
        autoPauseWarningShown = false;
        lastMilestoneDistance = 0.0;
    }
    
    function startActivity() {
        if (activityState == STATE_IDLE || activityState == STATE_STOPPED) {
            startTime = Time.now();
            activityState = STATE_RUNNING;
            Sensor.enableSensor(Sensor.SENSOR_HEART_RATE);
            Activity.start(Activity.ACTIVITY_TYPE_RUNNING);
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPositionUpdate));
            startNewLap();
            notifyStateChange();
            
            // Audio feedback for start
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(100, 500)]);
            }
        }
    }
    
    function pauseActivity() {
        if (activityState == STATE_RUNNING) {
            pauseTime = Time.now();
            activityState = STATE_PAUSED;
            Sensor.disableSensor(Sensor.SENSOR_HEART_RATE);
            cancelAutoPauseTimer();
            notifyStateChange();
            
            // Audio feedback for pause
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(50, 200), new Attention.VibeProfile(50, 200)]);
            }
        }
    }
    
    function resumeActivity() {
        if (activityState == STATE_PAUSED) {
            if (pauseTime != null) {
                var now = Time.now();
                totalPauseTime += (now.value() - pauseTime.value());
                pauseTime = null;
            }
            activityState = STATE_RUNNING;
            Sensor.enableSensor(Sensor.SENSOR_HEART_RATE);
            notifyStateChange();
            
            // Audio feedback for resume
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(100, 300)]);
            }
        }
    }
    
    function stopActivity() {
        if (activityState != STATE_IDLE) {
            activityState = STATE_STOPPED;
            Sensor.disableSensor(Sensor.SENSOR_HEART_RATE);
            Activity.stop();
            Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPositionUpdate));
            endCurrentLap();
            cancelAutoPauseTimer();
            notifyStateChange();
            
            // Audio feedback for stop
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(100, 200), new Attention.VibeProfile(100, 200), new Attention.VibeProfile(100, 200)]);
            }
        }
    }
    
    function updateData() {
        // Update heart rate
        var hr = Sensor.getHeartRate();
        if (hr != null) {
            heartRate = hr.toString();
        }
        
        // Update time
        if (startTime != null && activityState != STATE_IDLE) {
            var now = Time.now();
            elapsedTime = now.value() - startTime.value();
            activeTime = elapsedTime - totalPauseTime;
        }
        
        // Update distance and pace
        var actInfo = Activity.getInfo();
        if (actInfo != null) {
            if (actInfo.hasKey("distance")) {
                distance = actInfo["distance"] / 1000.0; // meters to km
            }
            if (actInfo.hasKey("calories")) {
                calories = actInfo["calories"];
            }
            if (actInfo.hasKey("totalAscent")) {
                elevation = actInfo["totalAscent"];
            }
        }
        
        // Calculate paces
        if (distance > 0 && activeTime > 0) {
            currentPace = activeTime / distance; // seconds per km
            averagePace = elapsedTime / distance; // seconds per km
        }
        
        // Update current lap
        if (currentLap != null) {
            currentLap["distance"] = distance - currentLap["startDistance"];
            currentLap["time"] = activeTime - currentLap["startTime"];
        }
        
        // Check for milestones
        checkMilestones();
        
        // Notify listeners
        if (onDataUpdateCallback != null) {
            onDataUpdateCallback.invoke();
        }
    }
    
    function onPositionUpdate(info) {
        if (info has :position) {
            currentPosition = info.position;
            var now = Time.now();
            
            // Store start position if this is the first position
            if (startPosition == null) {
                startPosition = currentPosition;
            }
            
            // Add to track points
            trackPoints.add(currentPosition);
            
            // Auto-pause detection
            if (AUTO_PAUSE_ENABLED && activityState == STATE_RUNNING) {
                checkAutoPause(now);
            }
            
            // Update position tracking
            lastPosition = currentPosition;
            lastPositionTime = now;
            
            // Notify listeners
            if (onPositionUpdateCallback != null) {
                onPositionUpdateCallback.invoke();
            }
        }
    }
    
    function checkAutoPause(now) {
        if (lastPosition != null && lastPositionTime != null) {
            var timeDiff = now.value() - lastPositionTime.value();
            if (timeDiff > 2000) { // 2 seconds without movement
                if (!autoPauseWarningShown) {
                    showAutoPauseWarning();
                    autoPauseWarningShown = true;
                }
                
                if (timeDiff > AUTO_PAUSE_DELAY) {
                    pauseActivity();
                    autoPauseWarningShown = false;
                }
            } else {
                autoPauseWarningShown = false;
                cancelAutoPauseTimer();
            }
        }
    }
    
    function showAutoPauseWarning() {
        // Haptic warning for auto-pause
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 100), new Attention.VibeProfile(50, 100)]);
        }
        System.println("Auto-pause warning: You appear to have stopped moving");
    }
    
    function cancelAutoPauseTimer() {
        if (autoPauseTimer != null) {
            Sys.cancelTimer(autoPauseTimer);
            autoPauseTimer = null;
        }
    }
    
    function checkMilestones() {
        for (var i = 0; i < milestoneDistances.size(); i++) {
            var milestone = milestoneDistances[i];
            if (distance >= milestone && lastMilestoneDistance < milestone) {
                announceMilestone(milestone);
                lastMilestoneDistance = milestone;
            }
        }
    }
    
    function announceMilestone(distance) {
        // Haptic feedback for milestone
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 300), new Attention.VibeProfile(100, 300)]);
        }
        System.println("Milestone reached: " + distance + " km!");
    }
    
    function startNewLap() {
        endCurrentLap();
        currentLap = {
            "startDistance" => distance,
            "startTime" => activeTime,
            "distance" => 0.0,
            "time" => 0,
            "pace" => 0.0
        };
        
        // Haptic feedback for new lap
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(75, 200)]);
        }
    }
    
    function endCurrentLap() {
        if (currentLap != null) {
            currentLap["distance"] = distance - currentLap["startDistance"];
            currentLap["time"] = activeTime - currentLap["startTime"];
            if (currentLap["distance"] > 0) {
                currentLap["pace"] = currentLap["time"] / currentLap["distance"];
            }
            laps.add(currentLap);
            currentLap = null;
            
            // Haptic feedback for lap completion
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(100, 400)]);
            }
        }
    }
    
    function getFormattedTime() {
        if (elapsedTime == 0) {
            return "--:--:--";
        }
        
        var hours = (elapsedTime / 3600).toFloor();
        var minutes = ((elapsedTime % 3600) / 60).toFloor();
        var seconds = (elapsedTime % 60).toFloor();
        return hours.format("%02d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
    }
    
    function getActiveTime() {
        if (activeTime == 0) {
            return "--:--:--";
        }
        
        var hours = (activeTime / 3600).toFloor();
        var minutes = ((activeTime % 3600) / 60).toFloor();
        var seconds = (activeTime % 60).toFloor();
        return hours.format("%02d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
    }
    
    function getCurrentPace() {
        if (currentPace == 0) {
            return "--:--";
        }
        return formatTime(currentPace);
    }
    
    function getAveragePace() {
        if (averagePace == 0) {
            return "--:--";
        }
        return formatTime(averagePace);
    }
    
    function getPrediction(targetDistance) {
        if (distance < MIN_DISTANCE_FOR_PREDICTION) {
            return "--:--";
        }
        
        var paceSeconds = currentPace > 0 ? currentPace : averagePace;
        var predictedSeconds = paceSeconds * targetDistance;
        return formatTime(predictedSeconds);
    }
    
    function getFiveKPrediction() {
        return getPrediction(FIVE_K_DISTANCE);
    }
    
    function getTenKPrediction() {
        return getPrediction(TEN_K_DISTANCE);
    }
    
    function getStateString() {
        switch (activityState) {
            case STATE_IDLE:
                return "Ready";
            case STATE_RUNNING:
                return "Running";
            case STATE_PAUSED:
                return "Paused";
            case STATE_STOPPED:
                return "Stopped";
            default:
                return "Unknown";
        }
    }
    
    function formatTime(seconds) {
        var minutes = (seconds / 60).toFloor();
        var secs = (seconds % 60).toFloor();
        return minutes.format("%02d") + ":" + secs.format("%02d");
    }
    
    function setDataUpdateCallback(callback) {
        onDataUpdateCallback = callback;
    }
    
    function setPositionUpdateCallback(callback) {
        onPositionUpdateCallback = callback;
    }
    
    function setStateChangeCallback(callback) {
        onStateChangeCallback = callback;
    }
    
    function notifyStateChange() {
        if (onStateChangeCallback != null) {
            onStateChangeCallback.invoke();
        }
    }
} 