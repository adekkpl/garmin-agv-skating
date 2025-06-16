// TrickDetector.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Improved Trick Detection Engine
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;

class TrickDetector {
    
    // Detection states
    const STATE_RIDING = 0;
    const STATE_TAKEOFF = 1;
    const STATE_AIRBORNE = 2;
    const STATE_GRINDING = 3;
    const STATE_LANDING = 4;

    // Improved detection thresholds - przenieś przed function initialize()
    // Detection thresholds
    const TAKEOFF_ACCEL_THRESHOLD = 1.5;      // Reduced from 2.0g
    const TAKEOFF_HEIGHT_THRESHOLD = 0.2;     // Reduced from 0.3m
    const GRIND_HEIGHT_STABILITY = 0.15;      // Reduced from 0.2m
    const GRIND_MIN_DURATION = 300;           // Reduced from 500ms
    const LANDING_ACCEL_THRESHOLD = 1.3;      // Reduced from 1.5g
    const VIBRATION_THRESHOLD = 0.4;          // Reduced from 0.5g
    const MIN_JUMP_HEIGHT = 0.15;             // Minimum height for jump
    const BUFFER_SIZE = 20;
    const CALIBRATION_SAMPLES = 50;

    var currentState;
    var previousState;
    
    // State tracking variables
    var takeoffStartTime;
    var takeoffStartHeight;
    var grindStartTime;
    var grindHeight;
    var maxJumpHeight;
    var baselineHeight;
    var lastUpdateTime;
    
    // Analysis buffers - properly sized
    var accelBuffer as Lang.Array<Lang.Float> = new Lang.Array<Lang.Float>[BUFFER_SIZE];
    var altitudeBuffer as Lang.Array<Lang.Float> = new Lang.Array<Lang.Float>[BUFFER_SIZE];
    var heightChangeBuffer as Lang.Array<Lang.Float> = new Lang.Array<Lang.Float>[BUFFER_SIZE];
    var bufferIndex = 0;
    
    // Calibration and filtering
    var isCalibrated = false;
    var baselineAccel;
    var heightBaseline = 0.0;
    var calibrationSamples = 0;
    
    // Detection sensitivity
    var sensitivityMultiplier = 1.0;
    
    // Statistics
    var totalTricksDetected = 0;
    var totalGrindsDetected = 0;
    var totalJumpsDetected = 0;
    var longestGrindDuration = 0;
    var lastTrickTime = 0;
    
    // Callbacks
    var trickDetectedCallback;

    function initialize() {
        currentState = STATE_RIDING;
        previousState = STATE_RIDING;
        
        // Initialize buffers
        accelBuffer = new Lang.Array<Lang.Float>[BUFFER_SIZE];
        altitudeBuffer = new Lang.Array<Lang.Float>[BUFFER_SIZE];
        heightChangeBuffer = new Lang.Array<Lang.Float>[BUFFER_SIZE];
        
        for (var i = 0; i < BUFFER_SIZE; i++) {
            accelBuffer[i] = 9.8; // Standard gravity
            altitudeBuffer[i] = 0.0;
            heightChangeBuffer[i] = 0.0;
        }
        
        baselineAccel = {"x" => 0.0, "y" => 0.0, "z" => 9.8};
        takeoffStartTime = null;
        grindStartTime = null;
        lastUpdateTime = 0;
        
        System.println("TrickDetector: Initialized with improved thresholds");
    }

    // Main detection update function
    function updateDetection(sensorData, timestamp) {
        if (sensorData == null) {
            return;
        }
        
        try {
            lastUpdateTime = timestamp;
            
            // Extract sensor data
            var accelData = sensorData.get("accelerometer");
            var altitude = sensorData.get("altitude");
            var pressure = sensorData.get("pressure");
            
            if (accelData == null) {
                return;
            }
            
            // Calculate acceleration magnitude
            var accelMagnitude = calculateAccelMagnitude(accelData);
            
            // Use pressure for height if altitude not available
            var currentHeight = altitude;
            if (currentHeight == null && pressure != null) {
                currentHeight = pressureToAltitude(pressure);
            }
            if (currentHeight == null) {
                currentHeight = 0.0;
            }
            
            // Calibration phase
            if (!isCalibrated) {
                calibrate(accelData, currentHeight);
                return;
            }
            
            // Update buffers
            updateBuffers(accelMagnitude, currentHeight);
            
            // State machine
            switch (currentState) {
                case STATE_RIDING:
                    checkForTakeoff(accelData, currentHeight, timestamp);
                    break;
                case STATE_TAKEOFF:
                    checkTakeoffProgress(accelData, currentHeight, timestamp);
                    break;
                case STATE_AIRBORNE:
                    checkForGrindOrLanding(accelData, currentHeight, timestamp);
                    break;
                case STATE_GRINDING:
                    checkGrindProgress(accelData, currentHeight, timestamp);
                    break;
                case STATE_LANDING:
                    checkLandingComplete(accelData, currentHeight, timestamp);
                    break;
            }
            
            // Timeout protection
            checkForTimeouts(timestamp);
            
        } catch (exception) {
            System.println("TrickDetector: Error in updateDetection: " + exception.getErrorMessage());
        }
    }

    // Calibration process
    function calibrate(accelData, height) {
        if (calibrationSamples == 0) {
            baselineAccel.put("x", 0.0);
            baselineAccel.put("y", 0.0);
            baselineAccel.put("z", 0.0);
            heightBaseline = 0.0;
        }
        
        baselineAccel.put("x", baselineAccel.get("x") + accelData.get("x"));
        baselineAccel.put("y", baselineAccel.get("y") + accelData.get("y"));
        baselineAccel.put("z", baselineAccel.get("z") + accelData.get("z"));
        heightBaseline += height;
        
        calibrationSamples++;
        
        if (calibrationSamples >= CALIBRATION_SAMPLES) {
            baselineAccel.put("x", baselineAccel.get("x") / CALIBRATION_SAMPLES);
            baselineAccel.put("y", baselineAccel.get("y") / CALIBRATION_SAMPLES);
            baselineAccel.put("z", baselineAccel.get("z") / CALIBRATION_SAMPLES);
            heightBaseline = heightBaseline / CALIBRATION_SAMPLES;
            
            isCalibrated = true;
            System.println("TrickDetector: Calibration complete - Baseline Z: " + 
                         baselineAccel.get("z").format("%.2f") + "g");
        }
    }

    // Calculate acceleration magnitude
    function calculateAccelMagnitude(accelData) {
        var x = accelData.get("x");
        var y = accelData.get("y");
        var z = accelData.get("z");
        
        return Math.sqrt(x * x + y * y + z * z);
    }

    // Update circular buffers
    function updateBuffers(accelMagnitude, height) {
        accelBuffer[bufferIndex] = accelMagnitude;
        altitudeBuffer[bufferIndex] = height;
        
        // Calculate height change rate
        var prevIndex = (bufferIndex - 1 + BUFFER_SIZE) % BUFFER_SIZE;
        heightChangeBuffer[bufferIndex] = height - altitudeBuffer[prevIndex];
        
        bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;
    }

    // Convert pressure to approximate altitude
    function pressureToAltitude(pressure) {
        // Standard atmosphere formula
        var SEA_LEVEL_PRESSURE = 101325.0; // Pa
        return 44330.0 * (1.0 - Math.pow(pressure / SEA_LEVEL_PRESSURE, 0.1903));
    }

    // Check for takeoff initiation
    function checkForTakeoff(accelData, height, timestamp) {
        var accelMagnitude = accelBuffer[(bufferIndex - 1 + BUFFER_SIZE) % BUFFER_SIZE];
        var baselineZ = baselineAccel.get("z");
        
        // Look for sudden acceleration increase
        var accelIncrease = accelMagnitude - baselineZ;
        
        // Check for upward acceleration and height change
        var heightChange = getRecentHeightChange();
        
        if (accelIncrease > TAKEOFF_ACCEL_THRESHOLD * sensitivityMultiplier || 
            heightChange > 0.1) {
            
            takeoffStartTime = timestamp;
            takeoffStartHeight = height;
            maxJumpHeight = height;
            currentState = STATE_TAKEOFF;
            
            System.println("TrickDetector: Takeoff detected - Accel: " + 
                         accelIncrease.format("%.2f") + "g, Height change: " + 
                         heightChange.format("%.2f") + "m");
        }
    }

    // Monitor takeoff progress
    function checkTakeoffProgress(accelData, height, timestamp) {
        var heightGain = height - takeoffStartHeight;
        
        // Update max height
        if (height > maxJumpHeight) {
            maxJumpHeight = height;
        }
        
        // Check if sufficient height gained for jump
        if (heightGain > TAKEOFF_HEIGHT_THRESHOLD * sensitivityMultiplier) {
            currentState = STATE_AIRBORNE;
            System.println("TrickDetector: Airborne - Height gain: " + heightGain.format("%.2f") + "m");
        }
        
        // Timeout if takeoff takes too long
        if (timestamp - takeoffStartTime > 1000) {
            currentState = STATE_RIDING;
            System.println("TrickDetector: Takeoff timeout");
        }
    }

    // Check for grind or landing while airborne
    function checkForGrindOrLanding(accelData, height, timestamp) {
        var heightChange = getRecentHeightChange();
        var heightStability = calculateHeightStability();
        var hasVibration = detectGrindVibration(accelData);
        
        // Check for grind (stable height with vibration)
        if (heightStability < GRIND_HEIGHT_STABILITY && hasVibration) {
            grindStartTime = timestamp;
            grindHeight = height;
            currentState = STATE_GRINDING;
            System.println("TrickDetector: Grind started - Height: " + height.format("%.2f") + 
                         "m, Stability: " + heightStability.format("%.2f"));
        }
        // Check for landing (significant height drop)
        else if (heightChange < -0.15) {
            currentState = STATE_LANDING;
            System.println("TrickDetector: Landing detected - Height drop: " + heightChange.format("%.2f") + "m");
        }
        
        // Timeout if airborne too long
        if (timestamp - takeoffStartTime > 5000) {
            finalizeJump(timestamp);
        }
    }

    // Monitor grind progress
    function checkGrindProgress(accelData, height, timestamp) {
        var heightStability = calculateHeightStability();
        var hasVibration = detectGrindVibration(accelData);
        var grindDuration = timestamp - grindStartTime;
        
        // Check if grind continues
        if (heightStability < GRIND_HEIGHT_STABILITY && hasVibration) {
            // Grind continues - update duration
            if (grindDuration > longestGrindDuration) {
                longestGrindDuration = grindDuration;
            }
        } else {
            // Grind ended - check if it was long enough
            if (grindDuration > GRIND_MIN_DURATION) {
                finalizeGrind(timestamp, grindDuration);
            } else {
                // Too short, treat as jump
                currentState = STATE_LANDING;
            }
        }
    }

    // Check if landing is complete
    function checkLandingComplete(accelData, height, timestamp) {
        var accelMagnitude = accelBuffer[(bufferIndex - 1 + BUFFER_SIZE) % BUFFER_SIZE];
        var baselineZ = baselineAccel.get("z");
        
        // Look for impact (high acceleration)
        if (accelMagnitude > baselineZ + LANDING_ACCEL_THRESHOLD) {
            finalizeJump(timestamp);
        }
        
        // Timeout
        if (timestamp - takeoffStartTime > 3000) {
            finalizeJump(timestamp);
        }
    }

    // Get recent height change trend
    function getRecentHeightChange() {
        if (bufferIndex < 5) {
            return 0.0;
        }
        
        var recentHeight = altitudeBuffer[(bufferIndex - 1 + BUFFER_SIZE) % BUFFER_SIZE];
        var olderHeight = altitudeBuffer[(bufferIndex - 5 + BUFFER_SIZE) % BUFFER_SIZE];
        
        return recentHeight - olderHeight;
    }

    // Calculate height stability (standard deviation)
    function calculateHeightStability() {
        var count = BUFFER_SIZE < 10 ? BUFFER_SIZE : 10; // Use min from Utils.mc later
        var sum = 0.0;
        var mean = 0.0;
        
        // Calculate mean
        for (var i = 0; i < count; i++) {
            var index = (bufferIndex - 1 - i + BUFFER_SIZE) % BUFFER_SIZE;
            sum += altitudeBuffer[index];
        }
        mean = sum / count;
        
        // Calculate standard deviation
        var variance = 0.0;
        for (var i = 0; i < count; i++) {
            var index = (bufferIndex - 1 - i + BUFFER_SIZE) % BUFFER_SIZE;
            var diff = altitudeBuffer[index] - mean;
            variance += diff * diff;
        }
        
        return Math.sqrt(variance / count);
    }

    // Detect grind vibration patterns
    function detectGrindVibration(accelData) {
        var x = accelData.get("x") - baselineAccel.get("x");
        var y = accelData.get("y") - baselineAccel.get("y");
        
        var vibrationIntensity = Math.sqrt(x * x + y * y);
        
        return vibrationIntensity > VIBRATION_THRESHOLD * sensitivityMultiplier;
    }

    // Finalize detected grind
    function finalizeGrind(timestamp, duration) {
        var trickData = {
            "type" => "grind",
            "duration" => duration,
            "height" => grindHeight,
            "maxHeight" => maxJumpHeight - takeoffStartHeight,
            "timestamp" => timestamp
        };
        
        totalGrindsDetected++;
        totalTricksDetected++;
        lastTrickTime = timestamp;
        
        if (duration > longestGrindDuration) {
            longestGrindDuration = duration;
        }
        
        triggerTrickDetected("grind", trickData);
        
        currentState = STATE_LANDING;
        System.println("TrickDetector: Grind completed - Duration: " + duration + "ms");
    }

    // Finalize detected jump
    function finalizeJump(timestamp) {
        var jumpHeight = maxJumpHeight - takeoffStartHeight;
        var duration = timestamp - takeoffStartTime;
        
        // Only count as jump if sufficient height
        if (jumpHeight > MIN_JUMP_HEIGHT) {
            var trickData = {
                "type" => "jump",
                "duration" => duration,
                "height" => jumpHeight,
                "maxHeight" => jumpHeight,
                "timestamp" => timestamp
            };
            
            totalJumpsDetected++;
            totalTricksDetected++;
            lastTrickTime = timestamp;
            
            triggerTrickDetected("jump", trickData);
            
            System.println("TrickDetector: Jump completed - Height: " + jumpHeight.format("%.2f") + 
                         "m, Duration: " + duration + "ms");
        }
        
        currentState = STATE_RIDING;
        resetTrickState();
    }

    // Reset trick state variables
    function resetTrickState() {
        takeoffStartTime = null;
        takeoffStartHeight = 0.0;
        grindStartTime = null;
        grindHeight = 0.0;
        maxJumpHeight = 0.0;
    }

    // Check for state timeouts
    function checkForTimeouts(timestamp) {
        var timeoutDuration = 10000; // 10 seconds
        
        if (takeoffStartTime != null && timestamp - takeoffStartTime > timeoutDuration) {
            System.println("TrickDetector: State timeout - returning to riding");
            currentState = STATE_RIDING;
            resetTrickState();
        }
    }

    // Trigger trick detected callback
    function triggerTrickDetected(trickType, trickData) {
        if (trickDetectedCallback != null) {
            trickDetectedCallback.invoke(trickType, trickData);
        }
    }

    // Set callback for trick detection
    function setTrickDetectedCallback(callback) {
        trickDetectedCallback = callback;
    }

    // Get detection statistics
    function getDetectionStats() {
        return {
            "totalTricks" => totalTricksDetected,
            "totalGrinds" => totalGrindsDetected,
            "totalJumps" => totalJumpsDetected,
            "longestGrind" => longestGrindDuration,
            "currentState" => currentState,
            "isCalibrated" => isCalibrated
        };
    }

    // Adjust detection sensitivity
    function setSensitivity(sensitivity) {
        sensitivityMultiplier = sensitivity;
        System.println("TrickDetector: Sensitivity set to " + sensitivity);
    }

    // Get current state as string
    function getCurrentStateString() {
        switch (currentState) {
            case STATE_RIDING:
                return "RIDING";
            case STATE_TAKEOFF:
                return "TAKEOFF";
            case STATE_AIRBORNE:
                return "AIRBORNE";
            case STATE_GRINDING:
                return "GRINDING";
            case STATE_LANDING:
                return "LANDING";
            default:
                return "UNKNOWN";
        }
    }

    // Get calibration status
    function isCalibrationComplete() {
        return isCalibrated;
    }

    // Force recalibration
    function recalibrate() {
        isCalibrated = false;
        calibrationSamples = 0;
        System.println("TrickDetector: Recalibration started");
    }

    // Reset all statistics
    function resetStats() {
        totalTricksDetected = 0;
        totalGrindsDetected = 0;
        totalJumpsDetected = 0;
        longestGrindDuration = 0;
        lastTrickTime = 0;
        System.println("TrickDetector: Statistics reset");
    }

    // Get detailed state information
    function getStateInfo() {
        return {
            "currentState" => getCurrentStateString(),
            "takeoffTime" => takeoffStartTime,
            "grindTime" => grindStartTime,
            "lastTrick" => lastTrickTime,
            "sensitivity" => sensitivityMultiplier,
            "calibrated" => isCalibrated
        };
    }

    // Check if currently detecting a trick
    function isDetectingTrick() {
        return currentState != STATE_RIDING;
    }

    // Get time since last trick
    function getTimeSinceLastTrick() {
        if (lastTrickTime == 0) {
            return -1;
        }
        return lastUpdateTime - lastTrickTime;
    }

    // Cleanup resources
    function cleanup() {
        try {
            // Reset all state
            currentState = STATE_RIDING;
            resetTrickState();
            resetStats();
            
            // Clear buffers
            for (var i = 0; i < BUFFER_SIZE; i++) {
                accelBuffer[i] = 9.8;
                altitudeBuffer[i] = 0.0;
                heightChangeBuffer[i] = 0.0;
            }
            
            System.println("TrickDetector: Cleanup completed");
        } catch (exception) {
            System.println("TrickDetector: Error during cleanup: " + exception.getErrorMessage());
        }
    }
}