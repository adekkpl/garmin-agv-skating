// AggressiveSkatingApp.mc
// Garmin Aggressive Inline Skating Tracker v2.0.0
// Main Application Class
using Toybox.Lang;
using Toybox.Application;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.ActivityRecording;

class InlineSkatingApp extends Application.AppBase {
    
    var sensorManager;
    var trickDetector;
    var sessionStats;
    var activityRecorder;
    var isSessionActive = false;
    var mainView;
    var mainDelegate;

    function initialize() {
        AppBase.initialize();
        System.println("InlineSkatingApp: Application initializing...");
        System.println("=== APP START ===");
        System.println("Creating log file marker");

        activityRecorder = new ActivityRecorder();
    }

    // Called when application starts
    function onStart(state) {
        logDevice("App starting v2.0.0");
        System.println("InlineSkatingApp: Starting application v2.0.0");
        
        try {
            // Initialize core components
            var initSuccess = initializeComponents();
            
            if (!initSuccess) {
                logCritical("Component initialization FAILED");
                System.println("InlineSkatingApp: Component initialization failed");
                return;
            }
            
            logDevice("Components initialized successfully");
            
            // Restore session state if available
            if (state != null && state.hasKey("sessionActive") && state.get("sessionActive") == true) {
                isSessionActive = true;
                logDevice("Restoring active session");
                System.println("InlineSkatingApp: Restoring active session");
                resumeSession();
            }
            
            logDevice("App started successfully");
            System.println("InlineSkatingApp: Application started successfully");
            
        } catch (exception) {
            logError("onStart", exception);
        }
    }

    // Called when application is being stopped
    function onStop(state) {
        logDevice("App stopping");
        System.println("InlineSkatingApp: Stopping application");
        
        try {
            // Save current state
            if (state != null) {
                state.put("sessionActive", isSessionActive);
                if (sessionStats != null) {
                    try {
                        state.put("sessionData", sessionStats.getSessionData());
                        logDevice("Session data saved to state");
                    } catch (exception) {
                        logError("Saving session data", exception);
                        System.println("InlineSkatingApp: Error saving session data: " + exception.getErrorMessage());
                    }
                }
            }
            
            // POPRAWKA: Zamiast activityRecorder.onAppExit() użyj:
            if (activityRecorder != null) {
                try {
                    // Sprawdź czy session jest aktywna i zatrzymaj ją
                    if (activityRecorder.isSessionRecording()) {
                        logDevice("Stopping active recording session before app exit");
                        System.println("InlineSkatingApp: Stopping active recording session before app exit");
                        
                        var stopSuccess = activityRecorder.stopRecording();
                        if (stopSuccess) {
                            // Zapisz session
                            var saveSuccess = activityRecorder.saveSession();
                            if (saveSuccess) {
                                logDevice("Activity session auto-saved on app exit");
                                System.println("InlineSkatingApp: Activity session auto-saved on app exit");
                            } else {
                                // Jeśli zapis się nie udał, odrzuć żeby zwolnić pamięć
                                activityRecorder.discardSession();
                                logDevice("Activity session discarded due to save failure");
                            }
                        } else {
                            logDevice("Failed to stop recording session on app exit");
                        }
                    } else {
                        logDevice("No active recording session to stop");
                    }
                } catch (exception) {
                    logError("ActivityRecorder cleanup on app exit", exception);
                    System.println("InlineSkatingApp: Error during ActivityRecorder cleanup: " + exception.getErrorMessage());
                    
                    // W przypadku błędu, spróbuj przynajmniej odrzucić session
                    try {
                        activityRecorder.discardSession();
                    } catch (discardException) {
                        logError("Failed to discard session", discardException);
                    }
                }
            }
            
            // Clean up resources
            cleanupResources();
            logDevice("App stopped successfully");
            
        } catch (exception) {
            logError("onStop", exception);
        }
    }

    // Return the initial view and input delegate
    function getInitialView() {
        logDevice("Creating initial view and delegate");
        System.println("InlineSkatingApp: Creating initial view and delegate");
        
        try {
            // Create view and delegate
            mainView = new InlineSkatingView();
            mainDelegate = new InlineSkatingDelegate();
            
            if (mainView == null || mainDelegate == null) {
                logCritical("Failed to create view or delegate - NULL returned");
                return [new SimpleErrorView("Failed to create views"), new WatchUi.BehaviorDelegate()];
            }
            
            // Connect view and delegate
            mainDelegate.setView(mainView);
            
            logDevice("Initial view and delegate created successfully");
            System.println("InlineSkatingApp: Initial view and delegate created successfully");
            return [mainView, mainDelegate];
            
        } catch (exception) {
            logError("getInitialView", exception);
            System.println("InlineSkatingApp: Error creating initial view: " + exception.getErrorMessage());
            
            // Fallback to simple view if there's an error
            return [new SimpleErrorView("Failed to initialize app"), new WatchUi.BehaviorDelegate()];
        }
    }

    // Initialize all application components
    function initializeComponents() {
        logDevice("Initializing components START");
        
        try {
            System.println("InlineSkatingApp: Initializing components...");
            
            // Initialize session statistics first (no dependencies)
            logDevice("Creating SessionStats");
            sessionStats = new SessionStats();
            if (sessionStats == null) {
                logCritical("Failed to create SessionStats - NULL returned");
                System.println("InlineSkatingApp: Failed to create SessionStats");
                return false;
            }
            logDevice("SessionStats created successfully");
            System.println("InlineSkatingApp: SessionStats initialized");
            
            // Initialize sensor management
            logDevice("Creating SensorManager");
            sensorManager = new SensorManager();
            if (sensorManager == null) {
                logCritical("Failed to create SensorManager - NULL returned");
                System.println("InlineSkatingApp: Failed to create SensorManager");
                return false;
            }
            logDevice("SensorManager created successfully");
            System.println("InlineSkatingApp: SensorManager initialized");
            
           // ActivityRecorder initialization
            logDevice("Creating ActivityRecorder");
            activityRecorder = new ActivityRecorder();
            if (activityRecorder == null) {
                logCritical("Failed to create ActivityRecorder - NULL returned");
                System.println("InlineSkatingApp: Failed to create ActivityRecorder");
                return false;
            }

            // Initialize trick detection engine
            logDevice("Creating TrickDetector");
            trickDetector = new TrickDetector();
            if (trickDetector == null) {
                logCritical("Failed to create TrickDetector - NULL returned");
                System.println("InlineSkatingApp: Failed to create TrickDetector");
                return false;
            }
            
            // Set up trick detection callback
            trickDetector.setTrickDetectedCallback(method(:onTrickDetected));
            logDevice("TrickDetector created and callback set");
            System.println("InlineSkatingApp: TrickDetector initialized");
            
            logDevice("All components initialized successfully");
            System.println("InlineSkatingApp: All components initialized successfully");
            return true;
            
        } catch (exception) {
            logError("initializeComponents", exception);
            System.println("InlineSkatingApp: Error initializing components: " + exception.getErrorMessage());
            return false;
        }
    }

    // Clean up all resources
    function cleanupResources() as Void {
        logDevice("Cleanup resources START");
        
        try {
            // Stop any active session
            if (isSessionActive) {
                stopSession();
            }
            
            // Stop sensors
            if (sensorManager != null) {
                sensorManager.stopSensors();
                logDevice("Sensors stopped");
            }
            
            // Stop trick detection
            if (trickDetector != null) {
                trickDetector.stopDetection();
                logDevice("Trick detection stopped");
            }
            
            logDevice("Resources cleaned up successfully");
            System.println("InlineSkatingApp: Resources cleaned up successfully");
            
        } catch (exception) {
            logError("cleanupResources", exception);
            System.println("InlineSkatingApp: Error during cleanup: " + exception.getErrorMessage());
        }
    }

    // Start a new skating session
    function startSession() as Void {
        logDevice("Starting session");
        
        if (isSessionActive) {
            logDevice("Session already active - ignoring start request");
            System.println("InlineSkatingApp: Session already active");
            return;
        }
        
        try {
            System.println("InlineSkatingApp: Starting new session");
            
            // Ensure components are initialized - testing purpose
            if (!ensureComponentsReady()) {
                logCritical("Cannot start session - components not ready");
                System.println("InlineSkatingApp: Cannot start session - components not ready");
                return;
            }

            // Start FIT recording FIRST
            var recordingStarted = activityRecorder.startRecording();
            if (recordingStarted) {
                System.println("InlineSkatingApp: FIT recording started");
            } else {
                System.println("InlineSkatingApp: Warning - FIT recording failed to start");
                // Continue anyway - app can work without recording
            }
            
            // Reset and start statistics
            sessionStats.reset();
            sessionStats.startSession();
            logDevice("SessionStats reset and started");
            
            // Start sensor monitoring
            sensorManager.startSensors();
            logDevice("Sensors started");
            
            // Initialize trick detection
            trickDetector.startDetection();
            logDevice("Trick detection started");
            
            // Mark session as active
            isSessionActive = true;
            
            // Start activity recording
            //startActivitySession();
            
            logDevice("Session started successfully");
            System.println("InlineSkatingApp: Session started successfully");
            
        } catch (exception) {
            logError("startSession", exception);
            System.println("InlineSkatingApp: Error starting session: " + exception.getErrorMessage());
            isSessionActive = false;
        }
    }

    // Stop current skating session
    function stopSession() as Void {
        logDevice("Stopping session");
        
        if (!isSessionActive) {
            logDevice("No active session to stop");
            System.println("InlineSkatingApp: No active session to stop");
            return;
        }
        
        try {
            System.println("InlineSkatingApp: Stopping session");
            
            // Stop sensor monitoring
            /*if (sensorManager != null) {
                sensorManager.stopSensors();
                logDevice("Sensors stopped");
            }
            
            // Stop trick detection
            if (trickDetector != null) {
                trickDetector.stopDetection();
                logDevice("Trick detection stopped");
            }
            
            // End session statistics
            if (sessionStats != null) {
                sessionStats.endSession();
                logDevice("Session stats ended");
            }*/

            // Stop components first
            sensorManager.stopSensors();
            trickDetector.stopDetection();
            sessionStats.endSession();
            
            // Save and stop FIT recording
            //var recordingSaved = activityRecorder.stopAndSave();
            var stopSuccess = activityRecorder.stopRecording();
            var saveSuccess = activityRecorder.saveSession();

            /* if (recordingSaved) {
                System.println("InlineSkatingApp: FIT file saved to device");
            } else {
                System.println("InlineSkatingApp: Warning - FIT recording save failed");
            }    */         
            
            // Mark session as inactive
            isSessionActive = false;
            
            logDevice("Session stopped successfully");
            System.println("InlineSkatingApp: Session stopped successfully");
            
        } catch (exception) {
            logError("stopSession", exception);
            System.println("InlineSkatingApp: Error stopping session: " + exception.getErrorMessage());
        }
    }

    // Resume session after app restart
    function resumeSession() as Void {
        logDevice("Resuming session");
        
        try {
            System.println("InlineSkatingApp: Resuming session");
            
            if (!ensureComponentsReady()) {
                logCritical("Cannot resume session - components not ready");
                System.println("InlineSkatingApp: Cannot resume session - components not ready");
                isSessionActive = false;
                return;
            }
            
            // Restart sensors
            sensorManager.startSensors();
            logDevice("Sensors restarted");
            
            // Resume trick detection
            trickDetector.startDetection();
            logDevice("Trick detection resumed");
            
            logDevice("Session resumed successfully");
            System.println("InlineSkatingApp: Session resumed successfully");
            
        } catch (exception) {
            logError("resumeSession", exception);
            System.println("InlineSkatingApp: Error resuming session: " + exception.getErrorMessage());
            isSessionActive = false;
        }
    }

    // Ensure all components are ready
    function ensureComponentsReady() {
        if (sensorManager == null || trickDetector == null || sessionStats == null || activityRecorder == null) {
            logDevice("Components not ready, reinitializing");
            System.println("InlineSkatingApp: Components not ready, reinitializing...");
            return initializeComponents();
        }
        return true;
    }


    // Stop Garmin activity session
    function stopActivitySession() as Void {
        logDevice("Stopping activity recording");
        System.println("InlineSkatingApp: Stopping activity recording");
        
        if (activityRecorder != null) {
            // Stop recording first
            var stopSuccess = activityRecorder.stopRecording();
            if (stopSuccess) {
                logDevice("Activity recording stopped successfully");
                
                // Save the session
                var saveSuccess = activityRecorder.saveSession();
                if (saveSuccess) {
                    logDevice("Activity session saved successfully");
                    System.println("InlineSkatingApp: Activity session saved successfully");
                } else {
                    logDevice("Failed to save activity session");
                    System.println("InlineSkatingApp: Failed to save activity session");
                    
                    // If save fails, discard the session to free memory
                    activityRecorder.discardSession();
                }
            } else {
                logDevice("Failed to stop activity recording");
                System.println("InlineSkatingApp: Failed to stop activity recording");
            }
        }
    }
    /* 

    // Save session data to persistent storage
    function saveSessionData() as Void {
        logDevice("Saving session data");
        
        if (sessionStats != null) {
            try {
                var sessionData = sessionStats.getSessionData();
                // TODO: Save to persistent storage using Application.Storage
                logDevice("Session data saved - Tricks: " + sessionData.get("totalTricks") + ", Time: " + sessionData.get("totalTime"));
                System.println("InlineSkatingApp: Session data would be saved - Tricks: " + 
                              sessionData.get("totalTricks") + ", Time: " + 
                              sessionData.get("totalTime"));
            } catch (exception) {
                logError("saveSessionData", exception);
                System.println("InlineSkatingApp: Error getting session data: " + exception.getErrorMessage());
            }
        }
    } */

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
        logDevice("Trick detected callback - " + trickType);
        System.println("InlineSkatingApp: Trick detected callback - " + trickType);
        
        try {
            if (sessionStats != null) {
                sessionStats.addTrick(trickType, trickData);
                logDevice("Trick added to stats");
            }
            
            // Trigger UI update
            WatchUi.requestUpdate();
            
            // Optional: vibrate or beep
            if (Attention has :vibrate) {
                var vibeData = [new Attention.VibeProfile(50, 200)];
                Attention.vibrate(vibeData);
                logDevice("Vibration triggered for trick");
            }
            
        } catch (exception) {
            logError("onTrickDetected", exception);
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
        logDevice("Settings changed");
        System.println("InlineSkatingApp: Settings changed");
    }
}

// Simple error view for fallback
class SimpleErrorView extends WatchUi.View {
    var errorMessage;
    
    function initialize(message) {
        View.initialize();
        errorMessage = message;
        logCritical("SimpleErrorView created: " + message);
    }
    
    function onUpdate(dc) {
        try {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 20, Graphics.FONT_SMALL, "ERROR", Graphics.TEXT_JUSTIFY_CENTER);
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_TINY, errorMessage, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 20, Graphics.FONT_XTINY, "Check logs", Graphics.TEXT_JUSTIFY_CENTER);
            
        } catch (exception) {
            logError("SimpleErrorView onUpdate", exception);
        }
    }

 
    
}