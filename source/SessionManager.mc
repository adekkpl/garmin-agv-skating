// SessionManager.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Session State Management   -- w stopAndSaveSession()  -> saveSessionData();    !! zapis w /session/activityRecorer->saveSession()
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.Time;

class SessionManager {
    
    // Session states
    const STATE_STOPPED = 0;
    const STATE_ACTIVE = 1;
    const STATE_PAUSED = 2;
    
    var currentState;
    var sessionStartTime;
    var sessionPauseTime;
    var totalPausedTime;
    var activeSessionTime;
    
    // Component references
    var gpsTracker;
    var sessionStats;
    var activityRecorder;
    var stateChangeCallback;
    
    // Session data
    var sessionId;
    var sessionData;
    
    function initialize() {
        currentState = STATE_STOPPED;
        sessionStartTime = null;
        sessionPauseTime = null;
        totalPausedTime = 0;
        activeSessionTime = 0;
        sessionData = {};
        
        System.println("SessionManager: Initialized");
    }
    
    // Set component references
    function setGPSTracker(tracker) {
        gpsTracker = tracker;
    }
    
    function setSessionStats(stats) {
        sessionStats = stats;
    }
    
    function setActivityRecorder(recorder) {
        activityRecorder = recorder;
    }
    
    function setStateChangeCallback(callback) {
        stateChangeCallback = callback;
        // Dodatkowe logowanie dla debugowania
        System.println("SessionManager: State change callback set");
    }
    
    // Session control methods
    function startSession() {
        try {
            if (currentState != STATE_STOPPED) {
                System.println("SessionManager: Cannot start - session already active/paused");
                return false;
            }
            
            // Initialize new session
            var now = Time.now();
            sessionStartTime = now;
            sessionPauseTime = null;
            totalPausedTime = 0;
            activeSessionTime = 0;
            sessionId = now.value();
            
            // Start all components
            if (gpsTracker != null) {
                gpsTracker.startTracking();
            }
            
            if (sessionStats != null) {
                sessionStats.startNewSession();
            }
            
            if (activityRecorder != null) {
                activityRecorder.startRecording();
            }
            
            // Change state
            currentState = STATE_ACTIVE;
            notifyStateChange();
            
            System.println("SessionManager: Session started - ID: " + sessionId);
            return true;
            
        } catch (exception) {
            System.println("SessionManager: Error starting session: " + exception.getErrorMessage());
            return false;
        }
    }
    
    function pauseSession() {
        try {
            if (currentState != STATE_ACTIVE) {
                System.println("SessionManager: Cannot pause - session not active");
                return false;
            }
            
            // Record pause time
            sessionPauseTime = Time.now();
            
            // Update active session time
            if (sessionStartTime != null) {
                var currentSessionTime = sessionPauseTime.subtract(sessionStartTime);
                activeSessionTime = currentSessionTime.value() - totalPausedTime;
            }
            
            // Pause components
            if (gpsTracker != null) {
                gpsTracker.pauseTracking();
            }
            
            if (sessionStats != null) {
                sessionStats.pauseSession();
            }
            
            if (activityRecorder != null) {
                activityRecorder.pauseRecording();
            }
            
            // Change state
            currentState = STATE_PAUSED;
            notifyStateChange();
            
            System.println("SessionManager: Session paused");
            return true;
            
        } catch (exception) {
            System.println("SessionManager: Error pausing session: " + exception.getErrorMessage());
            return false;
        }
    }
    
    function resumeSession() {
        try {
            if (currentState != STATE_PAUSED) {
                System.println("SessionManager: Cannot resume - session not paused");
                return false;
            }
            
            // Calculate paused time
            if (sessionPauseTime != null) {
                var now = Time.now();
                var pauseDuration = now.subtract(sessionPauseTime);
                totalPausedTime += pauseDuration.value();
            }
            
            sessionPauseTime = null;
            
            // Resume components
            if (gpsTracker != null) {
                gpsTracker.resumeTracking();
            }
            
            if (sessionStats != null) {
                sessionStats.resumeSession();
            }
            
            if (activityRecorder != null) {
                activityRecorder.resumeRecording();
            }
            
            // Change state
            currentState = STATE_ACTIVE;
            notifyStateChange();
            
            System.println("SessionManager: Session resumed");
            return true;
            
        } catch (exception) {
            System.println("SessionManager: Error resuming session: " + exception.getErrorMessage());
            return false;
        }
    }
    
    function stopAndSaveSession() {
        try {
            if (currentState == STATE_STOPPED) {
                System.println("SessionManager: Cannot stop - session already stopped");
                return false;
            }
            
            // Update final session time
            var now = Time.now();
            if (sessionStartTime != null) {
                var totalSessionTime = now.subtract(sessionStartTime);
                activeSessionTime = totalSessionTime.value() - totalPausedTime;
            }
            
            // Stop and save components
            if (gpsTracker != null) {
                gpsTracker.stopTracking();
            }
            
            if (sessionStats != null) {
                sessionStats.finalizeSession();
            }
            
            if (activityRecorder != null) {
                activityRecorder.stopRecording();
                activityRecorder.saveSession();
            }
            
            // Save session data
            saveSessionData();
            
            // Change state
            currentState = STATE_STOPPED;
            notifyStateChange();
            
            System.println("SessionManager: Session stopped and saved - Duration: " + 
                         (activeSessionTime / 1000) + "s");
            return true;
            
        } catch (exception) {
            System.println("SessionManager: Error stopping session: " + exception.getErrorMessage());
            return false;
        }
    }
    
    function discardSession() {
        try {
            if (currentState == STATE_STOPPED) {
                System.println("SessionManager: Cannot discard - session already stopped");
                return false;
            }
            
            // Stop components without saving
            if (gpsTracker != null) {
                gpsTracker.stopTracking();
            }
            
            if (sessionStats != null) {
                sessionStats.discardSession();
            }
            
            if (activityRecorder != null) {
                activityRecorder.discardSession();
            }
            
            // Reset session data
            resetSessionData();
            
            // Change state
            currentState = STATE_STOPPED;
            notifyStateChange();
            
            System.println("SessionManager: Session discarded");
            return true;
            
        } catch (exception) {
            System.println("SessionManager: Error discarding session: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Toggle between active and paused (for single button press)
    function toggleActiveState() {
        if (currentState == STATE_STOPPED) {
            return startSession();
        } else if (currentState == STATE_ACTIVE) {
            return pauseSession();
        } else if (currentState == STATE_PAUSED) {
            return resumeSession();
        }
        return false;
    }
    
    // State query methods
    function getState() {
        return currentState;
    }
    
    function isActive() {
        return currentState == STATE_ACTIVE;
    }
    
    function isPaused() {
        return currentState == STATE_PAUSED;
    }
    
    function isStopped() {
        return currentState == STATE_STOPPED;
    }
    
    function getStateString() {
        switch (currentState) {
            case STATE_STOPPED:
                return "STOPPED";
            case STATE_ACTIVE:
                return "ACTIVE";
            case STATE_PAUSED:
                return "PAUSED";
            default:
                return "UNKNOWN";
        }
    }
    
    // Get session timing information
    function getSessionDuration() {
        var result = 0;

        if (currentState == STATE_STOPPED) {
            result = activeSessionTime;
            //return activeSessionTime;
        } else if (sessionStartTime != null) {
            var now = Time.now();
            var totalTime = now.subtract(sessionStartTime);
            var currentPauseTime = 0;
            
            if (currentState == STATE_PAUSED && sessionPauseTime != null) {
                currentPauseTime = now.subtract(sessionPauseTime).value();
            }
            
            result = totalTime.value() - totalPausedTime - currentPauseTime;
        }
        // DEBUG: Loguj wartość
        //System.println("SessionManager: getSessionDuration() = " + result + " (type: " + result.getClass() + ")");
  
        return result;
    }
    
    function getFormattedDuration() {
        try {
            /* var durationMs = getSessionDuration(); // Milisekundy
            
            var totalSeconds = Math.floor(durationMs / 1000); // UŻYJ Math.floor!             
            var hours = Math.floor(totalSeconds / 3600);
            var minutes = Math.floor((totalSeconds % 3600) / 60);
            var seconds = totalSeconds % 60; 
            
            // DEBUG: Loguj wartości
            System.println("SessionManager: Duration=" + durationMs + "ms, Formatted=" + 
                        hours + ":" + minutes + ":" + seconds);
            
            return hours.format("%02d") + ":" + 
                minutes.format("%02d") + ":" + 
                seconds.format("%02d"); */
 
            var duration = getSessionDuration() / 1000; // Convert to seconds
    
            var totalSeconds = duration;
            var hours = (totalSeconds / 3600).toNumber();
            var minutes = ((totalSeconds % 3600) / 60).toNumber();
            var seconds = (totalSeconds % 60).toNumber();

            var formattedDuration = hours.format("%d") + ":" + 
                        minutes.format("%02d") + ":" + 
                        seconds.format("%02d");
                        
            return formattedDuration;
                
        } catch (exception) {
            System.println("SessionManager: Error in getFormattedDuration: " + exception.getErrorMessage());
            return "00:00:00";
        }
    }
    
    // Session data management
    function getSessionData() {
        sessionData.put("state", currentState);
        sessionData.put("startTime", sessionStartTime);
        sessionData.put("duration", getSessionDuration());
        sessionData.put("sessionId", sessionId);
        
        if (sessionStats != null) {
            sessionData.put("stats", sessionStats.getSessionData());
        }
        
        return sessionData;
    }
    
    function restoreSessionData(data) {
        try {
            if (data != null) {
                currentState = data.get("state");
                sessionStartTime = data.get("startTime");
                sessionId = data.get("sessionId");
                
                var stats = data.get("stats");
                if (stats != null && sessionStats != null) {
                    sessionStats.restoreSessionData(stats);
                }
                
                System.println("SessionManager: Session data restored");
            }
        } catch (exception) {
            System.println("SessionManager: Error restoring session data: " + exception.getErrorMessage());
        }
    }
    
    function saveSessionData() {
        // Save session data to persistent storage if needed
        sessionData = getSessionData();
        System.println("SessionManager: Session data saved");
    }
    
    function resetSessionData() {
        sessionStartTime = null;
        sessionPauseTime = null;
        totalPausedTime = 0;
        activeSessionTime = 0;
        sessionId = null;
        sessionData = {};
        System.println("SessionManager: Session data reset");
    }
    
    // Notify state change
    /* function notifyStateChange() {
        if (stateChangeCallback != null) {
            stateChangeCallback.invoke(getStateString());
        }
    } */
    function notifyStateChange() {
        // Wywołaj callback jeśli istnieje (najlepsze rozwiązanie)
        if (stateChangeCallback != null) {
            try {
                stateChangeCallback.invoke(getStateString());
                System.println("SessionManager: State change callback invoked");
            } catch (exception) {
                System.println("SessionManager: Error in state callback: " + exception.getErrorMessage());
                
                // Fallback - jeśli callback się nie udał, zrób bezpośrednie update
                try {
                    WatchUi.requestUpdate();
                } catch (updateException) {
                    System.println("SessionManager: Error requesting update: " + updateException.getErrorMessage());
                }
            }
        } else {
            // Fallback - jeśli callback nie jest ustawiony
            System.println("SessionManager: No state callback set, using direct update");
            try {
                WatchUi.requestUpdate();
            } catch (exception) {
                System.println("SessionManager: Error requesting update: " + exception.getErrorMessage());
            }
        }
    }
    
    // Cleanup
    function cleanup() {
        try {
            if (currentState != STATE_STOPPED) {
                discardSession();
            }
            System.println("SessionManager: Cleanup completed");
        } catch (exception) {
            System.println("SessionManager: Error during cleanup: " + exception.getErrorMessage());
        }
    }
}