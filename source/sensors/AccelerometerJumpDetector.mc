// FILE: C:\Users\krawc\source\repos\adekkpl\garmin-agv-skating\source\sensors\AccelerometerJumpDetector.mc | AccelerometerJumpDetector.mc | ITERATION: 1 | CHANGES: Initial accelerometer-first jump detection algorithm
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Advanced Accelerometer-Based Jump Detection System
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;

class AccelerometerJumpDetector {
    
    // Detection states
    const STATE_BASELINE = 0;      // Establishing baseline activity
    const STATE_MONITORING = 1;    // Looking for jump patterns
    const STATE_PREJUMP = 2;       // Initial acceleration detected
    const STATE_AIRBORNE = 3;      // In flight phase
    const STATE_LANDING = 4;       // Landing impact detected
    const STATE_RECOVERY = 5;      // Post-landing stabilization
    
    var currentState;
    var stateStartTime;
    
    // Enhanced detection thresholds - based on real skating physics
    const BASELINE_WINDOW = 3000;           // 3s to establish baseline
    const TAKEOFF_ACCEL_MIN = 1.8 * G;          // Minimum 1.8g for takeoff detection (converted to m/s^2)
    const TAKEOFF_ACCEL_MAX = 6.0 * G;          // Maximum realistic takeoff acceleration (m/s^2)
    const LANDING_IMPACT_MIN = 2.0 * G;         // Minimum 2.0g for landing impact (m/s^2)
    const LANDING_IMPACT_MAX = 8.0 * G;         // Maximum safe landing impact (m/s^2)
    const AIRBORNE_MAX_DURATION = 2000;     // 2s maximum airborne time (realistic)
    const RECOVERY_DURATION = 1000;         // 1s recovery period after landing

    // Pattern analysis parameters
    const PATTERN_WINDOW_SIZE = 20;         // 200ms window @ 100Hz sampling
    const BASELINE_SAMPLES = 50;            // Samples for baseline calculation
    const NOISE_THRESHOLD = 0.3 * G;            // 0.3g noise tolerance (converted to m/s^2)
    
    // Data buffers for pattern analysis
    var accelBuffer;                        // Rolling acceleration magnitude buffer
    var accelXBuffer;                       // X-axis acceleration buffer
    var accelYBuffer;                       // Y-axis acceleration buffer  
    var accelZBuffer;                       // Z-axis acceleration buffer
    var timestampBuffer;                    // Timestamp buffer for correlation
    var bufferIndex = 0;
    
    // Baseline and calibration
    var baselineAccel = 9.8;               // Baseline acceleration magnitude
    var baselineVariance = 0.0;            // Baseline activity variance
    var isCalibrated = false;
    var calibrationSamples = 0;
    
    // Jump detection results
    var jumpDetected = false;
    var jumpStartTime = 0;
    var jumpEndTime = 0;
    var maxAcceleration = 0.0;
    var landingImpact = 0.0;
    var jumpDuration = 0;
    
    // Statistics and performance
    var totalJumpsDetected = 0;
    var falsePositiveCount = 0;
    var averageJumpHeight = 0.0;
    
    // Callbacks and logging
    var jumpDetectedCallback;
    var diagnosticLogger;
    
    function initialize() {
        // Initialize state
        currentState = STATE_BASELINE;
        stateStartTime = System.getTimer();
        
        // Initialize buffers
        accelBuffer = new Lang.Array<Lang.Float>[PATTERN_WINDOW_SIZE];
        accelXBuffer = new Lang.Array<Lang.Float>[PATTERN_WINDOW_SIZE];
        accelYBuffer = new Lang.Array<Lang.Float>[PATTERN_WINDOW_SIZE];
        accelZBuffer = new Lang.Array<Lang.Float>[PATTERN_WINDOW_SIZE];
        timestampBuffer = new Lang.Array<Lang.Long>[PATTERN_WINDOW_SIZE];
        
        // Initialize with gravity baseline
        for (var i = 0; i < PATTERN_WINDOW_SIZE; i++) {
            accelBuffer[i] = 9.8;
            accelXBuffer[i] = 0.0;
            accelYBuffer[i] = 0.0;
            accelZBuffer[i] = 9.8;
            timestampBuffer[i] = 0;
        }
        
        System.println("AccelerometerJumpDetector: Initialized - Advanced pattern detection enabled");
    }
    
    // Main detection update - processes new accelerometer data
    function updateDetection(accelData, timestamp) {
        if (accelData == null) {
            if (diagnosticLogger != null) {
                diagnosticLogger.logWarning("AccelerometerJumpDetector: Null accelerometer data");
            }
            return;
        }
        
        // Extract 3-axis acceleration data
        var x = accelData.get("x");
        var y = accelData.get("y");
        var z = accelData.get("z");
        
        if (x == null || y == null || z == null) {
            if (diagnosticLogger != null) {
                diagnosticLogger.logWarning("AccelerometerJumpDetector: Invalid acceleration components");
            }
            return;
        }
        
        // Calculate acceleration magnitude (total acceleration vector)
        var magnitude = Math.sqrt(x*x + y*y + z*z);
        
        // Update buffers with new data
        updateBuffers(magnitude, x, y, z, timestamp);
        
        // Log detailed sensor analysis
        if (diagnosticLogger != null) {
            diagnosticLogger.logDebug("ACCEL_JUMP: |a|=" + magnitude.format("%.3f") + 
                                    "g, X=" + x.format("%.3f") + 
                                    "g, Y=" + y.format("%.3f") + 
                                    "g, Z=" + z.format("%.3f") + "g");
        }
        
        // State machine for jump detection
        switch (currentState) {
            case STATE_BASELINE:
                processBaselineState(magnitude, timestamp);
                break;
            case STATE_MONITORING:
                processMonitoringState(magnitude, timestamp);
                break;
            case STATE_PREJUMP:
                processPreJumpState(magnitude, timestamp);
                break;
            case STATE_AIRBORNE:
                processAirborneState(magnitude, timestamp);
                break;
            case STATE_LANDING:
                processLandingState(magnitude, timestamp);
                break;
            case STATE_RECOVERY:
                processRecoveryState(magnitude, timestamp);
                break;
        }
    }
    
    // Establish baseline activity level
    function processBaselineState(magnitude, timestamp) {
        calibrationSamples++;
        
        // Running average of baseline acceleration
        baselineAccel = (baselineAccel * (calibrationSamples - 1) + magnitude) / calibrationSamples;
        
        // Calculate variance to understand normal activity level
        var deviation = magnitude - baselineAccel;
        baselineVariance = (baselineVariance * (calibrationSamples - 1) + 
                           deviation * deviation) / calibrationSamples;
        
        // Transition to monitoring after sufficient baseline data
        if (timestamp - stateStartTime > BASELINE_WINDOW || calibrationSamples >= BASELINE_SAMPLES) {
            isCalibrated = true;
            currentState = STATE_MONITORING;
            stateStartTime = timestamp;
            
            if (diagnosticLogger != null) {
                diagnosticLogger.logInfo("BASELINE COMPLETE: Accel=" + baselineAccel.format("%.3f") + 
                                       "g, Variance=" + baselineVariance.format("%.4f"));
            }
            
            System.println("AccelerometerJumpDetector: Baseline established - " + 
                         baselineAccel.format("%.2f") + "g +/- " + 
                         Math.sqrt(baselineVariance).format("%.3f") + "g");
        }
    }
    
    // Monitor for takeoff acceleration patterns
    function processMonitoringState(magnitude, timestamp) {
        if (!isCalibrated) { return; }
        
        // Look for significant acceleration above baseline + noise threshold
        var accelIncrease = magnitude - baselineAccel;
        var noiseLevel = Math.sqrt(baselineVariance) + NOISE_THRESHOLD;
        
        // Advanced pattern analysis: check for sustained acceleration
        var sustainedAccel = checkSustainedAcceleration(TAKEOFF_ACCEL_MIN);
        var isAboveNoise = accelIncrease > noiseLevel;
        var isWithinLimits = magnitude < TAKEOFF_ACCEL_MAX;
        
        if (diagnosticLogger != null && (sustainedAccel || magnitude > baselineAccel + 1.0)) {
            diagnosticLogger.logDebug("MONITOR: Δa=" + accelIncrease.format("%.3f") + 
                                    "g, noise=" + noiseLevel.format("%.3f") + 
                                    "g, sustained=" + sustainedAccel);
        }
        
        // Detect takeoff pattern: sustained acceleration above threshold
        if (sustainedAccel && isAboveNoise && isWithinLimits) {
            // Confirm this isn't just noise by checking pattern consistency
            if (isValidTakeoffPattern()) {
                currentState = STATE_PREJUMP;
                stateStartTime = timestamp;
                jumpStartTime = timestamp;
                maxAcceleration = magnitude;
                
                if (diagnosticLogger != null) {
                    diagnosticLogger.logInfo("PREJUMP DETECTED: Magnitude=" + magnitude.format("%.3f") + 
                                           "g, Pattern confirmed");
                }
                
                System.println("AccelerometerJumpDetector: Pre-jump detected - " + 
                             magnitude.format("%.2f") + "g");
            }
        }
    }
    
    // Track pre-jump acceleration buildup
    function processPreJumpState(magnitude, timestamp) {
        var timeSinceTakeoff = timestamp - jumpStartTime;
        
        // Update maximum acceleration seen
        if (magnitude > maxAcceleration) {
            maxAcceleration = magnitude;
        }
        
        // Look for transition to airborne (acceleration drops toward free-fall)
        var expectedAirborne = magnitude < baselineAccel + 2.0; // Near free-fall
        var hasAccelerated = maxAcceleration > baselineAccel + TAKEOFF_ACCEL_MIN;
        
        if (expectedAirborne && hasAccelerated) {
            currentState = STATE_AIRBORNE;
            stateStartTime = timestamp;
            
            if (diagnosticLogger != null) {
                diagnosticLogger.logInfo("AIRBORNE: Max accel=" + maxAcceleration.format("%.3f") + 
                                       "g, Current=" + magnitude.format("%.3f") + "g");
            }
            
            System.println("AccelerometerJumpDetector: Airborne phase - max accel " + 
                         maxAcceleration.format("%.2f") + "g");
        }
        
        // Timeout protection - if too long in pre-jump, false alarm
        if (timeSinceTakeoff > 500) { // 0.5s max pre-jump time
            currentState = STATE_MONITORING;
            stateStartTime = timestamp;
            
            if (diagnosticLogger != null) {
                diagnosticLogger.logWarning("PREJUMP TIMEOUT: Returning to monitoring");
            }
        }
    }
    
    // Monitor airborne phase and detect landing
    function processAirborneState(magnitude, timestamp) {
        var airborneTime = timestamp - stateStartTime;
        
        // Look for landing impact (sudden high acceleration)
        var isLandingImpact = magnitude > baselineAccel + LANDING_IMPACT_MIN && 
                             magnitude < LANDING_IMPACT_MAX;
        
        // Confirm landing with pattern analysis
        if (isLandingImpact && isValidLandingPattern()) {
            currentState = STATE_LANDING;
            stateStartTime = timestamp;
            jumpEndTime = timestamp;
            landingImpact = magnitude;
            jumpDuration = jumpEndTime - jumpStartTime;
            
            // Trigger jump detection event
            jumpDetected = true;
            totalJumpsDetected++;
            
            if (diagnosticLogger != null) {
                diagnosticLogger.logInfo("LANDING DETECTED: Impact=" + magnitude.format("%.3f") + 
                                       "g, Duration=" + jumpDuration + "ms");
            }
            
            // Calculate estimated jump height from flight time
            var flightTime = jumpDuration / 1000.0; // Convert to seconds
            var estimatedHeight = 0.125 * 9.8 * flightTime * flightTime; // h = 1/8 * g * t²
            
            // Trigger callback if available
            if (jumpDetectedCallback != null) {
                var jumpData = {
                    "height" => estimatedHeight,
                    "duration" => jumpDuration,
                    "maxAccel" => maxAcceleration,
                    "landingImpact" => landingImpact,
                    "timestamp" => timestamp
                };
                jumpDetectedCallback.invoke("jump", jumpData);
            }
            
            System.println("AccelerometerJumpDetector: JUMP CONFIRMED - Height: " + 
                         estimatedHeight.format("%.2f") + "m, Duration: " + jumpDuration + "ms");
            
        } else if (airborneTime > AIRBORNE_MAX_DURATION) {
            // Airborne too long - likely false detection
            currentState = STATE_MONITORING;
            stateStartTime = timestamp;
            falsePositiveCount++;
            
            if (diagnosticLogger != null) {
                diagnosticLogger.logWarning("AIRBORNE TIMEOUT: False positive, airborne=" + 
                                          airborneTime + "ms");
            }
        }
    }
    
    // Process landing impact and stabilization
    function processLandingState(magnitude, timestamp) {
        var landingTime = timestamp - stateStartTime;
        
        // Monitor for stabilization (return to baseline activity)
        var isStabilized = abs(magnitude - baselineAccel) < Math.sqrt(baselineVariance) + 0.5;
        
        if (isStabilized || landingTime > RECOVERY_DURATION) {
            currentState = STATE_RECOVERY;
            stateStartTime = timestamp;
            
            if (diagnosticLogger != null) {
                diagnosticLogger.logInfo("STABILIZED: Landing complete, entering recovery");
            }
        }
    }
    
    // Recovery period before returning to normal monitoring
    function processRecoveryState(magnitude, timestamp) {
        var recoveryTime = timestamp - stateStartTime;
        
        if (recoveryTime > RECOVERY_DURATION) {
            currentState = STATE_MONITORING;
            stateStartTime = timestamp;
            jumpDetected = false; // Reset for next detection
            
            if (diagnosticLogger != null) {
                diagnosticLogger.logInfo("RECOVERY COMPLETE: Returning to monitoring mode");
            }
        }
    }
    
    // Update circular buffers with new sensor data
    function updateBuffers(magnitude, x, y, z, timestamp) {
        accelBuffer[bufferIndex] = magnitude;
        accelXBuffer[bufferIndex] = x;
        accelYBuffer[bufferIndex] = y;
        accelZBuffer[bufferIndex] = z;
        timestampBuffer[bufferIndex] = timestamp;
        
        bufferIndex = (bufferIndex + 1) % PATTERN_WINDOW_SIZE;
    }
    
    // Check for sustained acceleration above threshold
    function checkSustainedAcceleration(threshold) {
        var count = 0;
        var required = PATTERN_WINDOW_SIZE / 4; // Need 25% of window above threshold
        
        for (var i = 0; i < PATTERN_WINDOW_SIZE; i++) {
            if (accelBuffer[i] > baselineAccel + threshold) {
                count++;
            }
        }
        
        return count >= required;
    }
    
    // Validate takeoff acceleration pattern
    function isValidTakeoffPattern() {
        // Check for smooth acceleration increase (not noise spikes)
        var trend = 0;
        var prevValue = accelBuffer[0];
        
        for (var i = 1; i < PATTERN_WINDOW_SIZE; i++) {
            if (accelBuffer[i] > prevValue) {
                trend++;
            }
            prevValue = accelBuffer[i];
        }
        
        // Require mostly increasing trend for takeoff
        return trend > PATTERN_WINDOW_SIZE * 0.6;
    }
    
    // Validate landing impact pattern  
    function isValidLandingPattern() {
        // Look for sharp acceleration spike (landing impact signature)
        var recentMax = 0.0;
        var recentMin = 999.0;
        
        // Check last few samples for impact pattern
        var samplesCheck = min(5, PATTERN_WINDOW_SIZE);
        for (var i = 0; i < samplesCheck; i++) {
            var idx = (bufferIndex - 1 - i + PATTERN_WINDOW_SIZE) % PATTERN_WINDOW_SIZE;
            var val = accelBuffer[idx];
            if (val > recentMax) { recentMax = val; }
            if (val < recentMin) { recentMin = val; }
        }
        
        // Landing should show sharp impact (high dynamic range)
        var dynamicRange = recentMax - recentMin;
        return dynamicRange > 2.0; // 2g difference indicates impact
    }
    
    // Get current detection statistics
    function getDetectionStats() {
        return {
            "totalJumps" => totalJumpsDetected,
            "falsePositives" => falsePositiveCount,
            "currentState" => getStateString(),
            "baseline" => baselineAccel,
            "variance" => baselineVariance,
            "isCalibrated" => isCalibrated,
            "lastJumpHeight" => averageJumpHeight
        };
    }
    
    // Convert state to readable string
    function getStateString() {
        switch (currentState) {
            case STATE_BASELINE: return "BASELINE";
            case STATE_MONITORING: return "MONITORING"; 
            case STATE_PREJUMP: return "PREJUMP";
            case STATE_AIRBORNE: return "AIRBORNE";
            case STATE_LANDING: return "LANDING";
            case STATE_RECOVERY: return "RECOVERY";
            default: return "UNKNOWN";
        }
    }
    
    // Configuration and callback methods
    function setJumpDetectedCallback(callback) {
        jumpDetectedCallback = callback;
    }
    
    function setDiagnosticLogger(logger) {
        diagnosticLogger = logger;
        if (logger != null) {
            logger.logInfo("AccelerometerJumpDetector: Diagnostic logging enabled");
        }
    }
    
    // Utility methods
    function isJumpDetected() {
        return jumpDetected;
    }
    
    function getLastJumpData() {
        if (!jumpDetected) { return null; }
        
        return {
            "startTime" => jumpStartTime,
            "endTime" => jumpEndTime,
            "duration" => jumpDuration,
            "maxAcceleration" => maxAcceleration,
            "landingImpact" => landingImpact
        };
    }
    
    // Reset detection state for testing
    function reset() {
        currentState = STATE_BASELINE;
        stateStartTime = System.getTimer();
        isCalibrated = false;
        calibrationSamples = 0;
        jumpDetected = false;
        
        System.println("AccelerometerJumpDetector: Reset to baseline state");
    }
    
    // Cleanup
    function cleanup() {
        if (diagnosticLogger != null) {
            diagnosticLogger.logInfo("AccelerometerJumpDetector: Cleanup - " + 
                                   totalJumpsDetected + " jumps detected, " + 
                                   falsePositiveCount + " false positives");
        }
        System.println("AccelerometerJumpDetector: Cleanup completed");
    }
}