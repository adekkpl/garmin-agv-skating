// AggressiveSkatingView.mc
/// Garmin Aggressive Inline Skating Tracker v2.0.0
// Aggressive Skating View

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Application;

class MainView extends WatchUi.View {
    private var app;

    function initialize(appInstance) {
        View.initialize();
        app = appInstance;
    }

    function onUpdate(dc) {
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        
        // Używaj Graphics zamiast Gfx
        dc.drawText(10, 10, Graphics.FONT_MEDIUM, "Skoki: 0", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(10, 30, Graphics.FONT_MEDIUM, "Dystans: " + app.distance + " m", Graphics.TEXT_JUSTIFY_LEFT);
        
        // Dodaj więcej informacji jeśli potrzeba
    }
}