import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class SoltaFaceLayout {

    private var _numerator as Number;
    private var _denominator as Number;

    function initialize(width as Number) {
        if (width >= 280) {
            _numerator = 7;
            _denominator = 6;
        } else if (width >= 260) {
            _numerator = 13;
            _denominator = 12;
        } else {
            _numerator = 1;
            _denominator = 1;
        }
    }

    function px(value as Number) as Number {
        return ((value * _numerator) + (_denominator / 2)) / _denominator;
    }
}

class SoltaFaceView extends WatchUi.WatchFace {

    private var _layout as SoltaFaceLayout;
    private var _secondsX as Number;
    private var _secondsY as Number;
    private var _secondsClipWidth as Number;
    private var _secondsClipHeight as Number;
    private var _partialUpdatesAllowed as Boolean;
    private var _isInstinct as Boolean;
    private var _subscreen;
    private var _alwaysRunningSeconds as Boolean;
    private var _inSleep as Boolean;
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
        _layout = new SoltaFaceLayout(240);
        _secondsX = 0;
        _secondsY = 81;
        _secondsClipWidth = 32;
        _secondsClipHeight = 30;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _isInstinct = false;
        _subscreen = null;
        _alwaysRunningSeconds = getApp().getAlwaysRunningSeconds();
        _inSleep = false;
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
        _layout = new SoltaFaceLayout(dc.getWidth());
        _isInstinct = (dc.getWidth() == 176) && (dc.getHeight() == 176);
        _subscreen = null;
        if (_isInstinct && (WatchUi has :getSubscreen)) {
            _subscreen = WatchUi.getSubscreen();
        }
        _timeFont = WatchUi.loadResource(Rez.Fonts.TimeFont) as FontResource;
        _dayFont = WatchUi.loadResource(Rez.Fonts.DayFont) as FontResource;
        _dateFont = WatchUi.loadResource(Rez.Fonts.DateFont) as FontResource;
        _batteryFont = WatchUi.loadResource(Rez.Fonts.BatteryFont) as FontResource;
        _metricFont = WatchUi.loadResource(Rez.Fonts.MetricFont) as FontResource;
        _metricSmallFont = WatchUi.loadResource(Rez.Fonts.MetricSmallFont) as FontResource;

        var secondsFont = _metricSmallFont;
        if (secondsFont != null) {
            _secondsY = _isInstinct ? 83 : _layout.px(81);
            _secondsClipWidth = dc.getTextWidthInPixels("00", secondsFont);
            _secondsClipHeight = dc.getFontHeight(secondsFont);
        }
    }

    function onShow() as Void {
        reloadSettings();
    }

    function reloadSettings() as Void {
        _alwaysRunningSeconds = getApp().getAlwaysRunningSeconds();
        _secondsActive = _partialUpdatesAllowed &&
                (!_inSleep || _alwaysRunningSeconds);
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();

        // A partial-update clip persists on the device context. Full updates
        // must restore the complete drawing area before clearing the display.
        dc.clearClip();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        if (_isInstinct) {
            drawInstinctStatus(dc);
            drawInstinctTime(dc);
            drawInstinctBottomData(dc);
            drawInstinctBattery(dc);
            drawSeconds(dc);
            return;
        }

        drawStatus(dc, width);
        drawTime(dc, width);
        drawBottomData(dc, width);

        // Full/minute refreshes preserve the last active seconds in sleep.
        drawSeconds(dc);
    }

    private function drawInstinctStatus(dc as Dc) as Void {
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var weekday = shortUpper(dateInfo.day_of_week.toString());
        var month = shortUpper(dateInfo.month.toString());
        var dateText = Lang.format("$1$ $2$", [dateInfo.day, month]);
        var dayFont = _dayFont;
        var dateFont = _dateFont;

        if ((dayFont == null) || (dateFont == null)) {
            return;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(30, 11, dayFont, weekday, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(30, 33, dateFont, dateText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawInstinctTime(dc as Dc) as Void {
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
        var groupWidth = timeWidth + 3 + secondsWidth;
        var startX = (dc.getWidth() - groupWidth) / 2;

        if (startX < 8) {
            startX = 8;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(startX, 68, timeFont, timeText, Graphics.TEXT_JUSTIFY_LEFT);
        _secondsX = startX + timeWidth + 3;
    }

    private function drawInstinctBottomData(dc as Dc) as Void {
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

        var stepsWidth = dc.getTextWidthInPixels(stepsText, stepsFont);
        var stepsGroupWidth = 15 + 4 + stepsWidth;
        var stepsX = 52 - (stepsGroupWidth / 2);
        var heartWidth = dc.getTextWidthInPixels(heartText, metricFont);
        var heartGroupWidth = 14 + 5 + heartWidth;
        var heartX = 126 - (heartGroupWidth / 2);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        drawInstinctFootprints(dc, stepsX, 132);
        dc.drawText(stepsX + 19, 128, stepsFont, stepsText, Graphics.TEXT_JUSTIFY_LEFT);
        drawInstinctHeart(dc, heartX + 7, 137);
        dc.drawText(heartX + 19, 128, metricFont, heartText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawInstinctBattery(dc as Dc) as Void {
        var battery = (System.getSystemStats().battery + 0.5).toNumber();
        if (battery < 0) {
            battery = 0;
        } else if (battery > 100) {
            battery = 100;
        }

        var batteryFont = _batteryFont;
        if (batteryFont == null) {
            return;
        }

        var batteryText = battery.toString() + "%";
        var subscreen = _subscreen;
        if (subscreen == null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawText(103, 8, batteryFont, batteryText, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var boxX = (subscreen.x == null) ? 113 : subscreen.x;
        var boxY = (subscreen.y == null) ? 0 : subscreen.y;
        var boxWidth = subscreen.width;
        var boxHeight = subscreen.height;

        // Fully repaint the physical subscreen on every full update so system
        // overlays cannot leave stale pixels behind.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(boxX, boxY, boxWidth, boxHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(boxX + (boxWidth / 2), boxY + 12,
                batteryFont, batteryText, Graphics.TEXT_JUSTIFY_CENTER);

        var barX = boxX + 10;
        var barY = boxY + 40;
        var barWidth = boxWidth - 20;
        var fillWidth = ((barWidth - 4) * battery) / 100;
        if ((battery > 0) && (fillWidth < 1)) {
            fillWidth = 1;
        }
        dc.setPenWidth(1);
        dc.drawRectangle(barX, barY, barWidth, 7);
        if (fillWidth > 0) {
            dc.fillRectangle(barX + 2, barY + 2, fillWidth, 3);
        }
    }

    private function drawInstinctHeart(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x - 3, y, 3);
        dc.fillCircle(x + 3, y, 3);
        dc.fillPolygon([
            [x - 6, y + 1],
            [x + 6, y + 1],
            [x, y + 8]
        ]);
    }

    private function drawInstinctFootprints(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x + 4, y + 4, 2);
        dc.fillPolygon([
            [x + 2, y + 6],
            [x + 6, y + 6],
            [x + 6, y + 12],
            [x + 4, y + 15],
            [x + 2, y + 13]
        ]);
        dc.fillCircle(x + 11, y + 2, 2);
        dc.fillPolygon([
            [x + 9, y + 4],
            [x + 13, y + 4],
            [x + 14, y + 9],
            [x + 12, y + 13],
            [x + 10, y + 11]
        ]);
    }

    public function onPartialUpdate(dc as Dc) as Void {
        if (!_partialUpdatesAllowed || !_secondsActive) {
            return;
        }

        // The clip follows the native seconds font selected for this resolution.
        // Filling it black first prevents stale segments and MIP ghost digits.
        dc.setClip(_secondsX, _secondsY, _secondsClipWidth, _secondsClipHeight);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(_secondsX, _secondsY, _secondsClipWidth, _secondsClipHeight);
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
        var rowGap = _layout.px(8);
        var rowX = (width - dayWidth - rowGap - dateWidth) / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(rowX, _layout.px(52), dayFont, weekday, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(rowX + dayWidth + rowGap, _layout.px(55), dateFont, dateText, Graphics.TEXT_JUSTIFY_LEFT);
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
        var secondsGap = _layout.px(5);
        var groupWidth = timeWidth + secondsGap + secondsWidth;
        var startX = (width - groupWidth) / 2;

        var minTimeX = _layout.px(12);
        if (startX < minTimeX) {
            startX = minTimeX;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(startX, _secondsY, timeFont, timeText, Graphics.TEXT_JUSTIFY_LEFT);
        _secondsX = startX + timeWidth + secondsGap;
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
        drawFootprints(dc, _layout.px(30), _layout.px(170));
        dc.drawText(_layout.px(54), _layout.px(170), stepsFont, stepsText, Graphics.TEXT_JUSTIFY_LEFT);
        drawHeart(dc, _layout.px(148), _layout.px(174));
        dc.drawText(_layout.px(162), _layout.px(170), metricFont, heartText, Graphics.TEXT_JUSTIFY_LEFT);
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
        dc.drawText(_secondsX, _secondsY, secondsFont, seconds, Graphics.TEXT_JUSTIFY_LEFT);
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

        dc.setPenWidth(_layout.px(5));
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.drawArc(width / 2, _layout.px(111), _layout.px(92), Graphics.ARC_CLOCKWISE, startAngle, endAngle);
        if (level > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawArc(width / 2, _layout.px(111), _layout.px(92), Graphics.ARC_CLOCKWISE, startAngle, activeEnd);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(width / 2, _layout.px(28), batteryFont, level.toString() + "%", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawHeart(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x - _layout.px(3), y, _layout.px(4));
        dc.fillCircle(x + _layout.px(3), y, _layout.px(4));
        dc.fillPolygon([
            [x - _layout.px(7), y + _layout.px(1)],
            [x + _layout.px(7), y + _layout.px(1)],
            [x, y + _layout.px(9)]
        ]);
    }

    private function drawFootprints(dc as Dc, x as Number, y as Number) as Void {
        dc.fillCircle(x + _layout.px(4), y + _layout.px(6), _layout.px(3));
        dc.fillPolygon([
            [x + _layout.px(2), y + _layout.px(8)],
            [x + _layout.px(7), y + _layout.px(8)],
            [x + _layout.px(7), y + _layout.px(14)],
            [x + _layout.px(5), y + _layout.px(18)],
            [x + _layout.px(2), y + _layout.px(16)],
            [x + _layout.px(1), y + _layout.px(12)]
        ]);
        dc.fillCircle(x + _layout.px(14), y + _layout.px(3), _layout.px(3));
        dc.fillPolygon([
            [x + _layout.px(11), y + _layout.px(5)],
            [x + _layout.px(16), y + _layout.px(5)],
            [x + _layout.px(17), y + _layout.px(10)],
            [x + _layout.px(16), y + _layout.px(14)],
            [x + _layout.px(13), y + _layout.px(16)],
            [x + _layout.px(11), y + _layout.px(11)]
        ]);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        _inSleep = false;
        reloadSettings();
        _secondsValue = System.getClockTime().sec;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        _inSleep = true;
        reloadSettings();
        // Active-only mode preserves the last rendered seconds. Always-running
        // mode leaves the lightweight seconds-only partial update enabled.
    }

    public function turnPartialUpdatesOff() as Void {
        _partialUpdatesAllowed = false;
        _secondsActive = false;
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
