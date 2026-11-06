import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

const NAMES = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];
// Index of each prayer inside PrayerTimes.compute() output.
const SLOTS = [0, 2, 3, 4, 5];

class PrayerView extends WatchUi.WatchFace {
    var awake = true;
    var lat = 21.4225f;   // Makkah until a real fix arrives
    var lng = 39.8262f;
    var haveFix = false;
    var dayKey = -1;
    var today as Array<Float> = [] as Array<Float>;
    var tomorrowFajr = 0.0f;

    function initialize() {
        WatchFace.initialize();
    }

    function onEnterSleep() as Void { awake = false; WatchUi.requestUpdate(); }
    function onExitSleep() as Void { awake = true; WatchUi.requestUpdate(); }

    function loadLocation() as Void {
        var info = Position.getInfo();
        if (info != null && info.position != null && info.accuracy != Position.QUALITY_NOT_AVAILABLE) {
            var d = info.position.toDegrees();
            lat = d[0].toFloat();
            lng = d[1].toFloat();
            Storage.setValue("lat", lat);
            Storage.setValue("lng", lng);
            haveFix = true;
            return;
        }
        var sl = Storage.getValue("lat");
        var sg = Storage.getValue("lng");
        if (sl != null && sg != null) {
            lat = sl.toFloat();
            lng = sg.toFloat();
            haveFix = true;
        }
    }

    // Recompute today's and tomorrow's Fajr when the date changes.
    function refresh(now as Moment) as Void {
        var t = Gregorian.info(now, Time.FORMAT_SHORT);
        var key = t.year * 10000 + t.month * 100 + t.day;
        if (key == dayKey) { return; }
        dayKey = key;
        loadLocation();
        var tz = System.getClockTime().timeZoneOffset.toFloat() / 3600.0;
        today = PrayerTimes.compute(t.year, t.month, t.day, lat, lng, tz);
        var n = Gregorian.info(now.add(new Time.Duration(86400)), Time.FORMAT_SHORT);
        tomorrowFajr = PrayerTimes.compute(n.year, n.month, n.day, lat, lng, tz)[0] + 24.0;
    }

    function clock(h as Float) as String {
        var m = Math.round(h * 60.0).toNumber();
        m = m % 1440;
        return (m / 60).format("%02d") + ":" + (m % 60).format("%02d");
    }

    function countdown(hours as Float) as String {
        var s = Math.round(hours * 3600.0).toNumber();
        if (s < 0) { s = 0; }
        var h = s / 3600;
        var m = (s % 3600) / 60;
        var out = h.format("%d") + ":" + m.format("%02d");
        if (awake) { out += ":" + (s % 60).format("%02d"); }
        return out;
    }

    function onUpdate(dc as Dc) as Void {
        var now = Time.now();
        refresh(now);
        var c = Gregorian.info(now, Time.FORMAT_SHORT);
        var nowH = c.hour + c.min / 60.0 + c.sec / 3600.0;

        // Pick the prayer whose iqama window is open, else the next adhan.
        var idx = -1;
        var inWindow = false;
        for (var i = 0; i < 5; i++) {
            var adhan = today[SLOTS[i]];
            var iqama = adhan + PrayerTimes.IQAMA_MIN[i] / 60.0;
            if (nowH >= adhan && nowH < iqama) { idx = i; inWindow = true; break; }
            if (nowH < adhan) { idx = i; break; }
        }
        var adhanH = tomorrowFajr;
        if (idx == -1) { idx = 0; } else { adhanH = today[SLOTS[idx]]; }
        var iqamaH = adhanH + PrayerTimes.IQAMA_MIN[idx] / 60.0;

        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var head = c.hour.format("%02d") + ":" + c.min.format("%02d") + (haveFix ? "" : "  (Makkah)");
        dc.drawText(w / 2, h * 0.10, Graphics.FONT_SMALL, head, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var title = inWindow ? NAMES[idx] + " - adhan " + clock(adhanH) : "Next: " + NAMES[idx] + " " + clock(adhanH);
        dc.drawText(w / 2, h * 0.24, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (inWindow) {
            dc.drawText(w / 2, h * 0.36, Graphics.FONT_NUMBER_HOT, countdown(iqamaH - nowH), Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 0.60, Graphics.FONT_SMALL, "to iqama " + clock(iqamaH), Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(w / 2, h * 0.36, Graphics.FONT_NUMBER_HOT, countdown(adhanH - nowH), Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 0.60, Graphics.FONT_SMALL, "iqama in " + countdown(iqamaH - nowH), Graphics.TEXT_JUSTIFY_CENTER);
        }

        // All five times, the next one highlighted.
        var line1 = "";
        var line2 = "";
        for (var i = 0; i < 5; i++) {
            var s = NAMES[i].substring(0, 1) + " " + clock(today[SLOTS[i]]);
            if (i < 3) { line1 += s + "  "; } else { line2 += s + "  "; }
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.73, Graphics.FONT_XTINY, line1, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h * 0.83, Graphics.FONT_XTINY, line2, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
