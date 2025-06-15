// Utils.mc
// Utility functions for Garmin Aggressive Inline Skating Tracker
using Toybox.Application.Storage;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Math;


// Globalne funkcje pomocnicze
function min(a, b) {
    return a < b ? a : b;
}

function max(a, b) {
    return a > b ? a : b;
}

function clamp(value, minVal, maxVal) {
    if (value < minVal) { return minVal; }
    if (value > maxVal) { return maxVal; }
    return value;
}

function abs(value) {
    return value < 0 ? -value : value;
}

// Konwersja jednostek
function metersPerSecondToKmh(mps) {
    return mps * 3.6;
}

function kmhToMetersPerSecond(kmh) {
    return kmh / 3.6;
}

// Funkcje matematyczne
function degreesToRadians(degrees) {
    return degrees * Math.PI / 180.0;
}

function radiansToDegrees(radians) {
    return radians * 180.0 / Math.PI;
}




// SYSTEM LOGOWANIA DLA ZEGARKA
class DeviceLogger {
    
    const MAX_LOG_ENTRIES = 100;
    const LOG_KEY = "device_logs";
    
    static var instance;
    var logEntries;
    var logCounter = 0;
    
    function initialize() {
        logEntries = Storage.getValue(LOG_KEY);
        if (logEntries == null) {
            logEntries = [];
        }
        
        // Dodaj separator dla nowej sesji
        addLogEntry("=== NEW SESSION START ===");
    }
    
    static function getInstance() {
        if (instance == null) {
            instance = new DeviceLogger();
        }
        return instance;
    }
    
    function addLogEntry(message) {
        var timestamp = System.getClockTime();
        var timeStr = timestamp.hour.format("%02d") + ":" + 
                     timestamp.min.format("%02d") + ":" + 
                     timestamp.sec.format("%02d");
        
        var entry = "[" + timeStr + "] " + message;
        
        // Dodaj do listy
        logEntries.add(entry);
        logCounter++;
        
        // Ogranicz rozmiar (zachowaj ostatnie MAX_LOG_ENTRIES)
        if (logEntries.size() > MAX_LOG_ENTRIES) {
            logEntries = logEntries.slice(logEntries.size() - MAX_LOG_ENTRIES, logEntries.size());
        }
        
        // Zapisz do storage
        try {
            Storage.setValue(LOG_KEY, logEntries);
        } catch (exception) {
            // Storage error - ignore
        }
        
        // Też wyślij do System.println dla debugera
        System.println("DEVICE_LOG: " + entry);
    }
    
    function getLogs() {
        return logEntries;
    }
    
    function getLogsAsString() {
        var result = "=== DEVICE LOGS ===\n";
        for (var i = 0; i < logEntries.size(); i++) {
            result += logEntries[i] + "\n";
        }
        result += "=== END LOGS ===";
        return result;
    }
    
    function clearLogs() {
        logEntries = [];
        Storage.setValue(LOG_KEY, logEntries);
        addLogEntry("Logs cleared");
    }
    
    function getLogCount() {
        return logCounter;
    }
}

// GLOBALNE FUNKCJE LOGOWANIA
function logDevice(message) {
    DeviceLogger.getInstance().addLogEntry(message);
}

function logError(context, exception) {
    var msg = context + " ERROR: " + exception.getErrorMessage();
    DeviceLogger.getInstance().addLogEntry(msg);
}

function logCritical(message) {
    var msg = "CRITICAL: " + message;
    DeviceLogger.getInstance().addLogEntry(msg);
    System.println("CRITICAL: " + message);
}