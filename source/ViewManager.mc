// ViewManager.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// View Management System
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;

class ViewManager {
    
    // View types
    const VIEW_MAIN = 0;
    const VIEW_STATS = 1;
    const VIEW_TRICKS = 2;
    const VIEW_ROTATION = 3;
    const VIEW_PROGRESS = 4;
    const VIEW_SETTINGS = 5;
    
    var currentViewType;
    var app;
    
    // View instances (lazy loaded)
    var mainView;
    var statsView;
    var tricksView;
    var rotationView;
    var progressView;
    var settingsView;
    
    function initialize(appRef) {
        app = appRef;
        currentViewType = VIEW_MAIN;
        
        // Views will be created on demand
        mainView = null;
        statsView = null;
        tricksView = null;
        rotationView = null;
        progressView = null;
        settingsView = null;
        
        System.println("ViewManager: Initialized");
    }
    
    // Get current view instance
    function getCurrentView() {
        switch (currentViewType) {
            case VIEW_MAIN:
                return getMainView();
            case VIEW_STATS:
                return getStatsView();
            case VIEW_TRICKS:
                return getTricksView();
            case VIEW_ROTATION:
                return getRotationView();
            case VIEW_PROGRESS:
                return getProgressView();
            case VIEW_SETTINGS:
                return getSettingsView();
            default:
                return getMainView();
        }
    }
    
    // Get specific view instances (lazy loading)
    function getMainView() {
        if (mainView == null) {
            mainView = new MainView(app);
            System.println("ViewManager: MainView created");
        }
        return mainView;
    }
    
    function getStatsView() {
        if (statsView == null) {
            statsView = new StatsView(app);
            System.println("ViewManager: StatsView created");
        }
        return statsView;
    }
    
    function getTricksView() {
        if (tricksView == null) {
            tricksView = new TricksView(app);
            System.println("ViewManager: TricksView created");
        }
        return tricksView;
    }
    
    function getRotationView() {
        if (rotationView == null) {
            rotationView = new RotationView(app);
            System.println("ViewManager: RotationView created");
        }
        return rotationView;
    }
    
    function getProgressView() {
        if (progressView == null) {
            progressView = new ProgressView(app);
            System.println("ViewManager: ProgressView created");
        }
        return progressView;
    }
    
    function getSettingsView() {
        if (settingsView == null) {
            settingsView = new SettingsView(app);
            System.println("ViewManager: SettingsView created");
        }
        return settingsView;
    }
    
    // Navigate to next view
    function switchToNextView() {
        var nextViewType = (currentViewType + 1) % 6; // 6 total views
        switchToView(nextViewType);
    }
    
    // Navigate to previous view
    function switchToPreviousView() {
        var prevViewType = currentViewType - 1;
        if (prevViewType < 0) {
            prevViewType = 5; // Last view
        }
        switchToView(prevViewType);
    }
    
    // Switch to specific view
    function switchToView(viewType) {
        if (viewType == currentViewType) {
            return false; // Already on this view
        }
        
        try {
            // Cleanup starego view (szczególnie timer w MainView)
            cleanupCurrentView();

            currentViewType = viewType;
            var newView = getCurrentView();
            
            if (newView != null) {
                WatchUi.switchToView(newView, new ViewDelegate(app), WatchUi.SLIDE_IMMEDIATE);
                System.println("ViewManager: Switched to " + getViewName(viewType));
                return true;
            } else {
                System.println("ViewManager: Failed to create view " + viewType);
                return false;
            }
            
        } catch (exception) {
            System.println("ViewManager: Error switching view: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Switch to main view (for BACK button)
    function switchToMainView() {
        return switchToView(VIEW_MAIN);
    }
    
    // Get current view type
    function getCurrentViewType() {
        return currentViewType;
    }
    
    // Check if currently on main view
    function isOnMainView() {
        return currentViewType == VIEW_MAIN;
    }
    
    // Get view name for debugging
    function getViewName(viewType) {
        switch (viewType) {
            case VIEW_MAIN:
                return "MAIN";
            case VIEW_STATS:
                return "STATS";
            case VIEW_TRICKS:
                return "TRICKS";
            case VIEW_ROTATION:
                return "ROTATION";
            case VIEW_PROGRESS:
                return "PROGRESS";
            case VIEW_SETTINGS:
                return "SETTINGS";
            default:
                return "UNKNOWN";
        }
    }
    
    function getCurrentViewName() {
        return getViewName(currentViewType);
    }
    
    // Notify all views of events
    function onTrickDetected(trickType, trickData) {
        try {
            // Notify all created views
            if (mainView != null) { mainView.onTrickDetected(trickType, trickData); }
            if (statsView != null) { statsView.onTrickDetected(trickType, trickData); }
            if (tricksView != null) { tricksView.onTrickDetected(trickType, trickData); }
            if (rotationView != null) { rotationView.onTrickDetected(trickType, trickData); }
            if (progressView != null) { progressView.onTrickDetected(trickType, trickData); }
            
            // Request update for current view
            WatchUi.requestUpdate();
            
        } catch (exception) {
            System.println("ViewManager: Error notifying trick detected: " + exception.getErrorMessage());
        }
    }
    
    function onRotationDetected(direction, angle) {
        try {
            // Notify all created views
            if (mainView != null) { mainView.onRotationDetected(direction, angle); }
            if (statsView != null) { statsView.onRotationDetected(direction, angle); }
            if (tricksView != null) { tricksView.onRotationDetected(direction, angle); }
            if (rotationView != null) { rotationView.onRotationDetected(direction, angle); }
            if (progressView != null) { progressView.onRotationDetected(direction, angle); }
            
            // Request update for current view
            WatchUi.requestUpdate();
            
        } catch (exception) {
            System.println("ViewManager: Error notifying rotation detected: " + exception.getErrorMessage());
        }
    }
    
    function onSessionStateChange(newState) {
        try {
            // Notify all created views
            if (mainView != null) { mainView.onSessionStateChange(newState); }
            if (statsView != null) { statsView.onSessionStateChange(newState); }
            if (tricksView != null) { tricksView.onSessionStateChange(newState); }
            if (rotationView != null) { rotationView.onSessionStateChange(newState); }
            if (progressView != null) { progressView.onSessionStateChange(newState); }
            if (settingsView != null) { settingsView.onSessionStateChange(newState); }
            
            // Request update for current view
            WatchUi.requestUpdate();
            
        } catch (exception) {
            System.println("ViewManager: Error notifying session state change: " + exception.getErrorMessage());
        }
    }
    
    // Force update current view
    function requestUpdate() {
        WatchUi.requestUpdate();
    }
    
    function cleanupCurrentView() {
        try {
            // Cleanup MainView timer jeśli istnieje
            if (mainView != null && mainView has :cleanup) {
                mainView.cleanup();
            }
            
            // Możesz dodać cleanup dla innych view jeśli potrzebne
            if (statsView != null && statsView has :cleanup) {
                statsView.cleanup();
            }
            
            if (tricksView != null && tricksView has :cleanup) {
                tricksView.cleanup();
            }
            
            if (rotationView != null && rotationView has :cleanup) {
                rotationView.cleanup();
            }
            
            if (progressView != null && progressView has :cleanup) {
                progressView.cleanup();
            }
            
            if (settingsView != null && settingsView has :cleanup) {
                settingsView.cleanup();
            }
            
            System.println("ViewManager: Current view cleaned up");
            
        } catch (exception) {
            System.println("ViewManager: Error in cleanup: " + exception.getErrorMessage());
        }
    }

    // Cleanup all views
    function cleanup() {
        try {
            cleanupCurrentView();

            // Reset view references
            /* mainView = null;
            statsView = null;
            tricksView = null;
            rotationView = null;
            progressView = null;
            settingsView = null; */
            if (mainView != null) { mainView.cleanup(); }
            if (statsView != null) { statsView.cleanup(); }
            if (tricksView != null) { tricksView.cleanup(); }
            if (rotationView != null) { rotationView.cleanup(); }
            if (progressView != null) { progressView.cleanup(); }
            if (settingsView != null) { settingsView.cleanup(); }
            
            System.println("ViewManager: Cleanup completed");
        } catch (exception) {
            System.println("ViewManager: Error during cleanup: " + exception.getErrorMessage());
        }
    }
}