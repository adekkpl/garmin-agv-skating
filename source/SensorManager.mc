// SensorManager.mc
// Garmin Aggressive Inline Skating Tracker v2.0.0
// Sensor Management Class - Updated with HR + GPS - API 5.0 COMPLIANT

using Toybox.Lang;
using Toybox.System;
using Toybox.Math;
using Toybox.Sensor;
using Toybox.Position;
using Toybox.Timer;
using Toybox.ActivityMonitor;

class SensorManager {
    
    // Sensor data storage - NULLABLE TYPES
    var currentAccelData as Lang.Dictionary or Null;
    var currentBarometerData as Lang.Dictionary or Null;
    var currentGpsData as Lang.Dictionary or Null;
    var currentHeartRateData as Lang.Dictionary or Null;
    
    // Data update timer
    var updateTimer as Timer.Timer or Null;
    var dataUpdateCallback as Lang.Method or Null;
    
    // Sensor availability flags
    var hasAccelerometer as Lang.Boolean = false;
    var hasBarometer as Lang.Boolean = false;
    var hasGps as Lang.Boolean = false;
    var hasHeartRate as Lang.Boolean = false;
    
    // Data history for analysis (circular buffers) - NULLABLE TYPED ARRAYS
    var accelHistory as Lang.Array<Lang.Dictionary> or Null;
    var altitudeHistory as Lang.Array<Lang.Dictionary> or Null;
    var gpsHistory as Lang.Array<Lang.Dictionary> or Null;
    
    // GPS tracking variables - NULLABLE TYPES
    var sessionStartPosition as Lang.Dictionary or Null;
    var sessionTotalDistance as Lang.Float = 0.0;
    var lastGpsPosition as Lang.Dictionary or Null;
    var sessionDistance as Lang.Float = 0.0;
    var sessionStartTime as Lang.Number or Null;
    
    const HISTORY_SIZE = 50; // ~5 seconds at 10Hz
    
    function initialize() {
        System.println("SensorManager: Initializing AGV sensor management");
        
        // Initialize data storage
        initializeDataStorage();
        
        // Check sensor availability
        checkSensorAvailability();
        
        // Setup update timer
        updateTimer = new Timer.Timer();
        
        // Initialize GPS tracking - SAFE INITIALIZATION with null
        lastGpsPosition = null;
        sessionDistance = 0.0;
        sessionStartTime = null;
        sessionStartPosition = null;
        sessionTotalDistance = 0.0;
    }

    // Initialize data storage structures - SAFE DICTIONARIES
    function initializeDataStorage() {
        System.println("SensorManager: Initializing data storage");
        
        // SAFE DICTIONARY CREATION with explicit types
        currentAccelData = {
            "x" => 0.0 as Lang.Float,
            "y" => 0.0 as Lang.Float,
            "z" => 0.0 as Lang.Float,
            "timestamp" => 0 as Lang.Number
        } as Lang.Dictionary;
        
        currentBarometerData = {
            "pressure" => 0.0 as Lang.Float,
            "altitude" => 0.0 as Lang.Float,
            "timestamp" => 0 as Lang.Number
        } as Lang.Dictionary;
        
        currentGpsData = {
            "latitude" => 0.0 as Lang.Float,
            "longitude" => 0.0 as Lang.Float,
            "altitude" => 0.0 as Lang.Float,
            "speed" => 0.0 as Lang.Float,
            "accuracy" => Position.QUALITY_NOT_AVAILABLE,
            "timestamp" => 0 as Lang.Number,
            "sessionDistance" => 0.0 as Lang.Float
        } as Lang.Dictionary;
        
        currentHeartRateData = {
            "heartRate" => 0 as Lang.Number,
            "timestamp" => 0 as Lang.Number
        } as Lang.Dictionary;
        
        // Initialize history arrays - TYPED ARRAYS
        accelHistory = new Lang.Array<Lang.Dictionary>[HISTORY_SIZE];
        altitudeHistory = new Lang.Array<Lang.Dictionary>[HISTORY_SIZE];
        gpsHistory = new Lang.Array<Lang.Dictionary>[HISTORY_SIZE];
        
        // SAFE ARRAY INITIALIZATION
        for (var i = 0; i < HISTORY_SIZE; i++) {
            if (i < accelHistory.size()) {
                accelHistory[i] = {
                    "x" => 0.0 as Lang.Float, 
                    "y" => 0.0 as Lang.Float, 
                    "z" => 0.0 as Lang.Float, 
                    "t" => 0 as Lang.Number
                } as Lang.Dictionary;
            }
            
            if (i < altitudeHistory.size()) {
                altitudeHistory[i] = {
                    "alt" => 0.0 as Lang.Float, 
                    "t" => 0 as Lang.Number
                } as Lang.Dictionary;
            }
            
            if (i < gpsHistory.size()) {
                gpsHistory[i] = {
                    "lat" => 0.0 as Lang.Float, 
                    "lon" => 0.0 as Lang.Float, 
                    "alt" => 0.0 as Lang.Float, 
                    "t" => 0 as Lang.Number
                } as Lang.Dictionary;
            }
        }
        
        System.println("SensorManager: Data storage initialized");
    }

    // Check which sensors are available on this device
    function checkSensorAvailability() {
        System.println("SensorManager: Checking AGV sensor availability");
        
        try {
            // Check heart rate availability
            var sensorInfo = Sensor.getInfo();
            hasHeartRate = (sensorInfo has :heartRate);
            
            // Check GPS availability
            try {
                var posInfo = Position.getInfo();
                hasGps = (posInfo != null);
            } catch (ex) {
                hasGps = false;
                System.println("SensorManager: GPS not available: " + ex.getErrorMessage());
            }
            
            // Set others to false for now (will be added later)
            hasAccelerometer = false;
            hasBarometer = false;
            
        } catch (exception) {
            System.println("SensorManager: Error checking sensors: " + exception.getErrorMessage());
            hasHeartRate = false;
            hasGps = false;
        }
        
        System.println("SensorManager: AGV sensors - HR: " + hasHeartRate + ", GPS: " + hasGps);
    }

    // Start AGV sensors (HR + GPS)
    function startSensors() {
        System.println("SensorManager: Starting AGV sensors (HR + GPS)");
        
        try {
            // Reset session tracking
            sessionDistance = 0.0;
            sessionStartTime = System.getTimer();
            lastGpsPosition = null;
            
            // 1. Start Heart Rate monitoring
            if (hasHeartRate) {
                System.println("SensorManager: Enabling heart rate sensor");
                Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
                Sensor.enableSensorEvents(method(:onSensorEvent));
                System.println("SensorManager: Heart rate sensor enabled");
            } else {
                System.println("SensorManager: Heart rate not available");
            }
            
            // 2. Start GPS tracking
            if (hasGps) {
                System.println("SensorManager: Enabling GPS tracking");
                Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onLocationEvent));
                System.println("SensorManager: GPS tracking enabled");
            } else {
                System.println("SensorManager: GPS not available");
            }
            
            // 3. Start regular data updates
            updateTimer.start(method(:updateAGVData), 2000, true); // Every 2 seconds
            System.println("SensorManager: AGV update timer started");
            
            System.println("SensorManager: AGV sensors started successfully");
            
        } catch (exception) {
            System.println("SensorManager: Error starting AGV sensors: " + exception.getErrorMessage());
        }
    }

    // Stop all sensors
    function stopSensors() as Void {
        System.println("SensorManager: Stopping AGV sensors");
        
        try {
            // Stop heart rate
            Sensor.setEnabledSensors([]); // Disable all sensors
            
            // Stop GPS
            if (hasGps) {
                Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
            }
            
            // Stop update timer
            if (updateTimer != null) {
                updateTimer.stop();
            }
            
            System.println("SensorManager: AGV sensors stopped");
            
        } catch (exception) {
            System.println("SensorManager: Error stopping sensors: " + exception.getErrorMessage());
        }
    }

    // Heart Rate sensor callback - SAFE DICTIONARY ACCESS
    function onSensorEvent(sensorInfo as Sensor.Info) as Void {
        System.println("SensorManager: Sensor event received");
        
        try {
            if (sensorInfo != null && sensorInfo.heartRate != null) {
                var hr = sensorInfo.heartRate as Lang.Number;
                System.println("SensorManager: HR = " + hr + " bpm");
                
                // SAFE DICTIONARY UPDATE
                if (currentHeartRateData != null) {
                    currentHeartRateData.put("heartRate", hr);
                    currentHeartRateData.put("timestamp", System.getTimer());
                }
            } else {
                System.println("SensorManager: HR data not available");
            }
        } catch (exception) {
            System.println("SensorManager: HR callback error: " + exception.getErrorMessage());
        }
    }

    // GPS position callback - SAFE DICTIONARY ACCESS
    function onLocationEvent(info as Position.Info) as Void {
        System.println("SensorManager: GPS event received");
        
        try {
            if (info != null && info.position != null) {
                var degrees = info.position.toDegrees();
                var timestamp = System.getTimer();
                
                // SAFE ARRAY ACCESS
                var latitude = degrees[0] as Lang.Double;
                var longitude = degrees[1] as Lang.Double;
                var altitude = (info.altitude != null) ? info.altitude as Lang.Float : 0.0;
                var speed = (info.speed != null) ? info.speed as Lang.Float : 0.0;
                
                // SAFE DICTIONARY UPDATE
                if (currentGpsData != null) {
                    currentGpsData.put("latitude", latitude);
                    currentGpsData.put("longitude", longitude);
                    currentGpsData.put("altitude", altitude);
                    currentGpsData.put("speed", speed);
                    currentGpsData.put("accuracy", info.accuracy);
                    currentGpsData.put("timestamp", timestamp);
                }
                
                // Calculate session distance - SAFE ACCESS
                if (lastGpsPosition != null && lastGpsPosition has :lat && lastGpsPosition has :lon) {
                    var distance = calculateDistance(lastGpsPosition, {
                        "lat" => latitude,
                        "lon" => longitude
                    });
                    sessionDistance += distance;
                    
                    if (currentGpsData != null) {
                        currentGpsData.put("sessionDistance", sessionDistance);
                    }
                }
                
                // Update last position - SAFE DICTIONARY CREATION
                lastGpsPosition = {
                    "lat" => latitude,
                    "lon" => longitude
                } as Lang.Dictionary;
                
                // Add to history - SAFE DICTIONARY CREATION
                var historyEntry = {
                    "lat" => latitude,
                    "lon" => longitude,
                    "alt" => altitude,
                    "t" => timestamp
                } as Lang.Dictionary;
                
                addToHistory(gpsHistory, historyEntry);
                
                System.println("SensorManager: GPS - Lat:" + latitude + 
                              " Lon:" + longitude + 
                              " Speed:" + speed + "m/s" +
                              " Distance:" + sessionDistance.format("%.1f") + "m");
                
            } else {
                System.println("SensorManager: GPS data not available");
            }
        } catch (exception) {
            System.println("SensorManager: GPS callback error: " + exception.getErrorMessage());
        }
    }

    // Regular AGV data update
    function updateAGVData() as Void {
        try {
            // Get additional data from ActivityMonitor
            var info = ActivityMonitor.getInfo();
            if (info != null) {
                // Log available ActivityMonitor data
                if (info.calories != null) {
                    System.println("SensorManager: Daily calories = " + info.calories);
                }
                
                if (info.steps != null) {
                    System.println("SensorManager: Daily steps = " + info.steps);
                }
            }
            
            // Trigger callback with current sensor data
            if (dataUpdateCallback != null) {
                dataUpdateCallback.invoke(getCurrentSensorData());
            }
            
        } catch (exception) {
            System.println("SensorManager: updateAGVData error: " + exception.getErrorMessage());
        }
    }

    // Calculate distance between two GPS coordinates - SAFE ACCESS
    function calculateDistance(pos1 as Lang.Dictionary, pos2 as Lang.Dictionary) as Lang.Float {
        try {
            // SAFE DICTIONARY ACCESS with type checking
            if (pos1 == null || pos2 == null || 
                !(pos1 has :lat) || !(pos1 has :lon) ||
                !(pos2 has :lat) || !(pos2 has :lon)) {
                return 0.0;
            }
            
            var lat1 = (pos1.get("lat") as Lang.Double) * Math.PI / 180.0;
            var lon1 = (pos1.get("lon") as Lang.Double) * Math.PI / 180.0;
            var lat2 = (pos2.get("lat") as Lang.Double) * Math.PI / 180.0;
            var lon2 = (pos2.get("lon") as Lang.Double) * Math.PI / 180.0;
            
            var earthRadius = 6371000.0; // meters
            
            var dLat = lat2 - lat1;
            var dLon = lon2 - lon1;
            
            var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                    Math.cos(lat1) * Math.cos(lat2) *
                    Math.sin(dLon/2) * Math.sin(dLon/2);
            
            var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
            
            var distance = earthRadius * c;
            return distance as Lang.Float;
            
        } catch (exception) {
            System.println("SensorManager: Distance calculation error: " + exception.getErrorMessage());
            return 0.0;
        }
    }

    // Add data to circular history buffer - SAFE ARRAY ACCESS
    function addToHistory(historyArray as Lang.Array<Lang.Dictionary>, data as Lang.Dictionary) as Void {
        try {
            // SAFE ARRAY ACCESS with bounds checking
            if (historyArray == null || historyArray.size() < HISTORY_SIZE) {
                System.println("SensorManager: Invalid history array");
                return;
            }
            
            // Simple circular buffer implementation - SAFE SHIFTING
            for (var i = 0; i < HISTORY_SIZE - 1; i++) {
                if (i + 1 < historyArray.size() && i < historyArray.size()) {
                    historyArray[i] = historyArray[i + 1];
                }
            }
            
            // Add new data at end - SAFE ACCESS
            if (HISTORY_SIZE - 1 < historyArray.size()) {
                historyArray[HISTORY_SIZE - 1] = data;
            }
            
        } catch (exception) {
            System.println("SensorManager: History update error: " + exception.getErrorMessage());
        }
    }

    // Get current sensor data snapshot - SAFE DICTIONARY CREATION
    function getCurrentSensorData() as Lang.Dictionary {
        return {
            "accel" => currentAccelData,
            "barometer" => currentBarometerData,
            "gps" => currentGpsData,
            "heartRate" => currentHeartRateData,
            "sessionDistance" => sessionTotalDistance,  
            "timestamp" => System.getTimer()
        } as Lang.Dictionary;
    }

    // Get sensor history data - SAFE DICTIONARY CREATION
    function getSensorHistory() as Lang.Dictionary {
        return {
            "accel" => accelHistory,
            "altitude" => altitudeHistory,
            "gps" => gpsHistory
        } as Lang.Dictionary;
    }

    // Set data update callback
    function setDataUpdateCallback(callback as Lang.Method or Null) as Void {
        dataUpdateCallback = callback;
    }

    // Get sensor availability status - SAFE DICTIONARY CREATION
    function getSensorStatus() as Lang.Dictionary {
        return {
            "accelerometer" => hasAccelerometer,
            "barometer" => hasBarometer,
            "gps" => hasGps,
            "heartRate" => hasHeartRate
        } as Lang.Dictionary;
    }

    // Get session statistics - SAFE DICTIONARY ACCESS & CREATION
    function getSessionStats() as Lang.Dictionary {
        var sessionTime = sessionStartTime != null ? (System.getTimer() - sessionStartTime) : 0;
        
        // SAFE DICTIONARY ACCESS
        var currentSpeed = 0.0;
        var currentHR = 0;
        var gpsAccuracy = Position.QUALITY_NOT_AVAILABLE;
        
        if (currentGpsData != null && currentGpsData has :speed) {
            currentSpeed = currentGpsData.get("speed") as Lang.Float;
        }
        
        if (currentHeartRateData != null && currentHeartRateData has :heartRate) {
            currentHR = currentHeartRateData.get("heartRate") as Lang.Number;
        }
        
        if (currentGpsData != null && currentGpsData has :accuracy) {
            gpsAccuracy = currentGpsData.get("accuracy");
        }
        
        return {
            "sessionDistance" => sessionDistance,
            "sessionTime" => sessionTime,
            "averageSpeed" => sessionTime > 0 ? (sessionDistance / (sessionTime / 1000.0)) : 0.0,
            "maxSpeed" => currentSpeed,
            "currentHeartRate" => currentHR,
            "gpsAccuracy" => gpsAccuracy
        } as Lang.Dictionary;
    }

    // Reset session data
    function resetSession() as Void {
        sessionDistance = 0.0;
        sessionStartTime = System.getTimer();
        lastGpsPosition = null;
        
        // SAFE DICTIONARY UPDATE
        if (currentGpsData != null) {
            currentGpsData.put("sessionDistance", 0.0);
        }
        
        System.println("SensorManager: Session data reset");
    }

    // Get formatted session distance
    function getFormattedDistance() as Lang.String {
        if (sessionDistance < 1000) {
            return sessionDistance.format("%.0f") + "m";
        } else {
            return (sessionDistance / 1000.0).format("%.2f") + "km";
        }
    }

    // Get formatted current speed - SAFE DICTIONARY ACCESS
    function getFormattedSpeed() as Lang.String {
        var speed = 0.0;
        if (currentGpsData != null && currentGpsData has :speed) {
            speed = currentGpsData.get("speed") as Lang.Float;
        }
        
        var speedKmh = speed * 3.6;
        return speedKmh.format("%.1f") + " km/h";
    }

    // Check if GPS has good accuracy - SAFE DICTIONARY ACCESS
    function hasGoodGpsSignal() as Lang.Boolean {
        if (currentGpsData != null && currentGpsData has :accuracy) {
            var accuracy = currentGpsData.get("accuracy");
            // POPRAWKA: Use numeric comparison instead of enum comparison
            if (accuracy != null) {
                // Position.QUALITY_GOOD = 3, so check if <= 3
                try {
                    var accuracyValue = accuracy as Lang.Number;
                    return accuracyValue <= Position.QUALITY_GOOD;
                } catch (exception) {
                    // If cast fails, assume poor accuracy
                    return false;
                }
            }
        }
        return false;
    }

    // Alternative GPS position callback - SAFE VERSION
    function onPositionData(info as Position.Info) as Void {
        System.println("SensorManager: Processing GPS data");
        
        if (info != null && info.position != null) {
            var timestamp = System.getTimer();
            var degrees = info.position.toDegrees();
            
            // SAFE ARRAY ACCESS
            var latitude = degrees[0] as Lang.Double;
            var longitude = degrees[1] as Lang.Double;
            var altitude = (info.altitude != null) ? info.altitude as Lang.Float : 0.0;
            var speed = (info.speed != null) ? info.speed as Lang.Float : 0.0;
            
            // SAFE DICTIONARY UPDATE
            if (currentGpsData != null) {
                currentGpsData.put("latitude", latitude);
                currentGpsData.put("longitude", longitude);
                currentGpsData.put("altitude", altitude);
                currentGpsData.put("speed", speed);
                currentGpsData.put("accuracy", info.accuracy);
                currentGpsData.put("timestamp", timestamp);
            }
            
            // Calculate session distance using Haversine
            if (sessionStartPosition != null && sessionStartPosition has :lat && sessionStartPosition has :lon &&
                latitude != 0 && longitude != 0) {
                
                var currentPos = {"lat" => latitude, "lon" => longitude} as Lang.Dictionary;
                var distance = calculateHaversineDistance(sessionStartPosition, currentPos);
                
                if (distance > 0 && distance < 1000) { // Ignore GPS glitches > 1km
                    sessionTotalDistance += distance;
                }
                sessionStartPosition = currentPos; // Update for next calculation
                
            } else if (latitude != 0 && longitude != 0) {
                // First valid GPS position
                sessionStartPosition = {"lat" => latitude, "lon" => longitude} as Lang.Dictionary;
            }
            
            // Add to history buffer
            var historyEntry = {
                "lat" => latitude,
                "lon" => longitude,
                "alt" => altitude,
                "t" => timestamp
            } as Lang.Dictionary;
            
            addToHistory(gpsHistory, historyEntry);
        }
    }

    // Haversine distance calculation - SAFE VERSION
    function calculateHaversineDistance(pos1 as Lang.Dictionary, pos2 as Lang.Dictionary) as Lang.Float {
        try {
            // SAFE DICTIONARY ACCESS with checks
            if (pos1 == null || pos2 == null || 
                !(pos1 has :lat) || !(pos1 has :lon) ||
                !(pos2 has :lat) || !(pos2 has :lon)) {
                return 0.0;
            }
            
            var lat1 = (pos1.get("lat") as Lang.Double) * Math.PI / 180.0;
            var lon1 = (pos1.get("lon") as Lang.Double) * Math.PI / 180.0;
            var lat2 = (pos2.get("lat") as Lang.Double) * Math.PI / 180.0;
            var lon2 = (pos2.get("lon") as Lang.Double) * Math.PI / 180.0;
            
            var earthRadius = 6371000.0; // meters
            
            var dLat = lat2 - lat1;
            var dLon = lon2 - lon1;
            
            var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                    Math.cos(lat1) * Math.cos(lat2) *
                    Math.sin(dLon/2) * Math.sin(dLon/2);
            
            var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
            
            return (earthRadius * c) as Lang.Float;
            
        } catch (exception) {
            System.println("SensorManager: Haversine calculation error: " + exception.getErrorMessage());
            return 0.0;
        }
    }

    // Reset session distance
    function resetSessionDistance() as Void {
        sessionTotalDistance = 0.0;
        sessionStartPosition = null;
        System.println("SensorManager: Session distance reset");
    }
}