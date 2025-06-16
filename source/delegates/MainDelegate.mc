// /delegates/MainDelegate.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Main Input Delegate with Long Press Support
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Timer;

class MainDelegate extends WatchUi.BehaviorDelegate {
    
    var app;
    var viewManager;
    var longPressTimer;
    
    // Button debouncing
    var lastButtonPress = 0;
    const BUTTON_DEBOUNCE_TIME = 800;  // 800ms debounce like in old version
    
    function initialize(appRef) {
        BehaviorDelegate.initialize();
        app = appRef;
        longPressTimer = null;
        
        System.println("MainDelegate: Initialized");
    }
    
    function setViewManager(manager) {
        viewManager = manager;
        System.println("MainDelegate: ViewManager set");
    }
    
    // Handle key events with proper press/release detection
    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        System.println("MainDelegate: Key event = " + key);
        
        // FIXED: Force START button to control session
        switch (key) {
            case 4:  // START button - FORCE session control
            case WatchUi.KEY_START:
                System.println("MainDelegate: START button detected - calling onStartPress");
                return onStartPress();
            case WatchUi.KEY_ENTER:
            case 7:  // CENTER button alternatives
            case 12:
                System.println("MainDelegate: ENTER button detected - switching view");
                return onEnterButton();
            case 13: // UP button
            case WatchUi.KEY_UP:
                System.println("MainDelegate: UP button detected - next view");
                return onUpButton();
            case 8:  // DOWN button
            case WatchUi.KEY_DOWN:
                System.println("MainDelegate: DOWN button detected - previous view");
                return onDownButton();
            case 5:  // BACK button - FORCE app exit logic
            case WatchUi.KEY_ESC:
                System.println("MainDelegate: BACK button detected - calling onBackButton");
                return onBackButton();
            default:
                System.println("MainDelegate: Unhandled key - " + key);
                return false;
        }
    }
    
    // Also handle key pressed for immediate feedback
    function onKeyPressed(keyEvent) {
        var key = keyEvent.getKey();
        System.println("MainDelegate: Key pressed = " + key + " (will be handled by onKey)");
        
        // FIXED: Don't intercept any keys - let onKey handle everything
        return false; // Always let onKey handle the logic
    }

    // Handle key released for START button
    function onStartPress() {
        System.println("MainDelegate: START pressed - controlling session");
        
        // Simple debounce protection
        var currentTime = System.getTimer();
        if (currentTime - lastButtonPress < BUTTON_DEBOUNCE_TIME) {
            System.println("MainDelegate: Ignoring rapid START press");
            return true;
        }
        lastButtonPress = currentTime;
        
        // FIXED: Use SessionManager instead of SessionStats
        try {
            if (app != null) {
                var sessionManager = app.getSessionManager();
                if (sessionManager != null) {
                    if (sessionManager.isActive()) {
                        // Stop current session
                        app.stopAndSaveSession();
                        System.println("MainDelegate: Session stopped by user");
                        logDevice("Session stopped via START button");
                    } else {
                        // Start new session
                        app.startSession();
                        System.println("MainDelegate: Session started by user");
                        logDevice("Session started via START button");
                    }
                } else {
                    System.println("MainDelegate: SessionManager is null");
                }
            } else {
                System.println("MainDelegate: App reference is null");
            }
        } catch (exception) {
            System.println("MainDelegate: Error controlling session: " + exception.getErrorMessage());
            logError("START button session control", exception);
        }
        
        return true;
    }
    
    function onStartRelease() {
        // Remove long press logic - not needed anymore
        return true;
    }
    
    function onLongPressDetected() {
        // Removed - no longer using long press
    }
    
    // Short START press - toggle session state  
    function handleShortStartPress() {
        // This functionality moved to onStartPress()
    }
    
    // Long START press - show session menu
    function showSessionMenu() {
        try {
            var sessionManager = app.getSessionManager();
            if (sessionManager == null) {
                return;
            }
            
            var menu = new WatchUi.Menu2({:title => "Session Options"});
            
            if (sessionManager.isPaused()) {
                menu.addItem(new WatchUi.MenuItem("Resume", "Continue session", :resume, null));
            }
            
            if (!sessionManager.isStopped()) {
                menu.addItem(new WatchUi.MenuItem("Stop & Save", "Save to Garmin", :stop_save, null));
                menu.addItem(new WatchUi.MenuItem("Discard", "Delete session", :discard, null));
            }
            
            menu.addItem(new WatchUi.MenuItem("Cancel", "Go back", :cancel, null));
            
            WatchUi.pushView(menu, new SessionMenuDelegate(app), WatchUi.SLIDE_UP);
            
        } catch (exception) {
            System.println("MainDelegate: Error showing session menu: " + exception.getErrorMessage());
        }
    }
    
    // CENTER/ENTER button - switch views
    function onEnterButton() {
        System.println("MainDelegate: ENTER pressed - switching view");
        
        try {
            if (viewManager != null) {
                viewManager.switchToNextView();
            }
        } catch (exception) {
            System.println("MainDelegate: Error in onEnterButton: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // UP button - switch to next view
    function onUpButton() {
        System.println("MainDelegate: UP pressed - next view");
        
        try {
            if (viewManager != null) {
                viewManager.switchToNextView();
            }
        } catch (exception) {
            System.println("MainDelegate: Error in onUpButton: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // DOWN button - switch to previous view
    function onDownButton() {
        System.println("MainDelegate: DOWN pressed - previous view");
        
        try {
            if (viewManager != null) {
                viewManager.switchToPreviousView();
            }
        } catch (exception) {
            System.println("MainDelegate: Error in onDownButton: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // BACK button - smart navigation
    function onBackButton() {
        System.println("MainDelegate: BACK pressed");
        
        try {
            // Check if session is active using SessionManager
            var sessionActive = false;
            if (app != null) {
                var sessionManager = app.getSessionManager();
                if (sessionManager != null) {
                    sessionActive = sessionManager.isActive();
                }
            }
            
            if (sessionActive) {
                // Session is active - show confirmation
                showExitConfirmation();
                return true;
            } else {
                // No active session - allow exit
                System.println("MainDelegate: No active session - allowing exit");
                return false;  // This allows app to exit
            }
            
        } catch (exception) {
            System.println("MainDelegate: Error in onBackButton: " + exception.getErrorMessage());
            return false;  // Allow exit on error
        }
    }
        
    // Show exit confirmation when on main view
    function showExitConfirmation() {
        try {
            var sessionManager = app.getSessionManager();
            
            if (sessionManager != null && sessionManager.isActive()) {
                // Session is active - show stop confirmation
                var confirmation = new WatchUi.Confirmation("Stop session and exit?");
                WatchUi.pushView(confirmation, new ExitConfirmationDelegate(), WatchUi.SLIDE_UP);
            } else {
                // No active session - show simple exit confirmation
                var confirmation = new WatchUi.Confirmation("Exit application?");
                WatchUi.pushView(confirmation, new SimpleExitDelegate(), WatchUi.SLIDE_UP);
            }
            
        } catch (exception) {
            System.println("MainDelegate: Error showing exit confirmation: " + exception.getErrorMessage());
        }
    }
    
    // MENU button - show main menu
    function onMenu() {
        System.println("MainDelegate: MENU pressed");
        
        try {
            var menu = new WatchUi.Menu2({:title => "AGV Options"});
            
            menu.addItem(new WatchUi.MenuItem("Settings", "App settings", :settings, null));
            menu.addItem(new WatchUi.MenuItem("Reset Stats", "Clear session", :reset, null));
            menu.addItem(new WatchUi.MenuItem("About", "App info", :about, null));
            
            WatchUi.pushView(menu, new MainMenuDelegate(app), WatchUi.SLIDE_UP);
            
        } catch (exception) {
            System.println("MainDelegate: Error showing menu: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // Override onSelect to prevent conflicts
    function onSelect() {
        System.println("MainDelegate: Select pressed - treating as START button");
        return onStartPress();  // FIXED: START button should control session
    }
}

// Session menu delegate
class SessionMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    
    function initialize(appRef) {
        Menu2InputDelegate.initialize();
        app = appRef;
    }
    
    function onSelect(item) {
        var id = item.getId();
        
        try {
            var sessionManager = app.getSessionManager();
            if (sessionManager == null) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return;
            }
            
            switch (id) {
                case :resume:
                    sessionManager.resumeSession();
                    break;
                case :stop_save:
                    sessionManager.stopAndSaveSession();
                    break;
                case :discard:
                    sessionManager.discardSession();
                    break;
                case :cancel:
                    break; // Just close menu
            }
            
        } catch (exception) {
            System.println("SessionMenuDelegate: Error: " + exception.getErrorMessage());
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// Exit confirmation delegate
class ExitConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    
    function initialize() {
        ConfirmationDelegate.initialize();
    }
    
    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            // User confirmed - stop session and exit
            try {
                var app = Application.getApp();
                if (app != null) {
                    var sessionManager = app.getSessionManager();
                    if (sessionManager != null && sessionManager.isActive()) {
                        // Stop and save session before exit
                        sessionManager.stopAndSaveSession();
                        System.println("ExitConfirmationDelegate: Session stopped before exit");
                    }
                }
            } catch (exception) {
                System.println("ExitConfirmationDelegate: Error stopping session: " + exception.getErrorMessage());
            }
            
            // Exit application
            System.exit();
        } else {
            // User cancelled - just close dialog
            WatchUi.popView(WatchUi.SLIDE_UP);
        }
        return true;
    }
}

class SimpleExitDelegate extends WatchUi.ConfirmationDelegate {
    
    function initialize() {
        ConfirmationDelegate.initialize();
    }
    
    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            // Simple exit without stopping session
            System.println("SimpleExitDelegate: Exiting application");
            System.exit();
        } else {
            // User cancelled - just close dialog
            WatchUi.popView(WatchUi.SLIDE_UP);
        }
        return true;
    }
}

// Main menu delegate
class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    
    function initialize(appRef) {
        Menu2InputDelegate.initialize();
        app = appRef;
    }
    
    function onSelect(item) {
        var id = item.getId();
        
        switch (id) {
            case :settings:
                // Show settings view
                if (app.getViewManager() != null) {
                    app.getViewManager().switchToView(5); // VIEW_SETTINGS = 5
                }
                break;
            case :reset:
                // Reset session stats
                if (app.getSessionStats() != null) {
                    app.getSessionStats().resetStats();
                }
                break;
            case :about:
                // Show about dialog
                showAboutDialog();
                break;
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    function showAboutDialog() {
        var confirmation = new WatchUi.Confirmation("AGV Tracker v3.0.0\nby Vít Kotačka");
        WatchUi.pushView(confirmation, new WatchUi.ConfirmationDelegate(), WatchUi.SLIDE_UP);
    }

    function logDevice(message) {
        System.println("AGV-DEVICE: " + message);
    }

    function logError(context, exception) {
        System.println("AGV-ERROR [" + context + "]: " + exception.getErrorMessage());
    }

}