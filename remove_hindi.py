import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'd:\bharatheeyamapp sample\lib\widgets\common.dart'
with open(path, 'r', encoding='utf-8-sig') as f:
    lines = f.readlines()

# Find boundaries
# Line 102 (0-indexed=101): "// ─── App Language / Locale (kn / hi)"
# Line 664 (0-indexed=663): "String tr(String text) => AppLocale.tr(text);"
# Everything from line 102 to 664 (inclusive) needs to be replaced

start_idx = None
end_idx = None

for i, line in enumerate(lines):
    if 'App Language / Locale' in line:
        start_idx = i
    if "String tr(String text) => AppLocale.tr(text);" in line:
        end_idx = i

if start_idx is None or end_idx is None:
    print(f"ERROR: start={start_idx}, end={end_idx}")
    sys.exit(1)

print(f"Replacing lines {start_idx+1} to {end_idx+1}")

# Build replacement
new_section = r"""// ─────────────────────────────────────────────
// App Language / Locale (Kannada only)
// ─────────────────────────────────────────────
class AppLocale {
  static final ValueNotifier<String> langNotifier = ValueNotifier('kn');
  static String get current => 'kn';
  static bool get isHindi => false;

  static void setLang(String lang) {
    langNotifier.value = 'kn';
  }

  static Future<void> loadLang() async {
    langNotifier.value = 'kn';
  }

  /// Get localized string by key (Kannada only)
  static String l(String key) {
    return _strings[key] ?? key;
  }

  static const Map<String, String> _strings = {
    'appName': '\u0cad\u0cbe\u0cb0\u0ca4\u0cc0\u0caf\u0cae\u0ccd',
    'home': '\u0cae\u0ca8\u0cc6', 'kundali': '\u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf', 'panchanga': '\u0caa\u0c82\u0c9a\u0cbe\u0c82\u0c97',
    'planets': '\u0c97\u0ccd\u0cb0\u0cb9\u0c97\u0cb3\u0cc1', 'appointment': '\u0c85\u0caa\u0cbe\u0caf\u0cbf\u0c82\u0c9f\u0ccd\u200c\u0cae\u0cc6\u0c82\u0c9f\u0ccd',
    'vedicClock': '\u0cb5\u0cc8\u0ca6\u0cbf\u0c95 \u0c97\u0ca1\u0cbf\u0caf\u0cbe\u0cb0', 'settings': '\u0cb8\u0cc6\u0c9f\u0ccd\u0c9f\u0cbf\u0c82\u0c97\u0ccd\u0cb8\u0ccd',
    'aboutUs': '\u0ca8\u0cae\u0ccd\u0cae \u0cac\u0c97\u0ccd\u0c97\u0cc6 / About Us',
    'themeSettings': '\u0ca5\u0cc0\u0cae\u0ccd \u0cb8\u0cc6\u0c9f\u0ccd\u0c9f\u0cbf\u0c82\u0c97\u0ccd\u0cb8\u0ccd',
    'chartStyle': '\u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf \u0cb6\u0cc8\u0cb2\u0cbf / Chart Style',
    'language': '\u0cad\u0cbe\u0cb7\u0cc6 / Language',
    'southIndian': '\u0ca6\u0c95\u0ccd\u0cb7\u0cbf\u0ca3 \u0cad\u0cbe\u0cb0\u0ca4', 'northIndian': '\u0c89\u0ca4\u0ccd\u0ca4\u0cb0 \u0cad\u0cbe\u0cb0\u0ca4',
    'googleAccount': 'Google \u0c96\u0cbe\u0ca4\u0cc6', 'premium': '\u0caa\u0ccd\u0cb0\u0cc0\u0cae\u0cbf\u0caf\u0c82 \u0c9a\u0c82\u0ca6\u0cbe\u0ca6\u0cbe\u0cb0\u0cbf\u0c95\u0cc6',
    'privacyPolicy': '\u0c97\u0ccc\u0caa\u0ccd\u0caf\u0ca4\u0cbe \u0ca8\u0cc0\u0ca4\u0cbf / Privacy Policy',
    'name': '\u0cb9\u0cc6\u0cb8\u0cb0\u0cc1', 'dob': '\u0c9c\u0ca8\u0ccd\u0cae \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95', 'time': '\u0c9c\u0ca8\u0ccd\u0cae \u0cb8\u0cae\u0caf',
    'place': '\u0c9c\u0ca8\u0ccd\u0cae \u0cb8\u0ccd\u0ca5\u0cb3', 'calculate': '\u0cb2\u0cc6\u0c95\u0ccd\u0c95 \u0cb9\u0cbe\u0c95\u0cbf',
    'selectDate': '\u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95 \u0c86\u0caf\u0ccd\u0c95\u0cc6', 'selectTime': '\u0cb8\u0cae\u0caf \u0c86\u0caf\u0ccd\u0c95\u0cc6',
    'chart': '\u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf', 'sphuta': '\u0cb8\u0ccd\u0cab\u0cc1\u0c9f', 'bhava': '\u0cad\u0cbe\u0cb5',
    'varga': '\u0cb5\u0cb0\u0ccd\u0c97', 'dasha': '\u0ca6\u0cb6\u0cbe', 'aroodha': '\u0c86\u0cb0\u0cc2\u0ca2',
    'ashtakavarga': '\u0c85\u0cb7\u0ccd\u0c9f\u0c95\u0cb5\u0cb0\u0ccd\u0c97', 'taranukoola': '\u0ca4\u0cbe\u0cb0\u0cbe\u0ca8\u0cc1\u0c95\u0cc2\u0cb2',
    'matchMaking': '\u0c97\u0cc1\u0ca3\u0cae\u0cbf\u0cb2\u0cbe\u0ca8', 'notes': '\u0c9f\u0cbf\u0caa\u0ccd\u0caa\u0ca3\u0cbf',
    'tithi': '\u0ca4\u0cbf\u0ca5\u0cbf', 'nakshatra': '\u0ca8\u0c95\u0ccd\u0cb7\u0ca4\u0ccd\u0cb0', 'yoga': '\u0caf\u0ccb\u0c97',
    'karana': '\u0c95\u0cb0\u0ca3', 'vara': '\u0cb5\u0cbe\u0cb0',
    'sunrise': '\u0cb8\u0cc2\u0cb0\u0ccd\u0caf\u0ccb\u0ca6\u0caf', 'sunset': '\u0cb8\u0cc2\u0cb0\u0ccd\u0caf\u0cbe\u0cb8\u0ccd\u0ca4',
    'rahuKala': '\u0cb0\u0cbe\u0cb9\u0cc1 \u0c95\u0cbe\u0cb2', 'gulikaKala': '\u0c97\u0cc1\u0cb3\u0cbf\u0c95 \u0c95\u0cbe\u0cb2',
    'yamaghantaKala': '\u0caf\u0cae\u0c98\u0c82\u0c9f \u0c95\u0cbe\u0cb2',
    'transits': '\u0c97\u0ccd\u0cb0\u0cb9 \u0cb8\u0c82\u0c9a\u0cbe\u0cb0', 'vakri': '\u0cb5\u0c95\u0ccd\u0cb0\u0cbf', 'asta': '\u0c85\u0cb8\u0ccd\u0ca4',
    'direct': '\u0ca8\u0cc7\u0cb0', 'retrograde': '\u0cb5\u0c95\u0ccd\u0cb0\u0cbf', 'combust': '\u0c85\u0cb8\u0ccd\u0ca4',
    'yes': '\u0cb9\u0ccc\u0ca6\u0cc1', 'no': '\u0c87\u0cb2\u0ccd\u0cb2', 'notApplicable': '\u0c85\u0ca8\u0ccd\u0cb5\u0caf\u0cbf\u0cb8\u0cc1\u0cb5\u0cc1\u0ca6\u0cbf\u0cb2\u0ccd\u0cb2',
    'booked': '\u0cac\u0cc1\u0c95\u0ccd \u0c86\u0c97\u0cbf\u0ca6\u0cc6', 'cancelled': '\u0cb0\u0ca6\u0ccd\u0ca6\u0cc1', 'completed': '\u0caa\u0cc2\u0cb0\u0ccd\u0ca3',
    'addNote': '\u0cb9\u0cca\u0cb8 \u0c9f\u0cbf\u0caa\u0ccd\u0caa\u0ca3\u0cbf \u0cb8\u0cc7\u0cb0\u0cbf\u0cb8\u0cbf...', 'noteHistory': '\u0c9f\u0cbf\u0caa\u0ccd\u0caa\u0ca3\u0cbf \u0c87\u0ca4\u0cbf\u0cb9\u0cbe\u0cb8',
    'noNotes': '\u0c87\u0ca8\u0ccd\u0ca8\u0cc2 \u0c9f\u0cbf\u0caa\u0ccd\u0caa\u0ca3\u0cbf\u0c97\u0cb3\u0cbf\u0cb2\u0ccd\u0cb2',
    'share': '\u0cb9\u0c82\u0c9a\u0cbf\u0c95\u0cca\u0cb3\u0ccd\u0cb3\u0cbf', 'delete': '\u0c85\u0cb3\u0cbf\u0cb8\u0cbf',
    'save': '\u0c89\u0cb3\u0cbf\u0cb8\u0cbf', 'cancel': '\u0cb0\u0ca6\u0ccd\u0ca6\u0cc1', 'confirm': '\u0ca6\u0cc3\u0ca2\u0caa\u0ca1\u0cbf\u0cb8\u0cbf',
    'clientId': '\u0c97\u0ccd\u0cb0\u0cbe\u0cb9\u0c95 ID', 'phone': '\u0cab\u0ccb\u0ca8\u0ccd',
    'selectPlace': '\u0cb8\u0ccd\u0ca5\u0cb3 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0cbe\u0ca1\u0cbf',
    'multiPlacesFound': '\u0c92\u0c82\u0ca6\u0cc7 \u0cb9\u0cc6\u0cb8\u0cb0\u0cbf\u0ca8 \u0cb9\u0cb2\u0cb5\u0cc1 \u0cb8\u0ccd\u0ca5\u0cb3\u0c97\u0cb3\u0cc1 \u0c95\u0c82\u0ca1\u0cc1\u0cac\u0c82\u0ca6\u0cbf\u0cb5\u0cc6:',
    'placeNotFound': '\u0cb8\u0ccd\u0ca5\u0cb3 \u0c95\u0c82\u0ca1\u0cc1\u0cac\u0c82\u0ca6\u0cbf\u0cb2\u0ccd\u0cb2.',
    'networkError': '\u0cb8\u0ccd\u0ca5\u0cb3 \u0cb9\u0cc1\u0ca1\u0cc1\u0c95 \u0cb8\u0cbe\u0ca7\u0ccd\u0caf\u0cb5\u0cbf\u0cb2\u0ccd\u0cb2. \u0c87\u0c82\u0c9f\u0cb0\u0ccd\u0ca8\u0cc6\u0c9f\u0ccd \u0cb8\u0c82\u0caa\u0cb0\u0ccd\u0c95/\u0cb8\u0ccd\u0ca5\u0cb3\u0ca6 \u0cb9\u0cc6\u0cb8\u0cb0\u0ca8\u0ccd\u0ca8\u0cc1 \u0caa\u0cb0\u0cc0\u0c95\u0ccd\u0cb7\u0cbf\u0cb8\u0cbf.',
    'lahiri': '\u0cb2\u0cbe\u0cb9\u0cbf\u0cb0\u0cbf', 'raman': '\u0cb0\u0cbe\u0cae\u0ca8\u0ccd', 'kp': '\u0c95\u0cc6.\u0caa\u0cbf',
    'trueRahu': '\u0ca8\u0cbf\u0c9c \u0cb0\u0cbe\u0cb9\u0cc1', 'meanRahu': '\u0cae\u0ca7\u0ccd\u0caf\u0cae \u0cb0\u0cbe\u0cb9\u0cc1',
    'unknown': '\u0c85\u0caa\u0cb0\u0cbf\u0c9a\u0cbf\u0ca4 \u0cb9\u0cc6\u0cb8\u0cb0\u0cc1 (Unknown)',
    'errorLabel': '\u0ca6\u0ccb\u0cb7',
    'date': '\u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95', 'timeLabel': '\u0cb8\u0cae\u0caf',
    'searchPlace': '\u0c8a\u0cb0\u0cc1 \u0cb9\u0cc1\u0ca1\u0cc1\u0c95\u0cbf',
    'lat': '\u0c85\u0c95\u0ccd\u0cb7\u0cbe\u0c82\u0cb6 (Lat)', 'lon': '\u0cb0\u0cc7\u0c96\u0cbe\u0c82\u0cb6 (Lon)', 'tzOffset': '\u0cb8\u0cae\u0caf \u0cb5\u0cb2\u0caf',
    'advancedSettings': '\u0c88 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0c97\u0cb3\u0cc1 \u0cac\u0ca6\u0cb2\u0cbe\u0caf\u0cbf\u0cb8\u0cac\u0cc7\u0ca1\u0cbf',
    'ayanamsa': '\u0c85\u0caf\u0ca8\u0cbe\u0c82\u0cb6', 'nodeType': '\u0ca8\u0ccb\u0ca1\u0ccd',
    'openSaved': '\u0ca4\u0cc6\u0cb0\u0cc6\u0caf\u0cbf\u0cb0\u0cbf', 'currentTime': '\u0caa\u0ccd\u0cb0\u0cb8\u0ccd\u0ca4\u0cc1\u0ca4', 'generate': '\u0cb0\u0c9a\u0cbf\u0cb8\u0cbf',
    'savedKundali': '\u0c89\u0cb3\u0cbf\u0cb8\u0cbf\u0ca6 \u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf (Appointments Merged)',
    'searchHint': '\u0cb9\u0cc6\u0cb8\u0cb0\u0cc1, \u0cb8\u0ccd\u0ca5\u0cb3, Client ID \u0c85\u0ca5\u0cb5\u0cbe \u0ca6\u0cbf\u0ca8 \u0cb9\u0cc1\u0ca1\u0cc1\u0c95\u0cbf...',
    'noSavedKundali': '\u0caf\u0cbe\u0cb5\u0cc1\u0ca6\u0cc7 \u0c9c\u0cbe\u0ca4\u0c95 \u0c89\u0cb3\u0cbf\u0cb8\u0cbf\u0cb2\u0ccd\u0cb2.',
    'noResults': '\u0caf\u0cbe\u0cb5\u0cc1\u0ca6\u0cc7 \u0cab\u0cb2\u0cbf\u0ca4\u0cbe\u0c82\u0cb6 \u0c95\u0c82\u0ca1\u0cc1\u0cac\u0c82\u0ca6\u0cbf\u0cb2\u0ccd\u0cb2.',
    'deleteConfirm': '\u0c85\u0cb3\u0cbf\u0cb8\u0cac\u0cc7\u0c95\u0cc7?',
    'deleteMsg': '\u0c9c\u0cbe\u0ca4\u0c95\u0cb5\u0ca8\u0ccd\u0ca8\u0cc1 \u0c85\u0cb3\u0cbf\u0cb8\u0cac\u0cc7\u0c95\u0cc7?',
    'noBtn': '\u0cac\u0cc7\u0ca1',
    'kundaliTitle': '\u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf',
    'webBlockedTitle': '\u0c87\u0c82\u0c9f\u0cb0\u0ccd\u0ca8\u0cc6\u0c9f\u0ccd \u0c85\u0c97\u0ca4\u0ccd\u0caf \u0cb8\u0c82\u0caa\u0cb0\u0ccd\u0c95 \u0c87\u0cb2\u0ccd\u0cb2',
    'webBlockedMsg': '\u0ca6\u0caf\u0cb5\u0cbf\u0c9f\u0ccd\u0c9f\u0cc1 \u0c87\u0c82\u0c9f\u0cb0\u0ccd\u0ca8\u0cc6\u0c9f\u0ccd\u0ca8\u0cb2\u0ccd\u0cb2\u0cbf \u0cb8\u0c82\u0caa\u0cb0\u0ccd\u0c95 \u0cb9\u0cca\u0c82\u0ca6\u0cbf\u0cb0\u0cbf \u0c88 \u0c85\u0caa\u0ccd\u0cb2\u0cbf\u0c95\u0cc7\u0cb6\u0ca8\u0ccd\u0ca8\u0ca8\u0ccd\u0ca8\u0cc1 \u0cac\u0cb3\u0cb8\u0cb2\u0cc1 \u0c87\u0c82\u0c9f\u0cb0\u0ccd\u0ca8\u0cc6\u0c9f\u0ccd \u0cac\u0cc7\u0c95\u0cc1.',
    'retryBtn': '\u0caa\u0cc1\u0ca8\u0c83\u0caa\u0ccd\u0cb0\u0caf\u0ca4\u0ccd\u0ca8\u0cbf\u0cb8\u0cbf',
  };

  /// Pass-through -- no translation
  static String tr(String text) => text;
}

/// Shorthand global function -- just returns text as-is
String tr(String text) => text;
"""

# Build new file
before = lines[:start_idx]  # lines 0 to 101
after = lines[end_idx + 1:]  # lines 665 onwards

new_content = ''.join(before) + new_section + ''.join(after)

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Done! Replaced lines {start_idx+1}-{end_idx+1} with minimal AppLocale. File now has no Hindi.")
