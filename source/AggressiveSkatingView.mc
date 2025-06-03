// AggressiveSkatingView.mc

class MainView extends Ui.View {
    var app;

    function initialize(appInstance) {
        app = appInstance;
    }

    function onUpdate(dc) {
        dc.clear();
        dc.drawText(10, 10, Gfx.FONT_MEDIUM, "Skoki: " + app.jumpCount);
        dc.drawText(10, 30, Gfx.FONT_MEDIUM, "Dystans: " + app.distance + " m");
        // Dodaj inne dane według potrzeb
    }
}
/* using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class MainView extends Ui.View {
    function onUpdate(dc) {
        dc.clear();
        dc.drawText(10, 10, Gfx.FONT_MEDIUM, "Skoki: " + AggressiveSkatingApp.jumpCount);
        dc.drawText(10, 30, Gfx.FONT_MEDIUM, "Dystans: " + AggressiveSkatingApp.distance + " m");
        dc.drawText(10, 50, Gfx.FONT_MEDIUM, "Tętno: " + AggressiveSkatingApp.heartRateZones.getHeartRateZones());
        // Dodaj inne dane według potrzeb
    }
}
 */

/*using Toybox.WatchUi;
 
class InlineSkatingView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // var info = Activity.getInfo();
        var info = ActivityMonitor.getInfo();
        var heartRate = info.currentHeartRate;
        dc.drawText(30, 30, Graphics.FONT_MEDIUM, heartRate, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

}
 */