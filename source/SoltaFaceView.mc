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
    private var _secondsActive as Boolean;
    private var _secondsValue as Number;
    private var _timeFont as FontResource?;
    private var _dayFont as FontResource?;
    private var _dateFont as FontResource?;
    private var _batteryFont as FontResource?;
    private var _metricFont as FontResource?;
    private var _metricSmallFont as FontResource?;

    function initialize() {
        WatchFace.initialize();
        _secondsX = 0;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _secondsActive = true;
        _secondsValue = System.getClockTime().sec;
        _timeFont = null;
        _dayFont = null;
        _dateFont = null;
        _batteryFont = null;
        _metricFont = null;
        _metricSmallFont = null;
    }

    function onLayout(dc as Dc) as Void {
        _timeFont = WatchUi.loadResource(Rez.Fonts.TimeFont) as FontResource;
        _dayFont = WatchUi.loadResource(Rez.Fonts.DayFont) as FontResource;
        _dateFont = WatchUi.loadResource(Rez.Fonts.DateFont) as FontResource;
        _batteryFont = WatchUi.loadResource(Rez.Fonts.BatteryFont) as FontResource;
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

        // Full/minute refreshes preserve the last active seconds in sleep.
        drawSeconds(dc);
    }

    public function onPartialUpdate(dc as Dc) as Void {
        if (!_partialUpdatesAllowed || !_secondsActive) {
            return;
        }

        // This 32x30 rectangle contains only the superscript seconds. Filling
        // it black first prevents stale segments and MIP ghost digits.
        dc.setClip(_secondsX, 81, 32, 30);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(_secondsX, 81, 32, 30);
        drawSeconds(dc);
    }

    private function drawStatus(dc as Dc, width as Number) as Void {
        var battery = (System.getSystemStats().battery + 0.5).toNumber();
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var weekday = shortUpper(dateInfo.day_of_week.toString());
        var month = shortUpper(dateInfo.month.toString());
        var dateText = Lang.format("$1$ $2$", [dateInfo.day, month]);
        var dayFont = _dayFont;
        var dateFont = _dateFont;
        var batteryFont = _batteryFont;

        if ((dayFont == null) || (dateFont == null) || (batteryFont == null)) {
            return;
        }

        drawBatteryProgress(dc, width, battery, batteryFont);

        var dayWidth = dc.getTextWidthInPixels(weekday, dayFont);
        var dateWidth = dc.getTextWidthInPixels(dateText, dateFont);
        var rowGap = 8;
        var rowX = (width - dayWidth - rowGap - dateWidth) / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(rowX, 52, dayFont, weekday, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(rowX + dayWidth + rowGap, 55, dateFont, dateText, Graphics.TEXT_JUSTIFY_LEFT);
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
        var secondsFont = _metricSmallFont;
        if ((timeFont == null) || (secondsFont == null)) {
            return;
        }

        var timeWidth = dc.getTextWidthInPixels(timeText, timeFont);
        var secondsWidth = dc.getTextWidthInPixels("00", secondsFont);
        var groupWidth = timeWidth + 5 + secondsWidth;
        var startX = (width - groupWidth) / 2;

        if (startX < 12) {
            startX = 12;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(startX, 81, timeFont, timeText, Graphics.TEXT_JUSTIFY_LEFT);
        _secondsX = startX + timeWidth + 5;
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
        drawFootprints(dc, 30, 170);
        dc.drawText(54, 170, stepsFont, stepsText, Graphics.TEXT_JUSTIFY_LEFT);
        drawHeart(dc, 148, 174);
        dc.drawText(162, 170, metricFont, heartText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawSeconds(dc as Dc) as Void {
        var secondsFont = _metricSmallFont;
        if (secondsFont == null) {
            return;
        }
        if (_secondsActive) {
            _secondsValue = System.getClockTime().sec;
        }
        var seconds = _secondsValue.format("%02d");
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(_secondsX, 81, secondsFont, seconds, Graphics.TEXT_JUSTIFY_LEFT);
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

    private function drawBatteryProgress(dc as Dc, width as Number, level as Number, batteryFont as FontResource) as Void {
        if (level < 0) {
            level = 0;
        } else if (level > 100) {
            level = 100;
        }

        // Garmin arcs use 90 degrees at 12 o'clock. Draw left-to-right across
        // the short upper arc and advance the active endpoint toward 40.
        var startAngle = 140;
        var endAngle = 40;
        var activeEnd = startAngle - (((startAngle - endAngle) * level) / 100);

        dc.setPenWidth(5);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.drawArc(width / 2, 111, 92, Graphics.ARC_CLOCKWISE, startAngle, endAngle);
        if (level > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawArc(width / 2, 111, 92, Graphics.ARC_CLOCKWISE, startAngle, activeEnd);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(width / 2, 28, batteryFont, level.toString() + "%", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawHeart(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x - 3, y, 4);
        dc.fillCircle(x + 3, y, 4);
        dc.fillPolygon([[x - 7, y + 1], [x + 7, y + 1], [x, y + 9]]);
    }

    private function drawFootprints(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x + 4, y + 6, 3);
        dc.fillPolygon([
            [x + 2, y + 8], [x + 7, y + 8], [x + 7, y + 14],
            [x + 5, y + 18], [x + 2, y + 16], [x + 1, y + 12]
        ]);
        dc.fillCircle(x + 14, y + 3, 3);
        dc.fillPolygon([
            [x + 11, y + 5], [x + 16, y + 5], [x + 17, y + 10],
            [x + 16, y + 14], [x + 13, y + 16], [x + 11, y + 11]
        ]);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        _secondsActive = true;
        _secondsValue = System.getClockTime().sec;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        // Preserve the last drawn seconds value without further 1 Hz updates.
        _secondsActive = false;
    }

    public function turnPartialUpdatesOff() as Void {
        _partialUpdatesAllowed = false;
        // Keep the last seconds visible if the platform stops 1 Hz updates.
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
