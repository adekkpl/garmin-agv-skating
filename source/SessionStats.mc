// Garmin Aggressive Inline Skating Tracker v2.0.0
// Session Statistics Management

import Toybox.System;
import Toybox.Math;

class SessionStats {
    
    // Basic session data
    var sessionStartTime;
    var sessionEndTime;
    var isSessionActive = false;
    
    // Trick statistics
    var totalTricks = 0;
    var totalGrinds = 0;
    var totalJumps = 0;
    var longestGrindDuration = 0;
    var shortestGrindDuration = 999999;
    var averageGrindDuration = 0.0;
    var totalGrindTime = 0;
    
    // Performance metrics
    var maxSpeed = 0.0;
    var averageSpeed = 0.0;
    var totalDistance = 0.0;
    var maxHeartRate = 0;
    var averageHeartRate = 0.0;
    var caloriesBurned = 0;
    
    // Detailed trick data storage
    var tricksHistory;
    var grindsHistory;
    var jumpsHistory;
    
    // Real-time tracking
    var speedSamples;
    var heartRateSamples;
    var distanceCheckpoints;
    var lastGpsPosition;
    
    // Session goals and achievements
    var sessionGoals;
    var achievementsUnlocked;
    
    const MAX_TRICK_HISTORY = 100;
    const MAX_SAMPLES = 1000;
    
    function initialize() {
        System.println("SessionStats: Initializing session statistics");
        
        // Initialize history arrays
        tricksHistory = new Array[MAX_TRICK_HISTORY];
        grindsHistory = new Array[MAX_TRICK_HISTORY];
        jumpsHistory = new Array[MAX_TRICK_HISTORY];
        
        // Initialize sample arrays
        speedSamples = new Array[MAX_SAMPLES];
        heartRateSamples = new Array[MAX_SAMPLES];
        distanceCheckpoints = new Array[MAX_SAMPLES];
        
        // Initialize arrays with default values
        for (var i = 0; i < MAX_TRICK_HISTORY; i++) {
            tricksHistory[i] = null;
            grindsHistory[i] = null;
            jumpsHistory[i] = null;
        }
        
        for (var i = 0; i < MAX_SAMPLES; i++) {
            speedSamples[i] = 0.0;
            heartRateSamples[i] = 0;
            distanceCheckpoints[i] = 0.0;
        }
        
        // Initialize goals
        sessionGoals = {
            "targetTricks" => 10,
            "targetGrinds" => 5,
            "targetDistance" => 5000.0, // 5km
            "targetTime" => 3600000 // 1 hour in milliseconds
        };
        
        achievementsUnlocked = [];
        
        reset();
    }

    // Reset all statistics for new session
    function reset() as Void {
        System.println("SessionStats: Resetting statistics for new session");
        
        // Reset counters
        totalTricks = 0;
        totalGrinds = 0;
        totalJumps = 0;
        longestGrindDuration = 0;
        shortestGrindDuration = 999999;
        averageGrindDuration = 0.0;
        totalGrindTime = 0;
        
        // Reset performance metrics
        maxSpeed = 0.0;
        averageSpeed = 0.0;
        totalDistance = 0.0;
        maxHeartRate = 0;
        averageHeartRate = 0.0;
        caloriesBurned = 0;
        
        // Clear history
        clearHistoryArrays();
        
        // Reset tracking variables
        lastGpsPosition = null;
        isSessionActive = false;
        sessionStartTime = null;
        sessionEndTime = null;
        
        // Clear achievements for this session
        achievementsUnlocked = [];
    }

    // Start new session
    function startSession() as Void {
        if (isSessionActive) {
            System.println("SessionStats: Session already active");
            return;
        }
        
        System.println("SessionStats: Starting new session");
        reset();
        sessionStartTime = System.getTimer();
        isSessionActive = true;
    }

    // End current session
    function endSession() as Void {
        if (!isSessionActive) {
            System.println("SessionStats: No active session to end");
            return;
        }
        
        System.println("SessionStats: Ending session");
        sessionEndTime = System.getTimer();
        isSessionActive = false;
        
        // Calculate final statistics
        calculateFinalStats();
        
        // Check for achievements
        checkAchievements();
        
        // Log session summary
        logSessionSummary();
    }

    // Add a detected trick to statistics
    function addTrick(trickType as String, trickData as Dictionary) as Void {
        if (!isSessionActive) {
            return;
        }
        
        totalTricks++;
        
        // Add to general tricks history
        addToHistory(tricksHistory, trickData);
        
        if (trickType.equals("grind")) {
            addGrind(trickData);
        } else if (trickType.equals("jump")) {
            addJump(trickData);
        }
        
        // Check for real-time achievements
        checkRealtimeAchievements();
        
        System.println("SessionStats: Added " + trickType + " - Total tricks: " + totalTricks);
    }

    // Add grind-specific data
    function addGrind(grindData as Dictionary) as Void {
        totalGrinds++;
        
        var duration = grindData.get("grindDuration");
        if (duration != null) {
            totalGrindTime += duration;
            
            // Update grind duration statistics
            if (duration > longestGrindDuration) {
                longestGrindDuration = duration;
            }
            
            if (duration < shortestGrindDuration) {
                shortestGrindDuration = duration;
            }
            
            // Recalculate average grind duration
            averageGrindDuration = totalGrindTime.toFloat() / totalGrinds;
        }
        
        // Add to grinds history
        addToHistory(grindsHistory, grindData);
    }

    // Add jump-specific data
    function addJump(jumpData as Dictionary) as Void {
        totalJumps++;
        
        // Add to jumps history
        addToHistory(jumpsHistory, jumpData);
    }

    // Update performance metrics with sensor data
    function updatePerformanceMetrics(sensorData as Dictionary) as Void {
        if (!isSessionActive || sensorData == null) {
            return;
        }
        
        // Update GPS-based metrics
        var gpsData = sensorData.get("gps");
        if (gpsData != null) {
            updateGpsMetrics(gpsData);
        }
        
        // Update heart rate metrics
        var heartRateData = sensorData.get("heartRate");
        if (heartRateData != null) {
            updateHeartRateMetrics(heartRateData);
        }
        
        // Estimate calories burned
        updateCalorieEstimate();
    }

    // Update GPS-based metrics (speed, distance)
    function updateGpsMetrics(gpsData as Dictionary) as Void {
        var currentSpeed = gpsData.get("speed");
        var currentPosition = {
            "lat" => gpsData.get("latitude"),
            "lon" => gpsData.get("longitude")
        };
        
        // Update speed statistics
        if (currentSpeed != null && currentSpeed > 0) {
            if (currentSpeed > maxSpeed) {
                maxSpeed = currentSpeed;
            }
            
            addToSampleArray(speedSamples, currentSpeed);
            averageSpeed = calculateArrayAverage(speedSamples);
        }
        
        // Calculate distance if we have previous position
        if (lastGpsPosition != null && currentPosition["lat"] != 0 && currentPosition["lon"] != 0) {
            var distance = calculateDistance(lastGpsPosition, currentPosition);
            totalDistance += distance;
        }
        
        lastGpsPosition = currentPosition;
    }

    // Update heart rate metrics
    function updateHeartRateMetrics(heartRateData as Dictionary) as Void {
        var currentHeartRate = heartRateData.get("heartRate");
        
        if (currentHeartRate != null && currentHeartRate > 0) {
            if (currentHeartRate > maxHeartRate) {
                maxHeartRate = currentHeartRate;
            }
            
            addToSampleArray(heartRateSamples, currentHeartRate);
            averageHeartRate = calculateArrayAverage(heartRateSamples);
        }
    }

    // Simple calorie estimation
    function updateCalorieEstimate() as Void {
        if (averageHeartRate > 0) {
            // Very rough estimation: calories per minute based on heart rate
            var sessionTimeMinutes = getSessionTimeMinutes();
            var caloriesPerMinute = (averageHeartRate - 60) * 0.1; // Simplified formula
            caloriesBurned = (sessionTimeMinutes * caloriesPerMinute).toNumber();
        }
    }

    // Calculate distance between two GPS coordinates
    function calculateDistance(pos1 as Dictionary, pos2 as Dictionary) as Float {
        var lat1 = pos1.get("lat") * Math.PI / 180.0;
        var lon1 = pos1.get("lon") * Math.PI / 180.0;
        var lat2 = pos2.get("lat") * Math.PI / 180.0;
        var lon2 = pos2.get("lon") * Math.PI / 180.0;
        
        var earthRadius = 6371000.0; // meters
        
        var dLat = lat2 - lat1;
        var dLon = lon2 - lon1;
        
        var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(lat1) * Math.cos(lat2) *
                Math.sin(dLon/2) * Math.sin(dLon/2);
        
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        
        return earthRadius * c;
    }

    // Add value to circular sample array
    function addToSampleArray(array as Array, value as Number or Float) as Void {
        for (var i = 0; i < MAX_SAMPLES - 1; i++) {
            array[i] = array[i + 1];
        }
        array[MAX_SAMPLES - 1] = value;
    }

    // Calculate average of sample array
    function calculateArrayAverage(array as Array) as Float {
        var sum = 0.0;
        var count = 0;
        
        for (var i = 0; i < MAX_SAMPLES; i++) {
            if (array[i] != null && array[i] > 0) {
                sum += array[i];
                count++;
            }
        }
        
        return count > 0 ? sum / count : 0.0;
    }

    // Add item to history array
    function addToHistory(historyArray as Array, item as Dictionary) as Void {
        for (var i = 0; i < MAX_TRICK_HISTORY - 1; i++) {
            historyArray[i] = historyArray[i + 1];
        }
        historyArray[MAX_TRICK_HISTORY - 1] = item;
    }

    // Clear all history arrays
    function clearHistoryArrays() as Void {
        for (var i = 0; i < MAX_TRICK_HISTORY; i++) {
            tricksHistory[i] = null;
            grindsHistory[i] = null;
            jumpsHistory[i] = null;
        }
        
        for (var i = 0; i < MAX_SAMPLES; i++) {
            speedSamples[i] = 0.0;
            heartRateSamples[i] = 0;
            distanceCheckpoints[i] = 0.0;
        }
    }

    // Check for achievements during session
    function checkRealtimeAchievements() as Void {
        // First trick achievement
        if (totalTricks == 1) {
            unlockAchievement("First Trick", "Landed your first trick!");
        }
        
        // Multiple tricks milestones
        if (totalTricks == 10) {
            unlockAchievement("Trick Master", "Landed 10 tricks in one session!");
        }
        
        if (totalTricks == 25) {
            unlockAchievement("Trick Legend", "Landed 25 tricks in one session!");
        }
        
        // Grind achievements
        if (totalGrinds == 1) {
            unlockAchievement("First Grind", "Your first successful grind!");
        }
        
        if (longestGrindDuration > 3000) { // 3 seconds
            unlockAchievement("Grind King", "Grinded for more than 3 seconds!");
        }
        
        if (longestGrindDuration > 5000) { // 5 seconds
            unlockAchievement("Grind Legend", "Epic 5+ second grind!");
        }
    }

    // Check for end-of-session achievements
    function checkAchievements() as Void {
        var sessionTime = getSessionTime();
        
        // Time-based achievements
        if (sessionTime > 1800000) { // 30 minutes
            unlockAchievement("Endurance Skater", "Skated for 30+ minutes!");
        }
        
        if (sessionTime > 3600000) { // 1 hour
            unlockAchievement("Marathon Skater", "Skated for over 1 hour!");
        }
        
        // Distance achievements
        if (totalDistance > 5000) { // 5km
            unlockAchievement("Distance Cruiser", "Covered 5+ kilometers!");
        }
        
        if (totalDistance > 10000) { // 10km
            unlockAchievement("Long Distance Legend", "Covered 10+ kilometers!");
        }
        
        // Performance achievements
        if (maxSpeed > 8.33) { // 30 km/h
            unlockAchievement("Speed Demon", "Reached 30+ km/h!");
        }
        
        if (averageSpeed > 5.56) { // 20 km/h average
            unlockAchievement("Consistent Speed", "Maintained 20+ km/h average!");
        }
        
        // Combo achievements
        if (totalTricks >= 20 && sessionTime > 1800000) {
            unlockAchievement("Trick Marathon", "20+ tricks in 30+ minutes!");
        }
    }

    // Unlock achievement
    function unlockAchievement(title as String, description as String) as Void {
        var achievement = {
            "title" => title,
            "description" => description,
            "timestamp" => System.getTimer()
        };
        
        achievementsUnlocked.add(achievement);
        System.println("SessionStats: Achievement unlocked - " + title);
    }

    // Calculate final session statistics
    function calculateFinalStats() as Void {
        // Recalculate averages
        if (totalGrinds > 0) {
            averageGrindDuration = totalGrindTime.toFloat() / totalGrinds;
        }
        
        // Final average calculations
        averageSpeed = calculateArrayAverage(speedSamples);
        averageHeartRate = calculateArrayAverage(heartRateSamples);
        
        // Final calorie calculation
        updateCalorieEstimate();
    }

    // Get current session time in milliseconds
    function getSessionTime() as Number {
        if (!isSessionActive || sessionStartTime == null) {
            return 0;
        }
        
        var endTime = sessionEndTime != null ? sessionEndTime : System.getTimer();
        return endTime - sessionStartTime;
    }

    // Get session time in minutes
    function getSessionTimeMinutes() as Float {
        return getSessionTime().toFloat() / 60000.0;
    }

    // Get session time formatted as string
    function getSessionTimeString() as String {
        var totalMs = getSessionTime();
        var hours = (totalMs / 3600000).toNumber();
        var minutes = ((totalMs % 3600000) / 60000).toNumber();
        var seconds = ((totalMs % 60000) / 1000).toNumber();
        
        if (hours > 0) {
            return hours.format("%d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
        } else {
            return minutes.format("%d") + ":" + seconds.format("%02d");
        }
    }

    // Get comprehensive session data
    function getSessionData() as Dictionary {
        return {
            // Basic session info
            "startTime" => sessionStartTime,
            "endTime" => sessionEndTime,
            "totalTime" => getSessionTime(),
            "isActive" => isSessionActive,
            
            // Trick statistics
            "totalTricks" => totalTricks,
            "totalGrinds" => totalGrinds,
            "totalJumps" => totalJumps,
            "longestGrind" => longestGrindDuration,
            "shortestGrind" => shortestGrindDuration != 999999 ? shortestGrindDuration : 0,
            "averageGrind" => averageGrindDuration,
            "totalGrindTime" => totalGrindTime,
            
            // Performance metrics
            "maxSpeed" => maxSpeed,
            "averageSpeed" => averageSpeed,
            "totalDistance" => totalDistance,
            "maxHeartRate" => maxHeartRate,
            "averageHeartRate" => averageHeartRate,
            "caloriesBurned" => caloriesBurned,
            
            // Goals progress
            "tricksGoalProgress" => totalTricks.toFloat() / sessionGoals.get("targetTricks") * 100,
            "grindsGoalProgress" => totalGrinds.toFloat() / sessionGoals.get("targetGrinds") * 100,
            "distanceGoalProgress" => totalDistance / sessionGoals.get("targetDistance") * 100,
            "timeGoalProgress" => getSessionTime().toFloat() / sessionGoals.get("targetTime") * 100,
            
            // Achievements
            "achievementsCount" => achievementsUnlocked.size(),
            "achievements" => achievementsUnlocked
        };
    }

    // Get real-time display data for UI
    function getDisplayData() as Dictionary {
        return {
            "tricks" => totalTricks,
            "grinds" => totalGrinds,
            "jumps" => totalJumps,
            "longestGrind" => formatDuration(longestGrindDuration),
            "sessionTime" => getSessionTimeString(),
            "distance" => formatDistance(totalDistance),
            "speed" => formatSpeed(averageSpeed),
            "maxSpeed" => formatSpeed(maxSpeed),
            "heartRate" => averageHeartRate.toNumber(),
            "maxHeartRate" => maxHeartRate,
            "calories" => caloriesBurned
        };
    }

    // Get recent tricks for UI display
    function getRecentTricks(count as Number) as Array {
        var recentTricks = [];
        var startIndex = Math.max(0, MAX_TRICK_HISTORY - count);
        
        for (var i = startIndex; i < MAX_TRICK_HISTORY; i++) {
            if (tricksHistory[i] != null) {
                recentTricks.add(tricksHistory[i]);
            }
        }
        
        return recentTricks;
    }

    // Format duration in milliseconds to readable string
    function formatDuration(durationMs as Number) as String {
        if (durationMs < 1000) {
            return (durationMs / 100).toNumber().format("%d") + "." + (durationMs % 100).format("%02d") + "s";
        } else {
            var seconds = (durationMs / 1000.0);
            return seconds.format("%.1f") + "s";
        }
    }

    // Format distance in meters to readable string
    function formatDistance(distanceM as Float) as String {
        if (distanceM < 1000) {
            return distanceM.toNumber().format("%d") + "m";
        } else {
            var km = distanceM / 1000.0;
            return km.format("%.2f") + "km";
        }
    }

    // Format speed in m/s to km/h string
    function formatSpeed(speedMs as Float) as String {
        var speedKmh = speedMs * 3.6;
        return speedKmh.format("%.1f") + " km/h";
    }

    // Log session summary
    function logSessionSummary() as Void {
        System.println("=== SESSION SUMMARY ===");
        System.println("Duration: " + getSessionTimeString());
        System.println("Total Tricks: " + totalTricks + " (Grinds: " + totalGrinds + ", Jumps: " + totalJumps + ")");
        System.println("Longest Grind: " + formatDuration(longestGrindDuration));
        System.println("Distance: " + formatDistance(totalDistance));
        System.println("Max Speed: " + formatSpeed(maxSpeed));
        System.println("Avg Speed: " + formatSpeed(averageSpeed));
        System.println("Max HR: " + maxHeartRate + " bpm");
        System.println("Avg HR: " + averageHeartRate.toNumber() + " bpm");
        System.println("Calories: " + caloriesBurned);
        System.println("Achievements: " + achievementsUnlocked.size());
        System.println("======================");
    }

    // Set session goals
    function setSessionGoals(goals as Dictionary) as Void {
        if (goals.hasKey("targetTricks")) {
            sessionGoals.put("targetTricks", goals.get("targetTricks"));
        }
        if (goals.hasKey("targetGrinds")) {
            sessionGoals.put("targetGrinds", goals.get("targetGrinds"));
        }
        if (goals.hasKey("targetDistance")) {
            sessionGoals.put("targetDistance", goals.get("targetDistance"));
        }
        if (goals.hasKey("targetTime")) {
            sessionGoals.put("targetTime", goals.get("targetTime"));
        }
        
        System.println("SessionStats: Goals updated");
    }

    // Get session goals
    function getSessionGoals() as Dictionary {
        return sessionGoals;
    }

    // Check if session is active
    function isActive() as Boolean {
        return isSessionActive;
    }

    // Get performance rating (0-100)
    function getPerformanceRating() as Number {
        var rating = 0;
        
        // Tricks performance (40 points max)
        rating += Math.min(40, totalTricks * 4);
        
        // Speed performance (20 points max)
        if (maxSpeed > 5.56) { // 20 km/h
            rating += Math.min(20, (maxSpeed - 5.56) * 10);
        }
        
        // Endurance performance (20 points max)
        var sessionHours = getSessionTimeMinutes() / 60.0;
        rating += Math.min(20, sessionHours * 20);
        
        // Grind performance (20 points max)
        if (longestGrindDuration > 1000) {
            rating += Math.min(20, (longestGrindDuration - 1000) / 200);
        }
        
        return Math.min(100, rating).toNumber();
    }

    // Export session data for sharing/saving
    function exportSessionData() as Dictionary {
        var exportData = getSessionData();
        
        // Add detailed trick history
        exportData.put("tricksHistory", tricksHistory);
        exportData.put("grindsHistory", grindsHistory);
        exportData.put("jumpsHistory", jumpsHistory);
        
        // Add version info
        exportData.put("appVersion", "2.0.0");
        exportData.put("exportTime", System.getTimer());
        
        return exportData;
    }
}