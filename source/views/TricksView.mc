// TricksView.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Tricks Detection Display View
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Math;

class TricksView extends WatchUi.View {
    
    var app;
    var screenWidth;
    var screenHeight;
    var centerX;
    var centerY;
    
    // Animation for new tricks
    var trickAnimation = false;
    var animationTimer = 0;
    var lastDetectedTrick = "";
    
    function initialize(appRef) {
        View.initialize();
        app = appRef;
        
        // Get screen dimensions
        var deviceSettings = System.getDeviceSettings();
        screenWidth = deviceSettings.screenWidth;
        screenHeight = deviceSettings.screenHeight;
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
        
        System.println("TricksView: Initialized");
    }
    
    function onLayout(dc) {
        // No layout file needed
    }
    
    function onShow() {
        System.println("TricksView: View shown");
        WatchUi.requestUpdate();
    }
    
    function onHide() {
        System.println("TricksView: View hidden");
    }
    
    function onUpdate(dc) {
        try {
            System.println("TricksView: Updating display");
            
            // Clear screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw header
            drawHeader(dc);
            
            // Draw trick statistics
            drawTrickStats(dc);
            
            // Draw detection state
            drawDetectionState(dc);
            
            // Draw animation if active
            if (trickAnimation) {
                drawTrickAnimation(dc);
                updateAnimation();
            }
            
        } catch (exception) {
            System.println("TricksView: Error in onUpdate: " + exception.getErrorMessage());
            drawErrorMessage(dc, "Display Error");
        }
    }
    
    // Draw view header
    function drawHeader(dc) {
        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 5, Graphics.FONT_TINY, "TRICKS", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Detection status indicator
        var trickDetector = app.getTrickDetector();
        var isCalibrated = false;
        var stateColor = Graphics.COLOR_RED;
        
        if (trickDetector != null) {
            isCalibrated = trickDetector.isCalibrationComplete();
            if (isCalibrated) {
                stateColor = Graphics.COLOR_GREEN;
            }
        }
        
        // Status circle
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, 25, 6);
        
        // Status text
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 35, Graphics.FONT_TINY, 
                   isCalibrated ? "READY" : "CALIBRATING", 
                   Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw trick statistics
    function drawTrickStats(dc) {
        var trickDetector = app.getTrickDetector();
        var stats = null;
        
        if (trickDetector != null) {
            stats = trickDetector.getDetectionStats();
        }
        
        var yPos = 90;
        var lineHeight = 40;
        
        // Total tricks
        var totalTricks = stats != null ? stats.get("totalTricks") : 0;
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(47, yPos, Graphics.FONT_SMALL, "Total:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 40, yPos, Graphics.FONT_SMALL, 
                   totalTricks.toString(), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Grinds
        var totalGrinds = stats != null ? stats.get("totalGrinds") : 0;
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Grinds:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, 
                   totalGrinds.toString(), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Jumps
        var totalJumps = stats != null ? stats.get("totalJumps") : 0;
        dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(16, yPos, Graphics.FONT_SMALL, "Jumps:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, 
                   totalJumps.toString(), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Longest grind
        var longestGrind = stats != null ? stats.get("longestGrind") : 0;
        var longestGrindText = formatDuration(longestGrind);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Best Grind:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, 
                   longestGrindText, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    
    // Draw current detection state
    function drawDetectionState(dc) {
        var trickDetector = app.getTrickDetector();
        var stateText = "UNKNOWN";
        var stateColor = Graphics.COLOR_DK_GRAY;
        
        if (trickDetector != null) {
            stateText = trickDetector.getCurrentStateString();
            
            // Color code the state
            switch (stateText) {
                case "RIDING":
                    stateColor = Graphics.COLOR_WHITE;
                    break;
                case "TAKEOFF":
                    stateColor = Graphics.COLOR_YELLOW;
                    break;
                case "AIRBORNE":
                    stateColor = Graphics.COLOR_BLUE;
                    break;
                case "GRINDING":
                    stateColor = Graphics.COLOR_ORANGE;
                    break;
                case "LANDING":
                    stateColor = Graphics.COLOR_GREEN;
                    break;
            }
        }
        
        // State display at bottom
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 110, Graphics.FONT_TINY, 
                   "STATE:", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 80, Graphics.FONT_SMALL, 
                   stateText, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw trick detection animation
    function drawTrickAnimation(dc) {
        if (lastDetectedTrick.length() == 0) {
            return;
        }
        
        try {
            // Pulsing animation
            var alpha = MathUtils.safeSin(animationTimer * 0.5) * 0.5 + 0.5;
            var animColor = Graphics.COLOR_YELLOW;
            
            if (lastDetectedTrick.equals("grind")) {
                animColor = Graphics.COLOR_ORANGE;
            } else if (lastDetectedTrick.equals("jump")) {
                animColor = Graphics.COLOR_PURPLE;
            }
            
            // Big animated text in center
            dc.setColor(animColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 10, Graphics.FONT_MEDIUM, 
                       lastDetectedTrick.toUpper() + "!", 
                       Graphics.TEXT_JUSTIFY_CENTER);
            
            // Animated border
            var radius = 60 + Math.sin(animationTimer * 0.3) * 10;
            dc.setPenWidth(3);
            dc.drawCircle(centerX, centerY, radius);
            
        } catch (exception) {
            System.println("TricksView: Error in animation: " + exception.getErrorMessage());
        }
    }
    
    // Update animation state
    function updateAnimation() {
        animationTimer++;
        if (animationTimer > 40) { // ~4 seconds at 10fps
            trickAnimation = false;
            animationTimer = 0;
            lastDetectedTrick = "";
        }
    }
    
    // Format duration from milliseconds
    function formatDuration(milliseconds) {
        if (milliseconds == 0) {
            return "0.0s";
        }
        
        var seconds = milliseconds / 1000.0;
        if (seconds < 1.0) {
            return (milliseconds).format("%d") + "ms";
        } else {
            return seconds.format("%.1f") + "s";
        }
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
            System.println("TricksView: Trick detected - " + trickType);
            lastDetectedTrick = trickType;
            trickAnimation = true;
            animationTimer = 0;
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("TricksView: Error in onTrickDetected: " + exception.getErrorMessage());
        }
    }
    
    function onRotationDetected(direction, angle) {
        try {
            System.println("TricksView: Rotation detected - " + direction + " " + angle + "°");
            // Could show rotation indicator here
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("TricksView: Error in onRotationDetected: " + exception.getErrorMessage());
        }
    }
    
    function onSessionStateChange(newState) {
        try {
            System.println("TricksView: Session state changed to " + newState);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("TricksView: Error in onSessionStateChange: " + exception.getErrorMessage());
        }
    }
    
    // Cleanup
    function cleanup() {
        System.println("TricksView: Cleanup completed");
    }
}