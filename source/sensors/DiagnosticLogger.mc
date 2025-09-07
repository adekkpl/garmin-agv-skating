// FILE: C:\Users\krawc\source\repos\adekkpl\garmin-agv-skating\source\sensors\DiagnosticLogger.mc | DiagnosticLogger.mc | ITERATION: 1 | CHANGES: Initial comprehensive diagnostic logging system
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Comprehensive Diagnostic Logging System for Detection Analysis
using Toybox.Lang;
using Toybox.System;

class DiagnosticLogger {
    
    // Logging configuration
    var debugMode = true;           // Enable detailed debug logging
    var logToFile = false;          // Future: CSV file logging capability  
    var logLevel = LOG_ALL;         // Control verbosity level
    
    // Log levels
    const LOG_NONE = 0;
    const LOG_ERROR = 1;
    const LOG_WARNING = 2;
    const LOG_INFO = 3;
    const LOG_DEBUG = 4;
    const LOG_ALL = 5;
    
    // Data collection buffers
    var sensorDataHistory;          // Rolling buffer of sensor readings
    var detectionEvents;            // Log of detection attempts and results
    var performanceMetrics;         // Timing and accuracy measurements
    
    const HISTORY_BUFFER_SIZE = 100; // Keep last 100 sensor readings
    const EVENT_BUFFER_SIZE = 50;    // Keep last 50 detection events
    
    // Performance tracking
    var totalDetections = 0;
    var truePositives = 0;
    var falsePositives = 0;
    var detectionStartTime;
    
    function initialize() {
        // Initialize data collection buffers
        sensorDataHistory = new Lang.Array<Lang.Dictionary>[HISTORY_BUFFER_SIZE];
        detectionEvents = new Lang.Array<Lang.Dictionary>[EVENT_BUFFER_SIZE];
        performanceMetrics = {
            "averageLatency" => 0.0,
            "detectionAccuracy" => 0.0,
            "sensorSampleRate" => 0.0
        };
        
        // Initialize buffers with empty dictionaries
        for (var i = 0; i < HISTORY_BUFFER_SIZE; i++) {
            sensorDataHistory[i] = {};
        }
        for (var i = 0; i < EVENT_BUFFER_SIZE; i++) {
            detectionEvents[i] = {};
        }
        
        logInfo("DiagnosticLogger: Initialized - Debug mode: " + debugMode);
    }
    
    // Core logging methods with level filtering
    function logError(message) {
        if (logLevel >= LOG_ERROR) {
            System.println("[ERROR] " + getCurrentTimeString() + " " + message);
        }
    }
    
    function logWarning(message) {
        if (logLevel >= LOG_WARNING) {
            System.println("[WARN]  " + getCurrentTimeString() + " " + message);
        }
    }
    
    function logInfo(message) {
        if (logLevel >= LOG_INFO) {
            System.println("[INFO]  " + getCurrentTimeString() + " " + message);
        }
    }
    
    function logDebug(message) {
        if (logLevel >= LOG_DEBUG && debugMode) {
            System.println("[DEBUG] " + getCurrentTimeString() + " " + message);
        }
    }
    
    // Sensor data logging with comprehensive details
    function logSensorData(sensorType, data, timestamp) {
        if (!debugMode) { return; }
        
        var sensorEntry = {
            "timestamp" => timestamp,
            "type" => sensorType,
            "data" => data,
            "systemTime" => System.getTimer()
        };
        
        // Add to rolling buffer (circular buffer implementation)
        var index = (timestamp / 100) % HISTORY_BUFFER_SIZE; // Simple indexing
        sensorDataHistory[index] = sensorEntry;
        
        // Detailed sensor-specific logging
        switch (sensorType) {
            case "accelerometer":
                logAccelerometerDetails(data, timestamp);
                break;
            case "gyroscope":  
                logGyroscopeDetails(data, timestamp);
                break;
            case "barometer":
                logBarometerDetails(data, timestamp);
                break;
        }
    }
    
    // Detailed accelerometer analysis
    function logAccelerometerDetails(accelData, timestamp) {
        if (accelData == null) { return; }
        
        var x = accelData.get("x");
        var y = accelData.get("y"); 
        var z = accelData.get("z");
        
        if (x != null && y != null && z != null) {
            // Calculate vector magnitude for jump detection analysis
            var magnitude = Math.sqrt(x*x + y*y + z*z);
            var verticalComponent = abs(z - 9.8); // Deviation from gravity
            
            logDebug("ACCEL: X=" + x.format("%.3f") + 
                    " Y=" + y.format("%.3f") + 
                    " Z=" + z.format("%.3f") + 
                    " |V|=" + magnitude.format("%.3f") + 
                    " ΔZ=" + verticalComponent.format("%.3f"));
            
            // Flag significant acceleration events
            if (magnitude > 12.0 || verticalComponent > 3.0) {
                logWarning("ACCEL SPIKE: Magnitude=" + magnitude.format("%.2f") + 
                          "g, Vertical deviation=" + verticalComponent.format("%.2f") + "g");
            }
        }
    }
    
    // Detailed gyroscope analysis  
    function logGyroscopeDetails(gyroData, timestamp) {
        if (gyroData == null) { return; }
        
        var x = gyroData.get("x");
        var y = gyroData.get("y");
        var z = gyroData.get("z");
        
        if (x != null && y != null && z != null) {
            // Calculate total angular velocity
            var totalAngular = Math.sqrt(x*x + y*y + z*z);
            
            logDebug("GYRO: X=" + x.format("%.1f") + 
                    " Y=" + y.format("%.1f") + 
                    " Z=" + z.format("%.1f") + 
                    " |ω|=" + totalAngular.format("%.1f") + "°/s");
            
            // Flag significant rotation events
            if (totalAngular > 90.0) {
                logWarning("ROTATION DETECTED: Total angular velocity=" + 
                          totalAngular.format("%.1f") + "°/s");
            }
        }
    }
    
    // Detailed barometer analysis
    function logBarometerDetails(baroData, timestamp) {
        if (baroData == null) { return; }
        
        var pressure = baroData.get("pressure");
        var altitude = baroData.get("altitude");
        
        if (pressure != null && altitude != null) {
            logDebug("BARO: Pressure=" + pressure.format("%.1f") + 
                    "Pa, Altitude=" + altitude.format("%.3f") + "m");
        }
    }
    
    // Detection event logging with comprehensive analysis
    function logDetectionEvent(eventType, detected, confidence, sensorData, thresholds) {
        totalDetections++;
        
        var event = {
            "timestamp" => System.getTimer(),
            "type" => eventType,
            "detected" => detected,
            "confidence" => confidence,
            "sensorData" => sensorData,
            "thresholds" => thresholds,
            "eventId" => totalDetections
        };
        
        // Add to event buffer
        var index = totalDetections % EVENT_BUFFER_SIZE;
        detectionEvents[index] = event;
        
        // Comprehensive event logging
        var statusString = detected ? "DETECTED" : "NO DETECTION";
        var confidenceString = confidence != null ? confidence.format("%.2f") : "N/A";
        
        logInfo("DETECTION EVENT #" + totalDetections + ": " + eventType.toUpper() + 
               " - " + statusString + " (Confidence: " + confidenceString + ")");
        
        // Log threshold comparisons for analysis
        if (thresholds != null && sensorData != null) {
            logDetectionThresholdAnalysis(eventType, sensorData, thresholds);
        }
    }
    
    // Detailed threshold analysis for detection tuning
    function logDetectionThresholdAnalysis(eventType, sensorData, thresholds) {
        logDebug("THRESHOLD ANALYSIS for " + eventType + ":");
        
        var keys = thresholds.keys();
        for (var i = 0; i < keys.size(); i++) {
            var key = keys[i];
            var threshold = thresholds.get(key);
            var sensorValue = sensorData.get(key);
            
            if (sensorValue != null && threshold != null) {
                var comparison = sensorValue > threshold ? "EXCEEDS" : "BELOW";
                var ratio = (sensorValue / threshold).format("%.2f");
                
                logDebug("  " + key + ": " + sensorValue.format("%.3f") + 
                        " vs " + threshold.format("%.3f") + 
                        " (" + comparison + ", ratio=" + ratio + ")");
            }
        }
    }
    
    // Performance metrics calculation and reporting
    function updatePerformanceMetrics(detectionLatency, wasAccurate) {
        // Update accuracy tracking
        if (wasAccurate) {
            truePositives++;
        } else {
            falsePositives++;  
        }
        
        // Calculate detection accuracy percentage
        var accuracy = totalDetections > 0 ? 
            (truePositives * 100.0 / totalDetections) : 0.0;
        performanceMetrics.put("detectionAccuracy", accuracy);
        
        // Update average latency
        var currentAvg = performanceMetrics.get("averageLatency");
        var newAvg = (currentAvg * (totalDetections - 1) + detectionLatency) / totalDetections;
        performanceMetrics.put("averageLatency", newAvg);
        
        logInfo("PERFORMANCE: Accuracy=" + accuracy.format("%.1f") + 
               "%, Avg Latency=" + newAvg.format("%.0f") + "ms");
    }
    
    // Generate comprehensive diagnostic report
    function generateDiagnosticReport() {
        logInfo("=== DIAGNOSTIC REPORT ===");
        logInfo("Total Detections: " + totalDetections);
        logInfo("True Positives: " + truePositives);
        logInfo("False Positives: " + falsePositives);
        logInfo("Detection Accuracy: " + 
               performanceMetrics.get("detectionAccuracy").format("%.1f") + "%");
        logInfo("Average Latency: " + 
               performanceMetrics.get("averageLatency").format("%.0f") + "ms");
        
        // Recent sensor data summary
        logInfo("--- RECENT SENSOR PATTERNS ---");
        analyzeRecentSensorPatterns();
        
        logInfo("=== END DIAGNOSTIC REPORT ===");
    }
    
    // Pattern analysis of recent sensor data
    function analyzeRecentSensorPatterns() {
        var accelSpikes = 0;
        var rotationEvents = 0;
        var altitudeChanges = 0;
        
        for (var i = 0; i < HISTORY_BUFFER_SIZE; i++) {
            var entry = sensorDataHistory[i];
            if (entry.isEmpty()) { continue; }
            
            var type = entry.get("type");
            var data = entry.get("data");
            
            if (type.equals("accelerometer") && data != null) {
                var magnitude = calculateAccelMagnitude(data);
                if (magnitude > 12.0) { accelSpikes++; }
            } else if (type.equals("gyroscope") && data != null) {
                var angularVel = calculateTotalAngularVelocity(data);
                if (angularVel > 90.0) { rotationEvents++; }
            }
        }
        
        logInfo("Pattern Analysis: " + accelSpikes + " accel spikes, " + 
               rotationEvents + " rotation events in recent data");
    }
    
    // Helper functions for analysis
    function calculateAccelMagnitude(accelData) {
        var x = accelData.get("x");
        var y = accelData.get("y");
        var z = accelData.get("z");
        
        if (x != null && y != null && z != null) {
            return Math.sqrt(x*x + y*y + z*z);
        }
        return 0.0;
    }
    
    function calculateTotalAngularVelocity(gyroData) {
        var x = gyroData.get("x");
        var y = gyroData.get("y"); 
        var z = gyroData.get("z");
        
        if (x != null && y != null && z != null) {
            return Math.sqrt(x*x + y*y + z*z);
        }
        return 0.0;
    }
    
    // Utility functions
    function getCurrentTimeString() {
        var clockTime = System.getClockTime();
        return clockTime.hour.format("%02d") + ":" + 
               clockTime.min.format("%02d") + ":" + 
               clockTime.sec.format("%02d");
    }
    
    function setLogLevel(level) {
        logLevel = level;
        logInfo("DiagnosticLogger: Log level set to " + level);
    }
    
    function setDebugMode(enabled) {
        debugMode = enabled;
        logInfo("DiagnosticLogger: Debug mode " + (enabled ? "enabled" : "disabled"));
    }
    
    // Get diagnostic data for external analysis
    function getDiagnosticData() {
        return {
            "sensorHistory" => sensorDataHistory,
            "detectionEvents" => detectionEvents,
            "performanceMetrics" => performanceMetrics,
            "totalDetections" => totalDetections,
            "accuracy" => truePositives * 100.0 / (totalDetections > 0 ? totalDetections : 1)
        };
    }
    
    // Cleanup
    function cleanup() {
        generateDiagnosticReport();
        logInfo("DiagnosticLogger: Cleanup completed");
    }
}