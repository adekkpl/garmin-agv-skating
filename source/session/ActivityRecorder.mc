// ActivityRecorder.mc
// Garmin Aggressive Inline Skating Tracker v3.0.0
// Activity Recording for Garmin Connect
using Toybox.Lang;
using Toybox.ActivityRecording;
using Toybox.System;
// using Toybox.FitContributor; // Commented out - requires permission

class ActivityRecorder {
    
    // Recording state
    var session;
    var isRecording = false;
    var recordingStartTime;
    
    // FIT data contributors
    var tricksField;
    var grindsField;
    var rotationsField;
    var performanceField;
    
    // Session data tracking
    var sessionData;
    
    function initialize() {
        session = null;
        isRecording = false;
        recordingStartTime = null;
        sessionData = {};
        
        System.println("ActivityRecorder: Initialized");
    }
    
    // Start recording activity
    function startRecording() {
        try {
            if (isRecording) {
                System.println("ActivityRecorder: Already recording");
                return true;
            }
            
            // Create new recording session
            session = ActivityRecording.createSession({
                :name => "Aggressive Skating",
                :sport => ActivityRecording.SPORT_CYCLING, // Use non-deprecated sport
                :subSport => ActivityRecording.SUB_SPORT_GENERIC // Use non-deprecated subsport
            });
            
            if (session == null) {
                System.println("ActivityRecorder: Failed to create session");
                return false;
            }
            
            // Create custom FIT fields for our specific data
            createCustomFields();
            
            // Start the recording
            session.start();
            isRecording = true;
            recordingStartTime = System.getTimer();
            
            System.println("ActivityRecorder: Recording started");
            return true;
            
        } catch (exception) {
            System.println("ActivityRecorder: Error starting recording: " + exception.getErrorMessage());
            isRecording = false;
            return false;
        }
    }
    
    // Pause recording
    function pauseRecording() {
        try {
            if (!isRecording || session == null) {
                System.println("ActivityRecorder: Cannot pause - not recording");
                return false;
            }
            
            session.stop();
            System.println("ActivityRecorder: Recording paused");
            return true;
            
        } catch (exception) {
            System.println("ActivityRecorder: Error pausing recording: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Resume recording
    function resumeRecording() {
        try {
            if (!isRecording || session == null) {
                System.println("ActivityRecorder: Cannot resume - not recording");
                return false;
            }
            
            session.start();
            System.println("ActivityRecorder: Recording resumed");
            return true;
            
        } catch (exception) {
            System.println("ActivityRecorder: Error resuming recording: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Stop recording
    function stopRecording() {
        try {
            if (!isRecording || session == null) {
                System.println("ActivityRecorder: Not recording");
                return true;
            }
            
            session.stop();
            isRecording = false;
            
            System.println("ActivityRecorder: Recording stopped");
            return true;
            
        } catch (exception) {
            System.println("ActivityRecorder: Error stopping recording: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Save the recorded session
    function saveSession() {
        try {
            if (session == null) {
                System.println("ActivityRecorder: No session to save");
                return false;
            }
            
            if (isRecording) {
                stopRecording();
            }
            
            // Add final custom data
            updateCustomFields();
            
            // Save the session
            session.save();
            session = null;
            
            System.println("ActivityRecorder: Session saved to Garmin Connect");
            return true;
            
        } catch (exception) {
            System.println("ActivityRecorder: Error saving session: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Discard the recorded session
    function discardSession() {
        try {
            if (session == null) {
                System.println("ActivityRecorder: No session to discard");
                return true;
            }
            
            if (isRecording) {
                stopRecording();
            }
            
            session.discard();
            session = null;
            isRecording = false;
            
            System.println("ActivityRecorder: Session discarded");
            return true;
            
        } catch (exception) {
            System.println("ActivityRecorder: Error discarding session: " + exception.getErrorMessage());
            return false;
        }
    }
    
    // Create custom FIT fields for our specific data
    function createCustomFields() {
        try {
            // Custom FIT fields disabled for compatibility - would need FitContributor permission
            System.println("ActivityRecorder: Custom FIT fields disabled for compatibility");
            
            // In production, you would need to add FitContributor permission to manifest.xml
            // and uncomment the field creation code below:
            /*
            tricksField = session.createField(
                "tricks",
                0,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_SESSION}
            );
            */
            
        } catch (exception) {
            System.println("ActivityRecorder: Error creating custom fields: " + exception.getErrorMessage());
        }
    }
    
    // Update custom fields with current data
    function updateCustomFields() {
        if (session == null) {
            return;
        }
        
        try {
            // Get current session data from other components
            // This would typically be passed in or retrieved from a central data store
            
            if (tricksField != null) {
                var tricks = sessionData.get("totalTricks");
                if (tricks != null) {
                    tricksField.setData(tricks);
                }
            }
            
            if (grindsField != null) {
                var grinds = sessionData.get("totalGrinds");
                if (grinds != null) {
                    grindsField.setData(grinds);
                }
            }
            
            if (rotationsField != null) {
                var rotations = sessionData.get("totalRotations");
                if (rotations != null) {
                    rotationsField.setData(rotations.toNumber());
                }
            }
            
            if (performanceField != null) {
                var performance = sessionData.get("performanceRating");
                if (performance != null) {
                    performanceField.setData(performance);
                }
            }
            
            System.println("ActivityRecorder: Custom fields updated");
            
        } catch (exception) {
            System.println("ActivityRecorder: Error updating custom fields: " + exception.getErrorMessage());
        }
    }
    
    // Set session data for recording
    function setSessionData(data) {
        sessionData = data;
        
        // Update fields immediately if recording
        if (isRecording) {
            updateCustomFields();
        }
    }
    
    // Add a data point during recording
    function addDataPoint(dataType, value) {
        if (!isRecording || session == null) {
            return;
        }
        
        try {
            // Add specific data points if needed
            // This is for real-time data updates during recording
            sessionData.put(dataType, value);
            
        } catch (exception) {
            System.println("ActivityRecorder: Error adding data point: " + exception.getErrorMessage());
        }
    }
    
    // Record a trick event
    function recordTrickEvent(trickType, trickData) {
        if (!isRecording) {
            return;
        }
        
        try {
            // Add trick to session data
            var currentTricks = sessionData.get("totalTricks");
            if (currentTricks == null) {
                currentTricks = 0;
            }
            sessionData.put("totalTricks", currentTricks + 1);
            
            if (trickType.equals("grind")) {
                var currentGrinds = sessionData.get("totalGrinds");
                if (currentGrinds == null) {
                    currentGrinds = 0;
                }
                sessionData.put("totalGrinds", currentGrinds + 1);
            }
            
            // Update custom fields
            updateCustomFields();
            
            System.println("ActivityRecorder: Recorded trick event - " + trickType);
            
        } catch (exception) {
            System.println("ActivityRecorder: Error recording trick: " + exception.getErrorMessage());
        }
    }
    
    // Record a rotation event
    function recordRotationEvent(direction, angle) {
        if (!isRecording) {
            return;
        }
        
        try {
            var rotationAmount = angle / 360.0;
            var currentRotations = sessionData.get("totalRotations");
            if (currentRotations == null) {
                currentRotations = 0.0;
            }
            sessionData.put("totalRotations", currentRotations + rotationAmount);
            
            // Update custom fields
            updateCustomFields();
            
            System.println("ActivityRecorder: Recorded rotation - " + direction + " " + rotationAmount.format("%.2f"));
            
        } catch (exception) {
            System.println("ActivityRecorder: Error recording rotation: " + exception.getErrorMessage());
        }
    }
    
    // Get recording status
    function isSessionRecording() {
        return isRecording;
    }
    
    function getRecordingDuration() {
        if (recordingStartTime == null) {
            return 0;
        }
        return System.getTimer() - recordingStartTime;
    }
    
    function hasActiveSession() {
        return session != null;
    }
    
    // Get recording information
    function getRecordingInfo() {
        return {
            "isRecording" => isRecording,
            "hasSession" => session != null,
            "duration" => getRecordingDuration(),
            "startTime" => recordingStartTime
        };
    }
    
    // Force save current data (for periodic updates)
    function flushData() {
        if (isRecording && session != null) {
            updateCustomFields();
        }
    }
    
    // Cleanup
    function cleanup() {
        try {
            if (isRecording && session != null) {
                System.println("ActivityRecorder: Auto-saving session on cleanup");
                saveSession();
            } else if (session != null) {
                System.println("ActivityRecorder: Discarding unsaved session on cleanup");
                discardSession();
            }
            
            System.println("ActivityRecorder: Cleanup completed");
            
        } catch (exception) {
            System.println("ActivityRecorder: Error during cleanup: " + exception.getErrorMessage());
        }
    }
}