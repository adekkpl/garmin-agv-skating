// SettingsView.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Settings Display View
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;

class SettingsView extends WatchUi.View {
    
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
        
        System.println("SettingsView: Initialized");
    }
    
    function onLayout(dc) {
        // No layout file needed
    }
    
    function onShow() {
        System.println("SettingsView: View shown");
        WatchUi.requestUpdate();
    }
    
    function onHide() {
        System.println("SettingsView: View hidden");
    }
    
    function onUpdate(dc) {
        try {
            System.println("SettingsView: Updating display");
            
            // Clear screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw header
            drawHeader(dc);
            
            // Draw settings info
            drawSettingsInfo(dc);
            
            // Draw app info
            drawAppInfo(dc);
            
        } catch (exception) {
            System.println("SettingsView: Error in onUpdate: " + exception.getErrorMessage());
            drawErrorMessage(dc, "Display Error");
        }
    }
    
    // Draw view header
    function drawHeader(dc) {
        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 5, Graphics.FONT_TINY, "SETTINGS", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw settings information
    function drawSettingsInfo(dc) {
        var yPos = 40;
        var lineHeight = 25;
        
        // Detection sensitivity
        var sensitivity = 1.0;
        var trickDetector = app.getTrickDetector();
        if (trickDetector != null) {
            // Assume default sensitivity for now
            sensitivity = 1.0;
        }
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Sensitivity:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   sensitivity.format("%.1f"), Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // GPS accuracy
        var gpsTracker = app.getGPSTracker();
        var gpsQuality = "Unknown";
        if (gpsTracker != null) {
            gpsQuality = gpsTracker.getGPSQualityString();
        }
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "GPS Status:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   gpsQuality, Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Sensor status
        var sensorManager = app.getSensorManager();
        var sensorStatus = "Unknown";
        if (sensorManager != null) {
            sensorStatus = "Active";
        }
        
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Sensors:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   sensorStatus, Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Calibration status
        var calibrationStatus = "Unknown";
        if (trickDetector != null) {
            calibrationStatus = trickDetector.isCalibrationComplete() ? "Complete" : "In Progress";
        }
        
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Calibration:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   calibrationStatus, Graphics.TEXT_JUSTIFY_RIGHT);
        yPos += lineHeight;
        
        // Rotation detection
        var rotationDetector = app.getRotationDetector();
        var rotationStatus = "Disabled";
        if (rotationDetector != null) {
            var rotationStats = rotationDetector.getRotationStats();
            if (rotationStats != null) {
                rotationStatus = rotationStats.get("isCalibrated") ? "Ready" : "Calibrating";
            }
        }
        
        dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(20, yPos, Graphics.FONT_TINY, "Rotation:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth - 20, yPos, Graphics.FONT_TINY, 
                   rotationStatus, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    
    // Draw app information
    function drawAppInfo(dc) {
        var yPos = centerY + 20;
        var lineHeight = 20;
        
        // App version
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yPos, Graphics.FONT_TINY, 
                   "AGV Tracker v3.0.0", Graphics.TEXT_JUSTIFY_CENTER);
        yPos += lineHeight;
        
        // Author
        dc.drawText(centerX, yPos, Graphics.FONT_TINY, 
                   "by Vít Kotačka", Graphics.TEXT_JUSTIFY_CENTER);
        yPos += lineHeight;
        
        // Device info
        var deviceSettings = System.getDeviceSettings();
        var deviceName = deviceSettings.partNumber;
        if (deviceName == null) {
            deviceName = "Unknown Device";
        }
        
        dc.drawText(centerX, yPos, Graphics.FONT_TINY, 
                   deviceName, Graphics.TEXT_JUSTIFY_CENTER);
        yPos += lineHeight;
        
        // Memory info (if available)
        try {
            var stats = System.getSystemStats();
            if (stats != null) {
                var memoryUsed = stats.usedMemory;
                var totalMemory = stats.totalMemory;
                var memoryPercent = (memoryUsed * 100 / totalMemory).toNumber();
                
                dc.drawText(centerX, yPos, Graphics.FONT_TINY, 
                           "Memory: " + memoryPercent + "%", Graphics.TEXT_JUSTIFY_CENTER);
            }
        } catch (exception) {
            // Memory info not available
        }
        
        // Instructions at bottom
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, screenHeight - 30, Graphics.FONT_XTINY, 
                   "Use UP/DOWN to switch views", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, screenHeight - 15, Graphics.FONT_XTINY, 
                   "BACK to return to main", Graphics.TEXT_JUSTIFY_CENTER);
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
            System.println("SettingsView: Trick detected - " + trickType);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("SettingsView: Error in onTrickDetected: " + exception.getErrorMessage());
        }
    }
    
    function onRotationDetected(direction, angle) {
        try {
            System.println("SettingsView: Rotation detected - " + direction + " " + angle + "°");
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("SettingsView: Error in onRotationDetected: " + exception.getErrorMessage());
        }
    }
    
    function onSessionStateChange(newState) {
        try {
            System.println("SettingsView: Session state changed to " + newState);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("SettingsView: Error in onSessionStateChange: " + exception.getErrorMessage());
        }
    }
    
    // Cleanup
    function cleanup() {
        System.println("SettingsView: Cleanup completed");
    }
}