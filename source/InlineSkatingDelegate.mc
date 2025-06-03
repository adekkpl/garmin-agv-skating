// Garmin Aggressive Inline Skating Tracker v2.0.0
// Input Delegate for Main View

import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application;

class InlineSkatingDelegate extends WatchUi.BehaviorDelegate {
    
    var view;
    var app;
    var lastButtonPress;
    
    function initialize() {
        BehaviorDelegate.initialize();
        app = Application.getApp();
        lastButtonPress = System.getTimer();
        System.println("InlineSkatingDelegate: Input delegate initialized");
    }

    // Set reference to the view for interaction
    function setView(viewRef as InlineSkatingView) as Void {
        view = viewRef;
    }

    // Handle START button press (primary action button)
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        switch (key) {
            case WatchUi.KEY_START:
                return onStartButton();
            case WatchUi.KEY_ENTER:
                return onEnterButton();
            case WatchUi.KEY_UP:
                return onUpButton();
            case WatchUi.KEY_DOWN:
                return onDownButton();
            case WatchUi.KEY_ESC:
                return onBackButton();
            default:
                return false;
        }
    }

    // Handle SELECT button (center button)
    function onSelect() as Boolean {
        return onEnterButton();
    }

    // Handle MENU button
    function onMenu() as Boolean {
        System.println("InlineSkatingDelegate: Menu button pressed");
        
        // Show main menu
        var menu = new WatchUi.Menu2({:title => "Skating Options"});
        
        // Add menu items based on session state
        var sessionActive = view != null ? view.getSessionStatus() : false;
        
        if (sessionActive) {
            menu.addItem(new WatchUi.MenuItem(
                "Stop Session",
                "End current skating session",
                :stop_session,
                {}
            ));
        } else {
            menu.addItem(new WatchUi.MenuItem(
                "Start Session", 
                "Begin new skating session",
                :start_session,
                {}
            ));
        }
        
        menu.addItem(new WatchUi.MenuItem(
            "Settings",
            "Adjust detection sensitivity",
            :settings,
            {}
        ));
        
        menu.addItem(new WatchUi.MenuItem(
            "Statistics",
            "View session history",
            :statistics,
            {}
        ));
        
        menu.addItem(new WatchUi.MenuItem(
            "About",
            "App information and version",
            :about,
            {}
        ));
        
        WatchUi.pushView(menu, new InlineSkatingMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    // Handle START button press
    function onStartButton() as Boolean {
        System.println("InlineSkatingDelegate: START button pressed");
        
        // Prevent double-press
        var currentTime = System.getTimer();
        if (currentTime - lastButtonPress < 500) {
            return true;
        }
        lastButtonPress = currentTime;
        
        // Toggle session start/stop
        if (view != null) {
            view.toggleSession();
        }
        
        return true;
    }

    // Handle ENTER/SELECT button
    function onEnterButton() as Boolean {
        System.println("InlineSkatingDelegate: ENTER button pressed");
        
        // Switch display mode
        if (view != null) {
            view.switchDisplayMode();
        }
        
        return true;
    }

    // Handle UP button
    function onUpButton() as Boolean {
        System.println("InlineSkatingDelegate: UP button pressed");
        
        // Cycle through display modes (forward)
        if (view != null) {
            view.switchDisplayMode();
        }
        
        return true;
    }

    // Handle DOWN button  
    function onDownButton() as Boolean {
        System.println("InlineSkatingDelegate: DOWN button pressed");
        
        // Could implement reverse cycling through modes
        // For now, just switch normally
        if (view != null) {
            view.switchDisplayMode();
        }
        
        return true;
    }

    // Handle BACK/ESC button
    function onBackButton() as Boolean {
        System.println("InlineSkatingDelegate: BACK button pressed");
        
        // Check if session is active before allowing exit
        var sessionActive = view != null ? view.getSessionStatus() : false;
        
        if (sessionActive) {
            // Show confirmation dialog for stopping session
            var dialog = new WatchUi.Confirmation("Stop session and exit?");
            WatchUi.pushView(dialog, new ExitConfirmationDelegate(), WatchUi.SLIDE_DOWN);
            return true;
        } else {
            // Exit normally if no active session
            return false;
        }
    }

    // Handle physical key events (for watches with physical buttons)
    function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Boolean {
        return onKey(keyEvent);
    }

    // Handle key release events
    function onKeyReleased(keyEvent as WatchUi.KeyEvent) as Boolean {
        // Could implement long-press functionality here
        return false;
    }

    // Handle swipe gestures (for touchscreen devices)
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        
        switch (direction) {
            case WatchUi.SWIPE_LEFT:
                return onSwipeLeft();
            case WatchUi.SWIPE_RIGHT:
                return onSwipeRight();
            case WatchUi.SWIPE_UP:
                return onSwipeUp();
            case WatchUi.SWIPE_DOWN:
                return onSwipeDown();
            default:
                return false;
        }
    }

    // Handle left swipe - next display mode
    function onSwipeLeft() as Boolean {
        System.println("InlineSkatingDelegate: Swipe left");
        
        if (view != null) {
            view.switchDisplayMode();
        }
        
        return true;
    }

    // Handle right swipe - previous display mode
    function onSwipeRight() as Boolean {
        System.println("InlineSkatingDelegate: Swipe right");
        
        // Could implement reverse mode switching
        if (view != null) {
            view.switchDisplayMode();
        }
        
        return true;
    }

    // Handle up swipe - show menu
    function onSwipeUp() as Boolean {
        System.println("InlineSkatingDelegate: Swipe up");
        return onMenu();
    }

    // Handle down swipe - toggle session
    function onSwipeDown() as Boolean {
        System.println("InlineSkatingDelegate: Swipe down");
        
        if (view != null) {
            view.toggleSession();
        }
        
        return true;
    }

    // Handle tap events (for touchscreen)
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        System.println("InlineSkatingDelegate: Tap at " + coordinates[0] + "," + coordinates[1]);
        
        // Could implement zone-based tapping
        // For now, treat as enter button
        return onEnterButton();
    }

    // Handle touch events
    function onSelectable(selectableEvent as WatchUi.SelectableEvent) as Boolean {
        // Handle selectable UI elements if needed
        return false;
    }
}

// Menu delegate for handling main menu selections
class InlineSkatingMenuDelegate extends WatchUi.Menu2InputDelegate {
    
    function initialize() {
        Menu2InputDelegate.initialize();
        System.println("InlineSkatingMenuDelegate: Menu delegate initialized");
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        var app = Application.getApp();
        
        System.println("InlineSkatingMenuDelegate: Menu item selected - " + itemId);
        
        switch (itemId) {
            case :start_session:
                handleStartSession(app);
                break;
            case :stop_session:
                handleStopSession(app);
                break;
            case :settings:
                handleSettings();
                break;
            case :statistics:
                handleStatistics();
                break;
            case :about:
                handleAbout();
                break;
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    // Handle start session menu item
    function handleStartSession(app as InlineSkatingApp) as Void {
        if (app != null) {
            app.startSession();
            System.println("InlineSkatingMenuDelegate: Session started from menu");
        }
    }

    // Handle stop session menu item
    function handleStopSession(app as InlineSkatingApp) as Void {
        if (app != null) {
            app.stopSession();
            System.println("InlineSkatingMenuDelegate: Session stopped from menu");
        }
    }

    // Handle settings menu item
    function handleSettings() as Void {
        System.println("InlineSkatingMenuDelegate: Opening settings");
        
        var settingsMenu = new WatchUi.Menu2({:title => "Settings"});
        
        settingsMenu.addItem(new WatchUi.MenuItem(
            "Trick Sensitivity",
            "Adjust trick detection",
            :sensitivity,
            {}
        ));
        
        settingsMenu.addItem(new WatchUi.MenuItem(
            "GPS Settings",
            "Configure GPS options",
            :gps_settings,
            {}
        ));
        
        settingsMenu.addItem(new WatchUi.MenuItem(
            "Reset Statistics",
            "Clear all session data",
            :reset_stats,
            {}
        ));
        
        WatchUi.pushView(settingsMenu, new SettingsMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Handle statistics menu item
    function handleStatistics() as Void {
        System.println("InlineSkatingMenuDelegate: Opening statistics");
        WatchUi.pushView(new StatisticsView(), new StatisticsDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Handle about menu item
    function handleAbout() as Void {
        System.println("InlineSkatingMenuDelegate: Opening about");
        
        var aboutText = "Aggressive Inline Skating Tracker\n\n" +
                       "Version: 2.0.0\n" +
                       "Author: Vít Kotačka\n\n" +
                       "Automatically detects tricks, grinds, and jumps during aggressive skating sessions.\n\n" +
                       "Features:\n" +
                       "• GPS tracking\n" +
                       "• Trick detection\n" +
                       "• Performance metrics\n" +
                       "• Session statistics\n\n" +
                       "Press BACK to return";
        
        WatchUi.pushView(new AboutView(aboutText), new AboutDelegate(), WatchUi.SLIDE_LEFT);
    }
}

// Settings menu delegate
class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        var app = Application.getApp();
        
        switch (itemId) {
            case :sensitivity:
                handleSensitivitySettings(app);
                break;
            case :gps_settings:
                handleGpsSettings();
                break;
            case :reset_stats:
                handleResetStats();
                break;
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function handleSensitivitySettings(app as InlineSkatingApp) as Void {
        // Create sensitivity adjustment menu
        var sensitivityMenu = new WatchUi.Menu2({:title => "Trick Sensitivity"});
        
        sensitivityMenu.addItem(new WatchUi.MenuItem("Low", "Less sensitive", :low_sensitivity, {}));
        sensitivityMenu.addItem(new WatchUi.MenuItem("Medium", "Default sensitivity", :medium_sensitivity, {}));
        sensitivityMenu.addItem(new WatchUi.MenuItem("High", "More sensitive", :high_sensitivity, {}));
        
        WatchUi.pushView(sensitivityMenu, new SensitivityDelegate(), WatchUi.SLIDE_LEFT);
    }

    function handleGpsSettings() as Void {
        // Show GPS configuration options
        System.println("SettingsMenuDelegate: GPS settings not yet implemented");
    }

    function handleResetStats() as Void {
        // Show confirmation dialog for resetting statistics
        var dialog = new WatchUi.Confirmation("Reset all statistics?");
        WatchUi.pushView(dialog, new ResetStatsDelegate(), WatchUi.SLIDE_UP);
    }
}

// Sensitivity adjustment delegate
class SensitivityDelegate extends WatchUi.Menu2InputDelegate {
    
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        var app = Application.getApp();
        var trickDetector = app != null ? app.getTrickDetector() : null;
        
        if (trickDetector != null) {
            switch (itemId) {
                case :low_sensitivity:
                    trickDetector.setSensitivity(0.7);
                    break;
                case :medium_sensitivity:
                    trickDetector.setSensitivity(1.0);
                    break;
                case :high_sensitivity:
                    trickDetector.setSensitivity(1.3);
                    break;
            }
        }
        
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// Exit confirmation delegate
class ExitConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    
    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Response) as Boolean {
        if (response == WatchUi.RESPONSE_YES) {
            // User confirmed - stop session and exit
            var app = Application.getApp();
            if (app != null) {
                app.stopSession();
            }
            System.exit();
            return true;
        } else {
            // User cancelled - just close dialog
            WatchUi.popView(WatchUi.SLIDE_UP);
            return true;
        }
    }
}

// Reset statistics confirmation delegate
class ResetStatsDelegate extends WatchUi.ConfirmationDelegate {
    
    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Response) as Boolean {
        if (response == WatchUi.RESPONSE_YES) {
            // User confirmed - reset all statistics
            var app = Application.getApp();
            var sessionStats = app != null ? app.getSessionStats() : null;
            
            if (sessionStats != null) {
                sessionStats.reset();
                System.println("ResetStatsDelegate: Statistics reset");
            }
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}