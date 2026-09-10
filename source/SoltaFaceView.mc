import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class SoltaFaceView extends WatchUi.WatchFace {

    private var _secondsX as Number;
    private var _partialUpdatesAllowed as Boolean;
    private var _timeFont as FontResource?;
    private var _labelFont as FontResource?;
    private var _dateFont as FontResource?;

    function initialize() {
        WatchFace.initialize();
        _secondsX = 0;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _timeFont = null;
        _labelFont = null;
        _dateFont = null;
    }

    function onLayout(dc as Dc) as Void {
        _timeFont = WatchUi.loadResource(Rez.Fonts.TimeFont) as FontResource;
        _labelFont = WatchUi.loadResource(Rez.Fonts.LabelFont) as FontResource;
        _dateFont = WatchUi.loadResource(Rez.Fonts.DateFont) as FontResource;
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();

        // A partial-update clip persists on the device context. Full updates
        // must restore the complete drawing area before clearing the display.
        dc.clearClip();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        drawStatus(dc, width);
        drawTimeAndDate(dc, width);
        drawBottomData(dc, width);

        // Include seconds in every full/minute refresh. Subsequent seconds are
        // handled by onPartialUpdate without touching any other complication.
        if (_partialUpdatesAllowed) {
            drawSeconds(dc);
        }
    }

    public function onPartialUpdate(dc as Dc) as Void {
        if (!_partialUpdatesAllowed) {
            return;
        }

        // This 55x30 rectangle contains only the superscript seconds. Filling
        // it black first prevents stale segments and MIP ghost digits.
        dc.setClip(_secondsX, 63, 55, 29);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(_secondsX, 63, 55, 29);
        drawSeconds(dc);
    }

    private function drawStatus(dc as Dc, width as Number) as Void {
        var settings = System.getDeviceSettings();
        var notificationCount = settings.notificationCount;
        var battery = (System.getSystemStats().battery + 0.5).toNumber();

        // Bell and count are kept well inside the circular edge.
        drawBell(dc, 46, 43);
        dc.drawText(59, 30, Graphics.FONT_MEDIUM, notificationCount.toString(), Graphics.TEXT_JUSTIFY_LEFT);

        // Battery group is right-aligned so three-digit percentages remain safe.
        var batteryText = battery.toString();
        var textWidth = dc.getTextWidthInPixels(batteryText, Graphics.FONT_MEDIUM);
        var batteryX = width - 50 - textWidth;
        drawBattery(dc, batteryX - 31, 39, 25, 13, battery);
        dc.drawText(width - 43, 30, Graphics.FONT_MEDIUM, batteryText, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    private function drawTimeAndDate(dc as Dc, width as Number) as Void {
        var clockTime = System.getClockTime();
        var settings = System.getDeviceSettings();
        var hour = clockTime.hour;

        if (!settings.is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }

        var timeText = Lang.format("$1$:$2$", [hour, clockTime.min.format("%02d")]);
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var weekday = shortUpper(dateInfo.day_of_week.toString());
        var month = shortUpper(dateInfo.month.toString());
        var dateText = Lang.format("$1$ $2$", [dateInfo.day, month]);

        var timeFont = _timeFont;
        var dateFont = _dateFont;
        if ((timeFont == null) || (dateFont == null)) {
            return;
        }

        var timeWidth = dc.getTextWidthInPixels(timeText, timeFont);
        var dateWidth = 48;
        var groupWidth = timeWidth + 5 + dateWidth;
        var startX = (width - groupWidth) / 2;

        // Guard against unusually wide localized/system glyph metrics.
        if (startX < 9) {
            startX = 9;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(startX, 65, timeFont, timeText, Graphics.TEXT_JUSTIFY_LEFT);

        var dateX = startX + timeWidth + 5;
        _secondsX = dateX - 1;
        dc.drawText(dateX, 92, Graphics.FONT_SMALL, weekday, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(dateX, 117, dateFont, dateText, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(25, 134, width - 50, 2);
    }

    private function drawBottomData(dc as Dc, width as Number) as Void {
        var info = ActivityMonitor.getInfo();
        var stepsValue = null;
        if ((info has :steps) && (info.steps != null)) {
            stepsValue = info.steps;
        }
        var stepsText = (stepsValue == null) ? "--" : stepsValue.toString();

        var heartRate = getLatestHeartRate();
        var heartText = (heartRate == null) ? "--" : heartRate.toString();
        var stepsFont = Graphics.FONT_NUMBER_MEDIUM;
        if ((stepsValue != null) && (stepsValue >= 10000)) {
            stepsFont = Graphics.FONT_NUMBER_MILD;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(64, 135, stepsFont, stepsText, Graphics.TEXT_JUSTIFY_CENTER);
        drawHeart(dc, 142, 143);
        dc.drawText(181, 135, Graphics.FONT_NUMBER_MEDIUM, heartText, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        if (_labelFont != null) {
            dc.drawText(64, 165, _labelFont, "STEPS", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(181, 165, _labelFont, "BPM", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function drawSeconds(dc as Dc) as Void {
        var seconds = System.getClockTime().sec.format("%02d");
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(_secondsX, 63, Graphics.FONT_SMALL, seconds, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function getLatestHeartRate() as Number? {
        var iterator = ActivityMonitor.getHeartRateHistory(1, true);
        var sample = iterator.next();

        if ((sample != null) && (sample.heartRate != null) &&
                (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) &&
                (sample.heartRate > 0)) {
            return sample.heartRate;
        }

        return null;
    }

    private function shortUpper(value as String) as String {
        var endIndex = value.length();
        if (endIndex > 3) {
            endIndex = 3;
        }
        return (value.substring(0, endIndex) as String).toUpper();
    }

    private function drawBell(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x, y - 4, 7);
        dc.fillRectangle(x - 7, y - 4, 14, 9);
        dc.fillPolygon([[x - 10, y + 7], [x + 10, y + 7], [x + 7, y + 3], [x - 7, y + 3]]);
        dc.fillCircle(x, y + 10, 3);
    }

    private function drawBattery(dc as Dc, x as Number, y as Number, w as Number, h as Number, level as Number) as Void {
        dc.setPenWidth(2);
        dc.drawRectangle(x, y, w, h);
        dc.fillRectangle(x + w, y + 4, 3, h - 8);

        var fillWidth = ((w - 4) * level) / 100;
        if (fillWidth > 0) {
            dc.fillRectangle(x + 2, y + 2, fillWidth, h - 4);
        }
    }

    private function drawHeart(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x - 4, y, 5);
        dc.fillCircle(x + 4, y, 5);
        dc.fillPolygon([[x - 9, y + 1], [x + 9, y + 1], [x, y + 11]]);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
        // Fenix 5X continues to invoke onPartialUpdate in low-power mode.
        // No timer or full-screen refresh is needed for the transition.
    }

    public function turnPartialUpdatesOff() as Void {
        _partialUpdatesAllowed = false;
        // Clear a potentially stale seconds value on the next full refresh.
        WatchUi.requestUpdate();
    }
}

class SoltaFaceDelegate extends WatchUi.WatchFaceDelegate {
    private var _view as SoltaFaceView;

    function initialize(view as SoltaFaceView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    public function onPowerBudgetExceeded(powerInfo as WatchFacePowerInfo) as Void {
        System.println("POWER_BUDGET_EXCEEDED");
        System.println("Average execution time: " + powerInfo.executionTimeAverage);
        System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
        _view.turnPartialUpdatesOff();
    }
}
