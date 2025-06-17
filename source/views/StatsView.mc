// StatsView.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Session Statistics Display View
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

class StatsView extends WatchUi.View {
    
    var app;
    var screenWidth;
    var screenHeight;
    var centerX;
    var centerY;
    
    function initialize(appRef) {
        View.initialize();
        app = appRef;
        
        // Get screen dimensions
        var deviceSettings = System.getDeviceSettings();
        screenWidth = deviceSettings.screenWidth;
        screenHeight = deviceSettings.screenHeight;
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
        
        System.println("StatsView: Initialized");
    }
    
    function onLayout(dc) {
        // No layout file needed
    }
    
    function onShow() {
        System.println("StatsView: View shown");
        WatchUi.requestUpdate();
    }
    
    function onHide() {
        System.println("StatsView: View hidden");
    }
    
    function onUpdate(dc) {
        try {
            System.println("StatsView: Updating display");
            
            // Clear screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw header
            drawHeader(dc);
            
            // Draw session statistics
            drawSessionStats(dc);
            
            // Draw performance metrics
            drawPerformanceMetrics(dc);
            
        } catch (exception) {
            System.println("StatsView: Error in onUpdate: " + exception.getErrorMessage());
            drawErrorMessage(dc, "Display Error");
        }
    }
    
    // Draw view header
    function drawHeader(dc) {
        
        // Session status
        var sessionManager = app.getSessionManager();
        
        var statusColor = Graphics.COLOR_WHITE;
        var stateText = "STOPPED";        
        if (sessionManager != null) {
            //timeText = sessionManager.getFormattedDuration();
            stateText = sessionManager.getStateString();
            
            // Color code based on session state
            if (sessionManager.isActive()) {
                statusColor = Graphics.COLOR_GREEN;
            } else if (sessionManager.isPaused()) {
                statusColor = Graphics.COLOR_YELLOW;
            } else {
                statusColor = Graphics.COLOR_WHITE;
            }
        }
        /* 
        //var statusText = "STOPPED";
        //var statusColor = Graphics.COLOR_RED;
        if (sessionManager != null) {
            statusText = sessionManager.getStateString();
            
            if (sessionManager.isActive()) {
                statusColor = Graphics.COLOR_GREEN;
            } else if (sessionManager.isPaused()) {
                statusColor = Graphics.COLOR_YELLOW;
            }
        } */
        
        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 5, Graphics.FONT_TINY, "STATS", Graphics.TEXT_JUSTIFY_CENTER);

        // Status indicator
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, 25, 6);
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 35, Graphics.FONT_TINY, stateText, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw session statistics
    function drawSessionStats(dc) {
        var sessionStats = app.getSessionStats();
        var displayData = null;
        
        if (sessionStats != null) {
            displayData = sessionStats.getDisplayData();
        }
        
        var yPos = 90;
        var lineHeight = 40;
        
        // Distance
        var distance = displayData != null ? displayData.get("distance") : 0.0;
        var distanceText = formatDistance(distance);
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Distance:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   distanceText, Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Speed
        var gpsTracker = app.getGPSTracker();
        var currentSpeed = 0.0;
        var maxSpeed = 0.0;
        var avgSpeed = 0.0;
        
        if (gpsTracker != null) {
            var gpsData = gpsTracker.getGPSData();
            if (gpsData != null) {
                currentSpeed = gpsData.get("currentSpeed");
                maxSpeed = gpsData.get("maxSpeed");
                avgSpeed = gpsData.get("averageSpeed");
            }
        }
        
        // Current speed
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Speed:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   formatSpeed(currentSpeed), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Max speed
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Max Speed:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   formatSpeed(maxSpeed), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Average speed
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Avg Speed:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   formatSpeed(avgSpeed), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Calories
        var calories = displayData != null ? displayData.get("calories") : 0;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Calories:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   calories.toString(), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Heart rate
        var sensorManager = app.getSensorManager();
        var heartRate = 0;
        var avgHeartRate = 0;
        var maxHeartRate = 0;
        
        if (sensorManager != null) {
            var sensorData = sensorManager.getCurrentSensorData();
            if (sensorData != null) {
                var hr = sensorData.get("heartRate");
                if (hr != null) {
                    heartRate = hr;
                }
                
                var avgHr = sensorData.get("averageHeartRate");
                if (avgHr != null) {
                    avgHeartRate = avgHr;
                }
                
                var maxHr = sensorData.get("maxHeartRate");
                if (maxHr != null) {
                    maxHeartRate = maxHr;
                }
            }
        }
        
        // Current heart rate
        dc.setColor(Graphics.COLOR_PINK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "HR:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   heartRate.toString() + " bpm", Graphics.TEXT_JUSTIFY_RIGHT);
    }
    
    // Draw performance metrics
    function drawPerformanceMetrics(dc) {
        var sessionStats = app.getSessionStats();
        var performanceRating = 0;
        
        if (sessionStats != null) {
            // Sprawdź czy metoda istnieje, jeśli nie - oblicz prostą ocenę
            try {
                performanceRating = sessionStats.getPerformanceRating();
            } catch (exception) {
                // Fallback - oblicz prostą ocenę na podstawie dostępnych danych
                performanceRating = calculateSimplePerformanceRating();
            }
        }
        
        // Performance rating at bottom
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 110, Graphics.FONT_TINY, 
                   "PERFORMANCE:", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Color code the rating
        var ratingColor = Graphics.COLOR_WHITE;
        if (performanceRating > 80) {
            ratingColor = Graphics.COLOR_GREEN;
        } else if (performanceRating > 60) {
            ratingColor = Graphics.COLOR_YELLOW;
        } else if (performanceRating > 40) {
            ratingColor = Graphics.COLOR_ORANGE;
        } else {
            ratingColor = Graphics.COLOR_RED;
        }
        
        dc.setColor(ratingColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 80, Graphics.FONT_SMALL, 
                   performanceRating.toString() + "/100", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Calculate simple performance rating based on available data
    function calculateSimplePerformanceRating() {
        var rating = 50; // Base rating
        
        try {
            // Add points for session duration
            var sessionManager = app.getSessionManager();
            if (sessionManager != null) {
                var duration = sessionManager.getSessionDuration() / 1000; // seconds
                if (duration > 1800) { // 30 minutes
                    rating += 20;
                } else if (duration > 900) { // 15 minutes
                    rating += 10;
                }
            }
            
            // Add points for tricks
            var trickDetector = app.getTrickDetector();
            if (trickDetector != null) {
                var stats = trickDetector.getDetectionStats();
                if (stats != null) {
                    var totalTricks = stats.get("totalTricks");
                    rating += min(totalTricks * 2, 30); // Use Utils.mc function
                }
            }
            
            // Ensure rating is within bounds
            if (rating > 100) { rating = 100; }
            if (rating < 0) { rating = 0; }
            
        } catch (exception) {
            System.println("StatsView: Error calculating performance rating: " + exception.getErrorMessage());
            rating = 50; // Default rating on error
        }
        
        return rating;
    }
    
    // Format distance for display
    function formatDistance(distance) {
        if (distance == null || distance == 0.0) {
            return "0 m";
        }
        
        if (distance < 1000.0) {
            return distance.format("%.0f") + " m";
        } else {
            return (distance / 1000.0).format("%.2f") + " km";
        }
    }
    
    // Format speed for display (m/s to km/h)
    function formatSpeed(speed) {
        if (speed == null || speed == 0.0) {
            return "0 km/h";
        }
        
        var kmh = speed * 3.6; // Convert m/s to km/h
        return kmh.format("%.1f") + " km/h";
    }
    
    // Draw error message
    function drawErrorMessage(dc, message) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 20, Graphics.FONT_SMALL, 
                   "ERROR", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY + 10, Graphics.FONT_TINY, 
                   message, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Event handlers
    function onTrickDetected(trickType, trickData) {
        try {
            System.println("StatsView: Trick detected - " + trickType);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("StatsView: Error in onTrickDetected: " + exception.getErrorMessage());
        }
    }
    
    function onRotationDetected(direction, angle) {
        try {
            System.println("StatsView: Rotation detected - " + direction + " " + angle + "°");
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("StatsView: Error in onRotationDetected: " + exception.getErrorMessage());
        }
    }
    
    function onSessionStateChange(newState) {
        try {
            System.println("StatsView: Session state changed to " + newState);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("StatsView: Error in onSessionStateChange: " + exception.getErrorMessage());
        }
    }
    
    // Cleanup
    function cleanup() {
        System.println("StatsView: Cleanup completed");
    }
}