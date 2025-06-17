// SessionStats.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Session Statistics Management
using Toybox.Lang;
using Toybox.System;
using Toybox.Math;

class SessionStats {
    
    // Session data
    var sessionActive = false;
    var sessionStartTime;
    var sessionDuration = 0;
    var sessionDistance = 0.0;
    
    // Performance metrics
    var totalCalories = 0;
    var averageSpeed = 0.0;
    var maxSpeed = 0.0;
    var currentSpeed = 0.0;
    
    // Trick statistics
    var totalTricks = 0;
    var totalGrinds = 0;
    var totalJumps = 0;
    var longestGrind = 0;
    var bestJumpHeight = 0.0;
    
    // Rotation statistics
    var totalRotations = 0.0;
    var rightRotations = 0.0;
    var leftRotations = 0.0;
    
    // Heart rate data
    var currentHeartRate = 0;
    var averageHeartRate = 0;
    var maxHeartRate = 0;
    var heartRateZoneTime = {}; // Time spent in each HR zone
    
    // Speed tracking
    var speedSamples = 0;
    var speedSum = 0.0;
    
    // Calories calculation
    var lastCalorieUpdate = 0;
    var userWeight = 70.0; // Default 70kg, could be from user profile
    
    function initialize() {
        resetSessionData();
        
        // Initialize heart rate zones
        heartRateZoneTime.put("zone1", 0); // Recovery: <60% max HR
        heartRateZoneTime.put("zone2", 0); // Aerobic: 60-70%
        heartRateZoneTime.put("zone3", 0); // Tempo: 70-80%
        heartRateZoneTime.put("zone4", 0); // Threshold: 80-90%
        heartRateZoneTime.put("zone5", 0); // VO2 Max: >90%
        
        System.println("SessionStats: Initialized");
    }
    
    // Start new session
    function startNewSession() {
        resetSessionData();
        sessionActive = true;
        sessionStartTime = System.getTimer();
        lastCalorieUpdate = sessionStartTime;
        
        System.println("SessionStats: New session started");
    }
    
    // Pause session
    function pauseSession() {
        sessionActive = false;
        System.println("SessionStats: Session paused");
    }
    
    // Resume session
    function resumeSession() {
        sessionActive = true;
        lastCalorieUpdate = System.getTimer();
        System.println("SessionStats: Session resumed");
    }
    
    // Finalize session
    function finalizeSession() {
        sessionActive = false;
        updateSessionDuration();
        calculateFinalStats();
        System.println("SessionStats: Session finalized");
    }
    
    // Discard session
    function discardSession() {
        resetSessionData();
        System.println("SessionStats: Session discarded");
    }
    
    // Reset all session data
    function resetSessionData() {
        sessionActive = false;
        sessionStartTime = null;
        sessionDuration = 0;
        sessionDistance = 0.0;
        
        totalCalories = 0;
        averageSpeed = 0.0;
        maxSpeed = 0.0;
        currentSpeed = 0.0;
        
        totalTricks = 0;
        totalGrinds = 0;
        totalJumps = 0;
        longestGrind = 0;
        bestJumpHeight = 0.0;
        
        totalRotations = 0.0;
        rightRotations = 0.0;
        leftRotations = 0.0;
        
        currentHeartRate = 0;
        averageHeartRate = 0;
        maxHeartRate = 0;
        
        speedSamples = 0;
        speedSum = 0.0;
        
        System.println("SessionStats: Session data reset");
    }
    
    // Update GPS data
    function updateGPSData(position) {
        if (!sessionActive || position == null) {
            return;
        }
        
        // GPS data will be handled by GPSTracker
        // This is just a placeholder for compatibility
    }
    
    // Update heart rate data
    function updateHeartRate(heartRate) {
        if (!sessionActive || heartRate <= 0) {
            return;
        }
        
        currentHeartRate = heartRate;
        
        // Update max heart rate
        if (heartRate > maxHeartRate) {
            maxHeartRate = heartRate;
        }
        
        // Update average heart rate
        // Simple running average - could be improved
        if (averageHeartRate == 0) {
            averageHeartRate = heartRate;
        } else {
            averageHeartRate = (averageHeartRate * 0.9) + (heartRate * 0.1);
        }
        
        // Update heart rate zone time
        updateHeartRateZone(heartRate);
        
        // Update calories based on heart rate
        updateCalories(heartRate);
    }
    
    // Update heart rate zone tracking
    function updateHeartRateZone(heartRate) {
        var maxHR = estimateMaxHeartRate(); // Estimate based on age or use 200 default
        var hrPercent = (heartRate * 100.0) / maxHR;
        
        var zone = "zone1";
        if (hrPercent > 90) {
            zone = "zone5";
        } else if (hrPercent > 80) {
            zone = "zone4";
        } else if (hrPercent > 70) {
            zone = "zone3";
        } else if (hrPercent > 60) {
            zone = "zone2";
        }
        
        // Add time to current zone (approximate)
        var currentTime = heartRateZoneTime.get(zone);
        heartRateZoneTime.put(zone, currentTime + 1);
    }
    
    // Estimate maximum heart rate
    function estimateMaxHeartRate() {
        // Simple age-based formula: 220 - age
        // Default to 190 if age unknown
        return 190;
    }
    
    // Update speed data
    function updateSpeed(speed) {
        if (!sessionActive || speed < 0) {
            return;
        }
        
        currentSpeed = speed;
        
        // Update max speed
        if (speed > maxSpeed) {
            maxSpeed = speed;
        }
        
        // Update average speed
        speedSum += speed;
        speedSamples++;
        averageSpeed = speedSum / speedSamples;
    }
    
    // Update distance
    function updateDistance(distance) {
        if (!sessionActive) {
            return;
        }
        
        sessionDistance = distance;
    }


    // Get session start time for other components
    function getSessionStartTime() {
        return sessionStartTime != null ? sessionStartTime : 0;
    }

    // Add jump to statistics
    function addJump() {
        if (sessionActive) {
            totalJumps++;
            totalTricks++; // Jump is also a trick
            System.println("SessionStats: Jump added - Total: " + totalJumps);
        }
    }

    // Update best jump height
    function updateJumpHeight(height) {
        if (sessionActive && height != null && height > bestJumpHeight) {
            bestJumpHeight = height;
            System.println("SessionStats: New best jump height: " + height.format("%.2f") + "m");
        }
    }

    // Add grind to statistics
    function addGrind(duration) {
        if (sessionActive) {
            totalGrinds++;
            totalTricks++; // Grind is also a trick
            
            if (duration != null && duration > longestGrind) {
                longestGrind = duration;
            }
            
            System.println("SessionStats: Grind added - Total: " + totalGrinds);
        }
    }
    
    // Add detected trick
    function addTrick(trickType, trickData) {
        if (!sessionActive) {
            return;
        }
        
        totalTricks++;
        
        if (trickType.equals("grind")) {
            totalGrinds++;
            var duration = trickData.get("duration");
            if (duration != null && duration > longestGrind) {
                longestGrind = duration;
            }
        } else if (trickType.equals("jump")) {
            totalJumps++;
            var height = trickData.get("height");
            if (height != null && height > bestJumpHeight) {
                bestJumpHeight = height;
            }
        }
        
        System.println("SessionStats: Added " + trickType + " - Total tricks: " + totalTricks);
    }
    
    // Add detected rotation
    /* function addRotation(direction, angle) {
        if (!sessionActive) {
            return;
        }
        
        var rotationAmount = angle / 360.0;
        totalRotations += rotationAmount;
        
        if (direction.equals("right")) {
            rightRotations += rotationAmount;
        } else if (direction.equals("left")) {
            leftRotations += rotationAmount;
        }
        
        System.println("SessionStats: Added rotation " + direction + " " + rotationAmount.format("%.2f") + " turns");
    } */
    // Add rotation to statistics
    function addRotation(degrees, direction) {
        if (sessionActive) {
            totalRotations += abs(degrees);
            
            if (direction != null) {
                if (direction > 0) {
                    rightRotations += abs(degrees);
                } else if (direction < 0) {
                    leftRotations += abs(degrees);
                }
            }
            
            System.println("SessionStats: Rotation added - " + degrees + " degrees");
        }
    }
    
    // Update calories estimation
    function updateCalories(heartRate) {
        var currentTime = System.getTimer();
        var timeDelta = (currentTime - lastCalorieUpdate) / 1000.0; // Convert to seconds
        
        if (timeDelta < 1.0) {
            return; // Update at most once per second
        }
        
        // Simple calorie calculation based on heart rate and time
        // More sophisticated formula could use speed, weight, etc.
        var caloriesPerMinute = calculateCaloriesPerMinute(heartRate);
        var additionalCalories = (caloriesPerMinute * timeDelta) / 60.0;
        
        totalCalories += additionalCalories.toNumber();
        lastCalorieUpdate = currentTime;
    }
    
    // Calculate calories per minute based on heart rate
    function calculateCaloriesPerMinute(heartRate) {
        // Simple formula: Base metabolic rate + activity calories
        // Adjust based on user weight and heart rate
        var baseCaloriesPerMinute = (userWeight * 0.02); // Base metabolism
        var hrScale = heartRate / 100.0;
        var activityMultiplier = max(1.0, hrScale); // Use Utils.mc function
        
        return baseCaloriesPerMinute * activityMultiplier;
    }
    
    // Calculate performance rating
    function getPerformanceRating() {
        var rating = 50; // Base rating
        
        // Add points for session duration
        if (sessionDuration > 1800) { // 30 minutes
            rating += 20;
        } else if (sessionDuration > 900) { // 15 minutes
            rating += 10;
        }
        
        // Add points for tricks
        rating += min(totalTricks * 2, 30); // Use Utils.mc function
        
        // Add points for distance
        if (sessionDistance > 2000) { // 2km
            rating += 15;
        } else if (sessionDistance > 1000) { // 1km
            rating += 10;
        }
        
        // Add points for heart rate consistency
        if (averageHeartRate > 120 && averageHeartRate < 180) {
            rating += 5; // Good training zone
        }
        
        // Ensure within bounds
        if (rating > 100) { rating = 100; }
        if (rating < 0) { rating = 0; }
        
        return rating;
    }
    
    // Update session duration
    function updateSessionDuration() {
        if (sessionStartTime != null) {
            var currentTime = System.getTimer();
            sessionDuration = (currentTime - sessionStartTime) / 1000; // Convert to seconds
        }
    }
    
    // Calculate final statistics
    function calculateFinalStats() {
        updateSessionDuration();
        
        // Final average calculations if needed
        if (speedSamples > 0) {
            averageSpeed = speedSum / speedSamples;
        }
        
        System.println("SessionStats: Final stats calculated - Duration: " + sessionDuration + 
                     "s, Distance: " + sessionDistance.format("%.2f") + "m, Tricks: " + totalTricks);
    }
    
    // Get display data for views
    function getDisplayData() {
        updateSessionDuration();
        
        return {
            "duration" => sessionDuration,
            "distance" => sessionDistance,
            "calories" => totalCalories,
            "tricks" => totalTricks,
            "grinds" => totalGrinds,
            "jumps" => totalJumps,
            "longestGrind" => formatDuration(longestGrind),
            "rotations" => totalRotations,
            "heartRate" => currentHeartRate,
            "averageHeartRate" => averageHeartRate,
            "maxHeartRate" => maxHeartRate,
            "speed" => currentSpeed,
            "averageSpeed" => averageSpeed,
            "maxSpeed" => maxSpeed,
            "performance" => getPerformanceRating()
        };
    }
    
    // Get session data for saving
    function getSessionData() {
        return {
            "active" => sessionActive,
            "startTime" => sessionStartTime,
            "duration" => sessionDuration,
            "distance" => sessionDistance,
            "calories" => totalCalories,
            "tricks" => totalTricks,
            "grinds" => totalGrinds,
            "jumps" => totalJumps,
            "rotations" => totalRotations,
            "maxHeartRate" => maxHeartRate,
            "averageHeartRate" => averageHeartRate,
            "maxSpeed" => maxSpeed,
            "averageSpeed" => averageSpeed
        };
    }
    
    // Restore session data
    function restoreSessionData(data) {
        if (data == null) {
            return;
        }
        
        try {
            sessionActive = data.get("active");
            sessionStartTime = data.get("startTime");
            sessionDuration = data.get("duration");
            sessionDistance = data.get("distance");
            totalCalories = data.get("calories");
            totalTricks = data.get("tricks");
            totalGrinds = data.get("grinds");
            totalJumps = data.get("jumps");
            totalRotations = data.get("rotations");
            maxHeartRate = data.get("maxHeartRate");
            averageHeartRate = data.get("averageHeartRate");
            maxSpeed = data.get("maxSpeed");
            averageSpeed = data.get("averageSpeed");
            
            System.println("SessionStats: Session data restored");
        } catch (exception) {
            System.println("SessionStats: Error restoring data: " + exception.getErrorMessage());
        }
    }
    
    // Format duration from milliseconds to string
    function formatDuration(milliseconds) {
        if (milliseconds == null || milliseconds == 0) {
            return "0.0s";
        }
        
        var seconds = milliseconds / 1000.0;
        if (seconds < 1.0) {
            return milliseconds.format("%d") + "ms";
        } else {
            return seconds.format("%.1f") + "s";
        }
    }
    
    // Status methods
    function isActive() {
        return sessionActive;
    }
    
    function getTotalTricks() {
        return totalTricks;
    }
    
    function getSessionDuration() {
        updateSessionDuration();
        return sessionDuration;
    }
    
    function getSessionDistance() {
        return sessionDistance;
    }
    
    // Reset statistics only (keep session active)
    function resetStats() {
        totalTricks = 0;
        totalGrinds = 0;
        totalJumps = 0;
        longestGrind = 0;
        bestJumpHeight = 0.0;
        totalRotations = 0.0;
        rightRotations = 0.0;
        leftRotations = 0.0;
        totalCalories = 0;
        
        System.println("SessionStats: Statistics reset");
    }
}