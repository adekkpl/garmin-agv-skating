// GPSTracker.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Dedicated GPS Distance Tracking
using Toybox.Lang;
using Toybox.Position;
using Toybox.Math;
using Toybox.System;

class GPSTracker {
    
    // GPS state
    var isTracking = false;
    var isPaused = false;
    var lastPosition;
    var sessionDistance = 0.0;
    var totalDistance = 0.0;
    
    // Position history for accuracy
    var positionHistory as Lang.Array<Position.Location or Null>;
    const HISTORY_SIZE = 10;
    var historyIndex = 0;
    
    // Distance calculation
    var currentPosition;
    var lastValidPosition;
    var positionUpdateCallback;
    var accuracyThreshold = Position.QUALITY_GOOD;
    
    // Speed tracking
    var currentSpeed = 0.0;
    var maxSpeed = 0.0;
    var averageSpeed = 0.0;
    var speedSamples = 0;
    var totalSpeedSum = 0.0;
    
    // GPS status
    var gpsQuality = Position.QUALITY_NOT_AVAILABLE;
    var lastPositionTime;
    
    function initialize() {
        positionHistory = new Lang.Array<Position.Location or Null>[HISTORY_SIZE];
        for (var i = 0; i < HISTORY_SIZE; i++) {
            positionHistory[i] = null;
        }
        
        lastPosition = null;
        lastValidPosition = null;
        lastPositionTime = null;
        
        System.println("GPSTracker: Initialized");
    }
    
    // Start GPS tracking
    function startTracking() {
        try {
            if (isTracking) {
                System.println("GPSTracker: Already tracking");
                return true;
            }
            
            // Reset session data
            sessionDistance = 0.0;
            currentSpeed = 0.0;
            maxSpeed = 0.0;
            averageSpeed = 0.0;
            speedSamples = 0;
            totalSpeedSum = 0.0;
            
            // Clear position history
            for (var i = 0; i < HISTORY_SIZE; i++) {
                positionHistory[i] = null;
            }
            historyIndex = 0;
            
            // Enable GPS
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
            isTracking = true;
            isPaused = false;
            
            System.println("GPSTracker: Tracking started");
            return true;
            
        } catch (exception) {
            System.println("GPSTracker: Error starting tracking: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Pause GPS tracking (keep GPS on but don't accumulate distance)
    function pauseTracking() {
        try {
            if (!isTracking || isPaused) {
                System.println("GPSTracker: Cannot pause - not tracking or already paused");
                return false;
            }
            
            isPaused = true;
            System.println("GPSTracker: Tracking paused");
            return true;
            
        } catch (exception) {
            System.println("GPSTracker: Error pausing tracking: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Resume GPS tracking
    function resumeTracking() {
        try {
            if (!isTracking || !isPaused) {
                System.println("GPSTracker: Cannot resume - not tracking or not paused");
                return false;
            }
            
            isPaused = false;
            lastValidPosition = null; // Reset to avoid distance jump
            System.println("GPSTracker: Tracking resumed");
            return true;
            
        } catch (exception) {
            System.println("GPSTracker: Error resuming tracking: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Stop GPS tracking
    function stopTracking() {
        try {
            if (!isTracking) {
                System.println("GPSTracker: Not tracking");
                return true;
            }
            
            // Disable GPS
            Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
            isTracking = false;
            isPaused = false;
            
            System.println("GPSTracker: Tracking stopped - Total distance: " + sessionDistance.format("%.2f") + "m");
            return true;
            
        } catch (exception) {
            System.println("GPSTracker: Error stopping tracking: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // GPS position callback
    function onPosition(info as Position.Info) as Void {
        try {
            if (!isTracking || isPaused) {
                return;
            }
            
            var position = info.position;
            var accuracy = info.accuracy;
            
            if (position == null) {
                System.println("GPSTracker: No position data");
                return;
            }
            
            // Update GPS quality
            gpsQuality = accuracy;
            lastPositionTime = System.getTimer();
            
            // Check if accuracy is good enough
            if (accuracy < accuracyThreshold) {
                System.println("GPSTracker: Poor GPS accuracy: " + accuracy);
                return;
            }
            
            // Add to position history
            addToHistory(position);
            
            // Calculate distance if we have a valid previous position
            if (lastValidPosition != null) {
                var distance = calculateDistance(lastValidPosition, position);
                
                // Sanity check - ignore huge jumps (probably GPS errors)
                if (distance < 100.0) { // Max 100m between readings
                    sessionDistance += distance;
                    totalDistance += distance;
                    
                    // Calculate speed
                    var speed = info.speed;
                    if (speed != null && speed >= 0) {
                        currentSpeed = speed;
                        if (speed > maxSpeed) {
                            maxSpeed = speed;
                        }
                        
                        // Update average speed
                        totalSpeedSum += speed;
                        speedSamples++;
                        averageSpeed = totalSpeedSum / speedSamples;
                    }
                    
                    System.println("GPSTracker: Distance += " + distance.format("%.2f") + "m, Total: " + sessionDistance.format("%.2f") + "m");
                }
            }
            
            lastValidPosition = position;
            lastPosition = position;
            
            // Notify callback
            if (positionUpdateCallback != null) {
                positionUpdateCallback.invoke(position);
            }
            
        } catch (exception) {
            System.println("GPSTracker: Error in onPosition: " + exception.getErrorMessage());
        }
    }
    
    // Add position to history for smoothing
    function addToHistory(position) {
        var history = positionHistory as Lang.Array<Position.Location or Null>;
        history[historyIndex] = position;
        historyIndex = (historyIndex + 1) % HISTORY_SIZE;
    }
    
    // Calculate distance between two positions using Haversine formula
    function calculateDistance(pos1, pos2) {
        if (pos1 == null || pos2 == null) {
            return 0.0;
        }
        
        try {
            // FIXED: Cast toDegrees() results to proper array type
            var coords1 = pos1.toDegrees() as Lang.Array<Lang.Double>;
            var coords2 = pos2.toDegrees() as Lang.Array<Lang.Double>;
            
            var lat1 = coords1[0] * Math.PI / 180.0;
            var lon1 = coords1[1] * Math.PI / 180.0;
            var lat2 = coords2[0] * Math.PI / 180.0;
            var lon2 = coords2[1] * Math.PI / 180.0;
            
            var dlat = lat2 - lat1;
            var dlon = lon2 - lon1;
            
            var a = Math.sin(dlat / 2) * Math.sin(dlat / 2) +
                    Math.cos(lat1) * Math.cos(lat2) *
                    Math.sin(dlon / 2) * Math.sin(dlon / 2);
            
            var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            var earthRadius = 6371000; // Earth radius in meters
            
            return earthRadius * c;
            
        } catch (exception) {
            System.println("GPSTracker: Error calculating distance: " + exception.getErrorMessage());
            return 0.0;
        }
    }
    
    // Get smoothed position (average of recent positions)
    function getSmoothedPosition() {
        var validPositions = 0;
        var latSum = 0.0;
        var lonSum = 0.0;
        
        var history = positionHistory as Lang.Array<Position.Location or Null>;
        
        for (var i = 0; i < HISTORY_SIZE; i++) {
            if (history[i] != null) {
                // FIXED: Cast toDegrees() result to proper array type
                var coords = history[i].toDegrees() as Lang.Array<Lang.Double>;
                latSum += coords[0];
                lonSum += coords[1];
                validPositions++;
            }
        }
        
        if (validPositions > 0) {
            // REMOVED: unused variables avgLat and avgLon
            // var avgLat = latSum / validPositions;
            // var avgLon = lonSum / validPositions;
            
            // W Garmin Connect IQ nie możemy tworzyć nowych objektów Position
            // Zwrócimy ostatnią znaną pozycję jako najlepsze przybliżenie
            return lastPosition;
        }
        
        return lastPosition;
    }
    
    // Getters
    function getSessionDistance() {
        return sessionDistance;
    }
    
    function getTotalDistance() {
        return totalDistance;
    }
    
    function getCurrentSpeed() {
        return currentSpeed;
    }
    
    function getMaxSpeed() {
        return maxSpeed;
    }
    
    function getAverageSpeed() {
        return averageSpeed;
    }
    
    function getCurrentPosition() {
        return lastPosition;
    }
    
    function getGPSQuality() {
        return gpsQuality;
    }
    
    function isGPSReady() {
        return gpsQuality >= accuracyThreshold;
    }
    
    /* function getGPSQualityString() {
        switch (gpsQuality) {
            case Position.QUALITY_NOT_AVAILABLE:
                return "NO GPS";
            case Position.QUALITY_LAST_KNOWN:
                return "LAST KNOWN";
            case Position.QUALITY_POOR:
                return "POOR";
            case Position.QUALITY_USABLE:
                return "USABLE";
            case Position.QUALITY_GOOD:
                return "GOOD";
            default:
                return "UNKNOWN";
        }
    } */
    function getGPSQualityString() {
        // Simple GPS quality indicator
        if (isTracking && currentPosition != null) {
            return "Good";
        } else if (isTracking) {
            return "Searching";
        } else {
            return "Disabled";
        }
    }
    
    // Status methods
    function isTrackingActive() {
        return isTracking && !isPaused;
    }
    
    function getTrackingState() {
        if (!isTracking) {
            return "STOPPED";
        } else if (isPaused) {
            return "PAUSED";
        } else {
            return "ACTIVE";
        }
    }
    
    // Set callback for position updates
    function setPositionUpdateCallback(callback) {
        positionUpdateCallback = callback;
    }
    
    // Set accuracy threshold
    function setAccuracyThreshold(threshold) {
        accuracyThreshold = threshold;
        System.println("GPSTracker: Accuracy threshold set to " + threshold);
    }
    
    // Get GPS data for display
    function getGPSData() {
        return {
            "sessionDistance" => sessionDistance,
            "totalDistance" => totalDistance,
            "currentSpeed" => currentSpeed,
            "maxSpeed" => maxSpeed,
            "averageSpeed" => averageSpeed,
            "gpsQuality" => gpsQuality,
            "isReady" => isGPSReady(),
            "isTracking" => isTracking,
            "isPaused" => isPaused,
            "position" => lastPosition
        };
    }
    
    // Reset session data
    function resetSessionData() {
        sessionDistance = 0.0;
        currentSpeed = 0.0;
        maxSpeed = 0.0;
        averageSpeed = 0.0;
        speedSamples = 0;
        totalSpeedSum = 0.0;
        System.println("GPSTracker: Session data reset");
    }
    
    // Cleanup
    function cleanup() {
        try {
            if (isTracking) {
                stopTracking();
            }
            System.println("GPSTracker: Cleanup completed");
        } catch (exception) {
            System.println("GPSTracker: Error during cleanup: " + exception.getErrorMessage());
        }
    }
}