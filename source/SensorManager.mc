// SensorManager.mc
// Garmin Aggressive Inline Skating Tracker v2.0.0
// Sensor Management Class

using Toybox.Lang;
using Toybox.System;
using Toybox.Math;
using Toybox.Sensor;
using Toybox.Position;

class SensorManager {
    
    // Sensor data storage
    var currentAccelData;
    var currentBarometerData;
    var currentGpsData;
    var currentHeartRateData;
    
    // Sensor listeners
    var accelListener;
    var barometerListener;
    var positionListener;
    var heartRateListener;
    
    // Data update timer
    var updateTimer;
    var dataUpdateCallback;
    
    // Sensor availability flags
    var hasAccelerometer = false;
    var hasBarometer = false;
    var hasGps = false;
    var hasHeartRate = false;
    
    // Data history for analysis (circular buffers)
    var accelHistory;
    var altitudeHistory;
    var gpsHistory;
    
    const HISTORY_SIZE = 50; // ~5 seconds at 10Hz
    
    function initialize() {
        System.println("SensorManager: Initializing sensor management");
        
        // Initialize data storage
        initializeDataStorage();
        
        // Check sensor availability
        checkSensorAvailability();
        
        // Initialize sensor listeners
        initializeSensorListeners();
        
        // Setup update timer
        updateTimer = new Timer.Timer();
    }

    // Initialize data storage structures
    function initializeDataStorage() {
        currentAccelData = {
            "x" => 0.0,
            "y" => 0.0, 
            "z" => 0.0,
            "timestamp" => 0
        };
        
        currentBarometerData = {
            "pressure" => 0.0,
            "altitude" => 0.0,
            "timestamp" => 0
        };
        
        currentGpsData = {
            "latitude" => 0.0,
            "longitude" => 0.0,
            "altitude" => 0.0,
            "speed" => 0.0,
            "accuracy" => Position.QUALITY_NOT_AVAILABLE,
            "timestamp" => 0
        };
        
        currentHeartRateData = {
            "heartRate" => 0,
            "timestamp" => 0
        };
        
        // Initialize history arrays
        accelHistory = new [HISTORY_SIZE];
        altitudeHistory = new [HISTORY_SIZE];
        gpsHistory = new [HISTORY_SIZE];
        
        for (var i = 0; i < HISTORY_SIZE; i++) {
            accelHistory[i] = {"x" => 0.0, "y" => 0.0, "z" => 0.0, "t" => 0};
            altitudeHistory[i] = {"alt" => 0.0, "t" => 0};
            gpsHistory[i] = {"lat" => 0.0, "lon" => 0.0, "alt" => 0.0, "t" => 0};
        }
    }

    // Check which sensors are available on this device
    function checkSensorAvailability(){
        var sensorInfo = Sensor.getInfo();
        
        hasAccelerometer = (sensorInfo has :accel) && (sensorInfo.accel != null);
        hasBarometer = (sensorInfo has :pressure) && (sensorInfo.pressure != null);
        hasHeartRate = (sensorInfo has :heartRate) && (sensorInfo.heartRate != null);
        hasGps = (Position has :getInfo) && (Position.getInfo().accuracy != Position.QUALITY_NOT_AVAILABLE);
        
        System.println("SensorManager: Sensor availability - Accel: " + hasAccelerometer + 
                      ", Baro: " + hasBarometer + ", GPS: " + hasGps + ", HR: " + hasHeartRate);
    }

    // Initialize sensor listeners
    function initializeSensorListeners() {
        try {
            if (hasAccelerometer) {
                accelListener = new AccelerometerListener(method(:onAccelerometerData));
            }
            
            if (hasBarometer) {
                barometerListener = new BarometerListener(method(:onBarometerData));
            }
            
            if (hasGps) {
                positionListener = new PositionListener(method(:onPositionData));
            }
            
            if (hasHeartRate) {
                heartRateListener = new HeartRateListener(method(:onHeartRateData));
            }
            
        } catch (exception) {
            System.println("SensorManager: Error initializing listeners: " + exception.getErrorMessage());
        }
    }

    // Start all available sensors
    function startSensors() {
        System.println("SensorManager: Starting sensors");
        
        try {
            if (hasAccelerometer && accelListener != null) {
                Sensor.registerSensorDataListener(accelListener, {
                    :period => 1, // 1 second intervals
                    :accelerometer => {
                        :enabled => true,
                        :sampleRate => 10 // 10 Hz
                    }
                });
            }
            
            if (hasBarometer && barometerListener != null) {
                Sensor.registerSensorDataListener(barometerListener, {
                    :period => 1,
                    :pressure => { :enabled => true }
                });
            }
            
            // TODO: Enable GPS if needed
           /*  if (hasGps && positionListener != null) {
                Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPositionData));
            } */
            
            if (hasHeartRate && heartRateListener != null) {
                Sensor.registerSensorDataListener(heartRateListener, {
                    :period => 1,
                    :heartRate => { :enabled => true }
                });
            }
            
            // Start data update timer
            updateTimer.start(method(:updateDataProcessing), 100, true); // 10Hz updates
            
        } catch (exception) {
            System.println("SensorManager: Error starting sensors: " + exception.getErrorMessage());
        }
    }

    // Stop all sensors
    function stopSensors() as Void {
        System.println("SensorManager: Stopping sensors");
        
        try {
            // Unregister all sensor listeners
            if (accelListener != null) {
                Sensor.unregisterSensorDataListener();
            }
            
            if (positionListener != null) {
                Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
            }
            
            // Stop update timer
            if (updateTimer != null) {
                updateTimer.stop();
            }
            
        } catch (exception) {
            System.println("SensorManager: Error stopping sensors: " + exception.getErrorMessage());
        }
    }

    // Accelerometer data callback
    function onAccelerometerData(sensorData) {
        if (sensorData.accelerometerData != null) {
            var accelData = sensorData.accelerometerData;
            var timestamp = System.getTimer();
            
            currentAccelData["x"] = accelData.x;
            currentAccelData["y"] = accelData.y;
            currentAccelData["z"] = accelData.z;
            currentAccelData["timestamp"] = timestamp;
            
            // Add to history buffer
            addToHistory(accelHistory, {
                "x" => accelData.x,
                "y" => accelData.y, 
                "z" => accelData.z,
                "t" => timestamp
            });
        }
    }

    // Barometer data callback
    function onBarometerData(sensorData) {
        if (sensorData.pressure != null) {
            var timestamp = System.getTimer();
            var altitude = pressureToAltitude(sensorData.pressure);
            
            currentBarometerData["pressure"] = sensorData.pressure;
            currentBarometerData["altitude"] = altitude;
            currentBarometerData["timestamp"] = timestamp;
            
            // Add to history buffer
            addToHistory(altitudeHistory, {
                "alt" => altitude,
                "t" => timestamp
            });
        }
    }

    // GPS position data callback
    function onPositionData(info) {
        if (info != null && info.position != null) {
            var timestamp = System.getTimer();
            
            currentGpsData["latitude"] = info.position.toDegrees()[0];
            currentGpsData["longitude"] = info.position.toDegrees()[1];
            currentGpsData["altitude"] = (info.altitude != null) ? info.altitude : 0.0;
            currentGpsData["speed"] = (info.speed != null) ? info.speed : 0.0;
            currentGpsData["accuracy"] = info.accuracy;
            currentGpsData["timestamp"] = timestamp;
            
            // Add to history buffer
            addToHistory(gpsHistory, {
                "lat" => currentGpsData["latitude"],
                "lon" => currentGpsData["longitude"],
                "alt" => currentGpsData["altitude"],
                "t" => timestamp
            });
        }
    }

    // Heart rate data callback
    function onHeartRateData(sensorData) {
        if (sensorData.heartRate != null) {
            currentHeartRateData["heartRate"] = sensorData.heartRate;
            currentHeartRateData["timestamp"] = System.getTimer();
        }
    }

    // Add data to circular history buffer
    function addToHistory(historyArray, data) {
        // Simple circular buffer implementation
        for (var i = 0; i < HISTORY_SIZE - 1; i++) {
            historyArray[i] = historyArray[i + 1];
        }
        historyArray[HISTORY_SIZE - 1] = data;
    }

    // Convert pressure to altitude (simple approximation)
    function pressureToAltitude(pressure) {
        // Standard barometric formula approximation
        var seaLevelPressure = 101325.0; // Pa
        var altitudeMeters = (1.0 - Math.pow(pressure / seaLevelPressure, 0.1903)) * 44307.69;
        return altitudeMeters;
    }

    // Data processing update callback
    function updateDataProcessing() as Void {
        if (dataUpdateCallback != null) {
            dataUpdateCallback.invoke(getCurrentSensorData());
        }
    }

    // Get current sensor data snapshot
    function getCurrentSensorData() {
        return {
            "accel" => currentAccelData,
            "barometer" => currentBarometerData,
            "gps" => currentGpsData,
            "heartRate" => currentHeartRateData,
            "timestamp" => System.getTimer()
        };
    }

    // Get sensor history data
    function getSensorHistory() {
        return {
            "accel" => accelHistory,
            "altitude" => altitudeHistory,
            "gps" => gpsHistory
        };
    }

    // Set data update callback
    function setDataUpdateCallback(callback) {
        dataUpdateCallback = callback;
    }

    // Get sensor availability status
    function getSensorStatus() {
        return {
            "accelerometer" => hasAccelerometer,
            "barometer" => hasBarometer,
            "gps" => hasGps,
            "heartRate" => hasHeartRate
        };
    }
}

// Helper classes for sensor listeners
class AccelerometerListener {
    var callback;
    
    function initialize(callbackMethod) {
        callback = callbackMethod;
    }
}

class BarometerListener {
    var callback;
    
    function initialize(callbackMethod) {
        callback = callbackMethod;
    }
}

class PositionListener {
    var callback;
    
    function initialize(callbackMethod) {
        callback = callbackMethod;
    }
}

class HeartRateListener {
    var callback;
    
    function initialize(callbackMethod) {
        callback = callbackMethod;
    }
}