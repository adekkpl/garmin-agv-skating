// SensorManager.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Sensor Management System
using Toybox.Lang;
using Toybox.Sensor;
using Toybox.System;
using Toybox.Timer;

class SensorManager {
    
    // Sensor data
    var currentHeartRate = 0;
    var currentAccelData;
    var currentGyroData;
    var currentBarometricData;
    var lastUpdateTime = 0;
    
    // Heart rate tracking
    //var heartRateHistory;
    // FIXED: Explicit type declaration
    var heartRateHistory as Lang.Array<Lang.Number>;    
    var maxHeartRate = 0;
    var avgHeartRate = 0;
    var hrSampleCount = 0;
    var hrSum = 0;
    
    // Component references
    var trickDetector;
    var rotationDetector;
    var gpsTracker;
    
    // Sensor callbacks
    var sensorUpdateCallback;
    
    // Sensor state
    var sensorsInitialized = false;
    var heartRateEnabled = false;
    var accelEnabled = false;
    var gyroEnabled = false;
    var barometerEnabled = false;
    
    // Update timer
    var updateTimer;
    const UPDATE_INTERVAL = 100; // 100ms = 10Hz
    
    function initialize() {
        currentAccelData = {"x" => 0.0, "y" => 0.0, "z" => 9.8};
        currentGyroData = {"x" => 0.0, "y" => 0.0, "z" => 0.0};
        currentBarometricData = {"pressure" => 101325.0, "altitude" => 0.0};
        
        heartRateHistory = new Lang.Array<Lang.Number>[10];
        for (var i = 0; i < 10; i++) {
            heartRateHistory[i] = 0;
        }
        
        System.println("SensorManager: Initialized");
    }
    
    // Initialize all available sensors
    function initializeSensors() {
        try {
            System.println("SensorManager: Initializing sensors...");
            
            // Enable actual sensors instead of disabling them
            heartRateEnabled = true;
            accelEnabled = true;
            barometerEnabled = true;
            gyroEnabled = false;
            
            // Enable heart rate sensor - UPROSZCZONA WERSJA BEZ TYPE CASTING
            try {
                Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
                Sensor.enableSensorEvents(method(:onSensorEvent));
                System.println("SensorManager: Heart rate sensor enabled");
            } catch (sensorException) {
                System.println("SensorManager: Heart rate sensor failed: " + sensorException.getErrorMessage());
                heartRateEnabled = false;
            }
            
            // Enable actual update timer
            startUpdateTimer();
            
            sensorsInitialized = true;
            System.println("SensorManager: Sensor initialization complete");
            
        } catch (exception) {
            System.println("SensorManager: Error initializing sensors: " + exception.getErrorMessage());
            sensorsInitialized = false;
        }
    }

    
    // Start periodic sensor updates
    function startUpdateTimer() {
        if (updateTimer != null) {
            updateTimer.stop();
        }
        
        try {
            // UPROSZCZONA WERSJA BEZ TYPE CASTING
            updateTimer = new Timer.Timer();
            updateTimer.start(method(:updateSensorData), UPDATE_INTERVAL, true);
            System.println("SensorManager: Update timer started");
        } catch (exception) {
            System.println("SensorManager: Failed to start update timer: " + exception.getErrorMessage());
        }
    }
    
    // Stop sensor updates
    function stopUpdateTimer() {
        if (updateTimer != null) {
            updateTimer.stop();
            updateTimer = null;
        }
        System.println("SensorManager: Update timer stopped");
    }
    
    // Sensor event callback
    function onSensorEvent(info as Sensor.Info) as Void {
        try {
            if (info == null) {
                return;
            }
            
            // Update heart rate
            if (info.heartRate != null) {
                var newHR = info.heartRate;
                if (newHR > 0) {
                    currentHeartRate = newHR;
                    updateHeartRateStats(newHR);
                    System.println("SensorManager: HR = " + newHR + " bpm");
                }
            }
            
            // Update accelerometer
            if (info.accel != null && info.accel.size() >= 3) {
                var accelArray = info.accel;
                
                currentAccelData.put("x", accelArray[0].toFloat());
                currentAccelData.put("y", accelArray[1].toFloat());
                currentAccelData.put("z", accelArray[2].toFloat());
                
                System.println("SensorManager: Accel = " + accelArray[0] + ", " + accelArray[1] + ", " + accelArray[2]);
            }
            
            // Update barometer/pressure if available
            if (info.pressure != null) {
                var pressure = info.pressure;
                currentBarometricData.put("pressure", pressure);
                System.println("SensorManager: Pressure = " + pressure + " Pa");
            }
            
            // Update altitude if available
            if (info.altitude != null) {
                var altitude = info.altitude;
                currentBarometricData.put("altitude", altitude);
                System.println("SensorManager: Altitude = " + altitude + " m");
            }
            
        } catch (exception) {
            System.println("SensorManager: Sensor callback error: " + exception.getErrorMessage());
        }
    }
    
    // Periodic sensor data update
/*     function updateSensorData() {
        try {
            var timestamp = System.getTimer();
            
            // Generate simulated data for development
            currentHeartRate = 75 + (timestamp % 50); // Simulated HR 75-125
            
            // Create sensor data package with simulated data
            var sensorData = {
                "heartRate" => currentHeartRate,
                "accelerometer" => currentAccelData,
                "gyroscope" => currentGyroData,
                "pressure" => currentBarometricData.get("pressure"),
                "altitude" => currentBarometricData.get("altitude"),
                "timestamp" => timestamp
            };
            
            // Update trick detector
            if (trickDetector != null) {
                trickDetector.updateDetection(sensorData, timestamp);
            }
            
            // Update rotation detector
            if (rotationDetector != null) {
                rotationDetector.updateRotationDetection(sensorData, timestamp);
            }
            
            // Trigger callback if set
            if (sensorUpdateCallback != null) {
                sensorUpdateCallback.invoke(sensorData);
            }
            
        } catch (exception) {
            System.println("SensorManager: Error in updateSensorData: " + exception.getErrorMessage());
        }
    } */
    function updateSensorData() as Void {
        try {
            lastUpdateTime = System.getTimer();
            
            // Get current sensor info
            var sensorInfo = Sensor.getInfo();
            if (sensorInfo != null) {
                onSensorEvent(sensorInfo);
            }
            
            // Notify trick detector if available
            if (trickDetector != null && trickDetector has :updateSensorData) {
                trickDetector.updateSensorData(currentAccelData, currentGyroData);
            }
            
            System.println("SensorManager: Sensor data updated - HR: " + currentHeartRate);
            
        } catch (exception) {
            System.println("SensorManager: Error updating sensor data: " + exception.getErrorMessage());
        }
    }


    // Update heart rate statistics
    function updateHeartRateStats(heartRate) {
        // Update max heart rate
        if (heartRate > maxHeartRate) {
            maxHeartRate = heartRate;
        }
        
        // Update average heart rate
        hrSum += heartRate;
        hrSampleCount++;
        avgHeartRate = hrSum / hrSampleCount;
        
        // FIXED: Cast heartRateHistory to proper array type
        var hrHistory = heartRateHistory as Lang.Array<Lang.Number>;
        
        // Add to history (circular buffer)
        for (var i = 8; i >= 0; i--) {
            hrHistory[i + 1] = hrHistory[i];
        }
        hrHistory[0] = heartRate;
    }

    // Convert pressure to altitude
    function pressureToAltitude(pressure) {
        var SEA_LEVEL_PRESSURE = 101325.0; // Pa
        return 44330.0 * (1.0 - Math.pow(pressure / SEA_LEVEL_PRESSURE, 0.1903));
    }
    
    // Set component references
    function setTrickDetector(detector) {
        trickDetector = detector;
        System.println("SensorManager: TrickDetector reference set");
    }
    
    function setRotationDetector(detector) {
        rotationDetector = detector;
        System.println("SensorManager: RotationDetector reference set");
    }
    
    function setGPSTracker(tracker) {
        gpsTracker = tracker;
        System.println("SensorManager: GPSTracker reference set");
    }
    
    function setSensorUpdateCallback(callback) {
        sensorUpdateCallback = callback;
    }
    
    // Public getters
    function getHeartRate() {
        return currentHeartRate;
    }
    
    function getMaxHeartRate() {
        return maxHeartRate;
    }
    
    function getAverageHeartRate() {
        return avgHeartRate;
    }
    
    function getCurrentSensorData() {
        return {
            "heartRate" => currentHeartRate,
            "maxHeartRate" => maxHeartRate,
            "averageHeartRate" => avgHeartRate,
            "accelerometer" => currentAccelData,
            "gyroscope" => currentGyroData,
            "pressure" => currentBarometricData.get("pressure"),
            "altitude" => currentBarometricData.get("altitude"),
            "lastUpdate" => lastUpdateTime
        };
    }
    
    function getAccelData() {
        return currentAccelData;
    }
    
    function getGyroData() {
        return currentGyroData;
    }
    
    function getBarometricData() {
        return currentBarometricData;
    }
    
    // Sensor status
    function areSensorsInitialized() {
        return sensorsInitialized;
    }
    
    function isHeartRateAvailable() {
        return heartRateEnabled && currentHeartRate > 0;
    }
    
    function isAccelAvailable() {
        return accelEnabled;
    }
    
    function isGyroAvailable() {
        return gyroEnabled;
    }
    
    function isBarometerAvailable() {
        return barometerEnabled;
    }
    
    function getSensorStatus() {
        return {
            "initialized" => sensorsInitialized,
            "heartRate" => heartRateEnabled,
            "accelerometer" => accelEnabled,
            "gyroscope" => gyroEnabled,
            "barometer" => barometerEnabled,
            "lastUpdate" => lastUpdateTime
        };
    }
    
    // Start all sensors
    function startSensors() {
        if (!sensorsInitialized) {
            initializeSensors();
        } else {
            startUpdateTimer();
        }
        System.println("SensorManager: Sensors started");
    }
    
    // Stop all sensors
    function stopSensors() {
        stopUpdateTimer();
        
        try {
            Sensor.setEnabledSensors([]);
        } catch (exception) {
            System.println("SensorManager: Error stopping sensors: " + exception.getErrorMessage());
        }
        
        System.println("SensorManager: Sensors stopped");
    }
    
    // Reset statistics
    function resetStats() {
        maxHeartRate = 0;
        avgHeartRate = 0;
        hrSampleCount = 0;
        hrSum = 0;
        
        for (var i = 0; i < 10; i++) {
            heartRateHistory[i] = 0;
        }
        
        System.println("SensorManager: Statistics reset");
    }
    
    // Cleanup
    function cleanup() {
        try {
            stopSensors();
            
            // Reset data
            currentHeartRate = 0;
            currentAccelData = {"x" => 0.0, "y" => 0.0, "z" => 9.8};
            currentGyroData = {"x" => 0.0, "y" => 0.0, "z" => 0.0};
            currentBarometricData = {"pressure" => 101325.0, "altitude" => 0.0};
            
            System.println("SensorManager: Cleanup completed");
        } catch (exception) {
            System.println("SensorManager: Error during cleanup: " + exception.getErrorMessage());
        }
    }
}