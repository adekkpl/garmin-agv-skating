// ProgressView.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Progress and Goals Display View
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

class ProgressView extends WatchUi.View {
    
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
        
        System.println("ProgressView: Initialized");
    }
    
    function onLayout(dc) {
        // No layout file needed
    }
    
    function onShow() {
        System.println("ProgressView: View shown");
        WatchUi.requestUpdate();
    }
    
    function onHide() {
        System.println("ProgressView: View hidden");
    }
    
    function onUpdate(dc) {
        try {
            System.println("ProgressView: Updating display");
            
            // Clear screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw header
            drawHeader(dc);
            
            // Draw session goals
            drawSessionGoals(dc);
            
            // Draw achievements
            drawAchievements(dc);
            
        } catch (exception) {
            System.println("ProgressView: Error in onUpdate: " + exception.getErrorMessage());
            drawErrorMessage(dc, "Display Error");
        }
    }
    
    // Draw view header
    function drawHeader(dc) {
        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 5, Graphics.FONT_TINY, "PROGRESS", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Session indicator
        var sessionManager = app.getSessionManager();
        var statusColor = Graphics.COLOR_RED;
        
        if (sessionManager != null && sessionManager.isActive()) {
            statusColor = Graphics.COLOR_GREEN;
        }
        
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, 25, 6);
    }
    
    // Draw session goals and progress
    function drawSessionGoals(dc) {
        var yPos = 50;
        var lineHeight = 25;
        
        // Session time goal
        var sessionDuration = 0;
        var sessionManager = app.getSessionManager();
        if (sessionManager != null) {
            sessionDuration = sessionManager.getSessionDuration() / 1000; // Convert to seconds
        }
        
        var timeGoal = 30 * 60; // 30 minutes goal
        var timeProgress = sessionDuration / timeGoal * 100;
        if (timeProgress > 100) { timeProgress = 100; }
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Time Goal:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   timeProgress.format("%.0f") + "%", Graphics.TEXT_JUSTIFY_RIGHT);
        
        // Draw progress bar
        drawProgressBar(dc, 20, yPos + 15, screenWidth - 40, 4, timeProgress, Graphics.COLOR_BLUE);
        yPos += lineHeight + 10;
        
        // Tricks goal
        var tricksGoal = 10;
        var totalTricks = 0;
        var trickDetector = app.getTrickDetector();
        if (trickDetector != null) {
            var stats = trickDetector.getDetectionStats();
            if (stats != null) {
                totalTricks = stats.get("totalTricks");
            }
        }
        
        var trickProgress = totalTricks / tricksGoal * 100;
        if (trickProgress > 100) { trickProgress = 100; }
        
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Tricks Goal:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   totalTricks + "/" + tricksGoal, Graphics.TEXT_JUSTIFY_RIGHT);
        
        drawProgressBar(dc, 20, yPos + 15, screenWidth - 40, 4, trickProgress, Graphics.COLOR_ORANGE);
        yPos += lineHeight + 10;
        
        // Distance goal
        var distanceGoal = 2000.0; // 2km goal
        var currentDistance = 0.0;
        var gpsTracker = app.getGPSTracker();
        if (gpsTracker != null) {
            currentDistance = gpsTracker.getSessionDistance();
        }
        
        var distanceProgress = currentDistance / distanceGoal * 100;
        if (distanceProgress > 100) { distanceProgress = 100; }
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Distance Goal:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   distanceProgress.format("%.0f") + "%", Graphics.TEXT_JUSTIFY_RIGHT);
        
        drawProgressBar(dc, 20, yPos + 15, screenWidth - 40, 4, distanceProgress, Graphics.COLOR_GREEN);
    }
    
    // Draw achievement indicators
    function drawAchievements(dc) {
        var yPos = screenHeight - 80;
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yPos, Graphics.FONT_TINY, "ACHIEVEMENTS", Graphics.TEXT_JUSTIFY_CENTER);
        yPos += 20;
        
        // Simple achievement indicators
        var achievements = getAchievements();
        if (achievements != null && achievements.size() > 0) {
            var xPos = 30;
            var spacing = (screenWidth - 60) / 4;
            
            // FIXED: Cast achievements to proper array type
            var achievementsArray = achievements as Lang.Array<Lang.Dictionary>;
            var maxCount = achievementsArray.size() < 4 ? achievementsArray.size() : 4;
            
            for (var i = 0; i < maxCount; i++) {
                // FIXED: Direct access to typed array
                var achievement = achievementsArray[i];
                var unlocked = achievement.get("unlocked") as Lang.Boolean;
                var symbol = achievement.get("symbol") as Lang.String;
                var color = unlocked ? Graphics.COLOR_YELLOW : Graphics.COLOR_DK_GRAY;
                
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(xPos + i * spacing, yPos, 8);
                
                // Achievement symbol
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.drawText(xPos + i * spacing, yPos - 5, Graphics.FONT_XTINY, 
                        symbol, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }
    
    // Get current achievements
    function getAchievements() {
        var achievements = [];
        
        // First trick achievement
        var trickDetector = app.getTrickDetector();
        var totalTricks = 0;
        if (trickDetector != null) {
            var stats = trickDetector.getDetectionStats();
            if (stats != null) {
                totalTricks = stats.get("totalTricks");
            }
        }
        
        achievements.add({
            "name" => "First Trick",
            "symbol" => "1",
            "unlocked" => totalTricks > 0
        });
        
        achievements.add({
            "name" => "Trick Master",
            "symbol" => "T",
            "unlocked" => totalTricks >= 10
        });
        
        // Session time achievement
        var sessionDuration = 0;
        var sessionManager = app.getSessionManager();
        if (sessionManager != null) {
            sessionDuration = sessionManager.getSessionDuration() / 1000;
        }
        
        achievements.add({
            "name" => "Long Session",
            "symbol" => "L",
            "unlocked" => sessionDuration >= 1800 // 30 minutes
        });
        
        // Distance achievement
        var distance = 0.0;
        var gpsTracker = app.getGPSTracker();
        if (gpsTracker != null) {
            distance = gpsTracker.getSessionDistance();
        }
        
        achievements.add({
            "name" => "Distance",
            "symbol" => "D",
            "unlocked" => distance >= 1000 // 1km
        });
        
        return achievements;
    }
    
    // Draw progress bar
    function drawProgressBar(dc, x, y, width, height, progress, color) {
        // Background
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, width, height);
        
        // Progress fill
        var fillWidth = (width * progress / 100).toNumber();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, fillWidth, height);
        
        // Border
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, width, height);
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
            System.println("ProgressView: Trick detected - " + trickType);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("ProgressView: Error in onTrickDetected: " + exception.getErrorMessage());
        }
    }
    
    function onRotationDetected(direction, angle) {
        try {
            System.println("ProgressView: Rotation detected - " + direction + " " + angle + "°");
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("ProgressView: Error in onRotationDetected: " + exception.getErrorMessage());
        }
    }
    
    function onSessionStateChange(newState) {
        try {
            System.println("ProgressView: Session state changed to " + newState);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("ProgressView: Error in onSessionStateChange: " + exception.getErrorMessage());
        }
    }
    
    // Cleanup
    function cleanup() {
        System.println("ProgressView: Cleanup completed");
    }
}