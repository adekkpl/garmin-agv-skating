// ViewDelegate.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// View-specific Input Delegate
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;

class ViewDelegate extends WatchUi.BehaviorDelegate {
    
    var app;
    var lastButtonPress = 0;
    const BUTTON_DEBOUNCE_TIME = 800; // Same as MainDelegate
    
    function initialize(appRef) {
        BehaviorDelegate.initialize();
        app = appRef;
        System.println("ViewDelegate: Initialized");
    }
    
    // Handle key events
    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        System.println("ViewDelegate: Key event = " + key);
        
        // FIXED: Przekaż START i BACK do MainDelegate
        switch (key) {
            case 4:  // START button - ZAWSZE przekaż do MainDelegate
            case WatchUi.KEY_START:
                System.println("ViewDelegate: START button - delegating to MainDelegate");
                return delegateToMainDelegate(keyEvent);
                
            case 5:  // BACK button - ZAWSZE przekaż do MainDelegate  
            case WatchUi.KEY_ESC:
                System.println("ViewDelegate: BACK button - delegating to MainDelegate");
                return delegateToMainDelegate(keyEvent);
                
            // Inne przyciski obsługuj normalnie
            case WatchUi.KEY_ENTER:
            case 7:
            case 12:
                return onEnterButton();
            case 13:
            case WatchUi.KEY_UP:
                return onUpButton();
            case 8:
            case WatchUi.KEY_DOWN:
                return onDownButton();
            default:
                return false;
        }
    }
    
    function delegateToMainDelegate(keyEvent) {
        try {
            // USUŃ linię z getMainDelegate() - nie istnieje
            // Użyj bezpośrednio fallback funkcji
            
            var key = keyEvent.getKey();
            System.println("ViewDelegate: Delegating key " + key + " to fallback handlers");
            
            if (key == 4 || key == WatchUi.KEY_START) {
                return handleStartButton();
            } else if (key == 5 || key == WatchUi.KEY_ESC) {
                return handleBackButton();
            }
            
        } catch (exception) {
            System.println("ViewDelegate: Error delegating key: " + exception.getErrorMessage());
        }
        
        return false;
    }


    function handleStartButton() {
        System.println("ViewDelegate: Handling START button for session control");
        
        try {
            var app = Application.getApp();
            if (app != null) {
                var sessionManager = app.getSessionManager();
                if (sessionManager != null) {
                    if (sessionManager.isActive()) {
                        app.stopAndSaveSession();
                        System.println("ViewDelegate: Session stopped by user");
                    } else {
                        app.startSession();
                        System.println("ViewDelegate: Session started by user");
                    }
                    return true;
                }
            }
        } catch (exception) {
            System.println("ViewDelegate: Error handling START: " + exception.getErrorMessage());
        }
        
        return false;
    }

    function handleBackButton() {
        System.println("ViewDelegate: Handling BACK button - checking session");
        
        try {
            var app = Application.getApp();
            if (app != null) {
                var sessionManager = app.getSessionManager();
                if (sessionManager != null && sessionManager.isActive()) {
                    // Session active - show confirmation
                    var confirmation = new WatchUi.Confirmation("Stop session and exit?");
                    WatchUi.pushView(confirmation, new ExitConfirmationDelegate(), WatchUi.SLIDE_UP);
                    return true;
                } else {
                    // No active session - allow exit
                    System.println("ViewDelegate: No active session - allowing exit");
                    return false;  // This allows app to exit
                }
            }
        } catch (exception) {
            System.println("ViewDelegate: Error handling BACK: " + exception.getErrorMessage());
        }
        
        return false;
    }

    // START button - same logic as old version
    function onStartButton() {
        System.println("ViewDelegate: START pressed - controlling session");
        
        // Simple debounce protection
        var currentTime = System.getTimer();
        if (currentTime - lastButtonPress < BUTTON_DEBOUNCE_TIME) {
            System.println("ViewDelegate: Ignoring rapid START press");
            return true;
        }
        lastButtonPress = currentTime;
        
        // Use same logic as old version
        try {
            var sessionStats = app.getSessionStats();
            if (sessionStats != null && sessionStats.isActive()) {
                // Stop current session
                app.stopAndSaveSession();
                System.println("ViewDelegate: Session stopped by user");
            } else {
                // Start new session
                app.startSession();
                System.println("ViewDelegate: Session started by user");
            }
        } catch (exception) {
            System.println("ViewDelegate: Error controlling session: " + exception.getErrorMessage());
        }
        
        return true;
    }

    function onStartPress() {
        System.println("ViewDelegate: START pressed - controlling session");
        
        // Simple debounce protection
        var currentTime = System.getTimer();
        if (currentTime - lastButtonPress < BUTTON_DEBOUNCE_TIME) {
            System.println("ViewDelegate: Ignoring rapid START press");
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
                        System.println("ViewDelegate: Session stopped by user");
                    } else {
                        // Start new session
                        app.startSession();
                        System.println("ViewDelegate: Session started by user");
                    }
                }
            }
        } catch (exception) {
            System.println("ViewDelegate: Error controlling session: " + exception.getErrorMessage());
        }
        
        return true;
    }    
    
    // ENTER button - next view
    function onEnterButton() {
        System.println("ViewDelegate: ENTER pressed - next view");
        
        try {
            var viewManager = app.getViewManager();
            if (viewManager != null) {
                viewManager.switchToNextView();
            }
        } catch (exception) {
            System.println("ViewDelegate: Error in ENTER: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // UP button - next view
    function onUpButton() {
        System.println("ViewDelegate: UP pressed - next view");
        
        try {
            var viewManager = app.getViewManager();
            if (viewManager != null) {
                viewManager.switchToNextView();
            }
        } catch (exception) {
            System.println("ViewDelegate: Error in UP: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // DOWN button - previous view
    function onDownButton() {
        System.println("ViewDelegate: DOWN pressed - previous view");
        
        try {
            var viewManager = app.getViewManager();
            if (viewManager != null) {
                viewManager.switchToPreviousView();
            }
        } catch (exception) {
            System.println("ViewDelegate: Error in DOWN: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // BACK button - return to main view
    function onBackButton() {
        System.println("ViewDelegate: BACK pressed - returning to main");
        
        try {
            var viewManager = app.getViewManager();
            if (viewManager != null) {
                viewManager.switchToMainView();
            }
        } catch (exception) {
            System.println("ViewDelegate: Error in BACK: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // MENU button
    function onMenu() {
        System.println("ViewDelegate: MENU pressed");
        
        try {
            showViewMenu();
        } catch (exception) {
            System.println("ViewDelegate: Error in MENU: " + exception.getErrorMessage());
        }
        
        return true;
    }
    
    // Show view-specific menu
    function showViewMenu() {
        var viewManager = app.getViewManager();
        if (viewManager == null) {
            return;
        }
        
        var menu = new WatchUi.Menu2({:title => "View Options"});
        
        // Add view navigation options
        menu.addItem(new WatchUi.MenuItem("Main View", "Session overview", :main, null));
        menu.addItem(new WatchUi.MenuItem("Stats View", "Session stats", :stats, null));
        menu.addItem(new WatchUi.MenuItem("Tricks View", "Trick detection", :tricks, null));
        menu.addItem(new WatchUi.MenuItem("Rotation View", "Rotation stats", :rotation, null));
        menu.addItem(new WatchUi.MenuItem("Progress View", "Goals & progress", :progress, null));
        menu.addItem(new WatchUi.MenuItem("Settings", "App settings", :settings, null));
        
        WatchUi.pushView(menu, new ViewMenuDelegate(app), WatchUi.SLIDE_UP);
    }
    
    // Override onSelect to prevent conflicts
    function onSelect() {
        return onEnterButton();
    }
}

// View menu delegate
class ViewMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    
    function initialize(appRef) {
        Menu2InputDelegate.initialize();
        app = appRef;
    }
    
    function onSelect(item) {
        var id = item.getId();
        var viewManager = app.getViewManager();
        
        if (viewManager == null) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }
        
        try {
            switch (id) {
                case :main:
                    viewManager.switchToView(0); // VIEW_MAIN
                    break;
                case :stats:
                    viewManager.switchToView(1); // VIEW_STATS
                    break;
                case :tricks:
                    viewManager.switchToView(2); // VIEW_TRICKS
                    break;
                case :rotation:
                    viewManager.switchToView(3); // VIEW_ROTATION
                    break;
                case :progress:
                    viewManager.switchToView(4); // VIEW_PROGRESS
                    break;
                case :settings:
                    viewManager.switchToView(5); // VIEW_SETTINGS
                    break;
            }
        } catch (exception) {
            System.println("ViewMenuDelegate: Error switching view: " + exception.getErrorMessage());
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}