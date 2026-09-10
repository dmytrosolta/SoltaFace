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
    private var _dateFont as FontResource?;
    private var _metricFont as FontResource?;
    private var _metricSmallFont as FontResource?;

    function initialize() {
        WatchFace.initialize();
        _secondsX = 0;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _timeFont = null;
        _dateFont = null;
        _metricFont = null;
        _metricSmallFont = null;
    }

    function onLayout(dc as Dc) as Void {
        _timeFont = WatchUi.loadResource(Rez.Fonts.TimeFont) as FontResource;
        _dateFont = WatchUi.loadResource(Rez.Fonts.DateFont) as FontResource;
        _metricFont = WatchUi.loadResource(Rez.Fonts.MetricFont) as FontResource;
        _metricSmallFont = WatchUi.loadResource(Rez.Fonts.MetricSmallFont) as FontResource;
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
        drawTime(dc, width);
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

        // This 32x29 rectangle contains only the superscript seconds. Filling
        // it black first prevents stale segments and MIP ghost digits.
        dc.setClip(_secondsX, 70, 32, 29);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(_secondsX, 70, 32, 29);
        drawSeconds(dc);
    }

    private function drawStatus(dc as Dc, width as Number) as Void {
        var settings = System.getDeviceSettings();
        var notificationCount = settings.notificationCount;
        var battery = (System.getSystemStats().battery + 0.5).toNumber();
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var weekday = shortUpper(dateInfo.day_of_week.toString());
        var month = shortUpper(dateInfo.month.toString());
        var dateText = Lang.format("$1$ $2$", [dateInfo.day, month]);
        var dateFont = _dateFont;

        if (dateFont == null) {
            return;
        }

        // Date/day own the upper arc; status groups sit directly below it.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(65, 23, Graphics.FONT_SMALL, weekday, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(120, 29, dateFont, dateText, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        drawBell(dc, 40, 54);
        dc.drawText(53, 45, dateFont, notificationCount.toString(), Graphics.TEXT_JUSTIFY_LEFT);

        // Right-align the battery group so a three-digit percentage stays safe.
        var batteryText = battery.toString();
        drawBattery(dc, 159, 49, 17, 10, battery);
        dc.drawText(width - 27, 45, dateFont, batteryText, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    private function drawTime(dc as Dc, width as Number) as Void {
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
        var timeFont = _timeFont;
        if (timeFont == null) {
            return;
        }

        var timeWidth = dc.getTextWidthInPixels(timeText, timeFont);
        var secondsWidth = dc.getTextWidthInPixels("00", Graphics.FONT_SMALL);
        var groupWidth = timeWidth + 3 + secondsWidth;
        var startX = (width - groupWidth) / 2;

        if (startX < 12) {
            startX = 12;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(startX, 70, timeFont, timeText, Graphics.TEXT_JUSTIFY_LEFT);
        _secondsX = startX + timeWidth + 3;
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
        var stepsFont = _metricFont;
        if ((stepsValue != null) && (stepsValue >= 10000)) {
            stepsFont = _metricSmallFont;
        }

        var metricFont = _metricFont;
        if ((stepsFont == null) || (metricFont == null)) {
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        drawShoe(dc, 30, 183);
        dc.drawText(54, 170, stepsFont, stepsText, Graphics.TEXT_JUSTIFY_LEFT);
        drawHeart(dc, 148, 183);
        dc.drawText(162, 170, metricFont, heartText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawSeconds(dc as Dc) as Void {
        var seconds = System.getClockTime().sec.format("%02d");
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(_secondsX, 70, Graphics.FONT_SMALL, seconds, Graphics.TEXT_JUSTIFY_LEFT);
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

    private function drawShoe(dc as Dc, x as Number, y as Number) as Void {
        dc.fillPolygon([
            [x, y - 7], [x + 5, y - 2], [x + 11, y + 1],
            [x + 18, y + 1], [x + 21, y + 5], [x + 19, y + 9],
            [x + 8, y + 9], [x + 1, y + 5], [x - 2, y]
        ]);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawLine(x + 2, y + 2, x + 9, y + 6);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
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
