// InlineSkatingMenuDelegate.mc
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;

class SkatingMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :item_1) {
            System.println("item 1");
        } else if (item == :item_2) {
            System.println("item 2");
        }
    }

}