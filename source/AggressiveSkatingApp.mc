// AggressiveSkatingApp.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Refactored Application Core
using Toybox.Lang;
using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Timer;

class AggressiveSkatingApp extends Application.AppBase {
    
    // Core components
    var sensorManager;
    var sessionManager;        // NOWY: Zarządzanie stanem sesji
    var sessionStats;
    var activityRecorder;
    var trickDetector;
    var rotationDetector;      // NOWY: Wykrywanie obrotów
    var gpsTracker;           // NOWY: Dedykowany GPS
    
    // View management
    var currentView;
    var mainDelegate;
    var viewManager;          // NOWY: Zarządzanie widokami
    
    // Application state
    var isInitialized = false;
    var debugMode = false;

    function initialize() {
        AppBase.initialize();
        System.println("AggressiveSkatingApp v3.0.0: Starting initialization...");
        logDevice("App initialization START");
    }

    function onStart(state) {
        try {
            logDevice("App starting...");
            System.println("AggressiveSkatingApp: onStart called");
            
            // Initialize all components
            if (!initializeComponents()) {
                logCritical("Component initialization failed");
                return;
            }
            
            // Restore session state if available
            if (state != null) {
                restoreSessionState(state);
            }
            
            isInitialized = true;
            logDevice("App started successfully");
            
        } catch (exception) {
            logError("onStart", exception);
        }
    }

    function onStop(state) {
        try {
            logDevice("App stopping...");
            
            // Save current session state
            if (state != null && sessionManager != null) {
                saveSessionState(state);
            }
            
            // Clean up all resources
            cleanupResources();
            logDevice("App stopped successfully");
            
        } catch (exception) {
            logError("onStop", exception);
        }
    }

    function getInitialView() {
        logDevice("Creating initial view and delegate");
        
        try {
            if (!isInitialized) {
                return [new ErrorView("App not initialized"), new WatchUi.BehaviorDelegate()];
            }
            
            // Create view manager and main delegate
            viewManager = new ViewManager(self);
            mainDelegate = new MainDelegate(self);
            
            // Get initial main view
            currentView = viewManager.getMainView();
            
            if (currentView == null || mainDelegate == null) {
                logCritical("Failed to create initial view or delegate");
                return [new ErrorView("Failed to create views"), new WatchUi.BehaviorDelegate()];
            }
            
            // Connect delegate with view manager
            mainDelegate.setViewManager(viewManager);
            
            logDevice("Initial view and delegate created successfully");
            return [currentView, mainDelegate];
            
        } catch (exception) {
            logError("getInitialView", exception);
            return [new ErrorView("Failed to initialize"), new WatchUi.BehaviorDelegate()];
        }
    }

    // Initialize all application components
    function initializeComponents() {
        logDevice("Initializing components START");
        
        try {
            // Initialize session management first
            logDevice("Creating SessionManager");
            sessionManager = new SessionManager();
            if (sessionManager == null) {
                logCritical("Failed to create SessionManager");
                return false;
            }
            
            // Initialize GPS tracker
            logDevice("Creating GPSTracker");
            gpsTracker = new GPSTracker();
            if (gpsTracker == null) {
                logCritical("Failed to create GPSTracker");
                return false;
            }
            
            // Initialize sensor management
            logDevice("Creating SensorManager");
            sensorManager = new SensorManager();
            if (sensorManager == null) {
                logCritical("Failed to create SensorManager");
                return false;
            }
            
            // Initialize session statistics
            logDevice("Creating SessionStats");
            sessionStats = new SessionStats();
            if (sessionStats == null) {
                logCritical("Failed to create SessionStats");
                return false;
            }
            
            // Initialize activity recorder
            logDevice("Creating ActivityRecorder");
            activityRecorder = new ActivityRecorder();
            if (activityRecorder == null) {
                logCritical("Failed to create ActivityRecorder");
                return false;
            }
            
            /* 
            // Initialize trick detection - moved to sensors 
            logDevice("Creating TrickDetector");
            trickDetector = new TrickDetector();
            if (trickDetector == null) {
                logCritical("Failed to create TrickDetector");
                return false;
            } */
            logDevice("TrickDetector will be initialized by SensorManager");
            
            // Initialize rotation detection
            logDevice("Creating RotationDetector");
            rotationDetector = new RotationDetector();
            if (rotationDetector == null) {
                logCritical("Failed to create RotationDetector");
                return false;
            }
            
            // Setup component connections
            setupComponentConnections();
            
            logDevice("All components initialized successfully");
            return true;
            
        } catch (exception) {
            logError("initializeComponents", exception);
            return false;
        }
    }
    
    // Setup connections between components
    function setupComponentConnections() {
        try {
            // Connect session manager with other components
            if (sessionManager != null) {
                sessionManager.setGPSTracker(gpsTracker);
                sessionManager.setSessionStats(sessionStats);
                sessionManager.setActivityRecorder(activityRecorder);
            }
            
            // Connect sensor manager with detectors - sprawdź czy metody istnieją
            if (sensorManager != null) {
                // Tylko wywołuj metody jeśli istnieją
                try {
                    if (sensorManager has :setTrickDetector) {
                        sensorManager.setTrickDetector(trickDetector);
                    }
                    if (sensorManager has :setRotationDetector) {
                        sensorManager.setRotationDetector(rotationDetector);
                    }
                    if (sensorManager has :setGPSTracker) {
                        sensorManager.setGPSTracker(gpsTracker);
                    }
                    if (sessionStats != null) {
                        sensorManager.setSessionStats(sessionStats);
                    }
                } catch (methodException) {
                    System.println("SensorManager methods not available: " + methodException.getErrorMessage());
                }
            }
            
            // Setup callbacks - sprawdź czy metody istnieją
            if (trickDetector != null) {
                try {
                    if (trickDetector has :setTrickDetectedCallback) {
                        trickDetector.setTrickDetectedCallback(method(:onTrickDetected));
                    }
                } catch (callbackException) {
                    System.println("TrickDetector callback not available: " + callbackException.getErrorMessage());
                }
            }
            
            if (rotationDetector != null) {
                try {
                    if (rotationDetector has :setRotationDetectedCallback) {
                        rotationDetector.setRotationDetectedCallback(method(:onRotationDetected));                        
                    }
                } catch (callbackException) {
                    System.println("RotationDetector callback not available: " + callbackException.getErrorMessage());
                }
            }
            
            if (gpsTracker != null) {
                try {
                    if (gpsTracker has :setPositionUpdateCallback) {
                        gpsTracker.setPositionUpdateCallback(method(:onPositionUpdate));
                    }
                } catch (callbackException) {
                    System.println("GPSTracker callback not available: " + callbackException.getErrorMessage());
                }
            }
            
        // Setup session state callbacks
            if (sessionManager != null) {
                try {
                    if (sessionManager has :setStateChangeCallback) {
                        sessionManager.setStateChangeCallback(method(:onSessionStateChange));
                    }
                } catch (callbackException) {
                    System.println("SessionManager callback not available: " + callbackException.getErrorMessage());
                }
            }

            // Start sensors immediately after setup
            if (sensorManager != null) {
                System.println("App: Starting sensors...");
                sensorManager.startSensors();
            }            
            
            logDevice("Component connections established (with safety checks)");
            
        } catch (exception) {
            logError("setupComponentConnections", exception);
        }
    }

    // Save session state for app restart
    function saveSessionState(state) {
        try {
            if (sessionManager != null) {
                var sessionData = sessionManager.getSessionData();
                state.put("sessionData", sessionData);
                logDevice("Session state saved");
            }
        } catch (exception) {
            logError("saveSessionState", exception);
        }
    }
    
    // Restore session state after app restart
    function restoreSessionState(state) {
        try {
            var sessionData = state.get("sessionData");
            if (sessionData != null && sessionManager != null) {
                sessionManager.restoreSessionData(sessionData);
                logDevice("Session state restored");
            }
        } catch (exception) {
            logError("restoreSessionState", exception);
        }
    }

    // Clean up all resources
    function cleanupResources() {
        try {
            if (sessionManager != null) {
                sessionManager.cleanup();
            }
            if (sensorManager != null) {
                sensorManager.cleanup();
            }
            if (gpsTracker != null) {
                gpsTracker.cleanup();
            }
            if (trickDetector != null) {
                trickDetector.cleanup();
            }
            if (rotationDetector != null) {
                rotationDetector.cleanup();
            }
            
            logDevice("Resources cleaned up");
            
        } catch (exception) {
            logError("cleanupResources", exception);
        }
    }

    // Callback handlers
    function onTrickDetected(trickType, trickData) {
        try {
            System.println("App: Trick detected - " + trickType);
            
            // Update statistics
            if (sessionStats != null) {
                sessionStats.addTrick(trickType, trickData);
            }
            
            // Notify views
            if (viewManager != null) {
                viewManager.onTrickDetected(trickType, trickData);
            }
            
        } catch (exception) {
            logError("onTrickDetected", exception);
        }
    }
    
    function onRotationDetected(degrees, direction) {  // degrees first, direction second
        try {
            System.println("App: Rotation detected - " + degrees + "° direction: " + direction);
            
            // Update statistics
            if (sessionStats != null) {
                sessionStats.addRotation(degrees, direction);
            }
            
            // Notify views
            if (viewManager != null) {
                viewManager.onRotationDetected(degrees, direction); 
            }
            
        } catch (exception) {
            logError("onRotationDetected", exception);
        }
    }
    
    function onJumpDetected(jumpType, jumpData) {
        try {
            System.println("App: Jump detected - " + jumpType + " magnitude: " + jumpData.get("acceleration"));
            
            // Update statistics
            if (sessionStats != null) {
                sessionStats.addTrick(jumpType, jumpData); // Użyj istniejącą metodę
            }
            
            // Notify views
            if (viewManager != null) {
                viewManager.onTrickDetected(jumpType, jumpData); // Użyj istniejący system
            }
            
        } catch (exception) {
            logError("onJumpDetected", exception);
        }
    }

    function onPositionUpdate(position) {
        try {
            // Update session stats with GPS data
            if (sessionStats != null) {
                sessionStats.updateGPSData(position);
            }
            
        } catch (exception) {
            logError("onPositionUpdate", exception);
        }
    }
    
    function onSessionStateChange(newState) {
        try {
            System.println("App: Session state changed to " + newState);
            
            // Notify all views
            if (viewManager != null) {
                viewManager.onSessionStateChange(newState);
            }

            // Wymuszaj odświeżenie ekranu 
            WatchUi.requestUpdate();            
            
        } catch (exception) {
            logError("onSessionStateChange", exception);
        }
    }

    // Public getters for components
    function getSessionManager() { return sessionManager; }
    function getSensorManager() { return sensorManager; }
    function getSessionStats() { return sessionStats; }
    function getActivityRecorder() { return activityRecorder; }
    function getTrickDetector() { return trickDetector; }
    function getRotationDetector() { return rotationDetector; }
    function getGPSTracker() { return gpsTracker; }
    function getViewManager() { return viewManager; }
    
    // Session control methods
    function startSession() {
        if (sessionManager != null) {
            sessionManager.startSession();
        }
    }
    
    function pauseSession() {
        if (sessionManager != null) {
            sessionManager.pauseSession();
        }
    }
    
    function resumeSession() {
        if (sessionManager != null) {
            sessionManager.resumeSession();
        }
    }
    
    function stopAndSaveSession() {
        if (sessionManager != null) {
            sessionManager.stopAndSaveSession();
        }
    }
    
    function discardSession() {
        if (sessionManager != null) {
            sessionManager.discardSession();
        }
    }

    // Logging helpers
    function logDevice(message) {
        System.println("AGV-APP: " + message);
    }
    
    function logError(context, exception) {
        System.println("AGV-APP ERROR [" + context + "]: " + exception.getErrorMessage());
    }
    
    function logCritical(message) {
        System.println("AGV-APP CRITICAL: " + message);
    }
}

// Simple error view for fallback
class ErrorView extends WatchUi.View {
    var errorMessage;
    
    function initialize(message) {
        View.initialize();
        errorMessage = message;
    }
    
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 20, 
                   Graphics.FONT_SMALL, "ERROR", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + 10, 
                   Graphics.FONT_TINY, errorMessage, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

