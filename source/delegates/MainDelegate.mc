// MainDelegate.mc
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
        
        // Use standard key handling for most buttons
        switch (key) {
            case 4:  // START button - session control
            case WatchUi.KEY_START:
                return onStartPress();
            case WatchUi.KEY_ENTER:
            case 7:  // CENTER button alternatives
            case 12:
                return onEnterButton();
            case 13: // UP button
            case WatchUi.KEY_UP:
                return onUpButton();
            case 8:  // DOWN button
            case WatchUi.KEY_DOWN:
                return onDownButton();
            case 5:  // BACK button
            case WatchUi.KEY_ESC:
                return onBackButton();
            default:
                System.println("MainDelegate: Unhandled key - " + key);
                return false;
        }
    }
    
    // Also handle key pressed for immediate feedback
    function onKeyPressed(keyEvent) {
        var key = keyEvent.getKey();
        System.println("MainDelegate: Key pressed = " + key);
        
        // Immediate feedback for START button
        if (key == 4 || key == WatchUi.KEY_START) {
            // Could add immediate visual feedback here
            return true;
        }
        
        return false; // Let onKey handle the actual logic
    }
    
    // START button - session control like in old version
    function onStartPress() {
        System.println("MainDelegate: START pressed - controlling session");
        
        // Simple debounce protection
        var currentTime = System.getTimer();
        if (currentTime - lastButtonPress < BUTTON_DEBOUNCE_TIME) {
            System.println("MainDelegate: Ignoring rapid START press");
            return true;
        }
        lastButtonPress = currentTime;
        
        // Use same logic as old version - check SessionStats and call app methods
        try {
            var sessionStats = app.getSessionStats();
            if (sessionStats != null && sessionStats.isActive()) {
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
            if (viewManager != null) {
                if (viewManager.isOnMainView()) {
                    // On main view - show exit confirmation
                    showExitConfirmation();
                } else {
                    // On other view - return to main
                    viewManager.switchToMainView();
                }
            }
        } catch (exception) {
            System.println("MainDelegate: Error in onBackButton: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // Show exit confirmation when on main view
    function showExitConfirmation() {
        try {
            var sessionManager = app.getSessionManager();
            
            if (sessionManager != null && !sessionManager.isStopped()) {
                // Session is active - show session options
                showSessionMenu();
            } else {
                // No active session - show simple exit confirmation
                var confirmation = new WatchUi.Confirmation("Exit application?");
                WatchUi.pushView(confirmation, new ExitConfirmationDelegate(), WatchUi.SLIDE_UP);
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
        System.println("MainDelegate: Select pressed - redirecting to ENTER");
        return onEnterButton();
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
            System.exit();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true; // Add missing return
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
}