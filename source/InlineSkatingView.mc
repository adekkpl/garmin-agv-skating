//InlineSkatingView.mc
// Garmin Aggressive Inline Skating Tracker v2.0.0
// Main Application View
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Application;
using Toybox.Math;

class InlineSkatingView extends WatchUi.View {
    
    // Display modes - jako stałe klasowe
    const MODE_MAIN = 0;
    const MODE_TRICKS = 1;
    const MODE_PERFORMANCE = 2;
    const MODE_SESSION = 3;
    
    var currentDisplayMode;
    var app;
    var lastUpdateTime;
    
    // UI elements and positioning
    var screenWidth;
    var screenHeight;
    var centerX;
    var centerY;
    
    // Data refresh flags
    var needsFullRedraw = true;
    var dataChanged = false;
    
    // Animation and visual effects
    var trickAnimationCounter = 0;
    var achievementShowTime = 0;
    var lastAchievement;
    
    function initialize() {
        View.initialize();
        currentDisplayMode = MODE_MAIN;
        // Poprawka: Bezpieczne uzyskanie referencji do aplikacji
        try {
            app = Application.getApp();
            System.println("InlineSkatingView: App reference obtained successfully");
        } catch (exception) {
            System.println("InlineSkatingView: Failed to get app reference: " + exception.getErrorMessage());
            app = null;
        }
        lastUpdateTime = System.getTimer();
        System.println("InlineSkatingView: View initialized");
    }

    // Load resources and setup layout
    function onLayout(dc as Graphics.Dc) as Void {
        // Get screen dimensions
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
        
        System.println("InlineSkatingView: Layout initialized - " + screenWidth + "x" + screenHeight);
    }

    // Called when view is shown
    function onShow() as Void {
        System.println("InlineSkatingView: View shown");
        needsFullRedraw = true;
        
        // Poprawka: Bezpieczne uzyskanie referencji jeśli wcześniej się nie udało
        if (app == null) {
            try {
                app = Application.getApp();
                System.println("InlineSkatingView: App reference obtained in onShow");
            } catch (exception) {
                System.println("InlineSkatingView: Still cannot get app reference: " + exception.getErrorMessage());
            }
        }
        
        // Setup sensor data callback if app is available
        if (app != null) {
            try {
                var sensorManager = app.getSensorManager();
                if (sensorManager != null) {
                    sensorManager.setDataUpdateCallback(method(:onSensorDataUpdate));
                    System.println("InlineSkatingView: Sensor callback set");
                }
                
                // Setup trick detection callback
                var trickDetector = app.getTrickDetector();
                if (trickDetector != null) {
                    trickDetector.setTrickDetectedCallback(method(:onTrickDetected));
                    System.println("InlineSkatingView: Trick detection callback set");
                }
            } catch (exception) {
                System.println("InlineSkatingView: Error setting up callbacks: " + exception.getErrorMessage());
            }
        }
    }

    // Called when view is hidden
    function onHide() as Void {
        System.println("InlineSkatingView: View hidden");
    }

    // Main update function
    function onUpdate(dc as Graphics.Dc) as Void {
        System.println("InlineSkatingView: onUpdate called - mode: " + currentDisplayMode);
        
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Check if we need full redraw
        if (needsFullRedraw) {
            drawBackground(dc);
            needsFullRedraw = false;
        }
        
        // Draw content based on current display mode
        switch (currentDisplayMode) {
            case MODE_MAIN:
                drawMainScreen(dc);
                break;
            case MODE_TRICKS:
                drawTricksScreen(dc);
                break;
            case MODE_PERFORMANCE:
                drawPerformanceScreen(dc);
                break;
            case MODE_SESSION:
                drawSessionScreen(dc);
                break;
            default:
                drawErrorScreen(dc, "Unknown display mode: " + currentDisplayMode);
                break;
        }
        
        // Draw common elements
        drawStatusBar(dc);
        drawAnimations(dc);
        
        // Call parent update
        View.onUpdate(dc);
    }

    // Draw background elements
    function drawBackground(dc as Graphics.Dc) as Void {
        // Simple gradient background effect
        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, screenWidth, screenHeight / 4);
        
        // App title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 10, Graphics.FONT_TINY, "AGGRESSIVE SKATING", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Poprawka: Dodaj ekran błędu dla debugowania
    function drawErrorScreen(dc, errorMsg) as Void {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 20, Graphics.FONT_SMALL, "ERROR", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, Graphics.FONT_TINY, errorMsg, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Draw main screen with key metrics
    function drawMainScreen(dc as Graphics.Dc) as Void {
        System.println("InlineSkatingView: Drawing main screen");
        
        var sessionStats = null;
        var displayData = null;
        
        if (app != null) {
            try {
                sessionStats = app.getSessionStats();
                if (sessionStats != null) {
                    displayData = sessionStats.getDisplayData();
                }
            } catch (exception) {
                System.println("InlineSkatingView: Error getting session stats: " + exception.getErrorMessage());
            }
        }
        
        if (displayData == null) {
            drawNoDataMessage(dc);
            return;
        }
        
        // Session status indicator
        var isActive = sessionStats != null ? sessionStats.isActive() : false;
        dc.setColor(isActive ? Graphics.COLOR_GREEN : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(20, 30, 5);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(35, 25, Graphics.FONT_XTINY, isActive ? "ACTIVE" : "STOPPED", Graphics.TEXT_JUSTIFY_LEFT);
        
        // Main metrics in quadrants
        var fontSize = Graphics.FONT_MEDIUM;
        var smallFont = Graphics.FONT_SMALL;
        
        // Top left - Tricks count
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX / 2, centerY - 40, fontSize, displayData.get("tricks").toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX / 2, centerY - 20, Graphics.FONT_XTINY, "TRICKS", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Top right - Session time
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + centerX / 2, centerY - 40, fontSize, displayData.get("sessionTime"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + centerX / 2, centerY - 20, Graphics.FONT_XTINY, "TIME", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Center - Heart rate (if available)
        var heartRate = displayData.get("heartRate");
        if (heartRate != null && heartRate > 0) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY + 5, Graphics.FONT_LARGE, heartRate.toString(), Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY + 25, Graphics.FONT_XTINY, "BPM", Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Bottom left - Grinds
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX / 2, centerY + 50, smallFont, displayData.get("grinds").toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX / 2, centerY + 70, Graphics.FONT_XTINY, "GRINDS", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Bottom right - Speed
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + centerX / 2, centerY + 50, smallFont, displayData.get("speed"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + centerX / 2, centerY + 70, Graphics.FONT_XTINY, "SPEED", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Bottom center - Distance
        dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 40, smallFont, displayData.get("distance"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 25, Graphics.FONT_XTINY, "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Draw tricks screen with detailed trick stats
    function drawTricksScreen(dc as Graphics.Dc) as Void {
        var sessionStats = app != null ? app.getSessionStats() : null;
        var displayData = sessionStats != null ? sessionStats.getDisplayData() : null;
        var trickDetector = app != null ? app.getTrickDetector() : null;
        
        if (displayData == null) {
            drawNoDataMessage(dc);
            return;
        }
        
        // Screen title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 30, Graphics.FONT_SMALL, "TRICK DETAILS", Graphics.TEXT_JUSTIFY_CENTER);
        
        var yPos = 60;
        var lineHeight = 25;
        
        // Total tricks
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Total Tricks:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, displayData.get("tricks").toString(), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Grinds breakdown
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Grinds:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, displayData.get("grinds").toString(), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Longest grind
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Longest Grind:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, displayData.get("longestGrind"), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Jumps
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Jumps:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, displayData.get("jumps").toString(), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Detection state (if available)
        if (trickDetector != null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(20, yPos, Graphics.FONT_TINY, "State:", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, trickDetector.getCurrentStateString(), Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    // Draw performance screen
    function drawPerformanceScreen(dc as Graphics.Dc) as Void {
        var sessionStats = app != null ? app.getSessionStats() : null;
        var displayData = sessionStats != null ? sessionStats.getDisplayData() : null;
        
        if (displayData == null) {
            drawNoDataMessage(dc);
            return;
        }
        
        // Screen title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 30, Graphics.FONT_SMALL, "PERFORMANCE", Graphics.TEXT_JUSTIFY_CENTER);
        
        var yPos = 60;
        var lineHeight = 22;
        
        // Speed metrics
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Speed:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, displayData.get("speed"), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Max Speed:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, displayData.get("maxSpeed"), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight + 5;
        
        // Heart rate metrics
        var heartRate = displayData.get("heartRate");
        if (heartRate != null && heartRate > 0) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(20, yPos, Graphics.FONT_SMALL, "Heart Rate:", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, heartRate.toString() + " bpm", Graphics.TEXT_JUSTIFY_RIGHT);
            yPos += lineHeight;
            
            dc.drawText(20, yPos, Graphics.FONT_TINY, "Max HR:", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, displayData.get("maxHeartRate").toString() + " bpm", Graphics.TEXT_JUSTIFY_RIGHT);
            yPos += lineHeight + 5;
        }
        
        // Calories
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Calories:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, displayData.get("calories").toString(), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Performance rating
        if (sessionStats != null) {
            var rating = sessionStats.getPerformanceRating();
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(20, yPos, Graphics.FONT_SMALL, "Rating:", Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, rating.toString() + "/100", Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    // Draw session overview screen
    function drawSessionScreen(dc as Graphics.Dc) as Void {
        var sessionStats = app != null ? app.getSessionStats() : null;
        
        if (sessionStats == null) {
            drawNoDataMessage(dc);
            return;
        }
        
        var sessionData = sessionStats.getSessionData();
        
        // Screen title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 30, Graphics.FONT_SMALL, "SESSION OVERVIEW", Graphics.TEXT_JUSTIFY_CENTER);
        
        var yPos = 60;
        var lineHeight = 20;
        
        // Session status
        var isActive = sessionData.get("isActive");
        dc.setColor(isActive ? Graphics.COLOR_GREEN : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yPos, Graphics.FONT_SMALL, isActive ? "SESSION ACTIVE" : "SESSION STOPPED", Graphics.TEXT_JUSTIFY_CENTER);
        yPos += lineHeight + 10;
        
        // Goals progress (if session is active)
        if (isActive) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(20, yPos, Graphics.FONT_TINY, "Goals Progress:", Graphics.TEXT_JUSTIFY_LEFT);
            yPos += 15;
            
            // Tricks goal
            var tricksProgress = sessionData.get("tricksGoalProgress");
            drawProgressBar(dc, 20, yPos, screenWidth - 40, 8, tricksProgress, Graphics.COLOR_YELLOW);
            dc.drawText(25, yPos - 12, Graphics.FONT_XTINY, "Tricks", Graphics.TEXT_JUSTIFY_LEFT);
            yPos += 20;
            
            // Distance goal
            var distanceProgress = sessionData.get("distanceGoalProgress");
            drawProgressBar(dc, 20, yPos, screenWidth - 40, 8, distanceProgress, Graphics.COLOR_PURPLE);
            dc.drawText(25, yPos - 12, Graphics.FONT_XTINY, "Distance", Graphics.TEXT_JUSTIFY_LEFT);
            yPos += 25;
        }
        
        // Achievements
        var achievementsCount = sessionData.get("achievementsCount");
        if (achievementsCount > 0) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(20, yPos, Graphics.FONT_SMALL, "Achievements: " + achievementsCount, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    // Draw progress bar
    function drawProgressBar(dc, x, y, width, height, progress, color) {
        // Background
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, width, height);
        
        // Progress fill
        var fillWidth = (width * min(progress, 100) / 100).toNumber();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, fillWidth, height);
        
        // Border
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, width, height);
        
        // Percentage text
        dc.drawText(x + width + 5, y - 3, Graphics.FONT_XTINY, progress.toNumber().toString() + "%", Graphics.TEXT_JUSTIFY_LEFT);
    }

    // Draw status bar with common indicators
    function drawStatusBar(dc as Graphics.Dc) as Void {
        var yPos = screenHeight - 15;
        
        // GPS status
        var sensorManager = app != null ? app.getSensorManager() : null;
        if (sensorManager != null) {
            var sensorStatus = sensorManager.getSensorStatus();
            
            // GPS indicator
            dc.setColor(sensorStatus.get("gps") ? Graphics.COLOR_GREEN : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(20, yPos, 3);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(30, yPos - 5, Graphics.FONT_XTINY, "GPS", Graphics.TEXT_JUSTIFY_LEFT);
            
            // Heart rate indicator
            dc.setColor(sensorStatus.get("heartRate") ? Graphics.COLOR_GREEN : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(60, yPos, 3);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(70, yPos - 5, Graphics.FONT_XTINY, "HR", Graphics.TEXT_JUSTIFY_LEFT);
        }
        
        // Mode indicator
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var modeText = "";
        switch (currentDisplayMode) {
            case MODE_MAIN:
                modeText = "MAIN";
                break;
            case MODE_TRICKS:
                modeText = "TRICKS";
                break;
            case MODE_PERFORMANCE:
                modeText = "PERF";
                break;
            case MODE_SESSION:
                modeText = "SESSION";
                break;
        }
        dc.drawText(screenWidth - 20, yPos - 5, Graphics.FONT_XTINY, modeText, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // Draw animations and visual effects
    function drawAnimations(dc as Graphics.Dc) as Void {
        // Trick detection animation
        if (trickAnimationCounter > 0) {
            var alpha = trickAnimationCounter / 30.0; // Fade out over 30 frames
            var radius = (30 - trickAnimationCounter) * 2;
            
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(centerX, centerY, radius);
            dc.drawText(centerX, centerY - 10, Graphics.FONT_SMALL, "TRICK!", Graphics.TEXT_JUSTIFY_CENTER);
            
            trickAnimationCounter--;
        }
        
        // Achievement notification
        if (achievementShowTime > 0 && lastAchievement != null) {
            var bgColor = Graphics.COLOR_DK_BLUE;
            var textColor = Graphics.COLOR_YELLOW;
            
            // Achievement banner
            dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(10, centerY - 30, screenWidth - 20, 60);
            dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(10, centerY - 30, screenWidth - 20, 60);
            
            // Achievement text
            dc.drawText(centerX, centerY - 20, Graphics.FONT_SMALL, "ACHIEVEMENT!", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, centerY, Graphics.FONT_TINY, lastAchievement.get("title"), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, centerY + 15, Graphics.FONT_XTINY, lastAchievement.get("description"), Graphics.TEXT_JUSTIFY_CENTER);
            
            achievementShowTime--;
        }
    }

    // Draw message when no data is available
    function drawNoDataMessage(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 20, Graphics.FONT_SMALL, "NO DATA", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, centerY, Graphics.FONT_TINY, "Start a session to", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, centerY + 15, Graphics.FONT_TINY, "begin tracking", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Start button hint
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY + 40, Graphics.FONT_TINY, "Press START to begin", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Sensor data update callback
    function onSensorDataUpdate(sensorData) {
        // Update session statistics with new sensor data
        var sessionStats = app != null ? app.getSessionStats() : null;
        if (sessionStats != null && sessionStats.isActive()) {
            sessionStats.updatePerformanceMetrics(sensorData);
        }
        
        // Feed data to trick detector
        var trickDetector = app != null ? app.getTrickDetector() : null;
        if (trickDetector != null) {
            trickDetector.analyzeSensorData(sensorData);
        }
        
        // Mark for UI update
        dataChanged = true;
        WatchUi.requestUpdate();
    }

    // Trick detection callback
    function onTrickDetected(trickType, trickData) {
        System.println("InlineSkatingView: Trick detected - " + trickType);
        
        // Start trick animation
        trickAnimationCounter = 30; // 30 frames of animation
        
        // Update statistics
        var sessionStats = app != null ? app.getSessionStats() : null;
        if (sessionStats != null) {
            sessionStats.addTrick(trickType, trickData);
        }
        
        // Check for new achievements
        checkForNewAchievements();
        
        // Request immediate UI update
        WatchUi.requestUpdate();
    }

    // Check for new achievements and show notification
    function checkForNewAchievements() as Void {
        var sessionStats = app != null ? app.getSessionStats() : null;
        if (sessionStats == null) {
            return;
        }
        
        var sessionData = sessionStats.getSessionData();
        var achievements = sessionData.get("achievements");
        
        if (achievements != null && achievements.size() > 0) {
            var latestAchievement = achievements[achievements.size() - 1];
            
            // Check if this is a new achievement
            if (lastAchievement == null || 
                !latestAchievement.get("title").equals(lastAchievement.get("title"))) {
                
                lastAchievement = latestAchievement;
                achievementShowTime = 180; // Show for ~3 seconds at 60fps
                
                System.println("InlineSkatingView: New achievement - " + latestAchievement.get("title"));
            }
        }
    }

    // Change display mode
    function switchDisplayMode() as Void {
        switch (currentDisplayMode) {
            case MODE_MAIN:
                currentDisplayMode = MODE_TRICKS;
                break;
            case MODE_TRICKS:
                currentDisplayMode = MODE_PERFORMANCE;
                break;
            case MODE_PERFORMANCE:
                currentDisplayMode = MODE_SESSION;
                break;
            case MODE_SESSION:
                currentDisplayMode = MODE_MAIN;
                break;
        }
        
        needsFullRedraw = true;
        WatchUi.requestUpdate();
        
        System.println("InlineSkatingView: Switched to mode - " + getCurrentModeString());
    }

    // Get current display mode as string
    function getCurrentModeString() {
        switch (currentDisplayMode) {
            case MODE_MAIN:
                return "MAIN";
            case MODE_TRICKS:
                return "TRICKS";
            case MODE_PERFORMANCE:
                return "PERFORMANCE";
            case MODE_SESSION:
                return "SESSION";
            default:
                return "UNKNOWN";
        }
    }

    // Handle start/stop session command
    function toggleSession() as Void {
        if (app == null) {
            return;
        }
        
        var sessionStats = app.getSessionStats();
        if (sessionStats != null && sessionStats.isActive()) {
            // Stop current session
            app.stopSession();
            System.println("InlineSkatingView: Session stopped by user");
        } else {
            // Start new session
            app.startSession();
            System.println("InlineSkatingView: Session started by user");
        }
        
        needsFullRedraw = true;
        WatchUi.requestUpdate();
    }

    // Get current session status for delegate
    function getSessionStatus() {
        var sessionStats = app != null ? app.getSessionStats() : null;
        return sessionStats != null ? sessionStats.isActive() : false;
    }

    // Force full redraw
    function requestFullRedraw() as Void {
        needsFullRedraw = true;
        WatchUi.requestUpdate();
    }

    // Get display mode for delegate
    function getCurrentDisplayMode() {
        return currentDisplayMode;
    }

    // Update performance optimization
    function onPartialUpdate(dc) {
        // Only update changed elements for better performance
        if (dataChanged) {
            // Update only the data areas that changed
            switch (currentDisplayMode) {
                case MODE_MAIN:
                    updateMainScreenData(dc);
                    break;
                case MODE_TRICKS:
                    updateTricksScreenData(dc);
                    break;
                case MODE_PERFORMANCE:
                    updatePerformanceScreenData(dc);
                    break;
                case MODE_SESSION:
                    updateSessionScreenData(dc);
                    break;
            }
            dataChanged = false;
        }
    }

    // Partial update functions for performance
    function updateMainScreenData(dc as Graphics.Dc) as Void {
        // Update only the dynamic data fields in main screen
        var sessionStats = app != null ? app.getSessionStats() : null;
        var displayData = sessionStats != null ? sessionStats.getDisplayData() : null;
        
        if (displayData != null) {
            // Clear and redraw dynamic areas
            var fontSize = Graphics.FONT_MEDIUM;
            
            // Tricks count
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillRectangle(centerX / 2 - 20, centerY - 50, 40, 30);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX / 2, centerY - 40, fontSize, displayData.get("tricks").toString(), Graphics.TEXT_JUSTIFY_CENTER);
            
            // Heart rate (if available)
            var heartRate = displayData.get("heartRate");
            if (heartRate != null && heartRate > 0) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillRectangle(centerX - 30, centerY - 10, 60, 35);
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, centerY + 5, Graphics.FONT_LARGE, heartRate.toString(), Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }

    function updateTricksScreenData(dc as Graphics.Dc) as Void {
        // Update tricks screen dynamic data
        // Implementation would update only the changing numbers
    }

    function updatePerformanceScreenData(dc as Graphics.Dc) as Void {
        // Update performance screen dynamic data
        // Implementation would update only the changing metrics
    }

    function updateSessionScreenData(dc as Graphics.Dc) as Void {
        // Update session screen dynamic data
        // Implementation would update progress bars and counters
    }
}