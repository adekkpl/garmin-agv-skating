// Utils.mc
// Utility functions for Garmin Aggressive Inline Skating Tracker
using Toybox.Lang;
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