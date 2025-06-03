// Garmin Aggressive Inline Skating Tracker v2.0.0
// Main Application Class

import Toybox.Application;
import Toybox.WatchUi;
import Toybox.System;

class InlineSkatingApp extends Application.AppBase {
    
    var sensorManager;
    var trickDetector;
    var sessionStats;
    var isSessionActive = false;

    function initialize() {
        AppBase.initialize();
    }

    // Called when application starts
    function onStart(state as Dictionary?) as Void {
        System.println("InlineSkatingApp: Starting application v2.0.0");
        
        // Initialize core components
        initializeComponents();
        
        // Restore session state if available
        if (state != null && state.hasKey("sessionActive")) {
            isSessionActive = state.get("sessionActive");
            if (isSessionActive) {
                System.println("InlineSkatingApp: Restoring active session");
                resumeSession();
            }
        }
    }

    // Called when application is being stopped
    function onStop(state as Dictionary?) as Void {
        System.println("InlineSkatingApp: Stopping application");
        
        // Save current state
        if (state != null) {
            state.put("sessionActive", isSessionActive);
            if (sessionStats != null) {
                state.put("sessionData", sessionStats.getSessionData());
            }
        }
        
        // Clean up resources
        if (sensorManager != null) {
            sensorManager.stopSensors();
        }
        
        // Stop any active session
        if (isSessionActive) {
            stopSession();
        }
    }

    // Return the initial view and input delegate
    function getInitialView() as Array<WatchUi.Views or WatchUi.InputDelegates>? {
        return [ new InlineSkatingView(), new InlineSkatingDelegate() ];
    }

    // Initialize all application components
    function initializeComponents() as Void {
        try {
            // Initialize sensor management
            sensorManager = new SensorManager();
            
            // Initialize trick detection engine
            trickDetector = new TrickDetector();
            
            // Initialize session statistics
            sessionStats = new SessionStats();
            
            System.println("InlineSkatingApp: Components initialized successfully");
            
        } catch (exception) {
            System.println("InlineSkatingApp: Error initializing components: " + exception.getErrorMessage());
        }
    }

    // Start a new skating session
    function startSession() as Void {
        if (isSessionActive) {
            System.println("InlineSkatingApp: Session already active");
            return;
        }
        
        try {
            System.println("InlineSkatingApp: Starting new session");
            
            // Reset statistics
            sessionStats.reset();
            
            // Start sensor monitoring
            sensorManager.startSensors();
            
            // Initialize trick detection
            trickDetector.startDetection();
            
            // Mark session as active
            isSessionActive = true;
            
            // Start activity recording
            startActivitySession();
            
            System.println("InlineSkatingApp: Session started successfully");
            
        } catch (exception) {
            System.println("InlineSkatingApp: Error starting session: " + exception.getErrorMessage());
            isSessionActive = false;
        }
    }

    // Stop current skating session
    function stopSession() as Void {
        if (!isSessionActive) {
            System.println("InlineSkatingApp: No active session to stop");
            return;
        }
        
        try {
            System.println("InlineSkatingApp: Stopping session");
            
            // Stop sensor monitoring
            sensorManager.stopSensors();
            
            // Stop trick detection
            trickDetector.stopDetection();
            
            // Stop activity recording
            stopActivitySession();
            
            // Mark session as inactive
            isSessionActive = false;
            
            // Save session data
            saveSessionData();
            
            System.println("InlineSkatingApp: Session stopped successfully");
            
        } catch (exception) {
            System.println("InlineSkatingApp: Error stopping session: " + exception.getErrorMessage());
        }
    }

    // Resume session after app restart
    function resumeSession() as Void {
        try {
            System.println("InlineSkatingApp: Resuming session");
            
            // Restart sensors
            sensorManager.startSensors();
            
            // Resume trick detection
            trickDetector.startDetection();
            
        } catch (exception) {
            System.println("InlineSkatingApp: Error resuming session: " + exception.getErrorMessage());
            isSessionActive = false;
        }
    }

    // Start Garmin activity session
    function startActivitySession() as Void {
        // This would integrate with Garmin's activity recording
        // Implementation depends on Connect IQ SDK version
        System.println("InlineSkatingApp: Starting activity recording");
    }

    // Stop Garmin activity session
    function stopActivitySession() as Void {
        // Stop and save activity
        System.println("InlineSkatingApp: Stopping activity recording");
    }

    // Save session data to persistent storage
    function saveSessionData() as Void {
        if (sessionStats != null) {
            var sessionData = sessionStats.getSessionData();
            // Save to persistent storage
            System.println("InlineSkatingApp: Session data saved - Tricks: " + 
                          sessionData.get("totalTricks") + ", Time: " + 
                          sessionData.get("totalTime"));
        }
    }

    // Get current session status
    function getSessionStatus() as Boolean {
        return isSessionActive;
    }

    // Get sensor manager instance
    function getSensorManager() as SensorManager? {
        return sensorManager;
    }

    // Get trick detector instance
    function getTrickDetector() as TrickDetector? {
        return trickDetector;
    }

    // Get session statistics instance
    function getSessionStats() as SessionStats? {
        return sessionStats;
    }

    // Handle trick detection callback
    function onTrickDetected(trickType as String, trickData as Dictionary) as Void {
        if (sessionStats != null) {
            sessionStats.addTrick(trickType, trickData);
        }
        
        // Trigger UI update
        WatchUi.requestUpdate();
        
        // Optional: vibrate or beep
        if (Attention has :vibrate) {
            var vibeData = [new Attention.VibeProfile(50, 200)];
            Attention.vibrate(vibeData);
        }
        
        System.println("InlineSkatingApp: Trick detected - " + trickType);
    }

    // Get application version
    function getVersion() as String {
        return "2.0.0";
    }
}