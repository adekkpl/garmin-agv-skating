// Garmin Aggressive Inline Skating Tracker v2.0.0
// Additional Views (About, Statistics, etc.)

import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

// About view showing app information
class AboutView extends WatchUi.View {
    
    var aboutText;
    var scrollOffset = 0;
    var maxScroll = 0;
    
    function initialize(text as String) {
        View.initialize();
        aboutText = text;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Calculate max scroll based on text height
        var textHeight = dc.getTextDimensions(aboutText, Graphics.FONT_TINY)[1];
        maxScroll = Math.max(0, textHeight - dc.getHeight() + 40);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Draw title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, 10, Graphics.FONT_SMALL, "ABOUT", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw scrollable text
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, 40 - scrollOffset, Graphics.FONT_TINY, aboutText, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw scroll indicator if needed
        if (maxScroll > 0) {
            var scrollPercent = scrollOffset.toFloat() / maxScroll;
            var indicatorHeight = (dc.getHeight() - 60) * (dc.getHeight() - 60) / (maxScroll + dc.getHeight() - 60);
            var indicatorY = 30 + scrollPercent * (dc.getHeight() - 60 - indicatorHeight);
            
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(dc.getWidth() - 5, indicatorY, 3, indicatorHeight);
        }
        
        View.onUpdate(dc);
    }
    
    function scrollUp() as Void {
        scrollOffset = Math.max(0, scrollOffset - 20);
        WatchUi.requestUpdate();
    }
    
    function scrollDown() as Void {
        scrollOffset = Math.min(maxScroll, scrollOffset + 20);
        WatchUi.requestUpdate();
    }
}

// About view delegate
class AboutDelegate extends WatchUi.BehaviorDelegate {
    
    var view;
    
    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function setView(aboutView as AboutView) as Void {
        view = aboutView;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        switch (key) {
            case WatchUi.KEY_UP:
                if (view != null) {
                    view.scrollUp();
                }
                return true;
            case WatchUi.KEY_DOWN:
                if (view != null) {
                    view.scrollDown();
                }
                return true;
            case WatchUi.KEY_ESC:
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                return true;
            default:
                return false;
        }
    }
    
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        
        switch (direction) {
            case WatchUi.SWIPE_UP:
                if (view != null) {
                    view.scrollDown();
                }
                return true;
            case WatchUi.SWIPE_DOWN:
                if (view != null) {
                    view.scrollUp();
                }
                return true;
            case WatchUi.SWIPE_RIGHT:
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                return true;
            default:
                return false;
        }
    }
}

// Statistics view showing session history and totals
class StatisticsView extends WatchUi.View {
    
    var currentPage = 0;
    var totalPages = 3;
    
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Draw title with page indicator
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, 10, Graphics.FONT_SMALL, 
                   "STATISTICS (" + (currentPage + 1) + "/" + totalPages + ")", 
                   Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw content based on current page
        switch (currentPage) {
            case 0:
                drawCurrentSessionStats(dc);
                break;
            case 1:
                drawAllTimeStats(dc);
                break;
            case 2:
                drawRecords(dc);
                break;
        }
        
        // Draw navigation hint
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() - 15, Graphics.FONT_XTINY, 
                   "UP/DOWN to navigate", Graphics.TEXT_JUSTIFY_CENTER);
        
        View.onUpdate(dc);
    }
    
    function drawCurrentSessionStats(dc as Graphics.Dc) as Void {
        var app = Application.getApp();
        var sessionStats = app != null ? app.getSessionStats() : null;
        
        if (sessionStats == null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL, 
                       "No active session", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        
        var displayData = sessionStats.getDisplayData();
        var yPos = 50;
        var lineHeight = 20;
        
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, yPos, Graphics.FONT_SMALL, "CURRENT SESSION", Graphics.TEXT_JUSTIFY_CENTER);
        yPos += 25;
        
        // Session stats
        drawStatLine(dc, "Session Time:", displayData.get("sessionTime"), yPos);
        yPos += lineHeight;
        drawStatLine(dc, "Total Tricks:", displayData.get("tricks").toString(), yPos);
        yPos += lineHeight;
        drawStatLine(dc, "Grinds:", displayData.get("grinds").toString(), yPos);
        yPos += lineHeight;
        drawStatLine(dc, "Jumps:", displayData.get("jumps").toString(), yPos);
        yPos += lineHeight;
        drawStatLine(dc, "Distance:", displayData.get("distance"), yPos);
        yPos += lineHeight;
        drawStatLine(dc, "Calories:", displayData.get("calories").toString(), yPos);
    }
    
    function drawAllTimeStats(dc as Graphics.Dc) as Void {
        var yPos = 50;
        var lineHeight = 20;
        
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, yPos, Graphics.FONT_SMALL, "ALL TIME TOTALS", Graphics.TEXT_JUSTIFY_CENTER);
        yPos += 25;
        
        // Placeholder for all-time statistics
        // These would be loaded from persistent storage
        drawStatLine(dc, "Total Sessions:", "0", yPos);
        yPos += lineHeight;
        drawStatLine(dc, "Total Tricks:", "0", yPos);
        yPos += lineHeight;
        drawStatLine(dc, "Total Distance:", "0.0 km", yPos);
        yPos += lineHeight;
        drawStatLine(dc, "Total Time:", "00:00:00", yPos);
        yPos += lineHeight;
        
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, yPos + 20, Graphics.FONT_TINY, 
                   "Historical data coming soon", Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawRecords(dc as Graphics.Dc) as Void {
        var yPos = 50;
        var lineHeight = 20;
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, yPos, Graphics.FONT_SMALL, "PERSONAL RECORDS", Graphics.TEXT_JUSTIFY_CENTER);
        yPos += 25;
        
        // Get current session records
        var app = Application.getApp();
        var sessionStats = app != null ? app.getSessionStats() : null;
        
        if (sessionStats != null) {
            var displayData = sessionStats.getDisplayData();
            
            drawStatLine(dc, "Longest Grind:", displayData.get("longestGrind"), yPos);
            yPos += lineHeight;
            drawStatLine(dc, "Max Speed:", displayData.get("maxSpeed"), yPos);
            yPos += lineHeight;
            drawStatLine(dc, "Max Heart Rate:", displayData.get("maxHeartRate").toString() + " bpm", yPos);
            yPos += lineHeight;
        }
        
        // Placeholder for historical records
        drawStatLine(dc, "Best Session:", "0 tricks", yPos);
        yPos += lineHeight;
        drawStatLine(dc, "Longest Session:", "00:00:00", yPos);
    }
    
    function drawStatLine(dc as Graphics.Dc, label as String, value as String, y as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, y, Graphics.FONT_TINY, label, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(dc.getWidth() - 10, y, Graphics.FONT_TINY, value, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    
    function nextPage() as Void {
        currentPage = (currentPage + 1) % totalPages;
        WatchUi.requestUpdate();
    }
    
    function previousPage() as Void {
        currentPage = (currentPage - 1 + totalPages) % totalPages;
        WatchUi.requestUpdate();
    }
}

// Statistics view delegate
class StatisticsDelegate extends WatchUi.BehaviorDelegate {
    
    var view;
    
    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function setView(statsView as StatisticsView) as Void {
        view = statsView;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        switch (key) {
            case WatchUi.KEY_UP:
                if (view != null) {
                    view.previousPage();
                }
                return true;
            case WatchUi.KEY_DOWN:
                if (view != null) {
                    view.nextPage();
                }
                return true;
            case WatchUi.KEY_ENTER:
                if (view != null) {
                    view.nextPage();
                }
                return true;
            case WatchUi.KEY_ESC:
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                return true;
            default:
                return false;
        }
    }
    
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        
        switch (direction) {
            case WatchUi.SWIPE_UP:
                if (view != null) {
                    view.nextPage();
                }
                return true;
            case WatchUi.SWIPE_DOWN:
                if (view != null) {
                    view.previousPage();
                }
                return true;
            case WatchUi.SWIPE_RIGHT:
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                return true;
            default:
                return false;
        }
    }
}

// Simple confirmation view for custom dialogs
class CustomConfirmationView extends WatchUi.View {
    
    var message;
    var yesCallback;
    var noCallback;
    
    function initialize(msg as String, yesCb as Method, noCb as Method) {
        View.initialize();
        message = msg;
        yesCallback = yesCb;
        noCallback = noCb;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Draw message
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 30, Graphics.FONT_SMALL, 
                   message, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw options
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 4, dc.getHeight() / 2 + 20, Graphics.FONT_SMALL, 
                   "YES", Graphics.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(3 * dc.getWidth() / 4, dc.getHeight() / 2 + 20, Graphics.FONT_SMALL, 
                   "NO", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw instructions
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() - 20, Graphics.FONT_XTINY, 
                   "UP=YES  DOWN=NO", Graphics.TEXT_JUSTIFY_CENTER);
        
        View.onUpdate(dc);
    }
}

// Custom confirmation delegate
class CustomConfirmationDelegate extends WatchUi.BehaviorDelegate {
    
    var view;
    
    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function setView(confirmView as CustomConfirmationView) as Void {
        view = confirmView;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        switch (key) {
            case WatchUi.KEY_UP:
                // YES selected
                if (view != null && view.yesCallback != null) {
                    view.yesCallback.invoke();
                }
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            case WatchUi.KEY_DOWN:
                // NO selected
                if (view != null && view.noCallback != null) {
                    view.noCallback.invoke();
                }
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            case WatchUi.KEY_ESC:
                // Cancel - same as NO
                if (view != null && view.noCallback != null) {
                    view.noCallback.invoke();
                }
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            default:
                return false;
        }
    }
}