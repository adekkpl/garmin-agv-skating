// MainView.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Main View - Primary Session Display
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Math;
using Toybox.Timer;

class MainView extends WatchUi.View {
    
    var app;
    var screenWidth;
    var screenHeight;
    /* var centerX;
    var centerY; */
    var width, height, centerX, centerY;
    
    // Animation state
    var trickAnimation = false;
    var animationTimer = 0;
    var lastTrickType = "";
    
    // Status indicators
    var gpsStatus = false;
    var hrStatus = false;

    // Timer
    var updateTimer;
    var isTimerActive = false;
    
    function initialize(appRef) {
        View.initialize();
        app = appRef;
        
        // Initialize timer
        updateTimer = new Timer.Timer();

        // Get screen dimensions
        var deviceSettings = System.getDeviceSettings();
        screenWidth = deviceSettings.screenWidth;
        screenHeight = deviceSettings.screenHeight;
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
        
        System.println("MainView: Initialized - " + screenWidth + "x" + screenHeight);
    }
    
    function onLayout(dc) {
        // No layout file needed - all drawing is custom
    }
    
    function onShow() {
        System.println("MainView: View shown");

        // Debug session state
        var sessionManager = app.getSessionManager();
        if (sessionManager != null) {
            System.println("MainView: Current session state: " + sessionManager.getStateString());
            System.println("MainView: Current duration: " + sessionManager.getFormattedDuration());
        }
        
        startUpdateTimer();
        WatchUi.requestUpdate();        
    }
    
    function onHide() {
        System.println("MainView: View hidden");
        // Zatrzymaj timer gdy view jest ukryty. Czy potrzebne ??
        stopUpdateTimer();
    }
    
    function onUpdate(dc) {
        try {
            System.println("MainView: Updating display");
            
            // Clear screen with black background
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            
            // Draw main content
            drawSessionTimer(dc);
            drawHeartRate(dc);
            drawDistance(dc);
            //drawSessionStatus(dc);
            //drawStatusBar(dc);
            
            // Draw animations if active
            if (trickAnimation) {
                drawTrickAnimation(dc);
                updateAnimation();
            }
            
        } catch (exception) {
            System.println("MainView: Error in onUpdate: " + exception.getErrorMessage());
            drawErrorMessage(dc, "Display Error");
        }
    }
    
    // Draw session timer (center, large)
    /* function drawSessionTimer(dc) {
        try {
            var sessionManager = app.getSessionManager();
            var timeText = "00:00:00";
            var color = Graphics.COLOR_WHITE;
            var stateText = "STOPPED";
            
            if (sessionManager != null) {
                timeText = sessionManager.getFormattedDuration();
                stateText = sessionManager.getStateString();
                
                // Color code based on session state
                if (sessionManager.isActive()) {
                    color = Graphics.COLOR_GREEN;
                } else if (sessionManager.isPaused()) {
                    color = Graphics.COLOR_YELLOW;
                } else {
                    color = Graphics.COLOR_WHITE;
                }
            }
            
            // Main timer display
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 20, Graphics.FONT_NUMBER_HOT, 
                   timeText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // Timer label
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 50, Graphics.FONT_TINY, 
                    "SESSION TIME", Graphics.TEXT_JUSTIFY_CENTER);      

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY + 15, Graphics.FONT_TINY, 
                   stateText, Graphics.TEXT_JUSTIFY_CENTER); 

            // DEBUG: Pokaż surowy czas w milisekundach
            if (sessionManager != null) {
                var rawDuration = sessionManager.getSessionDuration();
                dc.drawText(centerX, centerY + 35, Graphics.FONT_XTINY, 
                        "Raw: " + rawDuration + "ms", Graphics.TEXT_JUSTIFY_CENTER);
            }                                             
                       
        } catch (exception) {
            System.println("MainView: Error drawing timer: " + exception.getErrorMessage());

            // Fallback display przy błędzie
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY, Graphics.FONT_SMALL, 
                   "TIMER ERROR", Graphics.TEXT_JUSTIFY_CENTER);
        }
    } */
    function drawSessionTimer(dc) {
        try {
            var sessionManager = app.getSessionManager();
            var timeText = "00:00:00";
            var color = Graphics.COLOR_WHITE;
            var stateText = "STOPPED";
            
            if (sessionManager != null) {
                timeText = sessionManager.getFormattedDuration();
                stateText = sessionManager.getStateString();
                
                // Color code based on session state
                if (sessionManager.isActive()) {
                    color = Graphics.COLOR_GREEN;
                } else if (sessionManager.isPaused()) {
                    color = Graphics.COLOR_YELLOW;
                } else {
                    color = Graphics.COLOR_WHITE;
                }
            }
            
            // === POPRAWIONE ROZMIESZCZENIE NA EKRANIE 454x454 ===
            
            // App title na górze
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, 15, Graphics.FONT_TINY, "AGV TRACKER", Graphics.TEXT_JUSTIFY_CENTER);
            
            // Status w prawym górnym rogu  
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(screenWidth - 20, 15, Graphics.FONT_TINY, stateText, Graphics.TEXT_JUSTIFY_RIGHT);
            dc.fillCircle(screenWidth - 35, 20, 5); // Mała kropka statusu
            
            // === GŁÓWNY TIMER W CENTRUM ===
            
            // Label timera
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 60, Graphics.FONT_SMALL, 
                    "SESSION TIME", Graphics.TEXT_JUSTIFY_CENTER);
            
            // GŁÓWNY TIMER - duży i wyraźny
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 20, Graphics.FONT_NUMBER_HOT, 
                    timeText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // === DEBUG INFO NA DOLE ===
            
            // Raw duration dla debugowania
            if (sessionManager != null) {
                var rawDuration = sessionManager.getSessionDuration();
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, centerY + 40, Graphics.FONT_XTINY, 
                        "Raw: " + rawDuration + "ms", Graphics.TEXT_JUSTIFY_CENTER);
            }
            
        } catch (exception) {
            System.println("MainView: Error drawing timer: " + exception.getErrorMessage());
            
            // Fallback display
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY, Graphics.FONT_SMALL, 
                    "TIMER ERROR", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
    
    // Draw heart rate (top left)
    /* function drawHeartRate(dc) {
        try {
            var hrText = "---";
            var color = Graphics.COLOR_DK_GRAY;
            
            var sensorManager = app.getSensorManager();
            if (sensorManager != null) {
                var heartRate = sensorManager.getHeartRate();
                if (heartRate != null && heartRate > 0) {
                    hrText = heartRate.format("%d");
                    color = Graphics.COLOR_RED;
                    hrStatus = true;
                } else {
                    hrStatus = false;
                }
            }
            
            // Heart rate value
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(20, 30, Graphics.FONT_MEDIUM, hrText, Graphics.TEXT_JUSTIFY_LEFT);
            
            // Heart rate label
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(20, 55, Graphics.FONT_TINY, "BPM", Graphics.TEXT_JUSTIFY_LEFT);
            
            // Heart icon
            if (hrStatus) {
                drawHeartIcon(dc, 70, 40, Graphics.COLOR_RED);
            }
            
        } catch (exception) {
            System.println("MainView: Error drawing heart rate: " + exception.getErrorMessage());
        }
    } */
    function drawHeartRate(dc) {
        try {
            var hrText = "---";
            var color = Graphics.COLOR_DK_GRAY;
            
            var sensorManager = app.getSensorManager();
            if (sensorManager != null) {
                var heartRate = sensorManager.getHeartRate();
                if (heartRate != null && heartRate > 0) {
                    hrText = heartRate.format("%d");
                    color = Graphics.COLOR_RED;
                }
            }
            
            // Heart rate w lewym górnym rogu
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(20, 30, Graphics.FONT_MEDIUM, hrText, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(20, 55, Graphics.FONT_TINY, "BPM", Graphics.TEXT_JUSTIFY_LEFT);
            
        } catch (exception) {
            System.println("MainView: Error drawing heart rate: " + exception.getErrorMessage());
        }
    }
    
    // Draw GPS distance (bottom)
    /* function drawDistance(dc) {
        try {
            var gpsTracker = app.getGPSTracker();
            var distanceText = "0.0 m";
            var color = Graphics.COLOR_DK_GRAY;
            
            if (gpsTracker != null) {
                var distance = gpsTracker.getSessionDistance();
                if (distance != null && distance > 0) {
                    if (distance < 1000) {
                        distanceText = distance.format("%.0f") + " m";
                    } else {
                        distanceText = (distance / 1000.0).format("%.2f") + " km";
                    }
                    color = Graphics.COLOR_BLUE;
                    gpsStatus = true;
                } else {
                    gpsStatus = false;
                }
            }
            
            // Distance value
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, screenHeight - 50, Graphics.FONT_MEDIUM, 
                       distanceText, Graphics.TEXT_JUSTIFY_CENTER);
            
            // Distance label
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, screenHeight - 25, Graphics.FONT_TINY, 
                       "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER);
                       
        } catch (exception) {
            System.println("MainView: Error drawing distance: " + exception.getErrorMessage());
        }
    } */
    function drawDistance(dc) {
        try {
            var gpsTracker = app.getGPSTracker();
            var distanceText = "0.0 m";
            var color = Graphics.COLOR_DK_GRAY;
            
            if (gpsTracker != null) {
                var distance = gpsTracker.getSessionDistance();
                if (distance != null && distance > 0) {
                    if (distance < 1000) {
                        distanceText = distance.format("%.0f") + " m";
                    } else {
                        distanceText = (distance / 1000.0).format("%.2f") + " km";
                    }
                    color = Graphics.COLOR_BLUE;
                }
            }
            
            // Distance na dole ekranu
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, screenHeight - 50, Graphics.FONT_MEDIUM, 
                    distanceText, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, screenHeight - 25, Graphics.FONT_TINY, 
                    "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER);
                    
        } catch (exception) {
            System.println("MainView: Error drawing distance: " + exception.getErrorMessage());
        }
    }
    
    // Draw session status indicator (top right)
    function drawSessionStatus(dc) {
        try {
            var sessionManager = app.getSessionManager();
            var statusText = "STOPPED";
            var statusColor = Graphics.COLOR_RED;
            var circleColor = Graphics.COLOR_RED;
            
            if (sessionManager != null) {
                statusText = sessionManager.getStateString();
                
                if (sessionManager.isActive()) {
                    statusColor = Graphics.COLOR_GREEN;
                    circleColor = Graphics.COLOR_GREEN;
                } else if (sessionManager.isPaused()) {
                    statusColor = Graphics.COLOR_YELLOW;
                    circleColor = Graphics.COLOR_YELLOW;
                }
            }
            
            // Status circle
            dc.setColor(circleColor, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(screenWidth - 25, 35, 8);
            
            // Status text
            dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(screenWidth - 20, 50, Graphics.FONT_TINY, 
                       statusText, Graphics.TEXT_JUSTIFY_RIGHT);
                       
        } catch (exception) {
            System.println("MainView: Error drawing session status: " + exception.getErrorMessage());
        }
    }
    
    // Draw status bar (top)
    function drawStatusBar(dc) {
        try {
            // App title
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, 5, Graphics.FONT_TINY, 
                       "AGV TRACKER", Graphics.TEXT_JUSTIFY_CENTER);
            
            // GPS status icon
            if (gpsStatus) {
                drawGPSIcon(dc, centerX - 30, 25, Graphics.COLOR_GREEN);
            } else {
                drawGPSIcon(dc, centerX - 30, 25, Graphics.COLOR_DK_GRAY);
            }
            
            // View indicator
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX + 30, 25, Graphics.FONT_TINY, 
                       "MAIN", Graphics.TEXT_JUSTIFY_CENTER);
                       
        } catch (exception) {
            System.println("MainView: Error drawing status bar: " + exception.getErrorMessage());
        }
    }
    
    // Draw trick detection animation
    function drawTrickAnimation(dc) {
        try {
            if (lastTrickType.length() > 0) {
                // FIXED: Explicit conversion to Float and proper alpha calculation
                var sinValue = Math.sin(animationTimer * 0.3).toFloat();
                var alpha = (sinValue * 127.0 + 128.0).toNumber();
                
                // Ensure alpha is within valid range (0-255)
                if (alpha < 0) { alpha = 0; }
                if (alpha > 255) { alpha = 255; }
                
                // Rest of animation code...
            }
        } catch (exception) {
            System.println("MainView: Error in drawTrickAnimation: " + exception.getErrorMessage());
        }
    }
    
    // Update animation state
    function updateAnimation() {
        animationTimer++;
        if (animationTimer > 30) { // 30 frames ~ 3 seconds
            trickAnimation = false;
            animationTimer = 0;
            lastTrickType = "";
        }
    }
    
    // Draw simple heart icon
    function drawHeartIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        // Simple heart using circles and polygon
        dc.fillCircle(x - 3, y - 2, 4);
        dc.fillCircle(x + 3, y - 2, 4);
        var heartPoints = [[x - 6, y], [x, y + 8], [x + 6, y]];
        dc.fillPolygon(heartPoints);
    }
    
    // Draw simple GPS icon
    function drawGPSIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        // Simple GPS satellite icon
        dc.drawCircle(x, y, 6);
        dc.drawLine(x - 8, y - 8, x + 8, y + 8);
        dc.drawLine(x - 8, y + 8, x + 8, y - 8);
    }
    
    // Draw error message
    function drawErrorMessage(dc, message) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, Graphics.FONT_SMALL, 
                   "ERROR", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY + 30, Graphics.FONT_TINY, 
                   message, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Event handlers
    function onTrickDetected(trickType, trickData) {
        try {
            System.println("MainView: Trick detected - " + trickType);
            lastTrickType = trickType;
            trickAnimation = true;
            animationTimer = 0;
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("MainView: Error in onTrickDetected: " + exception.getErrorMessage());
        }
    }
    
    function onRotationDetected(direction, angle) {
        try {
            System.println("MainView: Rotation detected - " + direction + " " + angle + "°");
            // Could add rotation animation here
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("MainView: Error in onRotationDetected: " + exception.getErrorMessage());
        }
    }
    
    function onSessionStateChange(newState) {
        try {
            System.println("MainView: Session state changed to " + newState);
            WatchUi.requestUpdate();
        } catch (exception) {
            System.println("MainView: Error in onSessionStateChange: " + exception.getErrorMessage());
        }
    }

    function startUpdateTimer() {
        if (!isTimerActive && updateTimer != null) {
            try {
                var interval = 1000; // Domyślnie 1 sekunda

                /* var sessionManager = app.getSessionManager();
                // OPCJONALNIE: Zwiększ częstotliwość dla aktywnej sesji
                if (sessionManager != null && sessionManager.isActive()) {
                    interval = 500; // Co 0.5 sekundy dla aktywnej sesji
                } */

                // Odświeżaj co 1 sekundę (1000ms)
                updateTimer.start(method(:onTimerUpdate), interval, true);
                isTimerActive = true;
                //System.println("MainView: Update timer started");
                System.println("MainView: Update timer started (interval=" + interval + "ms)");
            } catch (exception) {
                System.println("MainView: Error starting timer: " + exception.getErrorMessage());
            }
        } else {
            System.println("MainView: Timer already active or updateTimer is null");
        }
    }
    function stopUpdateTimer() {
        if (isTimerActive && updateTimer != null) {
            try {
                updateTimer.stop();
                isTimerActive = false;
                System.println("MainView: Update timer stopped");
            } catch (exception) {
                System.println("MainView: Error stopping timer: " + exception.getErrorMessage());
            }
        }
    }

    // Callback dla timera - wywoływany co sekundę
    function onTimerUpdate() {
        try {
            // ZAWSZE odświeżaj ekran (nie tylko gdy sesja aktywna)
            WatchUi.requestUpdate();
            
            // Debug info
            var sessionManager = app.getSessionManager();
            if (sessionManager != null) {
                System.println("MainView: Timer tick - " + sessionManager.getFormattedDuration() + 
                            " (" + sessionManager.getStateString() + ")");
            }
        } catch (exception) {
            System.println("MainView: Error in timer update: " + exception.getErrorMessage());
        }
    }

    // Cleanup
    function cleanup() {
        stopUpdateTimer();
        updateTimer = null;
        System.println("MainView: Cleanup completed");
    }
}