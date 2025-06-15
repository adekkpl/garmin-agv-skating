// SensorManager.mc
// Garmin Aggressive Inline Skating Tracker v2.0.0
// Sensor Management Class

using Toybox.Lang;
using Toybox.System;
using Toybox.Math;
using Toybox.Sensor;
using Toybox.Position;
using Toybox.Timer;


class SensorManager {
    
    // Sensor data storage
    var currentAccelData;
    var currentBarometerData;
    var currentGpsData;
    var currentHeartRateData;
    
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
        
        // Setup update timer
        updateTimer = new Timer.Timer();
    }

    // Initialize data storage structures
    function initializeDataStorage() {
        System.println("SensorManager: Initializing data storage");
        
        // Use standard dictionary syntax
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
        
        System.println("SensorManager: Data storage initialized");
    }

    // Check which sensors are available on this device
    function checkSensorAvailability() {
        System.println("SensorManager: Checking sensor availability");
        
        try {
            var sensorInfo = Sensor.getInfo();
            
            hasAccelerometer = (sensorInfo has :accel) && (sensorInfo.accel != null);
            hasBarometer = (sensorInfo has :pressure) && (sensorInfo.pressure != null);
            hasHeartRate = (sensorInfo has :heartRate) && (sensorInfo.heartRate != null);
            
            // Check GPS differently
            try {
                var posInfo = Position.getInfo();
                hasGps = (posInfo != null);
            } catch (ex) {
                hasGps = false;
            }
            
        } catch (exception) {
            System.println("SensorManager: Error checking sensors: " + exception.getErrorMessage());
            hasAccelerometer = false;
            hasBarometer = false;
            hasHeartRate = false;
            hasGps = false;
        }
        
        System.println("SensorManager: Sensor availability - Accel: " + hasAccelerometer + 
                      ", Baro: " + hasBarometer + ", GPS: " + hasGps + ", HR: " + hasHeartRate);
    }

    function startSensors() {
        System.println("SensorManager: Starting sensors (official API)");
        
        try {
            // KROK 1: Najpierw basic sensors (stary API)
            if (hasHeartRate) {
                System.println("SensorManager: Enabling basic HR sensor");
                Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
                Sensor.enableSensorEvents(method(:onSensor));
                System.println("SensorManager: Basic HR enabled");
            }
            
            // KROK 2: High-frequency sensors (nowy API) - AKCELEROMETR
            System.println("SensorManager: Trying high-frequency accelerometer");
            var maxSampleRate = Sensor.getMaxSampleRate();
            System.println("SensorManager: Max sample rate = " + maxSampleRate);
            
            var options = {
                :period => 3,  // 3 sekundy 
                :accelerometer => {
                    :enabled => true,
                    :sampleRate => maxSampleRate > 25 ? 25 : maxSampleRate
                }
            };
            
            Sensor.registerSensorDataListener(method(:accelHistoryCallback), options);
            System.println("SensorManager: High-frequency accelerometer registered");
            
            updateTimer.start(method(:updateDataProcessing), 1000, true);
            
        } catch (exception) {
            System.println("SensorManager: Official API error: " + exception.getErrorMessage());
        }
    }

    // Callback dla basic sensorów (HR)
    function onSensor(sensorInfo as Sensor.Info) as Void {
        System.println("onSensor: Called");
        
        if (sensorInfo != null && sensorInfo.heartRate != null) {
            System.println("onSensor: HR = " + sensorInfo.heartRate + " bpm");
            currentHeartRateData["heartRate"] = sensorInfo.heartRate;
            currentHeartRateData["timestamp"] = System.getTimer();
        }
    }

    // Callback dla high-frequency data (Accelerometer) - POPRAWIONY TYP
    function accelHistoryCallback(sensorData as Sensor.SensorData) as Void {
        System.println("accelHistoryCallback: Called");
        
        if (sensorData != null && sensorData.accelerometerData != null) {
            var accelData = sensorData.accelerometerData;
            System.println("accelHistoryCallback: Got accelerometer data");
            System.println("accelHistoryCallback: X samples: " + accelData.x.size());
            
            // Zapisz najnowsze wartości
            if (accelData.x.size() > 0) {
                var lastIndex = accelData.x.size() - 1;
                currentAccelData["x"] = accelData.x[lastIndex];
                currentAccelData["y"] = accelData.y[lastIndex];
                currentAccelData["z"] = accelData.z[lastIndex];
                currentAccelData["timestamp"] = System.getTimer();
                
                System.println("accelHistoryCallback: Latest values - X:" + currentAccelData["x"] + 
                            " Y:" + currentAccelData["y"] + " Z:" + currentAccelData["z"]);
            }
        }
    }

    // Dodaj tę nową funkcję:
    function handleSensorData(sensorData) {
        System.println("handleSensorData: Called with data");
        
        try {
            if (sensorData != null) {
                System.println("handleSensorData: Data is not null");
                
                // Sprawdź jakie pola ma sensorData
                if (sensorData has :heartRate) {
                    System.println("handleSensorData: Has heartRate field");
                    if (sensorData.heartRate != null) {
                        System.println("handleSensorData: HR = " + sensorData.heartRate + " bpm");
                        currentHeartRateData["heartRate"] = sensorData.heartRate;
                        currentHeartRateData["timestamp"] = System.getTimer();
                    }
                } else {
                    System.println("handleSensorData: No heartRate field");
                }
            } else {
                System.println("handleSensorData: Data is null");
            }
        } catch (exception) {
            System.println("handleSensorData: Error: " + exception.getErrorMessage());
        }
    }


    // Stop all sensors
    function stopSensors() as Void {
        System.println("SensorManager: Stopping sensors");
        
        try {
            // Unregister sensor listeners
            Sensor.unregisterSensorDataListener();
            
            // Stop update timer
            if (updateTimer != null) {
                updateTimer.stop();
            }
            
        } catch (exception) {
            System.println("SensorManager: Error stopping sensors: " + exception.getErrorMessage());
        }
    }

    // SINGLE sensor data callback for ALL sensors
    function onSensorData(sensorData) {
        System.println("SensorManager: Sensor data received");
        
        try {
            // Handle accelerometer data
            if (sensorData has :accelerometerData && sensorData.accelerometerData != null) {
                onAccelerometerData(sensorData);
            }
            
            // Handle barometer data
            if (sensorData has :pressure && sensorData.pressure != null) {
                onBarometerData(sensorData);
            }
            
            // Handle heart rate data
            if (sensorData has :heartRate && sensorData.heartRate != null) {
                onHeartRateData(sensorData);
            }
            
        } catch (exception) {
            System.println("SensorManager: Error in sensor callback: " + exception.getErrorMessage());
        }
    }

    // Accelerometer data processing
    function onAccelerometerData(sensorData) {
        System.println("SensorManager: Processing accelerometer data");
        
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

    // Barometer data processing
    function onBarometerData(sensorData) {
        System.println("SensorManager: Processing barometer data");
        
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
        System.println("SensorManager: Processing GPS data");
        
        if (info != null && info.position != null) {
            var timestamp = System.getTimer();
            var degrees = info.position.toDegrees();
            
            currentGpsData["latitude"] = degrees[0];
            currentGpsData["longitude"] = degrees[1];
            currentGpsData["altitude"] = (info.altitude != null) ? info.altitude : 0.0;
            currentGpsData["speed"] = (info.speed != null) ? info.speed : 0.0;
            currentGpsData["accuracy"] = info.accuracy;
            currentGpsData["timestamp"] = timestamp;
            
            // Add to history buffer
            addToHistory(gpsHistory, {
                "lat" => degrees[0],
                "lon" => degrees[1],
                "alt" => currentGpsData["altitude"],
                "t" => timestamp
            });
        }
    }

    // Prosty Heart Rate callback
    function onHeartRateData(sensorData) {
        System.println("SensorManager: HR callback triggered");
        
        try {
            if (sensorData has :heartRate && sensorData.heartRate != null) {
                var hr = sensorData.heartRate;
                System.println("SensorManager: HR = " + hr + " bpm");
                
                currentHeartRateData["heartRate"] = hr;
                currentHeartRateData["timestamp"] = System.getTimer();
            } else {
                System.println("SensorManager: HR data is null");
            }
        } catch (exception) {
            System.println("SensorManager: HR callback error: " + exception.getErrorMessage());
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

/* 
class HeartRateCallback {
    var sensorManager;
    
    function initialize(manager) {
        sensorManager = manager;
    }
    
    function onSensorData(sensorData) {
        System.println("HeartRateCallback: Data received");
        
        if (sensorManager != null) {
            sensorManager.onHeartRateData(sensorData);
        }
    }
}

class BasicSensorListener {
    function onSensorData(sensorData) {
        System.println("BasicSensorListener: Got data");
        if (sensorData has :heartRate && sensorData.heartRate != null) {
            System.println("BasicSensorListener: HR = " + sensorData.heartRate);
        }
    }
}
 */