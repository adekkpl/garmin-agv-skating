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

    // State change callback
    var stateChangeCallback;
    var sessionStats;
    
    // Update timer
    var updateTimer;
    const UPDATE_INTERVAL = 1000; // 1000ms = 1Hz (zamiast 100ms = 10Hz)
    
    function initialize() {
        currentAccelData = {"x" => 0.0, "y" => 0.0, "z" => 9.8};
        currentGyroData = {"x" => 0.0, "y" => 0.0, "z" => 0.0};
        currentBarometricData = {"pressure" => 101325.0, "altitude" => 0.0};
        
        heartRateHistory = new Lang.Array<Lang.Number>[10];
        for (var i = 0; i < 10; i++) {
            heartRateHistory[i] = 0;
        }
        
        /* trickDetector = new TrickDetector();
        if (trickDetector != null) {
            trickDetector.startDetection();
            System.println("SensorManager: TrickDetector initialized");
        } */
        try {
            trickDetector = new TrickDetector();
            if (trickDetector != null) {
                trickDetector.startDetection();
                System.println("SensorManager: TrickDetector initialized and started");
            }
        } catch (trickException) {
            System.println("SensorManager: Failed to initialize TrickDetector: " + trickException.getErrorMessage());
            trickDetector = null;
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
            gyroEnabled = true;

            // Create array of sensors to enable
            var sensorsToEnable = [];
            
            // Enable heart rate sensor - UPROSZCZONA WERSJA BEZ TYPE CASTING
            try {
                Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);

                // Dodaj akcelerometr jeśli dostępny
                var sensorInfo = Sensor.getInfo();
                if (sensorInfo has :accel) {
                    accelEnabled = true;
                    // Note: Accelerometer is typically always enabled on Garmin devices
                    // No need to explicitly add it to setEnabledSensors for basic accel data
                }

                // Enable the sensors we want
                Sensor.setEnabledSensors(sensorsToEnable);
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

            // TYMCZASOWE DEBUG - usuń po sprawdzeniu
            if (System.getTimer() % 10000 < 100) { // Co 10 sekund
                System.println("=== DEBUG: Available Sensor.Info fields ===");
                if (info has :accel) { System.println("- accel: YES"); }
                if (info has :gyro) { System.println("- gyro: YES"); }
                if (info has :gyroscope) { System.println("- gyroscope: YES"); }
                if (info has :magnetometer) { System.println("- magnetometer: YES"); }
                if (info has :mag) { System.println("- mag: YES"); }
                if (info has :heartRate) { System.println("- heartRate: YES"); }
                if (info has :pressure) { System.println("- pressure: YES"); }
                if (info has :altitude) { System.println("- altitude: YES"); }
                System.println("=== END DEBUG ===");
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

                // Wykryj skok (proste - gdy Z > 12m/s²)
                var totalAccel = Math.sqrt(accelArray[0]*accelArray[0] + 
                                        accelArray[1]*accelArray[1] + 
                                        accelArray[2]*accelArray[2]);
                
                // Skok wykryty!
                if (totalAccel > 12.0) { 
                    System.println("SensorManager: JUMP detected! Accel = " + totalAccel.format("%.1f"));
                    notifyJumpDetected(totalAccel);
                }

                // ZMNIEJSZ LOGOWANIE - tylko co 10 czytanie
                if (System.getTimer() % 5000 < 100) { // Co 10 sekund
                    System.println("SensorManager: Accel = " + accelArray[0].format("%.1f") + 
                                ", " + accelArray[1].format("%.1f") + 
                                ", " + accelArray[2].format("%.1f"));
                }
                
                System.println("SensorManager: Accel = " + accelArray[0] + ", " + accelArray[1] + ", " + accelArray[2]);
            }

            // Update gyroscope data
            var gyroArray = null;
            if (info has :gyro && info.gyro != null) {
                gyroArray = info.gyro as Lang.Array<Lang.Number>;
            } else if (info has :gyroscope && info.gyroscope != null) {
                gyroArray = info.gyroscope as Lang.Array<Lang.Number>;
            }
            
            if (gyroArray != null && gyroArray.size() >= 3) {
                currentGyroData.put("x", gyroArray[0].toFloat());
                currentGyroData.put("y", gyroArray[1].toFloat());
                currentGyroData.put("z", gyroArray[2].toFloat());
                
                if (System.getTimer() % 5000 < 100) {
                    var x = gyroArray[0] as Lang.Number;
                    var y = gyroArray[1] as Lang.Number;
                    var z = gyroArray[2] as Lang.Number;
                    System.println("SensorManager: Gyro = " + x.format("%.1f") + 
                                ", " + y.format("%.1f") + 
                                ", " + z.format("%.1f"));
                }
            }

            // Update altitude if available
            if (info.altitude != null) {
                var altitude = info.altitude;
                currentBarometricData.put("altitude", altitude);
                if (System.getTimer() % 10000 < 100) { // Co 10 sekund
                    System.println("SensorManager: Altitude = " + altitude + " m");
                }
            }

            // PRZEKAŻ dane do detektorów (TYLKO TUTAJ, nie w updateSensorData!)
            // 1. Przekaż do TrickDetector (jeśli istnieje)
            if (trickDetector != null) {
                try {
                    trickDetector.updateSensorData(currentAccelData, currentGyroData);
                } catch (trickException) {
                    System.println("SensorManager: TrickDetector error: " + trickException.getErrorMessage());
                }
            }
            
            // 2. Przekaż do RotationDetector (jeśli istnieje)
            if (rotationDetector != null) {
                try {
                    rotationDetector.updateSensorData(currentGyroData);
                } catch (rotationException) {
                    System.println("SensorManager: RotationDetector error: " + rotationException.getErrorMessage());
                }
            }            

            // Update barometer/pressure if available
            /* if (info.pressure != null) {
                var pressure = info.pressure;
                currentBarometricData.put("pressure", pressure);
                System.println("SensorManager: Pressure = " + pressure + " Pa");
            } */            

            lastUpdateTime = System.getTimer();
            
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

            /* var sensorInfo = Sensor.getInfo();
            if (sensorInfo == null) {
                return;
            } */

            lastUpdateTime = System.getTimer();
            
            // Get current sensor info
            var sensorInfo = Sensor.getInfo();
            if (sensorInfo != null) {
                onSensorEvent(sensorInfo);
            }
            
            // Przekaż dane do TrickDetector
            /* if (trickDetector != null) {
                trickDetector.updateSensorData(currentAccelData, currentGyroData);
            }
            // Przekaż dane do RotationDetector
            if (rotationDetector != null) {
                rotationDetector.updateSensorData(currentGyroData);
            } */
            
            // Opcjonalnie: dodaj logowanie co jakiś czas
            if (System.getTimer() % 10000 < 100) {
                System.println("SensorManager: Sensor data updated - HR: " + currentHeartRate);
            }
            
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
    function setSessionStats(stats) {
        sessionStats = stats;
        System.println("SensorManager: SessionStats reference set");
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
            "lastUpdate" => lastUpdateTime,
            "gps" => getGPSDataFromTracker(),
            "sessionDistance" => getSessionDistanceFromGPS()
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

    function getGPSDataFromTracker() {
        if (gpsTracker != null) {
            return gpsTracker.getGPSData();
        }
        return null;
    }

    function getSessionDistanceFromGPS() {
        if (gpsTracker != null) {
            return gpsTracker.getSessionDistance();
        }
        return 0.0;
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

    function notifyStateChange() {

        // Wywołaj callback jeśli istnieje
        if (stateChangeCallback != null) {
            stateChangeCallback.invoke(getStateString());
        }
        
        
        try {
            // Wymuszaj odświeżenie ekranu przy zmianie stanu sesji
            WatchUi.requestUpdate();
            System.println("SessionManager: Display update requested for state change");
        } catch (exception) {
            System.println("SessionManager: Error requesting display update: " + exception.getErrorMessage());
        }
    }  

    /* function calculateCalories() {
        if (currentHeartRate > 0 && avgHeartRate > 0) {
            // Prosta formuła: (avgHR - 60) * 0.1 kalorii na minutę
            var sessionTimeMinutes = (System.getTimer() - (sessionStats != null ? sessionStats.sessionStartTime : 0)) / 60000.0;
            var caloriesPerMinute = (avgHeartRate - 60) * 0.1;
            return max(0, sessionTimeMinutes * caloriesPerMinute);
        }
        return 0;
    } */
    function calculateCalories() {
        if (currentHeartRate > 0 && avgHeartRate > 0) {
            // Pobierz czas rozpoczęcia sesji z SessionStats
            var sessionStartTime = 0;
            if (sessionStats != null) {
                sessionStartTime = sessionStats.getSessionStartTime();
            }
            
            // Prosta formuła: (avgHR - 60) * 0.1 kalorii na minutę
            var sessionTimeMinutes = (System.getTimer() - sessionStartTime) / 60000.0;
            var caloriesPerMinute = (avgHeartRate - 60) * 0.1;
            
            // Simple max function since Math.max might not be available
            var calories = sessionTimeMinutes * caloriesPerMinute;
            return calories > 0 ? calories : 0;
        }
        return 0;
    }

    // Returns a string representing the current sensor state
    function getStateString() {
        return "Sensors initialized: " + sensorsInitialized +
               ", HR: " + currentHeartRate +
               ", Max HR: " + maxHeartRate +
               ", Avg HR: " + avgHeartRate;
    }

    function notifyJumpDetected(accelMagnitude) {
        try {
            // Zwiększ licznik skoków
            /* if (sessionStats != null && sessionStats has :addJump) {
                sessionStats.addJump();
            } */
            if (sessionStats != null) {
                sessionStats.addJump();
            }
            
            // Powiadom aplikację
            var app = Application.getApp();
            if (app != null && app has :onJumpDetected) {
                app.onJumpDetected("jump", {"acceleration" => accelMagnitude});
            }
            
        } catch (exception) {
            System.println("SensorManager: Error notifying jump: " + exception.getErrorMessage());
        }
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