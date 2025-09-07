// AlertManager.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Alert System for Jump and Rotation Detection
using Toybox.Lang;
using Toybox.System;
using Toybox.Attention;

class AlertManager {
    
    // Alert types
    const ALERT_JUMP = 0;
    const ALERT_JUMP_180 = 1;
    const ALERT_JUMP_360 = 2;
    const ALERT_JUMP_540 = 3;
    const ALERT_GRIND = 4;
    
    // Alert settings
    var debugMode = true;           // Enable debug alerts
    var alertsEnabled = true;       // Master alert switch
    var alertVolume = 1.0;          // Alert volume (0.0 - 1.0)
    
    // Alert timing control
    var lastAlertTime = 0;
    const MIN_ALERT_INTERVAL = 500; // Minimum time between alerts (ms)
    
    // Statistics
    var totalAlertsPlayed = 0;
    var alertsByType = {};
    
    function initialize() {
        System.println("AlertManager: Initialized");
        
        // Initialize alert statistics
        alertsByType.put(0, 0); // ALERT_JUMP
        alertsByType.put(1, 0); // ALERT_JUMP_180
        alertsByType.put(2, 0); // ALERT_JUMP_360
        alertsByType.put(3, 0); // ALERT_JUMP_540
        alertsByType.put(4, 0); // ALERT_GRIND
        
        // Check if device supports audio alerts
        if (!(Attention has :playTone)) {
            System.println("AlertManager: Warning - Device does not support audio alerts");
            alertsEnabled = false;
        }
    }
    
    // Main alert trigger function
    function playAlert(alertType, rotationAngle) {
        if (!alertsEnabled || !debugMode) {
            return;
        }
        
        var currentTime = System.getTimer();
        
        // Prevent alert spam
        if (currentTime - lastAlertTime < MIN_ALERT_INTERVAL) {
            return;
        }
        
        try {
            switch (alertType) {
                case 0: // ALERT_JUMP
                    playJumpAlert(rotationAngle);
                    break;
                case 4: // ALERT_GRIND
                    playGrindAlert();
                    break;
                default:
                    playGenericAlert();
                    break;
            }
            
            // Update statistics
            totalAlertsPlayed++;
            var count = alertsByType.get(alertType);
            if (count != null) {
                alertsByType.put(alertType, count + 1);
            }
            
            lastAlertTime = currentTime;
            
        } catch (exception) {
            System.println("AlertManager: Error playing alert: " + exception.getErrorMessage());
        }
    }
    
    // Play jump alert based on rotation angle
    function playJumpAlert(rotationAngle) {
        var beepCount = 1; // Default: 1 beep for regular jump
        var tone = Attention.TONE_LOUD_BEEP;
        
        if (rotationAngle != null) {
            if (rotationAngle >= 540.0) {
                beepCount = 4;
                tone = Attention.TONE_SUCCESS; // Special tone for 540+
                System.println("AlertManager: 540°+ rotation detected!");
            } else if (rotationAngle >= 360.0) {
                beepCount = 2;
                System.println("AlertManager: 360° rotation detected!");
            } else if (rotationAngle >= 180.0) {
                beepCount = 1;
                tone = Attention.TONE_ALERT_HI; // Higher pitch for 180
                System.println("AlertManager: 180° rotation detected!");
            } else {
                beepCount = 1;
                System.println("AlertManager: Simple jump detected!");
            }
        }
        
        // Play the appropriate number of beeps
        playBeeps(tone, beepCount);
        
        System.println("AlertManager: Jump alert played - " + beepCount + " beep(s), angle: " + 
                      (rotationAngle != null ? rotationAngle.format("%.0f") + "°" : "N/A"));
    }
    
    // Play grind alert
    function playGrindAlert() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_INTERVAL_ALERT);
        }
        System.println("AlertManager: Grind alert played");
    }
    
    // Play generic alert
    function playGenericAlert() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_MSG);
        }
        System.println("AlertManager: Generic alert played");
    }
    
    // Play multiple beeps with timing
    function playBeeps(tone, count) {
        if (!(Attention has :playTone) || count <= 0) {
            return;
        }
        
        if (count == 1) {
            // Single beep
            Attention.playTone(tone);
        } else {
            // Multiple beeps - use tone profile for better control
            if (Attention has :ToneProfile) {
                var toneProfile = [];
                
                for (var i = 0; i < count; i++) {
                    // Add beep
                    toneProfile.add(new Attention.ToneProfile(2500, 150)); // 150ms beep
                    
                    // Add pause between beeps (except after last beep)
                    if (i < count - 1) {
                        toneProfile.add(new Attention.ToneProfile(0, 100)); // 100ms pause
                    }
                }
                
                try {
                    Attention.playTone({:toneProfile => toneProfile});
                } catch (exception) {
                    // Fallback to simple tone
                    Attention.playTone(tone);
                }
            } else {
                // Fallback: just play single tone
                Attention.playTone(tone);
            }
        }
    }
    
    // Configuration methods
    function setDebugMode(enabled) {
        debugMode = enabled;
        System.println("AlertManager: Debug mode " + (enabled ? "enabled" : "disabled"));
    }
    
    function setAlertsEnabled(enabled) {
        alertsEnabled = enabled;
        System.println("AlertManager: Alerts " + (enabled ? "enabled" : "disabled"));
    }
    
    function setAlertVolume(volume) {
        if (volume >= 0.0 && volume <= 1.0) {
            alertVolume = volume;
            System.println("AlertManager: Volume set to " + (volume * 100).format("%.0f") + "%");
        }
    }
    
    // Test alert functionality
    function testAlerts() {
        System.println("AlertManager: Testing alerts...");
        
        // Test different alert types
        playAlert(0, null); // ALERT_JUMP
        // Note: In real implementation, you'd want to add delays between tests
        // but Timer is complex in Garmin API, so this is a basic test
    }
    
    // Get statistics
    function getAlertStats() {
        return {
            "totalAlerts" => totalAlertsPlayed,
            "alertsByType" => alertsByType,
            "debugMode" => debugMode,
            "alertsEnabled" => alertsEnabled
        };
    }
    
    // Check if device supports alerts
    function isAlertSupported() {
        return (Attention has :playTone);
    }
    
    // Cleanup
    function cleanup() {
        System.println("AlertManager: Cleanup completed");
    }
}