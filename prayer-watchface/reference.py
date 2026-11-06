"""Reference Umm al-Qura prayer-time math. The Monkey C port in source/PrayerTimes.mc must match this."""
import math, datetime

def d2r(x): return math.radians(x)
def r2d(x): return math.degrees(x)
def fix(a, m):
    a = a - m * math.floor(a / m)
    return a

def julian(y, m, d):
    if m <= 2:
        y -= 1; m += 12
    A = y // 100
    B = 2 - A + A // 4
    return math.floor(365.25 * (y + 4716)) + math.floor(30.6001 * (m + 1)) + d + B - 1524.5

def sun(jd):
    D = jd - 2451545.0
    g = fix(357.529 + 0.98560028 * D, 360)
    q = fix(280.459 + 0.98564736 * D, 360)
    L = fix(q + 1.915 * math.sin(d2r(g)) + 0.020 * math.sin(d2r(2 * g)), 360)
    e = 23.439 - 0.00000036 * D
    RA = fix(r2d(math.atan2(math.cos(d2r(e)) * math.sin(d2r(L)), math.cos(d2r(L)))) / 15, 24)
    decl = r2d(math.asin(math.sin(d2r(e)) * math.sin(d2r(L))))
    eqt = q / 15 - RA
    return decl, eqt

def mid_day(jd, t):
    _, eqt = sun(jd + t)
    return fix(12 - eqt, 24)

def angle_time(jd, lat, angle, t, ccw):
    decl, _ = sun(jd + t)
    noon = mid_day(jd, t)
    c = (-math.sin(d2r(angle)) - math.sin(d2r(decl)) * math.sin(d2r(lat))) / (math.cos(d2r(decl)) * math.cos(d2r(lat)))
    if c > 1 or c < -1: return None
    T = r2d(math.acos(c)) / 15
    return noon - T if ccw else noon + T

def asr_time(jd, lat, t):
    decl, _ = sun(jd + t)
    ang = -r2d(math.atan(1 / (1 + math.tan(d2r(abs(lat - decl))))))
    return angle_time(jd, lat, ang, t, False)

def hijri_month(y, m, d):
    jd = int(julian(y, m, d) + 0.5)
    l = jd - 1948440 + 10632
    n = (l - 1) // 10631
    l = l - 10631 * n + 354
    j = ((10985 - l) // 5316) * ((50 * l) // 17719) + (l // 5670) * ((43 * l) // 15238)
    l = l - ((30 - j) // 15) * ((17719 * j) // 50) - (j // 16) * ((15238 * j) // 43) + 29
    return (24 * l) // 709

def times(y, m, d, lat, lng, tz):
    """Local decimal hours: fajr, sunrise, dhuhr, asr, maghrib, isha."""
    jd = julian(y, m, d) - lng / (15 * 24)
    adj = tz - lng / 15
    fajr = angle_time(jd, lat, 18.5, 5 / 24, True) + adj
    sunrise = angle_time(jd, lat, 0.833, 6 / 24, True) + adj
    dhuhr = mid_day(jd, 12 / 24) + adj
    asr = asr_time(jd, lat, 13 / 24) + adj
    maghrib = angle_time(jd, lat, 0.833, 18 / 24, False) + adj
    isha = maghrib + (2.0 if hijri_month(y, m, d) == 9 else 1.5)
    return fajr, sunrise, dhuhr, asr, maghrib, isha

def fmt(h):
    m = round(h * 60)
    return f"{m // 60:02d}:{m % 60:02d}"

if __name__ == "__main__":
    for (y, m, d) in [(2026, 11, 6), (2027, 2, 10), (2026, 6, 21)]:
        t = times(y, m, d, 21.4225, 39.8262, 3)
        print((y, m, d), "hijri month", hijri_month(y, m, d), [fmt(x) for x in t])
