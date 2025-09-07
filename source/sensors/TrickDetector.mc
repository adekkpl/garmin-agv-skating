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
    // Detection thresholds - FIXED: More realistic values for actual skating
    const TAKEOFF_ACCEL_THRESHOLD = 3.0;      // INCREASED: 3.0g change from baseline (real jump needed)
    const TAKEOFF_HEIGHT_THRESHOLD = 0.4;     // INCREASED: 0.4m minimum height change
    const GRIND_HEIGHT_STABILITY = 0.2;       // Restored from 0.15m
    const GRIND_MIN_DURATION = 500;           // Restored from 300ms
    const LANDING_ACCEL_THRESHOLD = 2.5;      // INCREASED: 2.5g landing impact
    const VIBRATION_THRESHOLD = 0.8;          // INCREASED: 0.8g vibration threshold
    const MIN_JUMP_HEIGHT = 0.3;              // INCREASED: 0.3m minimum jump height
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
    var accelBuffer = [];
    var altitudeBuffer = [];
    var heightChangeBuffer = [];
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
    
    // New: Integration with other detectors
    var rotationDetector;
    var alertManager;
    var diagnosticLogger;        // NEW: Comprehensive diagnostic logging system
    
    // New: Jump-rotation correlation tracking
    var jumpStartTime;
    var expectedRotationEnd;
    var jumpDetectionWindow = 2000; // 2 seconds window to correlate jump with rotation

    function initialize() {
        currentState = STATE_RIDING;
        previousState = STATE_RIDING;
        
        // Initialize buffers
        accelBuffer = [];
        altitudeBuffer = [];
        heightChangeBuffer = [];
        for (var i = 0; i < BUFFER_SIZE; i++) {
            accelBuffer.add(9.8);
            altitudeBuffer.add(0.0);
            heightChangeBuffer.add(0.0);
        }
        
        baselineAccel = {"x" => 0.0, "y" => 0.0, "z" => 9.8};
        takeoffStartTime = null;
        grindStartTime = null;
        lastUpdateTime = 0;
        
        // NEW: Initialize diagnostic logger for comprehensive analysis
        diagnosticLogger = new DiagnosticLogger();
        diagnosticLogger.initialize();
        diagnosticLogger.logInfo("TrickDetector: Initialized with diagnostic logging enabled");
        diagnosticLogger.logDebug("Detection thresholds - Takeoff: " + TAKEOFF_ACCEL_THRESHOLD + "g, " +
                                 "Height: " + TAKEOFF_HEIGHT_THRESHOLD + "m, " +
                                 "Landing: " + LANDING_ACCEL_THRESHOLD + "g");
        
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
            
            // NEW: Comprehensive sensor data logging for analysis
            if (diagnosticLogger != null) {
                // Log all sensor inputs with detailed analysis
                diagnosticLogger.logSensorData("accelerometer", accelData, timestamp);
                if (pressure != null) {
                    var baroData = {"pressure" => pressure, "altitude" => altitude};
                    diagnosticLogger.logSensorData("barometer", baroData, timestamp);
                }
            }
            
            if (accelData == null) {
                if (diagnosticLogger != null) {
                    diagnosticLogger.logWarning("Missing accelerometer data at timestamp " + timestamp);
                }
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
            
            // NEW: Log current detection state and key parameters
            if (diagnosticLogger != null) {
                var stateString = getCurrentStateString();
                var heightChange = getRecentHeightChange();
                
                diagnosticLogger.logDebug("STATE: " + stateString + 
                                         " | Accel: " + accelMagnitude.toString() + "g" +
                                         " | Height: " + currentHeight.toString() + "m" +
                                         " | ΔH: " + heightChange.toString() + "m");
            }
            
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
            
            // NEW: Log state transitions for analysis
            if (diagnosticLogger != null && currentState != previousState) {
                diagnosticLogger.logInfo("STATE TRANSITION: " + 
                                       getStateString(previousState) + " → " + 
                                       getCurrentStateString());
                previousState = currentState;
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
                         baselineAccel.get("z").toString() + "g");
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
        var aBuf = accelBuffer as Lang.Array;
        var altBuf = altitudeBuffer as Lang.Array;
        var hBuf = heightChangeBuffer as Lang.Array;

        aBuf[bufferIndex] = accelMagnitude;
        altBuf[bufferIndex] = height;

        // Calculate height change rate
        var prevIndex = (bufferIndex - 1 + BUFFER_SIZE) % BUFFER_SIZE;
        hBuf[bufferIndex] = height - altBuf[prevIndex];

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
        var aBuf = accelBuffer as Lang.Array;
        var accelMagnitude = aBuf[(bufferIndex - 1 + BUFFER_SIZE) % BUFFER_SIZE];
        
        // CRITICAL FIX: Compare magnitude with baseline magnitude, not just Z component
        var baselineMagnitude = Math.sqrt(
            baselineAccel.get("x") * baselineAccel.get("x") +
            baselineAccel.get("y") * baselineAccel.get("y") +
            baselineAccel.get("z") * baselineAccel.get("z")
        );
        
        // Look for sudden acceleration change from baseline
        var accelIncrease = abs(accelMagnitude - baselineMagnitude);
        
        // Check for upward acceleration and height change
        var heightChange = getRecentHeightChange();
        
        // NEW: Comprehensive takeoff detection analysis
        if (diagnosticLogger != null) {
            var threshold = TAKEOFF_ACCEL_THRESHOLD * sensitivityMultiplier;
            var accelTest = accelIncrease > threshold;
            var heightTest = heightChange > 0.1;
            
            // Create detailed threshold analysis
            var thresholds = {
                "accelThreshold" => threshold,
                "heightThreshold" => 0.1,
                "sensitivity" => sensitivityMultiplier
            };
            
            var sensorValues = {
                "accelIncrease" => accelIncrease,
                "heightChange" => heightChange,
                "accelMagnitude" => accelMagnitude,
                "baselineMagnitude" => baselineMagnitude
            };
            
            var detected = accelTest || heightTest;
            var confidence = max(
                accelIncrease / threshold,
                heightChange / 0.1
            );
            
            // Log detailed detection analysis
            diagnosticLogger.logDetectionEvent("takeoff", detected, confidence, 
                                              sensorValues, thresholds);
            
            if (!detected) {
                diagnosticLogger.logDebug("TAKEOFF REJECTED: Accel=" + accelIncrease.toString() + 
                                        "g (need >" + threshold.toString() + 
                                        "g), Height=" + heightChange.toString() + 
                                        "m (need >0.1m)");
            }
        }
        
        if (accelIncrease > TAKEOFF_ACCEL_THRESHOLD * sensitivityMultiplier || 
            heightChange > 0.1) {
            
            takeoffStartTime = timestamp;
            takeoffStartHeight = height;
            maxJumpHeight = height;
            currentState = STATE_TAKEOFF;
            
            // Enhanced detection logging
            if (diagnosticLogger != null) {
                diagnosticLogger.logInfo("TAKEOFF CONFIRMED: Accel increase=" + 
                                       accelIncrease.toString() + "g, Height change=" + 
                                       heightChange.toString() + "m");
            }
            
            System.println("TrickDetector: Takeoff detected - Accel: " + 
                         accelIncrease.toString() + "g, Height change: " + 
                         heightChange.toString() + "m");
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
            System.println("TrickDetector: Airborne - Height gain: " + heightGain.toString() + "m");
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
            System.println("TrickDetector: Grind started - Height: " + height.toString() + 
                         "m, Stability: " + heightStability.toString());
        }
        // Check for landing (significant height drop)
        else if (heightChange < -0.15) {
            currentState = STATE_LANDING;
            System.println("TrickDetector: Landing detected - Height drop: " + heightChange.toString() + "m");
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
        var aBuf = accelBuffer as Lang.Array;
        var accelMagnitude = aBuf[(bufferIndex - 1 + BUFFER_SIZE) % BUFFER_SIZE];
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
        
        var altBuf = altitudeBuffer as Lang.Array;
        var recentHeight = altBuf[(bufferIndex - 1 + BUFFER_SIZE) % BUFFER_SIZE];
        var olderHeight = altBuf[(bufferIndex - 5 + BUFFER_SIZE) % BUFFER_SIZE];
        
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
            var altBuf = altitudeBuffer as Lang.Array;
            sum += altBuf[index];
        }
        mean = sum / count;
        
        // Calculate standard deviation
        var variance = 0.0;
        for (var i = 0; i < count; i++) {
            var index = (bufferIndex - 1 - i + BUFFER_SIZE) % BUFFER_SIZE;
            var altBuf = altitudeBuffer as Lang.Array;
            var diff = altBuf[index] - mean;
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
            // Check for rotation during jump
            var rotationAngle = checkRotationDuringJump(timestamp);
            
            var trickData = {
                "type" => "jump",
                "duration" => duration,
                "height" => jumpHeight,
                "maxHeight" => jumpHeight,
                "timestamp" => timestamp,
                "rotation" => rotationAngle
            };
            
            totalJumpsDetected++;
            totalTricksDetected++;
            lastTrickTime = timestamp;
            
            triggerTrickDetected("jump", trickData);
            
            // Play alert based on rotation
            playJumpAlert(rotationAngle);
            
            System.println("TrickDetector: Jump completed - Height: " + jumpHeight.toString() + 
                         "m, Duration: " + duration + "ms, Rotation: " + 
                         (rotationAngle != null ? rotationAngle.toString() + "°" : "none"));
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

    function startDetection() as Void {
        currentState = STATE_RIDING;
        System.println("TrickDetector: Detection started");
    }

    function stopDetection() as Void {
        currentState = STATE_RIDING;
        System.println("TrickDetector: Detection stopped");
    }

    function setTrickDetectedCallback(callback as Lang.Method) as Void {
        trickDetectedCallback = callback;
        System.println("TrickDetector: Callback set");
    }


    // Get detection statistics
    function getDetectionStats() as Lang.Dictionary {
        return {
            "totalTricks" => totalTricksDetected,
            "totalGrinds" => totalGrindsDetected,
            "totalJumps" => totalJumpsDetected,
            "longestGrind" => longestGrindDuration
        } as Lang.Dictionary;
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
    
    // Get state name for given state value
    function getStateString(state) {
        switch (state) {
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
    function isCalibrationComplete() as Lang.Boolean {
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
    
    // NEW: Diagnostic logger access methods
    function getDiagnosticLogger() {
        return diagnosticLogger;
    }
    
    function generateDiagnosticReport() {
        if (diagnosticLogger != null) {
            diagnosticLogger.generateDiagnosticReport();
            return diagnosticLogger.getDiagnosticData();
        }
        return null;
    }
    
    function setDiagnosticMode(enabled) {
        if (diagnosticLogger != null) {
            diagnosticLogger.setDebugMode(enabled);
        }
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

    function detectTrick(trickType as Lang.String, trickData as Lang.Dictionary) as Void {
        totalTricksDetected++;
        System.println("TrickDetector: " + trickType + " detected!");
        
        if (trickDetectedCallback != null) {
            try {
                trickDetectedCallback.invoke(trickType, trickData);
            } catch (exception) {
                System.println("TrickDetector: Callback error: " + exception.getErrorMessage());
            }
        }
    }

    function updateSensorData(accelData as Lang.Dictionary, gyroData as Lang.Dictionary) as Void {
        if (accelData != null) {
            try {
                // Process accelerometer data for trick detection
                var x = accelData.get("x") as Lang.Float;
                var y = accelData.get("y") as Lang.Float;  
                var z = accelData.get("z") as Lang.Float;
                
                var magnitude = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
                
                // CRITICAL FIX: Subtract gravity baseline before comparison
                // magnitude includes gravity (~9.8g), so we need to compare against baseline
                var accelerationChange = abs(magnitude - 9.8); // Change from gravity baseline
                
                // Only detect if we're calibrated and acceleration change exceeds threshold
                if (isCalibrated && accelerationChange > TAKEOFF_ACCEL_THRESHOLD) {
                    var trickData = {
                        "magnitude" => magnitude,
                        "change" => accelerationChange
                    } as Lang.Dictionary;
                    detectTrick("jump", trickData);
                }
            } catch (exception) {
                System.println("TrickDetector: Error processing sensor data: " + exception.getErrorMessage());
            }
        }
    }

    // NEW: Integration methods
    
    // Set rotation detector for jump-rotation correlation
    function setRotationDetector(detector) {
        rotationDetector = detector;
        System.println("TrickDetector: RotationDetector linked");
    }
    
    // Set alert manager for audio feedback
    function setAlertManager(manager) {
        alertManager = manager;
        System.println("TrickDetector: AlertManager linked");
    }
    
    // Check if there was a rotation during jump
    function checkRotationDuringJump(timestamp) {
        if (rotationDetector == null || takeoffStartTime == null) {
            return null;
        }
        
        try {
            // Get rotation data from the period of the jump
            var jumpDuration = timestamp - takeoffStartTime;
            var rotationStats = rotationDetector.getRotationStats();
            
            if (rotationStats != null) {
                // Check if rotation occurred during jump timeframe
                var recentRotations = rotationStats.get("recentRotations");
                if (recentRotations != null && recentRotations instanceof Lang.Array && recentRotations.size() > 0) {
                    // Get the most recent rotation
                    var lastRotation = recentRotations[recentRotations.size() - 1] as Lang.Dictionary;
                    var rotationTime = lastRotation.get("timestamp");
                    
                    // Check if rotation happened during jump (+/- 500ms window)
                    if (rotationTime != null && 
                        abs(rotationTime - takeoffStartTime) < jumpDuration + 500) {
                        
                        var angle = lastRotation.get("angle");
                        if (angle != null && angle instanceof Lang.Float) {
                            System.println("TrickDetector: Rotation detected during jump: " + 
                                         angle.toString() + "°");
                            return angle;
                        }
                    }
                }
            }
            
        } catch (exception) {
            System.println("TrickDetector: Error checking rotation: " + exception.getErrorMessage());
        }
        
        return null;
    }
    
    // Play jump alert with rotation information
    function playJumpAlert(rotationAngle) {
        if (alertManager == null) {
            return;
        }
        
        try {
            // Determine alert type based on rotation
            var alertType = 0; // ALERT_JUMP
            
            if (rotationAngle != null) {
                if (rotationAngle >= 540.0) {
                    alertType = 3; // ALERT_JUMP_540
                } else if (rotationAngle >= 360.0) {
                    alertType = 2; // ALERT_JUMP_360
                } else if (rotationAngle >= 180.0) {
                    alertType = 1; // ALERT_JUMP_180
                }
            }
            
            alertManager.playAlert(alertType, rotationAngle);
            
        } catch (exception) {
            System.println("TrickDetector: Error playing alert: " + exception.getErrorMessage());
        }
    }
    
    // Get jump statistics with rotation info
    function getJumpStatsWithRotation() {
        return {
            "totalJumps" => totalJumpsDetected,
            "jumpsWithRotation" => getJumpsWithRotationCount(),
            "averageRotationAngle" => getAverageRotationAngle(),
            "maxRotationDetected" => getMaxRotationDetected()
        };
    }
    
    // Helper functions for rotation statistics
    function getJumpsWithRotationCount() {
        // This would need to be tracked separately in a real implementation
        // For now, return a placeholder
        return 0;
    }
    
    function getAverageRotationAngle() {
        // Placeholder - would calculate from stored rotation data
        return 0.0;
    }
    
    function getMaxRotationDetected() {
        // Placeholder - would track maximum rotation seen
        return 0.0;
    }

    // Cleanup resources
    function cleanup() {
        try {
            stopDetection();
            
            // Unregister high-frequency sensor listener
            try {
                Sensor.unregisterSensorDataListener();
                System.println("SensorManager: High-frequency sensor listener unregistered");
            } catch (unregisterException) {
                System.println("SensorManager: Error unregistering sensor listener: " + unregisterException.getErrorMessage());
            }
            
            // Reset data
            /* currentHeartRate = 0;
            currentAccelData = {"x" => 0.0, "y" => 0.0, "z" => 9.8};
            currentGyroData = {"x" => 0.0, "y" => 0.0, "z" => 0.0};
            currentBarometricData = {"pressure" => 101325.0, "altitude" => 0.0}; */
            
            System.println("SensorManager: Cleanup completed");
        } catch (exception) {
            System.println("SensorManager: Error during cleanup: " + exception.getErrorMessage());
        }
    }
}