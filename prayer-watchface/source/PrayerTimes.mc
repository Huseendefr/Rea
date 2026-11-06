import Toybox.Lang;
import Toybox.Math;

// Umm al-Qura prayer times. Must match reference.py exactly.
// Fajr 18.5 deg, standard Asr, Isha = Maghrib + 90 min (120 min in Ramadan).
module PrayerTimes {

    // Iqama delay in minutes after the adhan: Fajr, Dhuhr, Asr, Maghrib, Isha.
    const IQAMA_MIN = [25, 20, 20, 10, 20];

    function rad(x as Float) as Float { return x * Math.PI / 180.0; }
    function deg(x as Float) as Float { return x * 180.0 / Math.PI; }

    function fix(a as Float, m as Float) as Float {
        return a - m * Math.floor(a / m);
    }

    function julian(year as Number, month as Number, day as Number) as Float {
        var y = year;
        var m = month;
        if (m <= 2) { y -= 1; m += 12; }
        var a = y / 100;
        var b = 2 - a + a / 4;
        return Math.floor(365.25 * (y + 4716)).toFloat()
            + Math.floor(30.6001 * (m + 1)).toFloat() + day + b - 1524.5;
    }

    // Returns [declination, equation of time] in [degrees, hours].
    function sun(jd as Float) as Array<Float> {
        var d = jd - 2451545.0;
        var g = fix(357.529 + 0.98560028 * d, 360.0);
        var q = fix(280.459 + 0.98564736 * d, 360.0);
        var l = fix(q + 1.915 * Math.sin(rad(g)) + 0.020 * Math.sin(rad(2.0 * g)), 360.0);
        var e = 23.439 - 0.00000036 * d;
        var ra = fix(deg(Math.atan2(Math.cos(rad(e)) * Math.sin(rad(l)), Math.cos(rad(l)))) / 15.0, 24.0);
        var decl = deg(Math.asin(Math.sin(rad(e)) * Math.sin(rad(l))));
        return [decl, q / 15.0 - ra] as Array<Float>;
    }

    function midDay(jd as Float, t as Float) as Float {
        return fix(12.0 - sun(jd + t)[1], 24.0);
    }

    function angleTime(jd as Float, lat as Float, angle as Float, t as Float, ccw as Boolean) as Float {
        var decl = sun(jd + t)[0];
        var c = (-Math.sin(rad(angle)) - Math.sin(rad(decl)) * Math.sin(rad(lat)))
            / (Math.cos(rad(decl)) * Math.cos(rad(lat)));
        if (c > 1.0) { c = 1.0; }
        if (c < -1.0) { c = -1.0; }
        var tt = deg(Math.acos(c)) / 15.0;
        var noon = midDay(jd, t);
        return ccw ? noon - tt : noon + tt;
    }

    function asrTime(jd as Float, lat as Float, t as Float) as Float {
        var decl = sun(jd + t)[0];
        var diff = lat - decl;
        if (diff < 0.0) { diff = -diff; }
        var ang = -deg(Math.atan(1.0 / (1.0 + Math.tan(rad(diff)))));
        return angleTime(jd, lat, ang, t, false);
    }

    // Approximate Hijri month (1-12), tabular algorithm; off by a day at month edges.
    function hijriMonth(year as Number, month as Number, day as Number) as Number {
        var jd = (julian(year, month, day) + 0.5).toNumber();
        var l = jd - 1948440 + 10632;
        var n = (l - 1) / 10631;
        l = l - 10631 * n + 354;
        var j = ((10985 - l) / 5316) * ((50 * l) / 17719) + (l / 5670) * ((43 * l) / 15238);
        l = l - ((30 - j) / 15) * ((17719 * j) / 50) - (j / 16) * ((15238 * j) / 43) + 29;
        return (24 * l) / 709;
    }

    // Local decimal hours: [fajr, sunrise, dhuhr, asr, maghrib, isha].
    function compute(year as Number, month as Number, day as Number,
                     lat as Float, lng as Float, tz as Float) as Array<Float> {
        var jd = julian(year, month, day) - lng / 360.0;
        var adj = tz - lng / 15.0;
        var maghrib = angleTime(jd, lat, 0.833, 18.0 / 24.0, false) + adj;
        var ishaGap = (hijriMonth(year, month, day) == 9) ? 2.0 : 1.5;
        return [
            angleTime(jd, lat, 18.5, 5.0 / 24.0, true) + adj,
            angleTime(jd, lat, 0.833, 6.0 / 24.0, true) + adj,
            midDay(jd, 12.0 / 24.0) + adj,
            asrTime(jd, lat, 13.0 / 24.0) + adj,
            maghrib,
            maghrib + ishaGap
        ] as Array<Float>;
    }
}
