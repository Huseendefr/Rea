# Prayer Times watch face (Garmin vivoactive 6)

Shows the next prayer, time left to the adhan, and time left to the iqama.
Umm al-Qura method, computed on the watch (no internet). Location comes from the
watch's last known GPS fix, falling back to Makkah until one exists.

Iqama delay: Fajr 25 min, Maghrib 10 min, others 20 min (`IQAMA_MIN` in `source/PrayerTimes.mc`).

## Build and install (on your computer)
1. Install the Connect IQ SDK (via SDK Manager) and the VS Code "Monkey C" extension.
2. Open this folder, run "Monkey C: Build for Device", pick `vivoactive6`.
3. Connect the watch by USB and copy `bin/*.prg` into `GARMIN/APPS/` on the watch.
4. On the watch: hold the watch face > change watch face > Prayer Times.

## Status
Untested on a device: this code was written without the Garmin SDK.
`reference.py` is a verified-by-inspection Python version of the math; the Monkey C port
must give the same times (`python3 reference.py`). Check the times against your mosque calendar.

Known limits: Latin letters only (no Arabic glyphs); Ramadan Isha (+120 min) uses an
approximate Hijri date; daylight-saving shifts are not handled (Saudi Arabia has none).
