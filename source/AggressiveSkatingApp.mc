// AggressiveSkatingApp.mc
// Garmin Aggressive Inline Skating Tracker v2.0.0
// Main Application Class
using Toybox.Lang;
using Toybox.Application;
using Toybox.System;
using Toybox.WatchUi;

class InlineSkatingApp extends Application.AppBase {
    
    var sensorManager;
    var trickDetector;
    var sessionStats;
    var isSessionActive = false;
    var mainView;
    var mainDelegate;

    function initialize() {
        AppBase.initialize();
        System.println("InlineSkatingApp: Application initializing...");
    }

    // Called when application starts
    function onStart(state) {
        System.println("InlineSkatingApp: Starting application v2.0.0");
        
        // Initialize core components
        var initSuccess = initializeComponents();
        
        if (!initSuccess) {
            System.println("InlineSkatingApp: Component initialization failed");
            return;
        }
        
        // Restore session state if available
        if (state != null && state.hasKey("sessionActive") && state.get("sessionActive") == true) {
            isSessionActive = true;
            System.println("InlineSkatingApp: Restoring active session");
            resumeSession();
        }
        
        System.println("InlineSkatingApp: Application started successfully");
    }

    // Called when application is being stopped
    function onStop(state) {
        System.println("InlineSkatingApp: Stopping application");
        
        // Save current state
        if (state != null) {
            state.put("sessionActive", isSessionActive);
            if (sessionStats != null) {
                try {
                    state.put("sessionData", sessionStats.getSessionData());
                } catch (exception) {
                    System.println("InlineSkatingApp: Error saving session data: " + exception.getErrorMessage());
                }
            }
        }
        
        // Clean up resources
        cleanupResources();
    }

    // Return the initial view and input delegate
    function getInitialView() {
        System.println("InlineSkatingApp: Creating initial view and delegate");
        
        try {
            // Create view and delegate
            mainView = new InlineSkatingView();
            mainDelegate = new InlineSkatingDelegate();
            
            // Connect view and delegate
            mainDelegate.setView(mainView);
            
            System.println("InlineSkatingApp: Initial view and delegate created successfully");
            return [mainView, mainDelegate];
            
        } catch (exception) {
            System.println("InlineSkatingApp: Error creating initial view: " + exception.getErrorMessage());
            
            // Fallback to simple view if there's an error
            return [new SimpleErrorView("Failed to initialize app"), new WatchUi.BehaviorDelegate()];
        }
    }

    // Initialize all application components
    function initializeComponents() {
        try {
            System.println("InlineSkatingApp: Initializing components...");
            
            // Initialize session statistics first (no dependencies)
            sessionStats = new SessionStats();
            if (sessionStats == null) {
                System.println("InlineSkatingApp: Failed to create SessionStats");
                return false;
            }
            System.println("InlineSkatingApp: SessionStats initialized");
            
            // Initialize sensor management
            sensorManager = new SensorManager();
            if (sensorManager == null) {
                System.println("InlineSkatingApp: Failed to create SensorManager");
                return false;
            }
            System.println("InlineSkatingApp: SensorManager initialized");
            
            // Initialize trick detection engine
            trickDetector = new TrickDetector();
            if (trickDetector == null) {
                System.println("InlineSkatingApp: Failed to create TrickDetector");
                return false;
            }
            
            // Set up trick detection callback
            trickDetector.setTrickDetectedCallback(method(:onTrickDetected));
            System.println("InlineSkatingApp: TrickDetector initialized");
            
            System.println("InlineSkatingApp: All components initialized successfully");
            return true;
            
        } catch (exception) {
            System.println("InlineSkatingApp: Error initializing components: " + exception.getErrorMessage());
            return false;
        }
    }

    // Clean up all resources
    function cleanupResources() as Void {
        try {
            // Stop any active session
            if (isSessionActive) {
                stopSession();
            }
            
            // Stop sensors
            if (sensorManager != null) {
                sensorManager.stopSensors();
            }
            
            // Stop trick detection
            if (trickDetector != null) {
                trickDetector.stopDetection();
            }
            
            System.println("InlineSkatingApp: Resources cleaned up successfully");
            
        } catch (exception) {
            System.println("InlineSkatingApp: Error during cleanup: " + exception.getErrorMessage());
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
            
            // Ensure components are initialized
            if (!ensureComponentsReady()) {
                System.println("InlineSkatingApp: Cannot start session - components not ready");
                return;
            }
            
            // Reset and start statistics
            sessionStats.reset();
            sessionStats.startSession();
            
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
            if (sensorManager != null) {
                sensorManager.stopSensors();
            }
            
            // Stop trick detection
            if (trickDetector != null) {
                trickDetector.stopDetection();
            }
            
            // End session statistics
            if (sessionStats != null) {
                sessionStats.endSession();
            }
            
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
            
            if (!ensureComponentsReady()) {
                System.println("InlineSkatingApp: Cannot resume session - components not ready");
                isSessionActive = false;
                return;
            }
            
            // Restart sensors
            sensorManager.startSensors();
            
            // Resume trick detection
            trickDetector.startDetection();
            
            System.println("InlineSkatingApp: Session resumed successfully");
            
        } catch (exception) {
            System.println("InlineSkatingApp: Error resuming session: " + exception.getErrorMessage());
            isSessionActive = false;
        }
    }

    // Ensure all components are ready
    function ensureComponentsReady() {
        if (sensorManager == null || trickDetector == null || sessionStats == null) {
            System.println("InlineSkatingApp: Components not ready, reinitializing...");
            return initializeComponents();
        }
        return true;
    }

    // Start Garmin activity session
    function startActivitySession() as Void {
        // This would integrate with Garmin's activity recording
        // Implementation depends on Connect IQ SDK version
        System.println("InlineSkatingApp: Starting activity recording");
        
        // TODO: Implement activity session if needed
        // var session = ActivityRecording.createSession({:name=>"Aggressive Skating", :sport=>ActivityRecording.SPORT_CYCLING});
        // session.start();
    }

    // Stop Garmin activity session
    function stopActivitySession() as Void {
        // Stop and save activity
        System.println("InlineSkatingApp: Stopping activity recording");
        
        // TODO: Implement activity session stop
    }

    // Save session data to persistent storage
    function saveSessionData() as Void {
        if (sessionStats != null) {
            try {
                var sessionData = sessionStats.getSessionData();
                // TODO: Save to persistent storage using Application.Storage
                System.println("InlineSkatingApp: Session data would be saved - Tricks: " + 
                              sessionData.get("totalTricks") + ", Time: " + 
                              sessionData.get("totalTime"));
            } catch (exception) {
                System.println("InlineSkatingApp: Error getting session data: " + exception.getErrorMessage());
            }
        }
    }

    // Get current session status
    function getSessionStatus() {
        return isSessionActive;
    }

    // Get sensor manager instance
    function getSensorManager() {
        return sensorManager;
    }

    // Get trick detector instance
    function getTrickDetector() {
        return trickDetector;
    }

    // Get session statistics instance
    function getSessionStats() {
        return sessionStats;
    }

    // Handle trick detection callback
    function onTrickDetected(trickType, trickData) {
        System.println("InlineSkatingApp: Trick detected callback - " + trickType);
        
        try {
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
            
        } catch (exception) {
            System.println("InlineSkatingApp: Error in trick detected callback: " + exception.getErrorMessage());
        }
    }

    // Get application version
    function getVersion() {
        return "2.0.0";
    }

    // Handle application settings
    function getSettingsView() {
        return null; // No settings view for now
    }

    // Handle when app comes to foreground
    function onSettingsChanged() {
        // Handle settings changes
        System.println("InlineSkatingApp: Settings changed");
    }
}

// Simple error view for fallback
class SimpleErrorView extends WatchUi.View {
    var errorMessage;
    
    function initialize(message) {
        View.initialize();
        errorMessage = message;
    }
    
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 20, Graphics.FONT_SMALL, "ERROR", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_TINY, errorMessage, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 20, Graphics.FONT_XTINY, "Check logs", Graphics.TEXT_JUSTIFY_CENTER);
    }
}