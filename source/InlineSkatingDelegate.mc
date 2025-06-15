// InlineSkatingDelegate.mc
// Garmin Aggressive Inline Skating Tracker v2.0.0
// Input Delegate for Main View
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Application;

class InlineSkatingDelegate extends WatchUi.BehaviorDelegate {
    
    var view;
    var app;
    var lastButtonPress;
    
    function initialize() {
        BehaviorDelegate.initialize();
        lastButtonPress = 0;
        System.println("InlineSkatingDelegate: Input delegate initialized");
        
        // Poprawka: Bezpieczne uzyskanie referencji do aplikacji
        try {
            app = Application.getApp();
            if (app != null) {
                System.println("InlineSkatingDelegate: App reference obtained successfully");
            } else {
                System.println("InlineSkatingDelegate: App reference is null");
            }
        } catch (exception) {
            System.println("InlineSkatingDelegate: Failed to get app reference: " + exception.getErrorMessage());
            app = null;
        }
    }

    // Set reference to the view for interaction
    function setView(viewRef as InlineSkatingView) as Void {
        view = viewRef;
        System.println("InlineSkatingDelegate: View reference set");
    }

    // Handle key press - UPROSZCZONA WERSJA
    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        System.println("DEBUG: Key pressed = " + key);
        
        // Mapowanie kodów na nazwy
        var keyName = "UNKNOWN";
        switch (key) {
            case 4: keyName = "START (kod 4)"; break;
            case 5: keyName = "BACK (kod 5)"; break;
            case 8: keyName = "DOWN (kod 8)"; break;
            case 13: keyName = "UP (kod 13)"; break;
            case WatchUi.KEY_ENTER: keyName = "ENTER"; break;
        }
        System.println("DEBUG: " + keyName);
        
        // Logika obsługi klawiszy - BEZ dodatkowych timerów
        switch (key) {
            case 4:  // ← Fizyczny START button
                return onStartButton();
            case WatchUi.KEY_ENTER:  // ← Środkowy przycisk - przełączanie trybów
                return onEnterButton();
            case 13:  // ← UP button
            case WatchUi.KEY_UP:
                return onUpButton();
            case 8:   // ← DOWN button  
            case WatchUi.KEY_DOWN:
                return onDownButton();
            case 5:   // ← BACK button
            case WatchUi.KEY_ESC:
                return onBackButton();
            default:
                // DODAJ obsługę innych kodów klawiszy dla środkowego przycisku
                if (key == WatchUi.KEY_ENTER || key == 7 || key == 12) {  // Możliwe kody dla ENTER
                    return onEnterButton();
                }
                System.println("InlineSkatingDelegate: Unhandled key - " + key);
                return false;
        }
    }

    // Handle SELECT button (center button) - CAŁKOWICIE WYŁĄCZ
    function onSelect() {
        System.println("InlineSkatingDelegate: Select pressed - COMPLETELY IGNORED");
        // CAŁKOWICIE IGNORUJ - START button powoduje false SELECT events
        return true;
    }

    // Handle MENU button
    function onMenu() {
        logDevice("MENU BUTTON PRESSED - creating menu");
        System.println("InlineSkatingDelegate: Menu button pressed");
        
        // Bezpieczne uzyskanie referencji do aplikacji jeśli jeszcze nie ma
        if (app == null) {
            try {
                app = Application.getApp();
            } catch (exception) {
                logError("onMenu get app", exception);
                System.println("InlineSkatingDelegate: Cannot get app in onMenu: " + exception.getErrorMessage());
                return true;
            }
        }
        
        try {
            // Show main menu
            var menu = new WatchUi.Menu2({:title => "Skating Options"});
            
            // DODAJ View Logs na górę dla łatwego dostępu
            menu.addItem(new WatchUi.MenuItem(
                "View Logs",
                "Show crash logs",
                :view_logs,
                {}
            ));
            
            // Add menu items based on session state
            var sessionActive = false;
            if (view != null) {
                try {
                    sessionActive = view.getSessionStatus();
                } catch (exception) {
                    logError("getSessionStatus", exception);
                    System.println("InlineSkatingDelegate: Error getting session status: " + exception.getErrorMessage());
                }
            }
            
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
            
            logDevice("Menu created, pushing view");
            WatchUi.pushView(menu, new InlineSkatingMenuDelegate(), WatchUi.SLIDE_UP);
            
        } catch (exception) {
            logError("onMenu", exception);
        }
        
        return true;
    }

    // Handle START button press - UPROSZCZONE ZABEZPIECZENIE
    function onStartButton() {
        logDevice("START button pressed");
        try {
            System.println("InlineSkatingDelegate: START button pressed");
        
            // Proste zabezpieczenie - ignoruj szybkie powtórzenia START
            var currentTime = System.getTimer();
            if (currentTime - lastButtonPress < 800) {
                System.println("InlineSkatingDelegate: Ignoring rapid START press");
                return true;
            }
            lastButtonPress = currentTime;
            
            // Toggle session start/stop
            if (view != null) {
                try {
                    view.toggleSession();
                } catch (exception) {
                    logError("toggleSession", exception);
                    System.println("InlineSkatingDelegate: Error toggling session: " + exception.getErrorMessage());
                }
            } else {
                System.println("InlineSkatingDelegate: View is null, cannot toggle session");
            }
            
           
            logDevice("START button handled successfully");
        } catch (exception) {
            logError("onStartButton", exception);
        }                
        return true;
    }

    // Handle ENTER/SELECT button
    function onEnterButton() {
        System.println("InlineSkatingDelegate: ENTER button pressed");
        
        // Switch display mode
        if (view != null) {
            try {
                view.switchDisplayMode();
            } catch (exception) {
                System.println("InlineSkatingDelegate: Error switching display mode: " + exception.getErrorMessage());
            }
        } else {
            System.println("InlineSkatingDelegate: View is null, cannot switch mode");
        }
        
        return true;
    }

    // Handle UP button - USUŃ DODATKOWE ZABEZPIECZENIA
    function onUpButton() {
        System.println("InlineSkatingDelegate: UP button pressed - EXECUTING");
        
        if (view != null) {
            try {
                view.switchDisplayMode();  // Normalny kierunek
                System.println("InlineSkatingDelegate: UP button - mode switched successfully");
            } catch (exception) {
                System.println("InlineSkatingDelegate: Error in UP button: " + exception.getErrorMessage());
            }
        } else {
            System.println("InlineSkatingDelegate: View is null in UP button");
        }
        
        return true;
    }

    // Handle DOWN button - USUŃ DODATKOWE ZABEZPIECZENIA
    function onDownButton() {
        System.println("InlineSkatingDelegate: DOWN button pressed - EXECUTING");
        
        if (view != null) {
            try {
                // Używaj normalnego kierunku (tymczasowo)
                view.switchDisplayMode();
                System.println("InlineSkatingDelegate: DOWN button - mode switched successfully");
            } catch (exception) {
                System.println("InlineSkatingDelegate: Error in DOWN button: " + exception.getErrorMessage());
            }
        } else {
            System.println("InlineSkatingDelegate: View is null in DOWN button");
        }
        
        return true;
    }

    // Handle BACK/ESC button
    function onBackButton() {
        System.println("InlineSkatingDelegate: BACK button pressed");
        
        // Check if session is active before allowing exit
        var sessionActive = false;
        if (view != null) {
            try {
                sessionActive = view.getSessionStatus();
            } catch (exception) {
                System.println("InlineSkatingDelegate: Error getting session status in back: " + exception.getErrorMessage());
            }
        }
        
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
    function onKeyPressed(keyEvent) {
        // Obsługuj tylko PRESS events
        return onKey(keyEvent);
    }

    // Handle key release events
    function onKeyReleased(keyEvent) {
        // IGNORUJ RELEASE events
        System.println("InlineSkatingDelegate: Key RELEASED - IGNORED");
        return true;
    }

    // Handle swipe gestures (for touchscreen devices)
    function onSwipe(swipeEvent) {
        var direction = swipeEvent.getDirection();
        
        System.println("InlineSkatingDelegate: Swipe detected - " + direction);
        
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
    function onSwipeLeft() {
        System.println("InlineSkatingDelegate: Swipe left");
        
        if (view != null) {
            try {
                view.switchDisplayMode();
            } catch (exception) {
                System.println("InlineSkatingDelegate: Error in swipe left: " + exception.getErrorMessage());
            }
        }
        
        return true;
    }

    // Handle right swipe - previous display mode
    function onSwipeRight() {
        System.println("InlineSkatingDelegate: Swipe right");
        
        if (view != null) {
            try {
                view.switchDisplayMode();
            } catch (exception) {
                System.println("InlineSkatingDelegate: Error in swipe right: " + exception.getErrorMessage());
            }
        }
        
        return true;
    }

    // Handle up swipe - show menu
    function onSwipeUp() {
        System.println("InlineSkatingDelegate: Swipe up");
        return onMenu();
    }

    // Handle down swipe - toggle session
    function onSwipeDown() {
        System.println("InlineSkatingDelegate: Swipe down");
        
        if (view != null) {
            try {
                view.toggleSession();
            } catch (exception) {
                System.println("InlineSkatingDelegate: Error in swipe down: " + exception.getErrorMessage());
            }
        }
        
        return true;
    }

    // Handle tap events (for touchscreen)
    function onTap(clickEvent) {
        var coordinates = clickEvent.getCoordinates();
        System.println("InlineSkatingDelegate: Tap at " + coordinates[0] + "," + coordinates[1]);
        
        // Could implement zone-based tapping
        // For now, treat as enter button
        return onEnterButton();
    }

    // Handle touch events
    function onSelectable(selectableEvent) {
        // Handle selectable UI elements if needed
        return false;
    }
}

// Menu delegate for handling main menu selections
class InlineSkatingMenuDelegate extends WatchUi.Menu2InputDelegate {
    
    function initialize() {
        Menu2InputDelegate.initialize();
        logDevice("InlineSkatingMenuDelegate created");
        System.println("InlineSkatingMenuDelegate: Menu delegate initialized");
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        
        logDevice("Menu item selected: " + itemId);
        System.println("InlineSkatingMenuDelegate: Menu item selected - " + itemId);
        // NAJPIERW zamknij menu
        WatchUi.popView(WatchUi.SLIDE_DOWN);

        try {
            var app = null;
            try {
                app = Application.getApp();
            } catch (exception) {
                logError("Menu get app", exception);
                System.println("InlineSkatingMenuDelegate: Cannot get app: " + exception.getErrorMessage());
            }
            
            switch (itemId) {
                case :view_logs:
                    handleViewLogsDelayed();
                    break;
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
                default:
                    logDevice("Unknown menu item: " + itemId);
                    System.println("InlineSkatingMenuDelegate: Unknown menu item: " + itemId);
                    break;
            }
            
        } catch (exception) {
            logError("Menu onSelect", exception);
        }
        
        //WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        logDevice("Menu back pressed");
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    // Wersje z opóźnieniem używające Timer
    function handleViewLogsDelayed() as Void {
        var timer = new Timer.Timer();
        timer.start(method(:handleViewLogsNow), 100, false);
    }

    function handleViewLogsNow() as Void {
        logDevice("Opening logs view - delayed");
        try {
            var logger = DeviceLogger.getInstance();
            var logs = logger.getLogsAsString();
            
            WatchUi.pushView(new LogsView(logs), new LogsDelegate(), WatchUi.SLIDE_UP);
            
        } catch (exception) {
            logDevice("handleViewLogsNow error: " + exception.getErrorMessage());
        }
    }

    // Handle view logs menu item - MOVED TO TOP LEVEL
    /* function handleViewLogs() as Void {
        logDevice("Opening logs view from menu");
        try {
            var logger = DeviceLogger.getInstance();
            var logs = logger.getLogsAsString();
            
            WatchUi.pushView(new LogsView(logs), new LogsDelegate(), WatchUi.SLIDE_LEFT);
        } catch (exception) {
            logError("handleViewLogs", exception);
        }
    } */
    // Handle view logs menu item - UPROSZCZONA WERSJA
    /* function handleViewLogs() as Void {
        System.println("handleViewLogs: Starting");
        
        try {
            // Test czy DeviceLogger istnieje
            System.println("handleViewLogs: Testing DeviceLogger");
            logDevice("Test message from handleViewLogs");
            
            System.println("handleViewLogs: Getting instance");
            var logger = DeviceLogger.getInstance();
            
            System.println("handleViewLogs: Got instance, getting logs");
            var logs = logger.getLogsAsString();
            
            System.println("handleViewLogs: Got logs, length = " + logs.length());
            
            // Sprawdź czy LogsView się tworzy
            System.println("handleViewLogs: Creating LogsView");
            var logsView = new LogsView(logs);
            
            System.println("handleViewLogs: Creating LogsDelegate");
            var logsDelegate = new LogsDelegate();
            logsDelegate.setView(logsView);
            
            System.println("handleViewLogs: Pushing view");
            WatchUi.pushView(logsView, logsDelegate, WatchUi.SLIDE_LEFT);
            
            System.println("handleViewLogs: Success!");
            
        } catch (exception) {
            System.println("handleViewLogs ERROR: " + exception.getErrorMessage());
            System.println("handleViewLogs ERROR details: " + exception);
        }
    } */
function handleViewLogs() as Void {
    logDevice("Opening logs view - first popping menu");
    try {
        // Najpierw zamknij menu
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        
        // Potem otwórz logi
        var logger = DeviceLogger.getInstance();
        var logs = logger.getLogsAsString();
        
        var logsView = new LogsView(logs);
        var logsDelegate = new LogsDelegate();
        logsDelegate.setView(logsView);
        
        WatchUi.pushView(logsView, logsDelegate, WatchUi.SLIDE_UP);
        
    } catch (exception) {
        logDevice("handleViewLogs error: " + exception.getErrorMessage());
    }
}


    // Handle start session menu item
    function handleStartSession(app) as Void {
        if (app != null) {
            try {
                app.startSession();
                System.println("InlineSkatingMenuDelegate: Session started from menu");
            } catch (exception) {
                System.println("InlineSkatingMenuDelegate: Error starting session: " + exception.getErrorMessage());
            }
        } else {
            System.println("InlineSkatingMenuDelegate: Cannot start session - app is null");
        }
    }

    // Handle stop session menu item
    function handleStopSession(app) as Void {
        if (app != null) {
            try {
                app.stopSession();
                System.println("InlineSkatingMenuDelegate: Session stopped from menu");
            } catch (exception) {
                System.println("InlineSkatingMenuDelegate: Error stopping session: " + exception.getErrorMessage());
            }
        } else {
            System.println("InlineSkatingMenuDelegate: Cannot stop session - app is null");
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
    /* function handleAbout() as Void {
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
    } */
    // Handle about menu item
    function handleAbout() as Void {
        System.println("InlineSkatingMenuDelegate: Opening about");
        
        try {
            var aboutText = "Aggressive Inline Skating Tracker\n\n" +
                        "Version: 2.0.0\n" +
                        "Author: Vit Kotacka\n\n" +
                        "Basic info about the app.\n\n" +
                        "Press BACK to return";
            
            var aboutView = new AboutView(aboutText);
            var aboutDelegate = new AboutDelegate();
            aboutDelegate.setView(aboutView);  // Ważne!
            
            WatchUi.pushView(aboutView, aboutDelegate, WatchUi.SLIDE_LEFT);
            
        } catch (exception) {
            System.println("About view error: " + exception.getErrorMessage());
        }
    }

}

// Settings menu delegate
class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        
        var app = null;
        try {
            app = Application.getApp();
        } catch (exception) {
            System.println("SettingsMenuDelegate: Cannot get app: " + exception.getErrorMessage());
        }
        
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

    function handleSensitivitySettings(app) as Void {
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
        
        var app = null;
        try {
            app = Application.getApp();
        } catch (exception) {
            System.println("SensitivityDelegate: Cannot get app: " + exception.getErrorMessage());
        }
        
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

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            // User confirmed - stop session and exit
            var app = null;
            try {
                app = Application.getApp();
                if (app != null) {
                    app.stopSession();
                }
            } catch (exception) {
                System.println("ExitConfirmationDelegate: Error stopping session: " + exception.getErrorMessage());
            }
            System.exit();
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

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            // User confirmed - reset all statistics
            var app = null;
            try {
                app = Application.getApp();
                var sessionStats = app != null ? app.getSessionStats() : null;
                
                if (sessionStats != null) {
                    sessionStats.reset();
                    System.println("ResetStatsDelegate: Statistics reset");
                }
            } catch (exception) {
                System.println("ResetStatsDelegate: Error resetting stats: " + exception.getErrorMessage());
            }
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

// WIDOK LOGÓW
class LogsView extends WatchUi.View {
    
    var logsText;
    var scrollOffset = 0;
    var maxScroll = 0;
    
    function initialize(logs) {
        View.initialize();
        logsText = logs;
        logDevice("LogsView created with " + logs.length() + " characters");
    }

    function onLayout(dc) {
        logDevice("LogsView.onLayout START");
        try {
            // Calculate max scroll based on text height
            var textHeight = dc.getTextDimensions(logsText, Graphics.FONT_XTINY)[1];
            maxScroll = textHeight > (dc.getHeight() - 40) ? textHeight - dc.getHeight() + 40 : 0;
            logDevice("LogsView.onLayout maxScroll=" + maxScroll + ", textHeight=" + textHeight);
        } catch (exception) {
            maxScroll = 0;
            logDevice("LogsView.onLayout ERROR: " + exception.getErrorMessage());
        }
    }

    function onUpdate(dc) {
        logDevice("LogsView.onUpdate START");
        try {
            // Clear screen - użyj ciemnoszarego zamiast czarnego
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.clear();
            logDevice("LogsView.onUpdate screen cleared");
            
            // Draw title - użyj białego na niebieskim tle
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 0, dc.getWidth(), 30);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, 10, Graphics.FONT_SMALL, "DEVICE LOGS", Graphics.TEXT_JUSTIFY_CENTER);
            logDevice("LogsView.onUpdate title drawn");
            
            // Draw scrollable logs - BIAŁE NA CZARNYM dla maksymalnego kontrastu
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            logDevice("LogsView.onUpdate drawing text, offset=" + scrollOffset);
            
            // Spróbuj większą czcionkę i prostszy tekst
            var simpleText = "TEST: " + logsText.substring(0, 100) + "...";
            dc.drawText(10, 50, Graphics.FONT_TINY, simpleText, Graphics.TEXT_JUSTIFY_LEFT);
            logDevice("LogsView.onUpdate text drawn");
            
            // Draw scroll indicator - ŻÓŁTY dla widoczności
            if (maxScroll > 0) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(dc.getWidth() - 10, 40, 8, 50);
                logDevice("LogsView.onUpdate scroll indicator drawn");
            }
            
            View.onUpdate(dc);
            logDevice("LogsView.onUpdate COMPLETED");
            
        } catch (exception) {
            logDevice("LogsView.onUpdate ERROR: " + exception.getErrorMessage());
        }
    }
    
    function scrollUp() {
        scrollOffset = max(0, scrollOffset - 20);
        WatchUi.requestUpdate();
    }
    
    function scrollDown() {
        scrollOffset = min(maxScroll, scrollOffset + 20);
        WatchUi.requestUpdate();
    }
}

class LogsDelegate extends WatchUi.BehaviorDelegate {
    
    var view;
    
    function initialize() {
        BehaviorDelegate.initialize();
        logDevice("LogsDelegate created");
    }
    
    function setView(logsView as LogsView) as Void {
        view = logsView;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        
        switch (key) {
            case 13: // UP
            case WatchUi.KEY_UP:
                if (view != null) {
                    view.scrollUp();
                }
                return true;
            case 8: // DOWN
            case WatchUi.KEY_DOWN:
                if (view != null) {
                    view.scrollDown();
                }
                return true;
            case 5: // BACK
            case WatchUi.KEY_ESC:
                logDevice("Closing logs view");
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                return true;
            default:
                return false;
        }
    }
}