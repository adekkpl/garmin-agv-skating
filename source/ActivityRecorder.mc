// ActivityRecorder.mc
// Garmin Aggressive Inline Skating Tracker v2.0.0
// Activity Recording Management Class

using Toybox.Lang;
using Toybox.System;
using Toybox.Activity;
using Toybox.ActivityRecording;

class ActivityRecorder {
    
    var session;

    var isRecording = false;
    var sessionName;
    
    function initialize() {
        System.println("ActivityRecorder: Initializing activity recorder");
        session = null;


        isRecording = false;
        sessionName = "AGV Skating Session";
        
    }

    // Start recording FIT activity
    function startRecording() {
        if (session != null && session.isRecording()) {
            System.println("ActivityRecorder: Session already recording");
            return true;
        }
        
        try {
            // POPRAWKA: Użyj Activity.SPORT_* zamiast ActivityRecording.SPORT_*
            session = ActivityRecording.createSession({
                :name => "Aggressive Skating",
                :sport => Activity.SPORT_INLINE_SKATING,    // POPRAWIONE!
                :subSport => Activity.SUB_SPORT_GENERIC     // POPRAWIONE!
            });
            
            if (session != null) {
                var result = session.start();
                if (result) {
                    isRecording = true;
                    System.println("ActivityRecorder: Session started successfully");
                    return true;
                } else {
                    System.println("ActivityRecorder: Failed to start session");
                    return false;
                }
            } else {
                System.println("ActivityRecorder: Failed to create session");
                return false;
            }
            
        } catch (exception) {
            System.println("ActivityRecorder: Error starting recording: " + exception.getErrorMessage());
            return false;
        }
    }

    function stopRecording() {
        if (session == null || !session.isRecording()) {
            System.println("ActivityRecorder: No active session to stop");
            return false;
        }
        
        try {
            var result = session.stop();
            if (result) {
                isRecording = false;
                System.println("ActivityRecorder: Session stopped successfully");
                return true;
            } else {
                System.println("ActivityRecorder: Failed to stop session");
                return false;
            }
            
        } catch (exception) {
            System.println("ActivityRecorder: Error stopping recording: " + exception.getErrorMessage());
            return false;
        }
    }

    // Stop recording and save FIT file
    /* function stopAndSave() { //  as Boolean
        if (!isRecording || activitySession == null) {
            System.println("ActivityRecorder: No active recording to stop");
            return false;
        }
        
        try {
            System.println("ActivityRecorder: Stopping and saving FIT recording");
            
            var stopSuccess = activitySession.stop();
            if (stopSuccess) {
                var saveSuccess = activitySession.save();
                if (saveSuccess) {
                    System.println("ActivityRecorder: FIT file saved successfully to device");
                    cleanup();
                    return true;
                } else {
                    System.println("ActivityRecorder: Failed to save FIT file");
                    cleanup();
                    return false;
                }
            } else {
                System.println("ActivityRecorder: Failed to stop recording");
                return false;
            }
            
        } catch (exception) {
            System.println("ActivityRecorder: Stop/save error: " + exception.getErrorMessage());
            cleanup();
            return false;
        }
    } */



    function saveSession() {
        if (session == null) {
            System.println("ActivityRecorder: No session to save");
            return false;
        }
        
        try {
            var result = session.save();
            if (result) {
                System.println("ActivityRecorder: Session saved successfully");
                session = null; // Clear reference to free memory
                return true;
            } else {
                System.println("ActivityRecorder: Failed to save session");
                return false;
            }
            
        } catch (exception) {
            System.println("ActivityRecorder: Error saving session: " + exception.getErrorMessage());
            return false;
        }
    }

    function discardSession() {
        if (session == null) {
            System.println("ActivityRecorder: No session to discard");
            return false;
        }
        
        try {
            var result = session.discard();
            if (result) {
                System.println("ActivityRecorder: Session discarded successfully");
                session = null; // Clear reference to free memory
                return true;
            } else {
                System.println("ActivityRecorder: Failed to discard session");
                return false;
            }
            
        } catch (exception) {
            System.println("ActivityRecorder: Error discarding session: " + exception.getErrorMessage());
            return false;
        }
    }
    
    function isSessionRecording() {
        return isRecording && session != null && session.isRecording();
    }
    
    function addLap() {
        if (session != null && session.isRecording()) {
            try {
                var result = session.addLap();
                System.println("ActivityRecorder: Lap added - " + result);
                return result;
            } catch (exception) {
                System.println("ActivityRecorder: Error adding lap: " + exception.getErrorMessage());
                return false;
            }
        }
        return false;
    }


    // Set custom session name
    function setSessionName(name) { // (name as String) as Void
        if (name != null && name.length() > 0) {
            sessionName = name.length() > 15 ? name.substring(0, 15) : name;
            System.println("ActivityRecorder: Session name set to: " + sessionName);
        }
    }

    // Get current session name
    function getSessionName() { //as String 
        return sessionName;
    }


    // Handle app exit - auto-save or discard active session
    function onAppExit() {
        System.println("ActivityRecorder: App exit - handling active session");
        
        if (session == null) {
            System.println("ActivityRecorder: No session to handle on exit");
            return;
        }
        
        try {
            if (isRecording && session.isRecording()) {
                System.println("ActivityRecorder: Auto-stopping and saving session on app exit");
                
                // Stop recording
                var stopResult = session.stop();
                if (stopResult) {
                    isRecording = false;
                    System.println("ActivityRecorder: Session stopped successfully on exit");
                    
                    // Try to save
                    var saveResult = session.save();
                    if (saveResult) {
                        System.println("ActivityRecorder: Session auto-saved successfully on exit");
                        session = null; // Clear reference
                    } else {
                        System.println("ActivityRecorder: Failed to save session on exit - discarding");
                        // If save fails, discard to free memory
                        session.discard();
                        session = null;
                    }
                } else {
                    System.println("ActivityRecorder: Failed to stop session on exit - discarding");
                    // If can't stop, discard to prevent memory leaks
                    session.discard();
                    session = null;
                    isRecording = false;
                }
            } else {
                System.println("ActivityRecorder: Session not recording on exit");
                // Session exists but not recording - discard it
                if (session != null) {
                    session.discard();
                    session = null;
                }
            }
            
        } catch (exception) {
            System.println("ActivityRecorder: Error during app exit handling: " + exception.getErrorMessage());
            
            // Emergency cleanup - try to discard session to prevent memory leaks
            try {
                if (session != null) {
                    session.discard();
                    session = null;
                }
                isRecording = false;
            } catch (discardException) {
                System.println("ActivityRecorder: Failed to discard session during emergency cleanup: " + discardException.getErrorMessage());
            }
        }
    }

    // Cleanup resources
    /* function cleanup() as Void {
        activitySession = null;
        isRecording = false;
        System.println("ActivityRecorder: Cleaned up resources");
    }
 */
    // Get session info for display
    /* function getSessionInfo() { //as Dictionary
        return {
            "isRecording" => isRecording,
            "sessionName" => sessionName,
            "hasActiveSession" => (activitySession != null)
        };
    } */

    // Force cleanup if app is closing
    /* function onAppExit() as Void {
        if (isRecording && activitySession != null) {
            System.println("ActivityRecorder: App exiting - auto-saving session");
            stopAndSave();
        } else {
            cleanup();
        }
    } */
}