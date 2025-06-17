// RotationView.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Rotation Statistics Display View
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Math;

class RotationView extends WatchUi.View {
    
    var app;
    var screenWidth;
    var screenHeight;
    var centerX;
    var centerY;
    
    // Animation for new rotations
    var rotationAnimation = false;
    var animationTimer = 0;
    var lastRotationDirection = "";
    var lastRotationAngle = 0.0;
    
    function initialize(appRef) {
        View.initialize();
        app = appRef;
        
        // Get screen dimensions
        var deviceSettings = System.getDeviceSettings();
        screenWidth = deviceSettings.screenWidth;
        screenHeight = deviceSettings.screenHeight;
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
        
        System.println("RotationView: Initialized");
    }
    
    function onLayout(dc) {
        // No layout file needed
    }
    
    function onShow() {
        System.println("RotationView: View shown");
        WatchUi.requestUpdate();
    }
    
    function onHide() {
        System.println("RotationView: View hidden");
    }
    
    function onUpdate(dc) {
        try {
            System.println("RotationView: Updating display");
            
            // Clear screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw header
            drawHeader(dc);
            
            // Draw rotation statistics
            drawRotationStats(dc);
            
            // Draw preferred direction indicator
            drawPreferredDirection(dc);
            
            // Draw detection state
            drawDetectionState(dc);
            
            // Draw animation if active
            if (rotationAnimation) {
                drawRotationAnimation(dc);
                updateAnimation();
            }
            
        } catch (exception) {
            System.println("RotationView: Error in onUpdate: " + exception.getErrorMessage());
            drawErrorMessage(dc, "Display Error");
        }
    }
    
    // Draw view header
    function drawHeader(dc) {
        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 5, Graphics.FONT_TINY, "ROTATIONS", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Detection status
        var rotationDetector = app.getRotationDetector();
        var isCalibrated = false;
        var stateColor = Graphics.COLOR_RED;
        
        if (rotationDetector != null) {
            var stats = rotationDetector.getRotationStats();
            if (stats != null) {
                isCalibrated = stats.get("isCalibrated");
                if (isCalibrated) {
                    stateColor = Graphics.COLOR_GREEN;
                }
            }
        }
        
        // Status indicator
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(centerX, 25, 6);
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 35, Graphics.FONT_TINY, 
                   isCalibrated ? "GYRO READY" : "CALIBRATING", 
                   Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw rotation statistics
    function drawRotationStats(dc) {
        var rotationDetector = app.getRotationDetector();
        var stats = null;
        var formattedRotations = null;
        
        if (rotationDetector != null) {
            stats = rotationDetector.getRotationStats();
            formattedRotations = rotationDetector.getFormattedRotations();
        }
        
        var yPos = 90;
        var lineHeight = 40;
        
        // Right rotations
        var rightRotations = formattedRotations != null ? formattedRotations.get("rightDisplay") : "0.0";
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(30, yPos, Graphics.FONT_SMALL, "Right:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, 
                   rightRotations, Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Left rotations
        var leftRotations = formattedRotations != null ? formattedRotations.get("leftDisplay") : "0.0";
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Left:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, 
                   leftRotations, Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Total rotations
        var totalRotations = formattedRotations != null ? formattedRotations.get("totalDisplay") : "0.0";
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_SMALL, "Total:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_SMALL, 
                   totalRotations, Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Rotation counts
        var rightCount = stats != null ? stats.get("rightCount") : 0;
        var leftCount = stats != null ? stats.get("leftCount") : 0;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Count:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   "R:" + rightCount + " L:" + leftCount, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    
    // Draw preferred direction indicator
    function drawPreferredDirection(dc) {
        var rotationDetector = app.getRotationDetector();
        var preferredDirection = "BALANCED";
        var directionColor = Graphics.COLOR_WHITE;
        
        if (rotationDetector != null) {
            var stats = rotationDetector.getRotationStats();
            if (stats != null) {
                preferredDirection = stats.get("preferredDirection");
                
                // Color code the preference
                if (preferredDirection.equals("RIGHT")) {
                    directionColor = Graphics.COLOR_GREEN;
                } else if (preferredDirection.equals("LEFT")) {
                    directionColor = Graphics.COLOR_BLUE;
                } else {
                    directionColor = Graphics.COLOR_YELLOW;
                }
            }
        }
        
        // Draw preference indicator
        var yPos = centerY + 30;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yPos, Graphics.FONT_TINY, 
                   "PREFERENCE:", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(directionColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yPos + 40, Graphics.FONT_SMALL, 
                   preferredDirection, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw directional arrows
        drawDirectionalIndicator(dc, centerX, yPos + 35, preferredDirection);
    }
    
    // Draw directional indicator arrows
    function drawDirectionalIndicator(dc, x, y, direction) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        
        if (direction.equals("RIGHT")) {
            // Right arrow
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            var rightArrow = [[x + 10, y], [x + 20, y - 5], [x + 20, y + 5]];
            dc.fillPolygon(rightArrow);
        } else if (direction.equals("LEFT")) {
            // Left arrow
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            var leftArrow = [[x - 10, y], [x - 20, y - 5], [x - 20, y + 5]];
            dc.fillPolygon(leftArrow);
        } else {
            // Balanced - both arrows
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            var leftArrow = [[x - 15, y], [x - 25, y - 5], [x - 25, y + 5]];
            var rightArrow = [[x + 15, y], [x + 25, y - 5], [x + 25, y + 5]];
            dc.fillPolygon(leftArrow);
            dc.fillPolygon(rightArrow);
        }
    }
    
    // Draw current detection state
    function drawDetectionState(dc) {
        var rotationDetector = app.getRotationDetector();
        var stateText = "STABLE";
        var stateColor = Graphics.COLOR_WHITE;
        
        if (rotationDetector != null) {
            stateText = rotationDetector.getCurrentStateString();
            
            // Color code the state
            switch (stateText) {
                case "STABLE":
                    stateColor = Graphics.COLOR_WHITE;
                    break;
                case "ROTATING":
                    stateColor = Graphics.COLOR_ORANGE;
                    break;
                case "COMPLETING":
                    stateColor = Graphics.COLOR_YELLOW;
                    break;
            }
        }
        
        // State display at bottom
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 100, Graphics.FONT_TINY, 
                   "STATE:", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(stateColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 70, Graphics.FONT_SMALL, 
                   stateText, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw rotation detection animation
// RotationView.mc - FIXED ANIMATION FUNCTION

    function drawRotationAnimation(dc) {
        if (lastRotationDirection.length() == 0) {
            return;
        }
        
        try {
            var animColor = lastRotationDirection.equals("right") ? 
                        Graphics.COLOR_GREEN : Graphics.COLOR_BLUE;
            
            // Spinning animation
            var angle = animationTimer * 15; // degrees per frame
            var radius = 40;
            
            // Draw rotating indicator
            dc.setColor(animColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(4);
            
            // Calculate rotation direction
            var direction = lastRotationDirection.equals("right") ? 1 : -1;
            var currentAngle = angle * direction;
            
            // Draw arc to show rotation
            var startAngle = currentAngle - 60;
            var endAngle = currentAngle + 60;
            
            // Simple animated text
            var rotationText = lastRotationDirection.toUpper() + "\n" + 
                            (lastRotationAngle / 360.0).format("%.1f") + " turns";
            
            dc.setColor(animColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 40, Graphics.FONT_SMALL, 
                    rotationText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // FIXED: Spinning circle indicator with safe math
            var angleRad = currentAngle * Math.PI / 180.0;
            var sinValue = Math.sin(angleRad).toFloat();
            var cosValue = Math.cos(angleRad).toFloat();
            
            var spinX = (centerX + sinValue * 20.0).toNumber();
            var spinY = (centerY + cosValue * 20.0).toNumber();
            
            dc.fillCircle(spinX, spinY, 5);
            
        } catch (exception) {
            System.println("RotationView: Error in animation: " + exception.getErrorMessage());
        }
    }
    
    // Update animation state
    function updateAnimation() {
        animationTimer++;
        if (animationTimer > 30) { // ~3 seconds
            rotationAnimation = false;
            animationTimer = 0;
            lastRotationDirection = "";
            lastRotationAngle = 0.0;
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
            System.println("RotationView: Trick detected - " + trickType);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("RotationView: Error in onTrickDetected: " + exception.getErrorMessage());
        }
    }
    
    function onRotationDetected(direction, angle) {
        try {
            System.println("RotationView: Rotation detected - " + direction + " " + angle + "°");
            lastRotationDirection = direction;
            lastRotationAngle = angle;
            rotationAnimation = true;
            animationTimer = 0;
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("RotationView: Error in onRotationDetected: " + exception.getErrorMessage());
        }
    }
    
    function onSessionStateChange(newState) {
        try {
            System.println("RotationView: Session state changed to " + newState);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("RotationView: Error in onSessionStateChange: " + exception.getErrorMessage());
        }
    }
    
    // Cleanup
    function cleanup() {
        System.println("RotationView: Cleanup completed");
    }
}