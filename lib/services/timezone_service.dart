import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// DST-aware timezone service using IANA timezone database.
/// Call [init] once at app startup. Then use [offsetForDate] to get
/// the correct UTC offset (including DST) for any city + date.

bool _initialized = false;

/// Initialize timezone database. Safe to call multiple times.
void initTimezones() {
  if (_initialized) return;
  tz_data.initializeTimeZones();
  _initialized = true;
}

/// Get DST-aware UTC offset (in hours, e.g. 5.5, -4.0) for a given
/// IANA timezone name and date.
double offsetForDate(String ianaName, DateTime date) {
  try {
    final loc = tz.getLocation(ianaName);
    final tzDate = tz.TZDateTime(loc, date.year, date.month, date.day, 12); // noon to avoid edge cases
    return tzDate.timeZoneOffset.inMinutes / 60.0;
  } catch (_) {
    return _fallbackOffset(ianaName);
  }
}

/// Map a country code + coordinates to an IANA timezone name.
/// Handles multi-zone countries (US, CA, AU, RU, BR, etc.) via longitude.
String getIanaTimezone(String countryCode, double lat, double lon) {
  // Single-zone countries (fast path)
  final single = _singleZoneCountries[countryCode];
  if (single != null) return single;

  // Multi-zone countries
  switch (countryCode) {
    case 'US':
      return _usTimezone(lon, lat);
    case 'CA':
      return _caTimezone(lon);
    case 'AU':
      return _auTimezone(lon, lat);
    case 'RU':
      return _ruTimezone(lon);
    case 'BR':
      return _brTimezone(lon);
    case 'MX':
      return _mxTimezone(lon);
    case 'ID':
      return _idTimezone(lon);
    case 'CN':
      return 'Asia/Shanghai'; // China uses single tz officially
    default:
      // Estimate from longitude
      return _estimateFromLon(lon);
  }
}

/// Get DST-aware offset for a place (by country code, coords, and birth date).
/// Returns UTC offset in hours (e.g. 5.5, -4.0).
double getDstAwareOffset(String countryCode, double lat, double lon, DateTime date) {
  initTimezones();
  final iana = getIanaTimezone(countryCode, lat, lon);
  return offsetForDate(iana, date);
}

// ──────────────────────────────────────────────────
// Single-zone country mapping
// ──────────────────────────────────────────────────

const Map<String, String> _singleZoneCountries = {
  'IN': 'Asia/Kolkata',
  'LK': 'Asia/Colombo',
  'NP': 'Asia/Kathmandu',
  'BD': 'Asia/Dhaka',
  'PK': 'Asia/Karachi',
  'MM': 'Asia/Yangon',
  'AF': 'Asia/Kabul',
  'IR': 'Asia/Tehran',
  'IQ': 'Asia/Baghdad',
  'AE': 'Asia/Dubai',
  'SA': 'Asia/Riyadh',
  'QA': 'Asia/Qatar',
  'KW': 'Asia/Kuwait',
  'OM': 'Asia/Muscat',
  'BH': 'Asia/Bahrain',
  'JO': 'Asia/Amman',
  'LB': 'Asia/Beirut',
  'IL': 'Asia/Jerusalem',
  'TR': 'Europe/Istanbul',
  'GE': 'Asia/Tbilisi',
  'AM': 'Asia/Yerevan',
  'AZ': 'Asia/Baku',
  'KZ': 'Asia/Almaty',
  'UZ': 'Asia/Tashkent',
  'KG': 'Asia/Bishkek',
  'TM': 'Asia/Ashgabat',
  'JP': 'Asia/Tokyo',
  'KR': 'Asia/Seoul',
  'TW': 'Asia/Taipei',
  'SG': 'Asia/Singapore',
  'MY': 'Asia/Kuala_Lumpur',
  'TH': 'Asia/Bangkok',
  'VN': 'Asia/Ho_Chi_Minh',
  'PH': 'Asia/Manila',
  'KH': 'Asia/Phnom_Penh',
  'LA': 'Asia/Vientiane',
  'MN': 'Asia/Ulaanbaatar',
  'BN': 'Asia/Brunei',
  'GB': 'Europe/London',
  'IE': 'Europe/Dublin',
  'IS': 'Atlantic/Reykjavik',
  'DE': 'Europe/Berlin',
  'FR': 'Europe/Paris',
  'IT': 'Europe/Rome',
  'ES': 'Europe/Madrid',
  'PT': 'Europe/Lisbon',
  'NL': 'Europe/Amsterdam',
  'BE': 'Europe/Brussels',
  'AT': 'Europe/Vienna',
  'CH': 'Europe/Zurich',
  'SE': 'Europe/Stockholm',
  'NO': 'Europe/Oslo',
  'DK': 'Europe/Copenhagen',
  'FI': 'Europe/Helsinki',
  'PL': 'Europe/Warsaw',
  'CZ': 'Europe/Prague',
  'SK': 'Europe/Bratislava',
  'HU': 'Europe/Budapest',
  'RO': 'Europe/Bucharest',
  'BG': 'Europe/Sofia',
  'GR': 'Europe/Athens',
  'HR': 'Europe/Zagreb',
  'RS': 'Europe/Belgrade',
  'BA': 'Europe/Sarajevo',
  'SI': 'Europe/Ljubljana',
  'ME': 'Europe/Podgorica',
  'MK': 'Europe/Skopje',
  'AL': 'Europe/Tirane',
  'XK': 'Europe/Belgrade',
  'UA': 'Europe/Kiev',
  'LT': 'Europe/Vilnius',
  'LV': 'Europe/Riga',
  'EE': 'Europe/Tallinn',
  'CY': 'Asia/Nicosia',
  'MT': 'Europe/Malta',
  'LU': 'Europe/Luxembourg',
  'MC': 'Europe/Monaco',
  'AD': 'Europe/Andorra',
  'SM': 'Europe/San_Marino',
  'VA': 'Europe/Vatican',
  'LI': 'Europe/Vaduz',
  'EG': 'Africa/Cairo',
  'ZA': 'Africa/Johannesburg',
  'NG': 'Africa/Lagos',
  'KE': 'Africa/Nairobi',
  'ET': 'Africa/Addis_Ababa',
  'GH': 'Africa/Accra',
  'TZ': 'Africa/Dar_es_Salaam',
  'UG': 'Africa/Kampala',
  'RW': 'Africa/Kigali',
  'DZ': 'Africa/Algiers',
  'MA': 'Africa/Casablanca',
  'TN': 'Africa/Tunis',
  'LY': 'Africa/Tripoli',
  'SD': 'Africa/Khartoum',
  'SN': 'Africa/Dakar',
  'CM': 'Africa/Douala',
  'CI': 'Africa/Abidjan',
  'MG': 'Africa/Antananarivo',
  'MZ': 'Africa/Maputo',
  'AO': 'Africa/Luanda',
  'ZW': 'Africa/Harare',
  'ZM': 'Africa/Lusaka',
  'BW': 'Africa/Gaborone',
  'CD': 'Africa/Kinshasa',
  'CG': 'Africa/Brazzaville',
  'BF': 'Africa/Ouagadougou',
  'ML': 'Africa/Bamako',
  'NE': 'Africa/Niamey',
  'TD': 'Africa/Ndjamena',
  'GM': 'Africa/Banjul',
  'AR': 'America/Argentina/Buenos_Aires',
  'CO': 'America/Bogota',
  'CL': 'America/Santiago',
  'PE': 'America/Lima',
  'VE': 'America/Caracas',
  'EC': 'America/Guayaquil',
  'UY': 'America/Montevideo',
  'CR': 'America/Costa_Rica',
  'PA': 'America/Panama',
  'GT': 'America/Guatemala',
  'SV': 'America/El_Salvador',
  'HN': 'America/Tegucigalpa',
  'NI': 'America/Managua',
  'BZ': 'America/Belize',
  'JM': 'America/Jamaica',
  'TT': 'America/Port_of_Spain',
  'CU': 'America/Havana',
  'DO': 'America/Santo_Domingo',
  'HT': 'America/Port-au-Prince',
  'PR': 'America/Puerto_Rico',
  'NZ': 'Pacific/Auckland',
  'FJ': 'Pacific/Fiji',
  'GL': 'America/Godthab',
};

// ──────────────────────────────────────────────────
// Multi-zone country helpers
// ──────────────────────────────────────────────────

String _usTimezone(double lon, double lat) {
  // Alaska
  if (lon < -130) return 'America/Anchorage';
  // Hawaii
  if (lat < 25 && lon < -150) return 'Pacific/Honolulu';
  // Pacific
  if (lon < -115) return 'America/Los_Angeles';
  // Mountain
  if (lon < -102) return 'America/Denver';
  // Central
  if (lon < -85) return 'America/Chicago';
  // Eastern
  return 'America/New_York';
}

String _caTimezone(double lon) {
  if (lon < -120) return 'America/Vancouver';
  if (lon < -102) return 'America/Edmonton';
  if (lon < -88) return 'America/Winnipeg';
  if (lon < -70) return 'America/Toronto';
  return 'America/Halifax';
}

String _auTimezone(double lon, double lat) {
  if (lon < 129) return 'Australia/Perth';
  if (lon < 138) return 'Australia/Darwin';
  if (lat < -30 && lon < 142) return 'Australia/Adelaide';
  if (lon < 148) return 'Australia/Brisbane';
  return 'Australia/Sydney';
}

String _ruTimezone(double lon) {
  if (lon < 40) return 'Europe/Moscow';
  if (lon < 55) return 'Asia/Yekaterinburg';
  if (lon < 70) return 'Asia/Omsk';
  if (lon < 85) return 'Asia/Krasnoyarsk';
  if (lon < 105) return 'Asia/Irkutsk';
  if (lon < 120) return 'Asia/Yakutsk';
  if (lon < 140) return 'Asia/Vladivostok';
  return 'Asia/Kamchatka';
}

String _brTimezone(double lon) {
  if (lon < -60) return 'America/Manaus';
  if (lon < -45) return 'America/Sao_Paulo';
  return 'America/Recife';
}

String _mxTimezone(double lon) {
  if (lon < -110) return 'America/Tijuana';
  if (lon < -104) return 'America/Mazatlan';
  return 'America/Mexico_City';
}

String _idTimezone(double lon) {
  if (lon < 115) return 'Asia/Jakarta';
  if (lon < 125) return 'Asia/Makassar';
  return 'Asia/Jayapura';
}

String _estimateFromLon(double lon) {
  // Rough estimate: try to find closest IANA zone
  final offsetHours = (lon / 15.0).round();
  // Map to common zones
  const offsets = <int, String>{
    -12: 'Etc/GMT+12', -11: 'Etc/GMT+11', -10: 'Pacific/Honolulu',
    -9: 'America/Anchorage', -8: 'America/Los_Angeles', -7: 'America/Denver',
    -6: 'America/Chicago', -5: 'America/New_York', -4: 'America/Halifax',
    -3: 'America/Sao_Paulo', -2: 'Etc/GMT+2', -1: 'Atlantic/Azores',
    0: 'Europe/London', 1: 'Europe/Paris', 2: 'Europe/Berlin',
    3: 'Europe/Moscow', 4: 'Asia/Dubai', 5: 'Asia/Karachi',
    6: 'Asia/Dhaka', 7: 'Asia/Bangkok', 8: 'Asia/Shanghai',
    9: 'Asia/Tokyo', 10: 'Australia/Sydney', 11: 'Pacific/Guadalcanal',
    12: 'Pacific/Auckland',
  };
  return offsets[offsetHours] ?? 'Etc/UTC';
}

double _fallbackOffset(String ianaName) {
  // Simple fallback offsets for when timezone package fails
  if (ianaName.startsWith('Asia/Kolkata')) return 5.5;
  if (ianaName.startsWith('Europe/London')) return 0;
  if (ianaName.startsWith('America/New_York')) return -5;
  if (ianaName.startsWith('America/Los_Angeles')) return -8;
  return 0;
}
