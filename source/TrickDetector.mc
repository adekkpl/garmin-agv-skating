// TrickDetector.mc
// Garmin Aggressive Inline Skating Tracker v2.0.0
// Trick Detection Engine
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;


class TrickDetector {
    
    // Detection states
    /* enum DetectionState {
        STATE_RIDING,
        STATE_TAKEOFF,
        STATE_AIRBORNE,
        STATE_GRINDING,
        STATE_LANDING
    } */
   // Użyj stałych:
   const STATE_RIDING = 0;
   const STATE_TAKEOFF = 1;
   const STATE_AIRBORNE = 2;
   const STATE_GRINDING = 3;
   const STATE_LANDING = 4;

    var currentState;
    var previousState;
    
    // Detection thresholds
    const TAKEOFF_ACCEL_THRESHOLD = 2.0;      // g-force for jump detection
    const TAKEOFF_HEIGHT_THRESHOLD = 0.3;     // meters minimum height gain
    const GRIND_HEIGHT_STABILITY = 0.2;       // meters stability tolerance
    const GRIND_MIN_DURATION = 500;           // milliseconds minimum grind time
    const LANDING_ACCEL_THRESHOLD = 1.5;      // g-force for landing detection
    const VIBRATION_THRESHOLD = 0.5;          // g-force for grind vibration
    
    // State tracking variables
    var takeoffStartTime;
    var takeoffStartHeight;
    var grindStartTime;
    var grindHeight;
    var currentTrickData;
    var baselineHeight;
    
    // Analysis buffers
   var accelAnalysisBuffer = null;
   var altitudeAnalysisBuffer = null;
   var heightChangeBuffer = null;
    
    // Calibration and filtering
    var noiseFilter;
    var calibrationComplete = false;
    var baselineAccel = {"x" => 0.0, "y" => 0.0, "z" => 9.8}; // Standard gravity
    
    // Detection sensitivity (adjustable)
    var sensitivityMultiplier = 1.0;
    
    // Statistics
    var totalTricksDetected = 0;
    var totalGrindsDetected = 0;
    var totalJumpsDetected = 0;
    var longestGrindDuration = 0;
    
    // Callbacks
    var trickDetectedCallback;
    
    function initialize() {
        System.println("TrickDetector: Initializing trick detection engine");
        
        // Initialize state
        currentState = STATE_RIDING;
        previousState = STATE_RIDING;
        
        // Initialize analysis buffers // Na bardziej explicite:
         accelAnalysisBuffer = new [20];
         altitudeAnalysisBuffer = new [20];
         heightChangeBuffer = new [10];

        //accelAnalysisBuffer = [];
        for (var i = 0; i < 20; i++) {
            accelAnalysisBuffer.add(0.0);
        }
        //altitudeAnalysisBuffer = [];
        for (var i = 0; i < 20; i++) {
            altitudeAnalysisBuffer.add(0.0);
        }
        //heightChangeBuffer = [];
        for (var i = 0; i < 10; i++) {
            heightChangeBuffer.add(0.0);
        }
        
        // Initialize buffers with zeros
        for (var i = 0; i < 20; i++) {
            accelAnalysisBuffer[i] = 0.0;
            altitudeAnalysisBuffer[i] = 0.0;
        }
        
        noiseFilter = new NoiseFilter();
        noiseFilter.initialize();
        for (var i = 0; i < 10; i++) {
            heightChangeBuffer[i] = 0.0;
        }
        
        // Initialize baseline values
        baselineHeight = 0.0;
        
        System.println("TrickDetector: Initialization complete");
    }

    // Start trick detection
    function startDetection() as Void {
        System.println("TrickDetector: Starting trick detection");
        currentState = STATE_RIDING;
        calibrationComplete = false;
        
        // Reset statistics for new session
        totalTricksDetected = 0;
        totalGrindsDetected = 0;
        totalJumpsDetected = 0;
        longestGrindDuration = 0;
    }

    // Stop trick detection
    function stopDetection() as Void {
        System.println("TrickDetector: Stopping trick detection");
        currentState = STATE_RIDING;
        
        // Log final statistics
        System.println("TrickDetector: Session complete - Tricks: " + totalTricksDetected + 
                      ", Grinds: " + totalGrindsDetected + ", Jumps: " + totalJumpsDetected);
    }

    // Main analysis function - called with sensor data
    function analyzeSensorData(sensorData) {
        if (sensorData == null) {
            return;
        }
        
        // Extract sensor readings
        var accelData = sensorData.get("accel");
        var barometerData = sensorData.get("barometer");
        var timestamp = sensorData.get("timestamp");
        
        if (accelData == null || barometerData == null) {
            return;
        }
        
        // Update analysis buffers
        updateAnalysisBuffers(accelData, barometerData);
        
        // Auto-calibration during riding
        if (!calibrationComplete) {
            performCalibration(accelData, barometerData);
        }
        
        // State machine for trick detection
        processDetectionStateMachine(accelData, barometerData, timestamp);
    }

    // Update circular analysis buffers
    function updateAnalysisBuffers(accelData, barometerData) {
        // Shift acceleration buffer
        for (var i = 0; i < 19; i++) {
            accelAnalysisBuffer[i] = accelAnalysisBuffer[i + 1];
        }
        
        // Calculate total acceleration magnitude
        var accelMagnitude = Math.sqrt(
            Math.pow(accelData.get("x"), 2) + 
            Math.pow(accelData.get("y"), 2) + 
            Math.pow(accelData.get("z"), 2)
        );
        accelAnalysisBuffer[19] = accelMagnitude;
        
        // Shift altitude buffer
        for (var i = 0; i < 19; i++) {
            altitudeAnalysisBuffer[i] = altitudeAnalysisBuffer[i + 1];
        }
        altitudeAnalysisBuffer[19] = barometerData.get("altitude");
        
        // Calculate height change for last few samples
        if (altitudeAnalysisBuffer[15] != 0.0) {
            var heightChange = altitudeAnalysisBuffer[19] - altitudeAnalysisBuffer[15];
            
            // Shift height change buffer
            for (var i = 0; i < 9; i++) {
                heightChangeBuffer[i] = heightChangeBuffer[i + 1];
            }
            heightChangeBuffer[9] = heightChange;
        }
    }

    // Auto-calibration for baseline values
    function performCalibration(accelData, barometerData) {
        // Simple calibration - establish baseline when relatively stable
        //var currentAccelMag = accelAnalysisBuffer[19];
        var currentAccelMag = accelAnalysisBuffer[19];
        //var currentAccelMag = (accelAnalysisBuffer as Array)[19];
        
        if (abs(currentAccelMag - 9.8) < 1.0) { // Close to 1g, probably stable
            baselineAccel["x"] = accelData.get("x");
            baselineAccel["y"] = accelData.get("y");
            baselineAccel["z"] = accelData.get("z");
            baselineHeight = barometerData.get("altitude");
            calibrationComplete = true;
            
            System.println("TrickDetector: Calibration complete - Baseline height: " + baselineHeight);
        }
    }

    // Main state machine for trick detection
    function processDetectionStateMachine(accelData, barometerData, timestamp) {
        previousState = currentState;
        
        switch (currentState) {
            case STATE_RIDING:
                checkForTakeoff(accelData, barometerData, timestamp);
                break;
                
            case STATE_TAKEOFF:
                checkForAirborne(accelData, barometerData, timestamp);
                break;
                
            case STATE_AIRBORNE:
                checkForGrindOrLanding(accelData, barometerData, timestamp);
                break;
                
            case STATE_GRINDING:
                checkForGrindEnd(accelData, barometerData, timestamp);
                break;
                
            case STATE_LANDING:
                checkForRiding(accelData, barometerData, timestamp);
                break;
        }
    }

    // Check for takeoff (jump start)
    function checkForTakeoff(accelData, barometerData, timestamp) {
        var currentAccelMag = accelAnalysisBuffer[19];
        var heightChange = heightChangeBuffer[9];
        
        // Detect sudden upward acceleration + height gain
        if (currentAccelMag > (9.8 + TAKEOFF_ACCEL_THRESHOLD * sensitivityMultiplier) && 
            heightChange > (TAKEOFF_HEIGHT_THRESHOLD * 0.5)) {
            
            // Transition to takeoff state
            currentState = STATE_TAKEOFF;
            takeoffStartTime = timestamp;
            takeoffStartHeight = barometerData.get("altitude");
            
            System.println("TrickDetector: Takeoff detected - Accel: " + currentAccelMag + "g, Height change: " + heightChange + "m");
        }
    }

    // Check for airborne state
    function checkForAirborne(accelData, barometerData , timestamp ) {
        var currentHeight = barometerData.get("altitude");
        var heightGain = currentHeight - takeoffStartHeight;
        
        // Confirm we're truly airborne with sufficient height gain
        if (heightGain >= TAKEOFF_HEIGHT_THRESHOLD) {
            currentState = STATE_AIRBORNE;
            System.println("TrickDetector: Airborne confirmed - Height gain: " + heightGain + "m");
        }
        
        // Timeout check - if too much time passed, probably false positive
        if (timestamp - takeoffStartTime > 2000) { // 2 seconds
            currentState = STATE_RIDING;
            System.println("TrickDetector: Takeoff timeout - returning to riding");
        }
    }

    // Check for grind start or direct landing
    function checkForGrindOrLanding(accelData, barometerData, timestamp) {
        var currentHeight = barometerData.get("altitude");
        var heightStability = calculateHeightStability();
        var hasVibration = detectGrindVibration(accelData);
        
        // Check for grind (stable height + vibration)
        if (heightStability < GRIND_HEIGHT_STABILITY && hasVibration) {
            currentState = STATE_GRINDING;
            grindStartTime = timestamp;
            grindHeight = currentHeight;
            
            System.println("TrickDetector: Grind detected - Height: " + currentHeight + "m, Stability: " + heightStability);
        }
        
        // Check for direct landing (significant height drop + impact)
        var heightDrop = takeoffStartHeight - currentHeight;
        var hasLandingImpact = detectLandingImpact(accelData);
        
        if (heightDrop > TAKEOFF_HEIGHT_THRESHOLD && hasLandingImpact) {
            currentState = STATE_LANDING;
            finalizeTrick("jump", timestamp, null);
        }
        
        // Timeout check
        if (timestamp - takeoffStartTime > 5000) { // 5 seconds max airtime
            currentState = STATE_RIDING;
        }
    }

    // Check for grind end
    function checkForGrindEnd(accelData, barometerData, timestamp) {
        var currentHeight = barometerData.get("altitude");
        var heightStability = calculateHeightStability();
        var hasVibration = detectGrindVibration(accelData);
        var hasLandingImpact = detectLandingImpact(accelData);
        System.println("Debug: Height=" + currentHeight + ", Vibration=" + hasVibration);
        
        // End grind if height becomes unstable or we detect landing impact
        if (heightStability > GRIND_HEIGHT_STABILITY || hasLandingImpact) {
            var grindDuration = timestamp - grindStartTime;
            
            if (grindDuration >= GRIND_MIN_DURATION) {
                currentState = STATE_LANDING;
                finalizeTrick("grind", timestamp, grindDuration);
            } else {
                // Too short, probably false positive
                currentState = STATE_AIRBORNE;
            }
        }
        
        // Timeout check for very long grinds
        if (timestamp - grindStartTime > 10000) { // 10 seconds max grind
            var grindDuration = timestamp - grindStartTime;
            currentState = STATE_LANDING;
            finalizeTrick("grind", timestamp, grindDuration);
        }
    }

    // Check for return to riding state
    function checkForRiding(accelData, barometerData, timestamp) {
        var currentAccelMag = accelAnalysisBuffer[19];
        var heightStability = calculateHeightStability();
        
        // Return to riding when acceleration normalizes and height is stable
        if (abs(currentAccelMag - 9.8) < 0.5 && heightStability < 0.1) {
            currentState = STATE_RIDING;
            System.println("TrickDetector: Returned to riding state");
        }
        
        // Force return after timeout
        if (timestamp - (grindStartTime != null ? grindStartTime : takeoffStartTime) > 3000) {
            currentState = STATE_RIDING;
        }
    }

    // Calculate height stability (standard deviation of recent altitude readings)
    function calculateHeightStability() {
        var sum = 0.0;
        var mean = 0.0;
        var variance = 0.0;
        var count = 0;
        
        // Calculate mean of last 10 altitude readings
        for (var i = 10; i < 20; i++) {
            if (altitudeAnalysisBuffer[i] != 0.0) {
                sum += altitudeAnalysisBuffer[i];
                count++;
            }
        }
        
        if (count == 0) {
            return 999.0; // High instability if no data
        }
        
        mean = sum / count;
        
        // Calculate variance
        for (var i = 10; i < 20; i++) {
            if (altitudeAnalysisBuffer[i] != 0.0) {
                variance += Math.pow(altitudeAnalysisBuffer[i] - mean, 2);
            }
        }
        
        variance = variance / count;
        return Math.sqrt(variance);
    }

    // Detect grind vibration patterns
    function detectGrindVibration(accelData) {
        // Look for characteristic vibration in X and Y axes during grinding
        var xAccel = accelData.get("x");
        var yAccel = accelData.get("y");
        
        // Calculate recent vibration intensity
        var vibrationIntensity = Math.sqrt(Math.pow(xAccel, 2) + Math.pow(yAccel, 2));
        
        return vibrationIntensity > VIBRATION_THRESHOLD;
    }

    // Detect landing impact
    function detectLandingImpact(accelData) {
        var currentAccelMag = accelAnalysisBuffer[19];
        return currentAccelMag > (9.8 + LANDING_ACCEL_THRESHOLD);
    }

    // Finalize and record detected trick
    function finalizeTrick(trickType, timestamp, duration) {
        var trickData = {
            "type" => trickType,
            "timestamp" => timestamp,
            "takeoffTime" => takeoffStartTime,
            "duration" => duration != null ? duration : (timestamp - takeoffStartTime)
        };
        
        if (trickType.equals("grind")) {
            trickData.put("grindDuration", duration);
            trickData.put("grindHeight", grindHeight);
            totalGrindsDetected++;
            
            if (duration > longestGrindDuration) {
                longestGrindDuration = duration;
            }
        } else if (trickType.equals("jump")) {
            totalJumpsDetected++;
        }
        
        totalTricksDetected++;
        
        // Trigger callback if set
        if (trickDetectedCallback != null) {
            trickDetectedCallback.invoke(trickType, trickData);
        }
        
        System.println("TrickDetector: " + trickType + " completed - Duration: " + trickData.get("duration") + "ms");
    }

    // Set trick detection callback
    function setTrickDetectedCallback(callback) {
        trickDetectedCallback = callback;
    }

    // Get current detection statistics
    function getDetectionStats() {
        return {
            "totalTricks" => totalTricksDetected,
            "totalGrinds" => totalGrindsDetected,
            "totalJumps" => totalJumpsDetected,
            "longestGrind" => longestGrindDuration,
            "currentState" => currentState
        };
    }

    // Adjust detection sensitivity
    function setSensitivity(sensitivity) {
        sensitivityMultiplier = sensitivity;
        System.println("TrickDetector: Sensitivity set to " + sensitivity);
    }

    // Get current state as string for debugging
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

   // Simple noise filter helper class
   class NoiseFilter {
      var filterBuffer;
      const FILTER_SIZE = 5;
      
      function initialize() {
         filterBuffer = new [FILTER_SIZE];
         for (var i = 0; i < FILTER_SIZE; i++) {
               filterBuffer[i] = 0.0;
         }
      }
      
      function filter(value){
         // Simple moving average filter
         for (var i = 0; i < FILTER_SIZE - 1; i++) {
               filterBuffer[i] = filterBuffer[i + 1];
         }
         filterBuffer[FILTER_SIZE - 1] = value;
         
         var sum = 0.0;
         for (var i = 0; i < FILTER_SIZE; i++) {
               sum += filterBuffer[i];
         }
         
         return sum / FILTER_SIZE;
      }
   }

}