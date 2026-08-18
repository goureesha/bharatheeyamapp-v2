import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/strings.dart';
import '../constants/places.dart';
import '../services/timezone_service.dart';
import '../widgets/common.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/dasha_widget.dart';
import '../core/match_making.dart';
import '../core/calculator.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/client_service.dart';
import '../services/match_pdf_service.dart';
import '../services/pdf_theme.dart';
import '../core/ephemeris.dart';
import 'package:sweph/sweph.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/date_time_input.dart';

class MatchMakingTab extends StatefulWidget {
  const MatchMakingTab({super.key});

  @override
  State<MatchMakingTab> createState() => _MatchMakingTabState();
}

class _MatchPerson {
  final String name;
  final DateTime dob;
  final int hour, minute;
  final String ampm;
  final String place;
  final double lat, lon, tz;
  final KundaliResult result;

  _MatchPerson({
    required this.name, required this.dob,
    required this.hour, required this.minute, required this.ampm,
    required this.place, required this.lat, required this.lon, required this.tz,
    required this.result,
  });
}

class _MatchMakingTabState extends State<MatchMakingTab> with TickerProviderStateMixin {
  // Bride input
  final _bNameCtrl = TextEditingController();
  final _bPlaceCtrl = TextEditingController();
  final _bLatCtrl = TextEditingController(text: '14.98');
  final _bLonCtrl = TextEditingController(text: '74.73');
  final _bTzCtrl = TextEditingController(text: '+5.5');
  DateTime _bDob = DateTime(2000, 1, 1);
  int _bHour = 6, _bMinute = 0;
  String _bAmpm = 'AM';
  bool _bGeoLoading = false;
  String _bGeoStatus = '';

  // Groom input
  final _gNameCtrl = TextEditingController();
  final _gPlaceCtrl = TextEditingController();
  final _gLatCtrl = TextEditingController(text: '14.98');
  final _gLonCtrl = TextEditingController(text: '74.73');
  final _gTzCtrl = TextEditingController(text: '+5.5');
  DateTime _gDob = DateTime(2000, 1, 1);
  int _gHour = 6, _gMinute = 0;
  String _gAmpm = 'AM';
  bool _gGeoLoading = false;
  String _gGeoStatus = '';

  bool _loading = false;
  KundaliResult? _brideResult;
  KundaliResult? _groomResult;
  Map<String, dynamic>? _fullResult;
  int _kootaMode = 0; // 0 = Ashta Koota, 1 = Dvadasha Koota

  // Multi-person lists
  final List<_MatchPerson> _varaList = [];
  final List<_MatchPerson> _vadhuList = [];
  int _activeVaraIdx = 0;
  int _activeVadhuIdx = 0;

  // Quick Koota tab state
  int _qBrideRashi = 0;
  int _qBrideNak = 0;
  int _qGroomRashi = 0;
  int _qGroomNak = 0;
  Map<String, dynamic>? _qResult;
  List<Map<String, dynamic>> _guruTransits = [];

  // ── Namaakshara (Letter-based) tab state ──
  String _nBrideInput = '';
  String _nGroomInput = '';
  int? _nBrideNak;
  int? _nBridePada;
  int? _nGroomNak;
  int? _nGroomPada;
  Map<String, dynamic>? _nResult;
  List<Map<String, dynamic>> _nGuruTransits = [];

  // ── PDF Jyotishi details (persisted) ──
  final _mJyotishiNameCtrl = TextEditingController();
  final _mJyotishiAddressCtrl = TextEditingController();
  final _mJyotishiPhoneCtrl = TextEditingController();
  final _mInvocationCtrl = TextEditingController(text: 'ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ');
  String _mSelectedThemeId = 'traditional';

  // Nakshatra pada syllables (27 nakshatras × 4 padas each)
  static const List<List<String>> _nakSyllables = [
    ['ಚು', 'ಚೇ', 'ಚೋ', 'ಲಾ'],       // 0 Ashwini
    ['ಲೀ', 'ಲೂ', 'ಲೇ', 'ಲೋ'],       // 1 Bharani
    ['ಅ', 'ಈ', 'ಉ', 'ಏ'],           // 2 Krittika
    ['ಓ', 'ವಾ', 'ವೀ', 'ವೂ'],       // 3 Rohini
    ['ವೇ', 'ವೋ', 'ಕಾ', 'ಕೀ'],       // 4 Mrigashira
    ['ಕೂ', 'ಘ', 'ಙ', 'ಛ'],           // 5 Ardra
    ['ಕೇ', 'ಕೋ', 'ಹಾ', 'ಹೀ'],       // 6 Punarvasu
    ['ಹೂ', 'ಹೇ', 'ಹೋ', 'ಡಾ'],       // 7 Pushya
    ['ಡೀ', 'ಡೂ', 'ಡೇ', 'ಡೋ'],       // 8 Ashlesha
    ['ಮಾ', 'ಮೀ', 'ಮೂ', 'ಮೇ'],       // 9 Magha
    ['ಮೋ', 'ಟಾ', 'ಟೀ', 'ಟೂ'],       // 10 Purva Phalguni
    ['ಟೇ', 'ಟೋ', 'ಪಾ', 'ಪೀ'],       // 11 Uttara Phalguni
    ['ಪೂ', 'ಷ', 'ಣ', 'ಠ'],           // 12 Hasta
    ['ಪೇ', 'ಪೋ', 'ರಾ', 'ರೀ'],       // 13 Chitra
    ['ರೂ', 'ರೇ', 'ರೋ', 'ತಾ'],       // 14 Swati
    ['ತೀ', 'ತೂ', 'ತೇ', 'ತೋ'],       // 15 Vishakha
    ['ನಾ', 'ನೀ', 'ನೂ', 'ನೇ'],       // 16 Anuradha
    ['ನೋ', 'ಯಾ', 'ಯೀ', 'ಯೂ'],       // 17 Jyeshtha
    ['ಯೇ', 'ಯೋ', 'ಭಾ', 'ಭೀ'],       // 18 Moola
    ['ಭೂ', 'ಧಾ', 'ಫಾ', 'ಢಾ'],       // 19 Purva Ashadha
    ['ಭೇ', 'ಭೋ', 'ಜಾ', 'ಜೀ'],       // 20 Uttara Ashadha
    ['ಖೀ', 'ಖೂ', 'ಖೇ', 'ಖೋ'],       // 21 Shravana
    ['ಗಾ', 'ಗೀ', 'ಗೂ', 'ಗೇ'],       // 22 Dhanishtha
    ['ಗೋ', 'ಸಾ', 'ಸೀ', 'ಸೂ'],       // 23 Shatabhisha
    ['ಸೇ', 'ಸೋ', 'ದಾ', 'ದೀ'],       // 24 Purva Bhadrapada
    ['ದೂ', 'ಥ', 'ಝ', 'ಞ'],           // 25 Uttara Bhadrapada
    ['ದೇ', 'ದೋ', 'ಚಾ', 'ಚೀ'],       // 26 Revati
  ];

  /// Find matching syllables for a given input string
  List<Map<String, dynamic>> _findMatchingSyllables(String input) {
    if (input.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    final lower = input.toLowerCase();
    for (int n = 0; n < 27; n++) {
      for (int p = 0; p < 4; p++) {
        final syl = _nakSyllables[n][p];
        if (syl.startsWith(lower) || lower.startsWith(syl)) {
          final rashiIdx = (n * 4 + p) ~/ 9;
          results.add({'nakIdx': n, 'padaIdx': p, 'syllable': syl, 'rashiIdx': rashiIdx});
        }
      }
    }
    return results;
  }

  /// Get rashi index from nakshatra + pada
  int _rashiFromNakPada(int nakIdx, int padaIdx) => (nakIdx * 4 + padaIdx) ~/ 9;

  /// Show a popup with all 108 syllables in a grid for tapping
  void _showSyllablePicker({required bool isBride}) {
    final Color accentColor = isBride ? kOrange : kTeal;
    final int? selectedNak = isBride ? _nBrideNak : _nGroomNak;
    final int? selectedPada = isBride ? _nBridePada : _nGroomPada;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1218),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) {
            return Column(children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Icon(isBride ? Icons.female : Icons.male, color: accentColor, size: 22),
                  const SizedBox(width: 8),
                  Text(isBride ? 'ವಧು ನಾಮಾಕ್ಷರ ಆಯ್ಕೆ' : 'ವರ ನಾಮಾಕ್ಷರ ಆಯ್ಕೆ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accentColor)),
                ]),
              ),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: 27,
                  itemBuilder: (_, nakIdx) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: kCard, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBorder.withOpacity(0.5)),
                      ),
                      child: Row(children: [
                        // Nakshatra name label
                        Container(
                          width: 90,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.06),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                          ),
                          child: Text(trAll(knNak[nakIdx]),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        // 4 pada syllable buttons
                        ...List.generate(4, (padaIdx) {
                          final syl = _nakSyllables[nakIdx][padaIdx];
                          final isSelected = selectedNak == nakIdx && selectedPada == padaIdx;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isBride) {
                                    _nBrideNak = nakIdx; _nBridePada = padaIdx;
                                    _nBrideInput = syl; _nResult = null;
                                  } else {
                                    _nGroomNak = nakIdx; _nGroomPada = padaIdx;
                                    _nGroomInput = syl; _nResult = null;
                                  }
                                });
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? accentColor : Colors.transparent,
                                  border: Border(left: BorderSide(color: kBorder.withOpacity(0.3))),
                                ),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text(syl, style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w900,
                                    color: isSelected ? Colors.white : kText)),
                                  Text('ಪಾದ ${padaIdx + 1}', style: TextStyle(
                                    fontSize: 8, color: isSelected ? Colors.white70 : kMuted)),
                                ]),
                              ),
                            ),
                          );
                        }),
                      ]),
                    );
                  },
                ),
              ),
            ]);
          },
        );
      },
    );
  }

  void _calculateNamaaksharaKoota() {
    if (_nBrideNak == null || _nGroomNak == null) return;
    final bRashi = _rashiFromNakPada(_nBrideNak!, _nBridePada ?? 0);
    final gRashi = _rashiFromNakPada(_nGroomNak!, _nGroomPada ?? 0);
    final ashta = MatchMakingLogic.calculateCompatibility(bRashi, _nBrideNak!, gRashi, _nGroomNak!);
    final dvadasha = MatchMakingLogic.calculateDvadashaKoota(bRashi, _nBrideNak!, gRashi, _nGroomNak!);
    final transits = _computeGuruTransits(bRashi, gRashi);
    setState(() {
      _nResult = {'ashtaKoota': ashta, 'dvadashaKoota': dvadasha, 'brideRashi': bRashi, 'groomRashi': gRashi};
      _nGuruTransits = transits;
    });
  }

  List<int> _naksForRashi(int rashiIdx) {
    final naks = <int>[];
    for (int n = 0; n < 27; n++) {
      for (int p = 0; p < 4; p++) {
        if ((n * 4 + p) ~/ 9 == rashiIdx) {
          naks.add(n);
          break;
        }
      }
    }
    return naks;
  }

  Future<void> _calculate() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      final bLat = double.tryParse(_bLatCtrl.text) ?? 14.98;
      final bLon = double.tryParse(_bLonCtrl.text) ?? 74.73;
      final bTz = double.tryParse(_bTzCtrl.text) ?? 5.5;
      int bH24 = _bHour + (_bAmpm == 'PM' && _bHour != 12 ? 12 : 0);
      if (_bAmpm == 'AM' && _bHour == 12) bH24 = 0;

      final gLat = double.tryParse(_gLatCtrl.text) ?? 14.98;
      final gLon = double.tryParse(_gLonCtrl.text) ?? 74.73;
      final gTz = double.tryParse(_gTzCtrl.text) ?? 5.5;
      int gH24 = _gHour + (_gAmpm == 'PM' && _gHour != 12 ? 12 : 0);
      if (_gAmpm == 'AM' && _gHour == 12) gH24 = 0;

      final brideR = await AstroCalculator.calculate(
        year: _bDob.year, month: _bDob.month, day: _bDob.day,
        hourUtcOffset: bTz, hour24: bH24 + _bMinute / 60.0,
        lat: bLat, lon: bLon, ayanamsaMode: 'lahiri', trueNode: true,
      );
      final groomR = await AstroCalculator.calculate(
        year: _gDob.year, month: _gDob.month, day: _gDob.day,
        hourUtcOffset: gTz, hour24: gH24 + _gMinute / 60.0,
        lat: gLat, lon: gLon, ayanamsaMode: 'lahiri', trueNode: true,
      );

      if (brideR == null || groomR == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.l('calcFailed')), backgroundColor: Colors.red),
          );
        }
        setState(() => _loading = false);
        return;
      }

      // Extract planet rashi indices
      Map<String, int> extractRashis(KundaliResult r) {
        final m = <String, int>{};
        for (final e in r.planets.entries) {
          m[e.key] = e.value.rashiIndex;
        }
        return m;
      }

      // Extract bhava house (1-12) for each planet based on bhava cusps
      // refPlanet: if set, shifts madhyas so that planet becomes 1st house (like kundali chart)
      Map<String, int> extractBhavaHouses(KundaliResult r, {String? refPlanet}) {
        final m = <String, int>{};
        final lagnaLong = r.planets['ಲಗ್ನ']?.longitude ?? 0;
        List<double> madhyas;
        if (refPlanet != null && r.planets.containsKey(refPlanet)) {
          final refLon = r.planets[refPlanet]!.longitude;
          final offset = (refLon - lagnaLong + 360.0) % 360.0;
          madhyas = List.generate(12, (i) => (r.bhavas[i] + offset) % 360.0);
        } else {
          madhyas = r.bhavas;
        }
        // Compute bhava sandhis (boundaries) = midpoint between consecutive madhyas
        final sandhis = List<double>.filled(12, 0.0);
        for (int i = 0; i < 12; i++) {
          final m1 = madhyas[i];
          final m2 = madhyas[(i + 1) % 12];
          final diff = ((m2 - m1) % 360 + 360) % 360;
          sandhis[i] = (m1 + diff / 2.0) % 360.0;
        }
        for (final e in r.planets.entries) {
          if (e.key == 'ಲಗ್ನ') continue; // skip lagna
          final pLon = e.value.longitude;
          int house = 1;
          for (int i = 0; i < 12; i++) {
            final start = sandhis[(i + 11) % 12]; // sandhi before this house
            final end = sandhis[i];               // sandhi after this house
            if (start < end) {
              if (pLon >= start && pLon < end) { house = i + 1; break; }
            } else {
              if (pLon >= start || pLon < end) { house = i + 1; break; }
            }
          }
          m[e.key] = house;
        }
        return m;
      }

      final bRashis = extractRashis(brideR);
      final gRashis = extractRashis(groomR);
      // Bhava houses from 3 references (Lagna, Chandra, Shukra)
      final bBhavaLagna = extractBhavaHouses(brideR);
      final gBhavaLagna = extractBhavaHouses(groomR);
      final bBhavaChandra = extractBhavaHouses(brideR, refPlanet: 'ಚಂದ್ರ');
      final gBhavaChandra = extractBhavaHouses(groomR, refPlanet: 'ಚಂದ್ರ');
      final bBhavaShukra = extractBhavaHouses(brideR, refPlanet: 'ಶುಕ್ರ');
      final gBhavaShukra = extractBhavaHouses(groomR, refPlanet: 'ಶುಕ್ರ');
      final bLagnaRashi = brideR.planets['ಲಗ್ನ']?.rashiIndex ?? 0;
      final gLagnaRashi = groomR.planets['ಲಗ್ನ']?.rashiIndex ?? 0;
      final bMoonRashi = brideR.planets['ಚಂದ್ರ']?.rashiIndex ?? 0;
      final gMoonRashi = groomR.planets['ಚಂದ್ರ']?.rashiIndex ?? 0;
      final bNakIdx = brideR.panchang.nakshatraIndex;
      final gNakIdx = groomR.panchang.nakshatraIndex;

      // Navamsha rashis
      final bNavLagna = MatchMakingLogic.navamshaRashi(brideR.planets['ಲಗ್ನ']?.longitude ?? 0);
      final bNavMoon = MatchMakingLogic.navamshaRashi(brideR.planets['ಚಂದ್ರ']?.longitude ?? 0);
      final gNavLagna = MatchMakingLogic.navamshaRashi(groomR.planets['ಲಗ್ನ']?.longitude ?? 0);
      final gNavMoon = MatchMakingLogic.navamshaRashi(groomR.planets['ಚಂದ್ರ']?.longitude ?? 0);

      final fullResult = MatchMakingLogic.calculateFullCompatibility(
        brideNakIdx: bNakIdx, brideMoonRashi: bMoonRashi, brideLagnaRashi: bLagnaRashi, bridePlanetRashis: bRashis,
        brideNavLagnaRashi: bNavLagna, brideNavMoonRashi: bNavMoon,
        groomNakIdx: gNakIdx, groomMoonRashi: gMoonRashi, groomLagnaRashi: gLagnaRashi, groomPlanetRashis: gRashis,
        groomNavLagnaRashi: gNavLagna, groomNavMoonRashi: gNavMoon,
        brideBhavaHouses: bBhavaLagna, groomBhavaHouses: gBhavaLagna,
        brideBhavaFromChandra: bBhavaChandra, groomBhavaFromChandra: gBhavaChandra,
        brideBhavaFromShukra: bBhavaShukra, groomBhavaFromShukra: gBhavaShukra,
      );

      setState(() {
        _brideResult = brideR;
        _groomResult = groomR;
        _fullResult = fullResult;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocale.l('calcFailed')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _addPerson({required bool isVara}) async {
    final nameCtrl = isVara ? _gNameCtrl : _bNameCtrl;
    final placeCtrl = isVara ? _gPlaceCtrl : _bPlaceCtrl;
    final latCtrl = isVara ? _gLatCtrl : _bLatCtrl;
    final lonCtrl = isVara ? _gLonCtrl : _bLonCtrl;
    final tzCtrl = isVara ? _gTzCtrl : _bTzCtrl;
    final dob = isVara ? _gDob : _bDob;
    final hour = isVara ? _gHour : _bHour;
    final minute = isVara ? _gMinute : _bMinute;
    final ampm = isVara ? _gAmpm : _bAmpm;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.l('enterName')), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final lat = double.tryParse(latCtrl.text) ?? 14.98;
      final lon = double.tryParse(lonCtrl.text) ?? 74.73;
      final tz = double.tryParse(tzCtrl.text) ?? 5.5;
      int h24 = hour + (ampm == 'PM' && hour != 12 ? 12 : 0);
      if (ampm == 'AM' && hour == 12) h24 = 0;

      final result = await AstroCalculator.calculate(
        year: dob.year, month: dob.month, day: dob.day,
        hourUtcOffset: tz, hour24: h24 + minute / 60.0,
        lat: lat, lon: lon, ayanamsaMode: 'lahiri', trueNode: true,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.l('calcFailed')), backgroundColor: Colors.red),
          );
        }
        setState(() => _loading = false);
        return;
      }

      final entry = _MatchPerson(
        name: name, dob: dob, hour: hour, minute: minute, ampm: ampm,
        place: placeCtrl.text, lat: lat, lon: lon, tz: tz, result: result,
      );

      setState(() {
        if (isVara) {
          _varaList.add(entry);
          _activeVaraIdx = _varaList.length - 1;
        } else {
          _vadhuList.add(entry);
          _activeVadhuIdx = _vadhuList.length - 1;
        }
        // Clear input fields for next entry
        nameCtrl.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  void _recalculateMatch() {
    if (_varaList.isEmpty || _vadhuList.isEmpty) return;
    if (_activeVaraIdx >= _varaList.length) _activeVaraIdx = 0;
    if (_activeVadhuIdx >= _vadhuList.length) _activeVadhuIdx = 0;

    final groomR = _varaList[_activeVaraIdx].result;
    final brideR = _vadhuList[_activeVadhuIdx].result;

    Map<String, int> extractRashis(KundaliResult r) {
      final m = <String, int>{};
      for (final e in r.planets.entries) m[e.key] = e.value.rashiIndex;
      return m;
    }

    Map<String, int> extractBhavaHouses(KundaliResult r, {String? refPlanet}) {
      final m = <String, int>{};
      final lagnaLong = r.planets['ಲಗ್ನ']?.longitude ?? 0;
      List<double> madhyas;
      if (refPlanet != null && r.planets.containsKey(refPlanet)) {
        final refLon = r.planets[refPlanet]!.longitude;
        final offset = (refLon - lagnaLong + 360.0) % 360.0;
        madhyas = List.generate(12, (i) => (r.bhavas[i] + offset) % 360.0);
      } else {
        madhyas = r.bhavas;
      }
      final sandhis = List<double>.filled(12, 0.0);
      for (int i = 0; i < 12; i++) {
        final m1 = madhyas[i];
        final m2 = madhyas[(i + 1) % 12];
        final diff = ((m2 - m1) % 360 + 360) % 360;
        sandhis[i] = (m1 + diff / 2.0) % 360.0;
      }
      for (final e in r.planets.entries) {
        if (e.key == 'ಲಗ್ನ') continue;
        final pLon = e.value.longitude;
        int house = 1;
        for (int i = 0; i < 12; i++) {
          final start = sandhis[(i + 11) % 12];
          final end = sandhis[i];
          if (start < end) {
            if (pLon >= start && pLon < end) { house = i + 1; break; }
          } else {
            if (pLon >= start || pLon < end) { house = i + 1; break; }
          }
        }
        m[e.key] = house;
      }
      return m;
    }

    final bRashis = extractRashis(brideR);
    final gRashis = extractRashis(groomR);
    final bBhavaLagna = extractBhavaHouses(brideR);
    final gBhavaLagna = extractBhavaHouses(groomR);
    final bBhavaChandra = extractBhavaHouses(brideR, refPlanet: 'ಚಂದ್ರ');
    final gBhavaChandra = extractBhavaHouses(groomR, refPlanet: 'ಚಂದ್ರ');
    final bBhavaShukra = extractBhavaHouses(brideR, refPlanet: 'ಶುಕ್ರ');
    final gBhavaShukra = extractBhavaHouses(groomR, refPlanet: 'ಶುಕ್ರ');
    final bLagnaRashi = brideR.planets['ಲಗ್ನ']?.rashiIndex ?? 0;
    final gLagnaRashi = groomR.planets['ಲಗ್ನ']?.rashiIndex ?? 0;
    final bMoonRashi = brideR.planets['ಚಂದ್ರ']?.rashiIndex ?? 0;
    final gMoonRashi = groomR.planets['ಚಂದ್ರ']?.rashiIndex ?? 0;
    final bNakIdx = brideR.panchang.nakshatraIndex;
    final gNakIdx = groomR.panchang.nakshatraIndex;

    final bNavLagna = MatchMakingLogic.navamshaRashi(brideR.planets['ಲಗ್ನ']?.longitude ?? 0);
    final bNavMoon = MatchMakingLogic.navamshaRashi(brideR.planets['ಚಂದ್ರ']?.longitude ?? 0);
    final gNavLagna = MatchMakingLogic.navamshaRashi(groomR.planets['ಲಗ್ನ']?.longitude ?? 0);
    final gNavMoon = MatchMakingLogic.navamshaRashi(groomR.planets['ಚಂದ್ರ']?.longitude ?? 0);

    final fullResult = MatchMakingLogic.calculateFullCompatibility(
      brideNakIdx: bNakIdx, brideMoonRashi: bMoonRashi, brideLagnaRashi: bLagnaRashi, bridePlanetRashis: bRashis,
      brideNavLagnaRashi: bNavLagna, brideNavMoonRashi: bNavMoon,
      groomNakIdx: gNakIdx, groomMoonRashi: gMoonRashi, groomLagnaRashi: gLagnaRashi, groomPlanetRashis: gRashis,
      groomNavLagnaRashi: gNavLagna, groomNavMoonRashi: gNavMoon,
      brideBhavaHouses: bBhavaLagna, groomBhavaHouses: gBhavaLagna,
      brideBhavaFromChandra: bBhavaChandra, groomBhavaFromChandra: gBhavaChandra,
      brideBhavaFromShukra: bBhavaShukra, groomBhavaFromShukra: gBhavaShukra,
    );

    setState(() {
      _groomResult = groomR;
      _brideResult = brideR;
      _fullResult = fullResult;
    });
  }

  Widget _buildPersonChips({required bool isVara, required Color color}) {
    final list = isVara ? _varaList : _vadhuList;
    final activeIdx = isVara ? _activeVaraIdx : _activeVadhuIdx;
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: List.generate(list.length, (i) {
          final isActive = i == activeIdx;
          return InputChip(
            label: Text(list[i].name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? Colors.white : kText)),
            selected: isActive,
            selectedColor: color,
            backgroundColor: kCard,
            side: BorderSide(color: isActive ? color : kBorder),
            onSelected: (_) => setState(() {
              if (isVara) _activeVaraIdx = i; else _activeVadhuIdx = i;
              _recalculateMatch();
            }),
            onDeleted: () => setState(() {
              if (isVara) {
                _varaList.removeAt(i);
                if (_activeVaraIdx >= _varaList.length) _activeVaraIdx = _varaList.isEmpty ? 0 : _varaList.length - 1;
              } else {
                _vadhuList.removeAt(i);
                if (_activeVadhuIdx >= _vadhuList.length) _activeVadhuIdx = _vadhuList.isEmpty ? 0 : _vadhuList.length - 1;
              }
              if (_varaList.isNotEmpty && _vadhuList.isNotEmpty) _recalculateMatch();
              else setState(() { _fullResult = null; _brideResult = null; _groomResult = null; });
            }),
            deleteIconColor: isActive ? Colors.white70 : kMuted,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        }),
      ),
    );
  }

  void _calculateQuickKoota() {
    final ashta = MatchMakingLogic.calculateCompatibility(_qBrideRashi, _qBrideNak, _qGroomRashi, _qGroomNak);
    final dvadasha = MatchMakingLogic.calculateDvadashaKoota(_qBrideRashi, _qBrideNak, _qGroomRashi, _qGroomNak);
    
    // Calculate Guru Bala transit windows for both bride and groom
    final transits = _computeGuruTransits(_qBrideRashi, _qGroomRashi);
    
    setState(() {
      _qResult = {'ashtaKoota': ashta, 'dvadashaKoota': dvadasha};
      _guruTransits = transits;
    });
  }

  List<Map<String, dynamic>> _computeGuruTransits(int brideRashi, int groomRashi) {
    final List<Map<String, dynamic>> windows = [];
    final now = DateTime.now();
    
    // Scan monthly for ~13 years (full Jupiter cycle + buffer)
    int prevJupRashi = -1;
    DateTime? periodStart;
    bool prevBrideBala = false;
    bool prevGroomBala = false;
    
    for (int m = 0; m <= 24; m++) {
      final dt = DateTime(now.year, now.month + m, 15);
      try {
        final jd = Sweph.swe_julday(dt.year, dt.month, dt.day, 12.0, CalendarType.SE_GREG_CAL);
        Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
        final ayn = Sweph.swe_get_ayanamsa(jd);
        final positions = Ephemeris.calcAll(jd, 'lahiri', true);
        final jupLon = positions['Jupiter']?[0] ?? 0.0;
        final jupRashi = (jupLon / 30.0).floor() % 12;
        
        final bCount = ((jupRashi - brideRashi + 12) % 12) + 1;
        final gCount = ((jupRashi - groomRashi + 12) % 12) + 1;
        final brideBala = const [1,2,4,5,7,9,10,11].contains(bCount);
        final groomBala = const [1,2,4,5,7,9,10,11].contains(gCount);
        
        if (jupRashi != prevJupRashi && prevJupRashi >= 0) {
          // Jupiter changed rashi — record the previous period
          windows.add({
            'rashi': prevJupRashi,
            'rashiName': knRashi[prevJupRashi],
            'start': periodStart ?? now,
            'end': dt,
            'brideBala': prevBrideBala,
            'groomBala': prevGroomBala,
            'brideHouse': ((prevJupRashi - brideRashi + 12) % 12) + 1,
            'groomHouse': ((prevJupRashi - groomRashi + 12) % 12) + 1,
          });
          periodStart = dt;
        }
        if (prevJupRashi < 0) periodStart = now;
        prevJupRashi = jupRashi;
        prevBrideBala = brideBala;
        prevGroomBala = groomBala;
      } catch (_) {}
    }
    // Add last period
    if (prevJupRashi >= 0 && periodStart != null) {
      final endDt = DateTime(now.year, now.month + 24, 15);
      windows.add({
        'rashi': prevJupRashi,
        'rashiName': knRashi[prevJupRashi],
        'start': periodStart,
        'end': endDt,
        'brideBala': prevBrideBala,
        'groomBala': prevGroomBala,
        'brideHouse': ((prevJupRashi - brideRashi + 12) % 12) + 1,
        'groomHouse': ((prevJupRashi - groomRashi + 12) % 12) + 1,
      });
    }
    return windows;
  }

  // Geocode helper
  Future<void> _geocode(String placeName, TextEditingController latCtrl, TextEditingController lonCtrl, TextEditingController tzCtrl, void Function(bool) setGeoLoading, void Function(String) setGeoStatus, {DateTime? birthDate}) async {
    if (placeName.trim().isEmpty) return;
    setGeoLoading(true);
    setGeoStatus('');
    try {
      final q = Uri.encodeComponent(placeName.trim());
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setGeoStatus(AppLocale.l('placeNotFound'));
        } else if (data.length == 1) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'] as String;
          final autoTz = await getTimezoneForPlace(displayName, lat, lon, birthDate: birthDate);
          setState(() {
            latCtrl.text = lat.toStringAsFixed(4);
            lonCtrl.text = lon.toStringAsFixed(4);
            tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
          });
          setGeoStatus('📍 $displayName');
        } else {
          if (mounted) _showPlaceDisambiguation(data, latCtrl, lonCtrl, tzCtrl, setGeoStatus, birthDate: birthDate);
        }
      }
    } catch (_) {
      setGeoStatus(AppLocale.l('networkError'));
    }
    setGeoLoading(false);
  }

  void _showPlaceDisambiguation(List<dynamic> results, TextEditingController latCtrl, TextEditingController lonCtrl, TextEditingController tzCtrl, void Function(String) setGeoStatus, {DateTime? birthDate}) {
    showModalBottomSheet(
      context: context, backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(AppLocale.l('selectPlace'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1))),
        Flexible(child: ListView.separated(
          shrinkWrap: true, itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final place = results[i];
            final displayName = place['display_name'] ?? '';
            return ListTile(
              leading: CircleAvatar(backgroundColor: kPurple1.withOpacity(0.1), child: Icon(Icons.location_on, color: kPurple1, size: 20)),
              title: Text(displayName, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () async {
                Navigator.pop(ctx);
                final lat = double.parse(place['lat']);
                final lon = double.parse(place['lon']);
                final autoTz = await getTimezoneForPlace(displayName, lat, lon, birthDate: birthDate);
                setState(() {
                  latCtrl.text = lat.toStringAsFixed(4);
                  lonCtrl.text = lon.toStringAsFixed(4);
                  tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                });
                setGeoStatus('📍 $displayName');
              },
            );
          },
        )),
        const SizedBox(height: 16),
      ])),
    );
  }

  /// Show bottom sheet to pick a saved kundali profile
  void _showProfilePicker({
    required TextEditingController nameCtrl,
    required TextEditingController placeCtrl,
    required TextEditingController latCtrl,
    required TextEditingController lonCtrl,
    required TextEditingController tzCtrl,
    required void Function(DateTime) onDobChanged,
    required void Function(int, int, String) onTimeChanged,
    required void Function(String) onGeoStatusChanged,
  }) async {
    final profiles = await StorageService.loadAll();
    if (profiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.l('noSavedProfiles')), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.person_search, color: kPurple1, size: 24),
                const SizedBox(width: 8),
                Text(AppLocale.l('selectSavedKundali'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple1)),
              ]),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: profiles.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
                itemBuilder: (_, i) {
                  final name = profiles.keys.elementAt(i);
                  final p = profiles[name]!;
                  final dateStr = p.date;
                  final timeStr = '${p.hour.toString().padLeft(2, "0")}:${p.minute.toString().padLeft(2, "0")} ${p.ampm}';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPurple1.withOpacity(0.1),
                      child: Icon(Icons.person, color: kPurple1, size: 20),
                    ),
                    title: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
                    subtitle: Text('$dateStr  $timeStr  ${p.place}', style: TextStyle(fontSize: 11, color: kMuted)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14, color: kMuted),
                    onTap: () {
                      Navigator.pop(ctx);
                      _loadProfileIntoFields(
                        profile: p, profileName: name,
                        nameCtrl: nameCtrl, placeCtrl: placeCtrl,
                        latCtrl: latCtrl, lonCtrl: lonCtrl, tzCtrl: tzCtrl,
                        onDobChanged: onDobChanged, onTimeChanged: onTimeChanged,
                        onGeoStatusChanged: onGeoStatusChanged,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  void _loadProfileIntoFields({
    required Profile profile,
    required String profileName,
    required TextEditingController nameCtrl,
    required TextEditingController placeCtrl,
    required TextEditingController latCtrl,
    required TextEditingController lonCtrl,
    required TextEditingController tzCtrl,
    required void Function(DateTime) onDobChanged,
    required void Function(int, int, String) onTimeChanged,
    required void Function(String) onGeoStatusChanged,
  }) {
    setState(() {
      nameCtrl.text = profileName;
      placeCtrl.text = profile.place;
      latCtrl.text = profile.lat.toStringAsFixed(4);
      lonCtrl.text = profile.lon.toStringAsFixed(4);
      final tz = profile.tzOffset;
      tzCtrl.text = '${tz >= 0 ? '+' : ''}$tz';

      // Parse date
      final parts = profile.date.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? 2000;
        final m = int.tryParse(parts[1]) ?? 1;
        final d = int.tryParse(parts[2]) ?? 1;
        onDobChanged(DateTime(y, m, d));
      }

      onTimeChanged(profile.hour, profile.minute, profile.ampm);
      onGeoStatusChanged('📍 ${profile.place}');
    });
  }

  /// Save a person's data as a profile with Client sync
  Future<void> _savePersonProfile({
    required TextEditingController nameCtrl,
    required TextEditingController placeCtrl,
    required TextEditingController latCtrl,
    required TextEditingController lonCtrl,
    required TextEditingController tzCtrl,
    required DateTime dob,
    required int hour,
    required int minute,
    required String ampm,
  }) async {
    String name = nameCtrl.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.l('enterName')), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final lat = double.tryParse(latCtrl.text) ?? 14.98;
    final lon = double.tryParse(lonCtrl.text) ?? 74.73;
    final tz = double.tryParse(tzCtrl.text) ?? 5.5;
    final dateStr = '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';

    // Resolve or create Client
    await ClientService.loadAll();
    final resolvedClient = await ClientService.getOrCreateClient(name: name, phone: 'No Phone');
    String? cId = resolvedClient?.clientId;

    final p = Profile(
      name: name,
      date: dateStr,
      hour: hour, minute: minute, ampm: ampm,
      lat: lat, lon: lon, tzOffset: tz,
      place: placeCtrl.text,
      clientId: cId,
    );

    // Sync as FamilyMember
    if (cId != null && cId.isNotEmpty) {
      final member = FamilyMember(
        clientId: cId,
        memberName: name,
        relation: 'Self',
        dob: dateStr,
        birthTime: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm',
        birthPlace: placeCtrl.text,
        lat: lat, lon: lon,
        tzOffset: LocationService.tzOffset,
        notes: '',
      );
      final members = ClientService.getMembersForClient(cId);
      if (!members.any((m) => m.memberName == name)) {
        await ClientService.addFamilyMember(member);
      } else {
        await ClientService.updateFamilyMember(member);
      }
    }

    await StorageService.save(p);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocale.l('savedSuccess')} - $name'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildPersonInput({
    required String title,
    required Color color,
    required TextEditingController nameCtrl,
    required TextEditingController placeCtrl,
    required TextEditingController latCtrl,
    required TextEditingController lonCtrl,
    required TextEditingController tzCtrl,
    required DateTime dob,
    required int hour,
    required int minute,
    required String ampm,
    required bool geoLoading,
    required String geoStatus,
    required void Function(DateTime) onDobChanged,
    required void Function(int, int, String) onTimeChanged,
    required void Function(bool) onGeoLoadingChanged,
    required void Function(String) onGeoStatusChanged,
    required VoidCallback onLoadSaved,
    required VoidCallback onSave,
    Widget? savedChips,
    VoidCallback? onAdd,
  }) {
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (savedChips != null) savedChips,
      Row(children: [
        Expanded(child: SectionTitle(title, color: color)),
        TextButton.icon(
          onPressed: onLoadSaved,
          icon: Icon(Icons.folder_open, size: 14, color: color),
          label: Text(AppLocale.l('loadSaved'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            backgroundColor: color.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: onSave,
          icon: Icon(Icons.save, size: 14, color: Colors.green),
          label: Text(AppLocale.l('saveBtn'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            backgroundColor: Colors.green.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      TextField(
        controller: nameCtrl,
        style: TextStyle(color: kText),
        decoration: InputDecoration(labelText: AppLocale.l('name'), prefixIcon: Icon(Icons.person_outline, color: kMuted), isDense: true),
      ),
      const SizedBox(height: 10),
      DateInputRow(
        date: dob,
        color: color,
        onChanged: onDobChanged,
      ),
      const SizedBox(height: 10),
      TimeInputRow(
        hour: hour,
        minute: minute,
        ampm: ampm,
        color: color,
        onChanged: onTimeChanged,
      ),
      const SizedBox(height: 10),
      Autocomplete<String>(
        key: ValueKey(placeCtrl.text),
        optionsBuilder: (TextEditingValue v) {
          if (v.text.isEmpty) return offlinePlaces.keys.take(15);
          final query = v.text.toLowerCase();
          final offline = offlinePlaces.keys.where((n) => n.toLowerCase().contains(query)).toList();
          if (worldCitiesLoaded) {
            final worldResults = searchWorldCities(v.text, limit: 15);
            for (final w in worldResults) {
              final label = worldCityLabel(w);
              if (!offline.any((o) => o.toLowerCase() == label.toLowerCase())) {
                offline.add(label);
              }
            }
          }
          return offline.take(20);
        },
        fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
          if (textCtrl.text.isEmpty && placeCtrl.text.isNotEmpty) textCtrl.text = placeCtrl.text;
          return TextField(
            controller: textCtrl, focusNode: focusNode, style: TextStyle(color: kText),
            decoration: InputDecoration(
              labelText: AppLocale.l('searchPlace'), prefixIcon: const Icon(Icons.search), isDense: true,
              suffixIcon: geoLoading
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(icon: Icon(Icons.my_location, color: kTeal, size: 18), onPressed: () {
                    placeCtrl.text = textCtrl.text;
                    _geocode(textCtrl.text, latCtrl, lonCtrl, tzCtrl, (v) => setState(() => onGeoLoadingChanged(v)), (v) => setState(() => onGeoStatusChanged(v)), birthDate: dob);
                  }),
            ),
            onSubmitted: (_) {
              placeCtrl.text = textCtrl.text;
              _geocode(textCtrl.text, latCtrl, lonCtrl, tzCtrl, (v) => setState(() => onGeoLoadingChanged(v)), (v) => setState(() => onGeoStatusChanged(v)), birthDate: dob);
            },
          );
        },
        onSelected: (String selection) async {
          if (offlinePlaces.containsKey(selection)) {
            final coords = offlinePlaces[selection]!;
            setState(() {
              placeCtrl.text = selection;
              latCtrl.text = coords[0].toStringAsFixed(4);
              lonCtrl.text = coords[1].toStringAsFixed(4);
              tzCtrl.text = '${coords[2] >= 0 ? '+' : ''}${coords[2]}';
            });
          } else {
            final worldResults = searchWorldCities(selection.split(', ').first, limit: 1);
            if (worldResults.isNotEmpty) {
              final w = worldResults.first;
              final lat = (w['la'] as num).toDouble();
              final lon = (w['lo'] as num).toDouble();
              final tz = (w['c'] != null)
                  ? getDstAwareOffset(w['c'] as String, lat, lon, dob)
                  : (w['tz'] as num).toDouble();
              setState(() {
                placeCtrl.text = selection;
                latCtrl.text = lat.toStringAsFixed(4);
                lonCtrl.text = lon.toStringAsFixed(4);
                tzCtrl.text = '${tz >= 0 ? '+' : ''}$tz';
              });
            }
          }
        },
        optionsViewBuilder: (context, onSelected, options) => Align(alignment: Alignment.topLeft, child: Material(elevation: 4.0, borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 64),
            child: ListView.builder(padding: EdgeInsets.zero, itemCount: options.length, shrinkWrap: true,
              itemBuilder: (context, i) {
                final o = options.elementAt(i);
                return ListTile(dense: true, leading: Icon(Icons.location_on, size: 16, color: color), title: Text(o, style: const TextStyle(fontSize: 12)), onTap: () => onSelected(o));
              }),
          ),
        )),
      ),
      if (geoStatus.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(geoStatus, style: TextStyle(fontSize: 11, color: kGreen))),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(flex: 4, child: TextField(controller: latCtrl, style: TextStyle(color: kText, fontSize: 12), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: AppLocale.l('lat'), isDense: true))),
        const SizedBox(width: 6),
        Expanded(flex: 4, child: TextField(controller: lonCtrl, style: TextStyle(color: kText, fontSize: 12), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: AppLocale.l('lon'), isDense: true))),
        const SizedBox(width: 6),
        Expanded(flex: 3, child: TextField(controller: tzCtrl, style: TextStyle(color: kText, fontSize: 12), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: AppLocale.l('tzOffset'), isDense: true))),
      ]),
      if (onAdd != null) ...[
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : onAdd,
            icon: const Icon(Icons.person_add, size: 16),
            label: Text(AppLocale.l('addLabel'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    ]));
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }

  Widget _doshaChip(String label, bool hasDosha, {String? detail}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasDosha ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasDosha ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(hasDosha ? Icons.warning_amber : Icons.check_circle, color: hasDosha ? Colors.red : Colors.green, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: hasDosha ? Colors.red.shade800 : Colors.green.shade800)),
        if (detail != null) Text(' ($detail)', style: TextStyle(fontSize: 11, color: kMuted)),
      ]),
    );
  }

  Widget _tableRow2(List<String> cells, {bool header = false, Color? bg}) {
    return Container(
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(children: cells.asMap().entries.map((e) => Expanded(
        flex: e.key == 0 ? 2 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: header ? FontWeight.w900 : FontWeight.w600, color: header ? kPurple2 : kText), textAlign: e.key == 0 ? TextAlign.left : TextAlign.center),
        ),
      )).toList()),
    );
  }

  Widget _buildResults() {
    if (_brideResult == null || _groomResult == null || _fullResult == null) return const SizedBox.shrink();
    final br = _brideResult!;
    final gr = _groomResult!;
    final fr = _fullResult!;

    final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
    final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Person pair switcher
      if (_varaList.length > 1 || _vadhuList.length > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            if (_varaList.length > 1)
              Expanded(child: DropdownButtonFormField<int>(
                value: _activeVaraIdx < _varaList.length ? _activeVaraIdx : 0,
                decoration: InputDecoration(labelText: AppLocale.l('groomDetails'), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                items: List.generate(_varaList.length, (i) => DropdownMenuItem(value: i, child: Text(_varaList[i].name, style: TextStyle(fontSize: 12)))),
                onChanged: (v) { if (v != null) { setState(() => _activeVaraIdx = v); _recalculateMatch(); } },
              )),
            if (_varaList.length > 1 && _vadhuList.length > 1) const SizedBox(width: 8),
            if (_vadhuList.length > 1)
              Expanded(child: DropdownButtonFormField<int>(
                value: _activeVadhuIdx < _vadhuList.length ? _activeVadhuIdx : 0,
                decoration: InputDecoration(labelText: AppLocale.l('brideDetails'), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                items: List.generate(_vadhuList.length, (i) => DropdownMenuItem(value: i, child: Text(_vadhuList[i].name, style: TextStyle(fontSize: 12)))),
                onChanged: (v) { if (v != null) { setState(() => _activeVadhuIdx = v); _recalculateMatch(); } },
              )),
          ]),
        ),
      // ── INDIVIDUAL DETAILS ──
      _sectionHeader('$gName — ${AppLocale.l('chart')}', Icons.male, kTeal),
      _buildPersonSummary(gr, gName, _gDob, _gHour, _gMinute, _gAmpm, _gPlaceCtrl.text),
      _sectionHeader('$bName — ${AppLocale.l('chart')}', Icons.female, kOrange),
      _buildPersonSummary(br, bName, _bDob, _bHour, _bMinute, _bAmpm, _bPlaceCtrl.text),

      // ── KUJA DOSHA ──
      _sectionHeader(AppLocale.l('kujaDosha'), Icons.brightness_7, Colors.red.shade700),
      _buildKujaDoshaSection(fr),

      // ── PAPA DOSHA ──
      _sectionHeader(AppLocale.l('papaDosha'), Icons.shield, Colors.deepOrange),
      _buildPapaDoshaSection(fr),

      // ── GRAHA MAITRI ──
      _sectionHeader(AppLocale.l('grahaMaitriAmsha'), Icons.handshake, kPurple2),
      _buildGrahaMaitriSection(fr),

      // ── SHATHA ASHTAKA & DVIRDVADASHA ──
      _sectionHeader('${AppLocale.l('shathaAshtaka')} & ${AppLocale.l('dvirdvadasha')}', Icons.compare_arrows, Colors.indigo),
      _buildShathaAshtakaDvirdvadashaSection(fr),

      // ── KOOTA TOGGLE + TABLE ──
      _sectionHeader(AppLocale.l('matchResult'), Icons.stars, kPurple1),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _kootaMode = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _kootaMode == 0 ? kPurple1 : kCard,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  border: Border.all(color: kPurple1),
                ),
                alignment: Alignment.center,
                child: Text(AppLocale.l('ashtaKootaLabel'), style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13,
                  color: _kootaMode == 0 ? Colors.white : kPurple1,
                )),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _kootaMode = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _kootaMode == 1 ? kPurple1 : kCard,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                  border: Border.all(color: kPurple1),
                ),
                alignment: Alignment.center,
                child: Text(AppLocale.l('dvadashaKootaLabel'), style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13,
                  color: _kootaMode == 1 ? Colors.white : kPurple1,
                )),
              ),
            ),
          ),
        ]),
      ),
      _kootaMode == 0
        ? _buildAshtaKootaTable(fr['ashtaKoota'])
        : _buildDvadashaKootaTable(fr['dvadashaKoota']),

      // ── DASHA SANDHI ──
      _sectionHeader(AppLocale.l('dashaSandhi'), Icons.swap_horiz, Colors.deepPurple),
      _buildDashaSandhiSection(br, gr),

      // ── PDF EXPORT BUTTON ──
      const SizedBox(height: 16),
      Center(
        child: ElevatedButton.icon(
          onPressed: _showMatchPdfDialog,
          icon: const Icon(Icons.picture_as_pdf, size: 20),
          label: Text('PDF ${AppLocale.l('save')}', style: const TextStyle(fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      const SizedBox(height: 32),
    ]);
  }

  void _loadMatchJyotishiDetails() async {
    final prefs = await SharedPreferences.getInstance();
    _mJyotishiNameCtrl.text = prefs.getString('match_jyotishi_name') ?? prefs.getString('default_jyotishi_name') ?? '';
    _mJyotishiAddressCtrl.text = prefs.getString('match_jyotishi_address') ?? prefs.getString('default_jyotishi_address') ?? '';
    _mJyotishiPhoneCtrl.text = prefs.getString('match_jyotishi_phone') ?? prefs.getString('default_jyotishi_phone') ?? '';
    final inv = prefs.getString('match_invocation');
    if (inv != null && inv.isNotEmpty) _mInvocationCtrl.text = inv;
    _mSelectedThemeId = prefs.getString('match_pdf_theme') ?? 'traditional';
  }

  void _saveMatchJyotishiDetails() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('match_jyotishi_name', _mJyotishiNameCtrl.text.trim());
    prefs.setString('match_jyotishi_address', _mJyotishiAddressCtrl.text.trim());
    prefs.setString('match_jyotishi_phone', _mJyotishiPhoneCtrl.text.trim());
    prefs.setString('match_invocation', _mInvocationCtrl.text.trim());
    prefs.setString('match_pdf_theme', _mSelectedThemeId);
  }

  void _showMatchPdfDialog() {
    if (_brideResult == null || _groomResult == null || _fullResult == null) return;
    _loadMatchJyotishiDetails();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text(AppLocale.l('matchPdfTitle'), style: TextStyle(fontWeight: FontWeight.w900, color: kText, fontSize: 18))),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocale.l('mangalaShloka'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              const SizedBox(height: 4),
              TextField(
                controller: _mInvocationCtrl,
                decoration: InputDecoration(hintText: 'ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ', prefixIcon: Icon(Icons.auto_awesome, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                onChanged: (_) => _saveMatchJyotishiDetails(),
              ),
              const SizedBox(height: 14),
              Text(AppLocale.l('jyotishiDetails'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
              const SizedBox(height: 4),
              TextField(
                controller: _mJyotishiNameCtrl,
                decoration: InputDecoration(labelText: AppLocale.l('nameLabel'), prefixIcon: Icon(Icons.storefront, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                onChanged: (_) => _saveMatchJyotishiDetails(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _mJyotishiAddressCtrl,
                maxLines: 2,
                decoration: InputDecoration(labelText: AppLocale.l('addressLabel'), prefixIcon: Icon(Icons.location_on_outlined, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                onChanged: (_) => _saveMatchJyotishiDetails(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _mJyotishiPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: AppLocale.l('phoneLabel'), prefixIcon: Icon(Icons.phone, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                onChanged: (_) => _saveMatchJyotishiDetails(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${AppLocale.l('groom')}: ${_gNameCtrl.text}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
                  Text('${AppLocale.l('bride')}: ${_bNameCtrl.text}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.pink.shade700)),
                  Text('${AppLocale.l('koota')}: ${_kootaMode == 0 ? AppLocale.l('ashtaKoota') : AppLocale.l('dvadashaKoota')}', style: TextStyle(fontSize: 11, color: kMuted)),
                ]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('cancel'), style: TextStyle(color: kMuted))),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              _saveMatchJyotishiDetails();
              final bDobStr = '${_bDob.day.toString().padLeft(2, '0')}-${_bDob.month.toString().padLeft(2, '0')}-${_bDob.year}';
              final gDobStr = '${_gDob.day.toString().padLeft(2, '0')}-${_gDob.month.toString().padLeft(2, '0')}-${_gDob.year}';
              final data = MatchPdfData(
                groomName: _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groom'),
                groomDob: gDobStr,
                groomTime: '${_gHour.toString().padLeft(2, '0')}:${_gMinute.toString().padLeft(2, '0')} $_gAmpm',
                groomPlace: _gPlaceCtrl.text,
                brideName: _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('bride'),
                brideDob: bDobStr,
                brideTime: '${_bHour.toString().padLeft(2, '0')}:${_bMinute.toString().padLeft(2, '0')} $_bAmpm',
                bridePlace: _bPlaceCtrl.text,
                groomResult: _groomResult!,
                brideResult: _brideResult!,
                fullResult: _fullResult!,
                kootaMode: _kootaMode,
                invocationText: _mInvocationCtrl.text.trim(),
                astrologerName: _mJyotishiNameCtrl.text.trim(),
                astrologerAddress: _mJyotishiAddressCtrl.text.trim(),
                astrologerPhone: _mJyotishiPhoneCtrl.text.trim(),
              );
              final selectedTheme = PdfThemes.all.firstWhere((t) => t.id == _mSelectedThemeId, orElse: () => PdfThemes.traditional);
              showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: kPurple1), const SizedBox(height: 16), Text(AppLocale.l('pdfCreating'), style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14, decoration: TextDecoration.none))]))));
              await Future.delayed(const Duration(milliseconds: 50));
              try {
                await MatchPdfService.generateAndPrint(data, theme: selectedTheme);
                if (mounted) Navigator.of(context, rootNavigator: true).pop();
              } catch (e) {
                if (mounted) Navigator.of(context, rootNavigator: true).pop();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
              }
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: Text(AppLocale.l('createPdf')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: (_groomResult == null || _brideResult == null || _fullResult == null) ? null : () async {
              final gDobStr = '${_gDob.day.toString().padLeft(2, '0')}-${_gDob.month.toString().padLeft(2, '0')}-${_gDob.year}';
              final bDobStr = '${_bDob.day.toString().padLeft(2, '0')}-${_bDob.month.toString().padLeft(2, '0')}-${_bDob.year}';
              final data = MatchPdfData(
                groomName: _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groom'),
                groomDob: gDobStr,
                groomTime: '${_gHour.toString().padLeft(2, '0')}:${_gMinute.toString().padLeft(2, '0')} $_gAmpm',
                groomPlace: _gPlaceCtrl.text,
                brideName: _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('bride'),
                brideDob: bDobStr,
                brideTime: '${_bHour.toString().padLeft(2, '0')}:${_bMinute.toString().padLeft(2, '0')} $_bAmpm',
                bridePlace: _bPlaceCtrl.text,
                groomResult: _groomResult!,
                brideResult: _brideResult!,
                fullResult: _fullResult!,
                kootaMode: _kootaMode,
                invocationText: _mInvocationCtrl.text.trim(),
                astrologerName: _mJyotishiNameCtrl.text.trim(),
                astrologerAddress: _mJyotishiAddressCtrl.text.trim(),
                astrologerPhone: _mJyotishiPhoneCtrl.text.trim(),
              );
              final selectedTheme = PdfThemes.all.firstWhere((t) => t.id == _mSelectedThemeId, orElse: () => PdfThemes.traditional);
              Navigator.pop(ctx);
              showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: kPurple1), const SizedBox(height: 16), Text(AppLocale.l('pdfCreating'), style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14, decoration: TextDecoration.none))]))));
              await Future.delayed(const Duration(milliseconds: 50));
              try {
                await MatchPdfService.generateAndShare(data, theme: selectedTheme);
                if (mounted) Navigator.of(context, rootNavigator: true).pop();
              } catch (e) {
                if (mounted) Navigator.of(context, rootNavigator: true).pop();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
              }
            },
            icon: const Icon(Icons.share, size: 18),
            label: Text(AppLocale.l('pdfShareDirect')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if any mahadasha of bride and groom end within 6 months of each other
  Widget _buildDashaSandhiSection(KundaliResult br, KundaliResult gr) {
    final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
    final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

    // Only consider mahadashas ending in the future
    final now = DateTime.now();
    final bDashas = br.dashas.where((d) => d.end.isAfter(now)).toList();
    final gDashas = gr.dashas.where((d) => d.end.isAfter(now)).toList();

    // Find pairs where both have a mahadasha ending within 6 months of each other
    final matches = <Map<String, dynamic>>[];
    const sixMonths = Duration(days: 183);

    for (final bd in bDashas) {
      for (final gd in gDashas) {
        final diff = bd.end.difference(gd.end).abs();
        if (diff <= sixMonths) {
          matches.add({
            'brideLord': bd.lord,
            'brideEnd': bd.end,
            'groomLord': gd.lord,
            'groomEnd': gd.end,
          });
        }
      }
    }

    final hasSandhi = matches.isNotEmpty;
    final verdict = hasSandhi ? AppLocale.l('dashaSandhiYes') : AppLocale.l('dashaSandhiNo');
    final vColor = hasSandhi ? Colors.red.shade700 : Colors.green.shade700;

    String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, "0")}-${d.month.toString().padLeft(2, "0")}-${d.year}';

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Current Dasha Details for both ──
      _buildCurrentDashaInfo(br, bName, Icons.female, kOrange),
      const SizedBox(height: 10),
      _buildCurrentDashaInfo(gr, gName, Icons.male, kTeal),
      const SizedBox(height: 14),
      Divider(color: kBorder),
      const SizedBox(height: 10),
      // Verdict
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: vColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(hasSandhi ? Icons.warning : Icons.check_circle, color: vColor, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(verdict, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: vColor))),
        ]),
      ),
      if (matches.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('${AppLocale.l('mahadashaEnds')} (${AppLocale.l('within6Months')})',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kMuted)),
        const SizedBox(height: 8),
        ...matches.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.male, size: 16, color: kTeal),
                const SizedBox(width: 4),
                Text('$gName: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
                Text('${trAll(m['groomLord'])} → ${_fmtDate(m['groomEnd'])}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kText)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.female, size: 16, color: kOrange),
                const SizedBox(width: 4),
                Text('$bName: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
                Text('${trAll(m['brideLord'])} → ${_fmtDate(m['brideEnd'])}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kText)),
              ]),
            ]),
          ),
        )),
      ],
    ]));
  }

  /// Build current running dasha info for a person
  Widget _buildCurrentDashaInfo(KundaliResult r, String name, IconData icon, Color accent) {
    final now = DateTime.now();
    String _fmtD(DateTime d) => '${d.day.toString().padLeft(2, "0")}-${d.month.toString().padLeft(2, "0")}-${d.year}';

    // Find current Mahadasha
    String mdLord = '', mdEnd = '';
    String adLord = '', adEnd = '';
    String pdLord = '', pdEnd = '';
    String sdLord = '', sdEnd = '';

    for (final md in r.dashas) {
      if (now.isBefore(md.end) && (now.isAfter(md.start) || now.isAtSameMomentAs(md.start))) {
        mdLord = trAll(md.lord);
        mdEnd = _fmtD(md.end);
        for (final ad in md.antardashas) {
          if (now.isBefore(ad.end) && (now.isAfter(ad.start) || now.isAtSameMomentAs(ad.start))) {
            adLord = trAll(ad.lord);
            adEnd = _fmtD(ad.end);
            for (final pd in ad.antardashas) {
              if (now.isBefore(pd.end) && (now.isAfter(pd.start) || now.isAtSameMomentAs(pd.start))) {
                pdLord = trAll(pd.lord);
                pdEnd = _fmtD(pd.end);
                for (final sd in pd.antardashas) {
                  if (now.isBefore(sd.end) && (now.isAfter(sd.start) || now.isAtSameMomentAs(sd.start))) {
                    sdLord = trAll(sd.lord);
                    sdEnd = _fmtD(sd.end);
                    break;
                  }
                }
                break;
              }
            }
            break;
          }
        }
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 6),
          Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: accent)),
          const Spacer(),
          Text(AppLocale.l('currentDasha'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kMuted)),
        ]),
        const SizedBox(height: 8),
        if (mdLord.isNotEmpty)
          _dashaRow(AppLocale.l('mahadasha'), mdLord, mdEnd, FontWeight.w900, 12),
        if (adLord.isNotEmpty)
          _dashaRow(AppLocale.l('bhukti'), adLord, adEnd, FontWeight.w700, 11),
        if (pdLord.isNotEmpty)
          _dashaRow(AppLocale.l('pratyantara'), pdLord, pdEnd, FontWeight.w600, 11),
        if (sdLord.isNotEmpty)
          _dashaRow(AppLocale.l('sookshma'), sdLord, sdEnd, FontWeight.w600, 10),
      ]),
    );
  }

  Widget _dashaRow(String label, String lord, String endDate, FontWeight fw, double fs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: fs, fontWeight: FontWeight.w600, color: kMuted))),
        Text(lord, style: TextStyle(fontSize: fs, fontWeight: fw, color: kText)),
        const Spacer(),
        Text('→ $endDate', style: TextStyle(fontSize: fs - 1, fontWeight: FontWeight.w600, color: kMuted)),
      ]),
    );
  }

  Widget _buildPersonSummary(KundaliResult r, String name, DateTime dob, int hour, int minute, String ampm, String place) {
    final pan = r.panchang;
    final dateStr = '${dob.day.toString().padLeft(2, "0")}-${dob.month.toString().padLeft(2, "0")}-${dob.year}';
    final timeStr = '${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")} $ampm';
    // Age calculation
    final now = DateTime.now();
    int ageYears = now.year - dob.year;
    int ageMonths = now.month - dob.month;
    if (ageMonths < 0 || (ageMonths == 0 && now.day < dob.day)) {
      ageYears--;
      ageMonths += 12;
    }
    if (now.day < dob.day) ageMonths = (ageMonths - 1 + 12) % 12;
    final ageStr = '$ageYears${AppLocale.l('yearShort')} $ageMonths${AppLocale.l('monthShort')}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _kv(AppLocale.l('nameLabel'), name),
        _kv(AppLocale.l('placeLabel'), place),
        _kv(AppLocale.l('dateLabel'), dateStr),
        _kv(AppLocale.l('timeLabel'), timeStr),
        _kv(AppLocale.l('ageLabel'), ageStr),
        _kv(AppLocale.l('chandraNakshatra'), '${trAll(pan.nakshatra)} - ${AppLocale.l('padaLabel')} ${r.planets['ಚಂದ್ರ']?.pada ?? 1}'),
        _kv(AppLocale.l('chandraRashiLabel'), trAll(pan.chandraRashi)),
        _kv(AppLocale.l('dashaLord'), '${trAll(pan.dashaLord)} ${AppLocale.l('dashaBalance')}: ${pan.dashaBalance}'),
      ])),
      const SizedBox(height: 8),
      // Charts — horizontally swipeable
      SizedBox(
        height: MediaQuery.of(context).size.width * 0.75 + 30,
        child: _ChartSlider(result: r),
      ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _kv(String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text('$key: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kMuted)),
        Flexible(child: Text(val, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kText))),
      ]),
    );
  }

  Widget _buildKujaDoshaSection(Map<String, dynamic> fr) {
    final bk = fr['brideKujaDosha'] as Map<String, dynamic>;
    final gk = fr['groomKujaDosha'] as Map<String, dynamic>;
    final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
    final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

    Widget doshaRow(String label, Map<String, dynamic> d) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kText)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _doshaChip(AppLocale.l('lagna'), d['fromLagna'] > 0, detail: d['fromLagna'] > 0 ? '${d['fromLagna']}' : null),
          _doshaChip(AppLocale.l('chandraRashiLabel'), d['fromChandra'] > 0, detail: d['fromChandra'] > 0 ? '${d['fromChandra']}' : null),
          _doshaChip(AppLocale.l('planetShukra'), d['fromShukra'] > 0, detail: d['fromShukra'] > 0 ? '${d['fromShukra']}' : null),
        ]),
        const SizedBox(height: 10),
      ]);
    }

    final bothHave = bk['hasDosha'] == true && gk['hasDosha'] == true;
    final neitherHas = bk['hasDosha'] == false && gk['hasDosha'] == false;
    String verdict;
    Color vColor;
    if (bothHave || neitherHas) {
      verdict = bothHave ? AppLocale.l('kujaDoshaBoth') : AppLocale.l('kujaDoshaNone');
      vColor = Colors.green.shade700;
    } else {
      verdict = AppLocale.l('kujaDoshaMismatch');
      vColor = Colors.red.shade700;
    }

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      doshaRow(gName, gk),
      const Divider(),
      doshaRow(bName, bk),
      const Divider(),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: vColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(bothHave || neitherHas ? Icons.check_circle : Icons.warning, color: vColor, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(verdict, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: vColor))),
        ]),
      ),
    ]));
  }

  Widget _buildPapaDoshaSection(Map<String, dynamic> fr) {
    final bp = fr['bridePapaDosha'] as Map<String, dynamic>;
    final gp = fr['groomPapaDosha'] as Map<String, dynamic>;
    final ps = fr['papaSamya'] as Map<String, dynamic>;
    final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
    final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _tableRow2([AppLocale.l('papaDosha'), gName, bName], header: true, bg: kPurple2.withOpacity(0.08)),
      _tableRow2([AppLocale.l('lagna'), '${gp['fromLagna']}', '${bp['fromLagna']}']),
      _tableRow2([AppLocale.l('chandraRashiLabel'), '${gp['fromChandra']}', '${bp['fromChandra']}']),
      _tableRow2([AppLocale.l('planetShukra'), '${gp['fromShukra']}', '${bp['fromShukra']}']),
      _tableRow2([AppLocale.l('totalGuna'), '${gp['total']}', '${bp['total']}'], bg: kPurple1.withOpacity(0.05)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (ps['isSamya'] as bool) ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon((ps['isSamya'] as bool) ? Icons.check_circle : Icons.warning, color: (ps['isSamya'] as bool) ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(
            (ps['isSamya'] as bool) ? '${AppLocale.l('papaSamyaOk')} (${AppLocale.l('diffLabel')}: ${ps['difference']})' : '${AppLocale.l('papaAsaman')} (${AppLocale.l('diffLabel')}: ${ps['difference']})',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: (ps['isSamya'] as bool) ? Colors.green.shade800 : Colors.red.shade800),
          )),
        ]),
      ),
    ]));
  }

  Widget _buildGrahaMaitriSection(Map<String, dynamic> fr) {
    final gm = fr['grahaMaitri'] as Map<String, dynamic>;
    final rows = gm['rows'] as List<Map<String, dynamic>>;

    Color maitriColor(String m) {
      if (m == 'ಮಿತ್ರ') return Colors.green;
      if (m == 'ಶತ್ರು') return Colors.red;
      return Colors.orange;
    }

    final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
    final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

    return AppCard(padding: EdgeInsets.zero, child: Column(children: [
      _tableRow2(['', bName, gName, AppLocale.l('phala')], header: true, bg: kPurple2.withOpacity(0.08)),
      ...rows.map((r) => Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
        child: Row(children: [
          Expanded(flex: 2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(trAll(r['label']), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)))),
          Expanded(child: Text(trAll(r['brideLordName']), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted))),
          Expanded(child: Text(trAll(r['groomLordName']), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted))),
          Expanded(child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(color: maitriColor(r['maitri']).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(trAll(r['maitri']), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: maitriColor(r['maitri']))),
          )),
        ]),
      )),
    ]));
  }

  Widget _buildShathaAshtakaDvirdvadashaSection(Map<String, dynamic> fr) {
    final sa = fr['shathaAshtaka'] as Map<String, dynamic>;
    final dv = fr['dvirdvadasha'] as Map<String, dynamic>;

    Widget subRow(String label, Map<String, dynamic> d) {
      final has = d['hasDosha'] as bool;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Icon(has ? Icons.close : Icons.check, color: has ? Colors.red : Colors.green, size: 14),
          const SizedBox(width: 4),
          Text('$label: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
          Text(has ? AppLocale.l('doshaPresent') : AppLocale.l('doshaAbsent'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: has ? Colors.red.shade700 : Colors.green.shade700)),
          Text(' (${d['brideFromGroom']}/${d['groomFromBride']})', style: TextStyle(fontSize: 10, color: kMuted)),
        ]),
      );
    }

    Widget doshaCard(String title, Map<String, dynamic> d) {
      final has = d['hasDosha'] as bool;
      final fromChandra = d['fromChandra'] as Map<String, dynamic>;
      final fromLagna = d['fromLagna'] as Map<String, dynamic>;
      return Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: has ? Colors.red.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: has ? Colors.red.shade200 : Colors.green.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Icon(has ? Icons.warning_amber : Icons.check_circle, color: has ? Colors.red : Colors.green, size: 24)),
          const SizedBox(height: 4),
          Center(child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kText))),
          const SizedBox(height: 6),
          subRow(AppLocale.l('chandraRashiLabel'), fromChandra),
          subRow(AppLocale.l('lagna'), fromLagna),
        ]),
      ));
    }

    return Row(children: [
      doshaCard(AppLocale.l('shathaAshtaka'), sa),
      const SizedBox(width: 10),
      doshaCard(AppLocale.l('dvirdvadasha'), dv),
    ]);
  }

  Widget _buildAshtaKootaTable(Map<String, dynamic> result) {
    final total = result['total'] as double;
    String verdict;
    Color verdictColor;
    if (total <= 18) { verdict = AppLocale.l('matchPoor'); verdictColor = Colors.red.shade700; }
    else if (total <= 25) { verdict = AppLocale.l('matchMedium'); verdictColor = Colors.orange.shade700; }
    else { verdict = AppLocale.l('matchGood'); verdictColor = Colors.green.shade700; }

    TableRow row(String name, double pts, int max) {
      return TableRow(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
        children: [
          Padding(padding: const EdgeInsets.all(10), child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Padding(padding: const EdgeInsets.all(10), child: Text(pts.toStringAsFixed(1), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          Padding(padding: const EdgeInsets.all(10), child: Text(max.toString(), textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13))),
        ],
      );
    }

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)}, children: [
        TableRow(
          decoration: BoxDecoration(color: kPurple2.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          children: [
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('koota'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('padeGuna'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('garishThaGuna'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          ],
        ),
        row(AppLocale.l('varna'), result['varna'], 1),
        row(AppLocale.l('vashya'), result['vashya'], 2),
        row(AppLocale.l('tara'), result['tara'], 3),
        row(AppLocale.l('yoni'), result['yoni'], 4),
        row(AppLocale.l('grahaMaitri'), result['graha'], 5),
        row(AppLocale.l('gana'), result['gana'], 6),
        row(AppLocale.l('bhakoot'), result['bhakoot'], 7),
        row(AppLocale.l('naadi'), result['nadi'], 8),
        TableRow(
          decoration: BoxDecoration(color: kPurple1.withOpacity(0.05)),
          children: [
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('totalGuna'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            Padding(padding: const EdgeInsets.all(10), child: Text(total.toStringAsFixed(1), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kPurple1))),
            Padding(padding: const EdgeInsets.all(10), child: Text('36', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kMuted))),
          ],
        ),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(color: verdictColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: verdictColor.withOpacity(0.3))),
        child: Column(children: [
          Text('${AppLocale.l('result')}:', style: TextStyle(fontSize: 13, color: verdictColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(verdict, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: verdictColor)),
        ]),
      ),
    ]));
  }

  Widget _buildDvadashaKootaTable(Map<String, dynamic> result) {
    final total = result['total'] as double;
    String verdict;
    Color verdictColor;
    if (total <= 20) { verdict = AppLocale.l('matchPoor'); verdictColor = Colors.red.shade700; }
    else if (total <= 28) { verdict = AppLocale.l('matchMedium'); verdictColor = Colors.orange.shade700; }
    else { verdict = AppLocale.l('matchGood'); verdictColor = Colors.green.shade700; }

    TableRow row(String name, double pts, int max) {
      return TableRow(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
        children: [
          Padding(padding: const EdgeInsets.all(10), child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Padding(padding: const EdgeInsets.all(10), child: Text(pts.toStringAsFixed(1), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          Padding(padding: const EdgeInsets.all(10), child: Text(max.toString(), textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13))),
        ],
      );
    }

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)}, children: [
        TableRow(
          decoration: BoxDecoration(color: kPurple2.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          children: [
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('koota'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('padeGuna'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('garishThaGuna'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          ],
        ),
        row(AppLocale.l('varna'), result['varna'], 1),
        row(AppLocale.l('vashya'), result['vashya'], 2),
        row(AppLocale.l('tara'), result['tara'], 3),
        row(AppLocale.l('yoni'), result['yoni'], 4),
        row(AppLocale.l('grahaMaitri'), result['graha'], 5),
        row(AppLocale.l('gana'), result['gana'], 6),
        row(AppLocale.l('bhakoot'), result['bhakoot'], 7),
        row(AppLocale.l('naadi'), result['nadi'], 8),
        row(AppLocale.l('mahendra'), result['mahendra'], 1),
        row(AppLocale.l('streeDeergha'), result['streeDeergha'], 1),
        row(AppLocale.l('rajju'), result['rajju'], 1),
        row(AppLocale.l('vedha'), result['vedha'], 1),
        TableRow(
          decoration: BoxDecoration(color: kPurple1.withOpacity(0.05)),
          children: [
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('totalGuna'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            Padding(padding: const EdgeInsets.all(10), child: Text(total.toStringAsFixed(1), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kPurple1))),
            Padding(padding: const EdgeInsets.all(10), child: Text('40', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kMuted))),
          ],
        ),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(color: verdictColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: verdictColor.withOpacity(0.3))),
        child: Column(children: [
          Text('${AppLocale.l('result')}:', style: TextStyle(fontSize: 13, color: verdictColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(verdict, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: verdictColor)),
        ]),
      ),
    ]));
  }

  Widget _buildQuickKootaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.female, color: kOrange, size: 20),
            const SizedBox(width: 8),
            Text(AppLocale.l('brideDetails'), style: TextStyle(color: kOrange, fontWeight: FontWeight.w900, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(labelText: AppLocale.l('chandraRashiLabel'), isDense: true),
            value: _qBrideRashi,
            items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text(trAll(knRashi[i])))),
            onChanged: (v) { if (v != null) setState(() { _qBrideRashi = v; _qBrideNak = _naksForRashi(v).first; }); },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(labelText: AppLocale.l('chandraNakshatra'), isDense: true),
            value: _qBrideNak,
            items: _naksForRashi(_qBrideRashi).map((i) => DropdownMenuItem(value: i, child: Text(trAll(knNak[i])))).toList(),
            onChanged: (v) { if (v != null) setState(() => _qBrideNak = v); },
          ),
        ])),
        const SizedBox(height: 12),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.male, color: kTeal, size: 20),
            const SizedBox(width: 8),
            Text(AppLocale.l('groomDetails'), style: TextStyle(color: kTeal, fontWeight: FontWeight.w900, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(labelText: AppLocale.l('chandraRashiLabel'), isDense: true),
            value: _qGroomRashi,
            items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text(trAll(knRashi[i])))),
            onChanged: (v) { if (v != null) setState(() { _qGroomRashi = v; _qGroomNak = _naksForRashi(v).first; }); },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(labelText: AppLocale.l('chandraNakshatra'), isDense: true),
            value: _qGroomNak,
            items: _naksForRashi(_qGroomRashi).map((i) => DropdownMenuItem(value: i, child: Text(trAll(knNak[i])))).toList(),
            onChanged: (v) { if (v != null) setState(() => _qGroomNak = v); },
          ),
        ])),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _calculateQuickKoota,
          icon: const Icon(Icons.calculate),
          label: Text('⚡ ತ್ವರಿತ ಕೂಟ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPurple1, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_qResult != null) ...[
          const SizedBox(height: 16),
          _sectionHeader(AppLocale.l('matchResult'), Icons.stars, kPurple1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _kootaMode = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _kootaMode == 0 ? kPurple1 : kCard,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                      border: Border.all(color: kPurple1),
                    ),
                    alignment: Alignment.center,
                    child: Text(AppLocale.l('ashtaKootaLabel'), style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13,
                      color: _kootaMode == 0 ? Colors.white : kPurple1,
                    )),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _kootaMode = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _kootaMode == 1 ? kPurple1 : kCard,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                      border: Border.all(color: kPurple1),
                    ),
                    alignment: Alignment.center,
                    child: Text(AppLocale.l('dvadashaKootaLabel'), style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13,
                      color: _kootaMode == 1 ? Colors.white : kPurple1,
                    )),
                  ),
                ),
              ),
            ]),
          ),
          _kootaMode == 0
            ? _buildAshtaKootaTable(_qResult!['ashtaKoota'])
            : _buildDvadashaKootaTable(_qResult!['dvadashaKoota']),
          const SizedBox(height: 16),
          // ── Vadhu (Bride) Guru Bala ──
          _sectionHeader('🔸 ವಧು ಗುರು ಬಲ (${trAll(knRashi[_qBrideRashi])})', Icons.female, kOrange),
          ..._guruTransits.map((t) {
            final start = t['start'] as DateTime;
            final end = t['end'] as DateTime;
            final brideBala = t['brideBala'] as bool;
            final now = DateTime.now();
            final isCurrent = now.isAfter(start) && now.isBefore(end);
            final dateFmt = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: brideBala ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCurrent ? kOrange : (brideBala ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.15)), width: isCurrent ? 2 : 1),
              ),
              child: Row(children: [
                Icon(brideBala ? Icons.check_circle : Icons.cancel, size: 18, color: brideBala ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('ಗುರು ${trAll(t['rashiName'])}ದಲ್ಲಿ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isCurrent ? kOrange : kText)),
                    const SizedBox(width: 6),
                    Text('(${t['brideHouse']} ನೇ ಮನೆ)', style: TextStyle(fontSize: 11, color: kMuted)),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('ಈಗ', style: TextStyle(fontSize: 9, color: kOrange, fontWeight: FontWeight.bold))),
                    ],
                  ]),
                  Text(dateFmt, style: TextStyle(fontSize: 11, color: kMuted)),
                ])),
                Text(brideBala ? 'ಶುಭ' : 'ಅಶುಭ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brideBala ? Colors.green : Colors.red)),
              ]),
            );
          }).toList(),

          const SizedBox(height: 16),
          // ── Vara (Groom) Guru Bala ──
          _sectionHeader('🔹 ವರ ಗುರು ಬಲ (${trAll(knRashi[_qGroomRashi])})', Icons.male, kTeal),
          ..._guruTransits.map((t) {
            final start = t['start'] as DateTime;
            final end = t['end'] as DateTime;
            final groomBala = t['groomBala'] as bool;
            final now = DateTime.now();
            final isCurrent = now.isAfter(start) && now.isBefore(end);
            final dateFmt = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: groomBala ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCurrent ? kTeal : (groomBala ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.15)), width: isCurrent ? 2 : 1),
              ),
              child: Row(children: [
                Icon(groomBala ? Icons.check_circle : Icons.cancel, size: 18, color: groomBala ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('ಗುರು ${trAll(t['rashiName'])}ದಲ್ಲಿ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isCurrent ? kTeal : kText)),
                    const SizedBox(width: 6),
                    Text('(${t['groomHouse']} ನೇ ಮನೆ)', style: TextStyle(fontSize: 11, color: kMuted)),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: kTeal.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('ಈಗ', style: TextStyle(fontSize: 9, color: kTeal, fontWeight: FontWeight.bold))),
                    ],
                  ]),
                  Text(dateFmt, style: TextStyle(fontSize: 11, color: kMuted)),
                ])),
                Text(groomBala ? 'ಶುಭ' : 'ಅಶುಭ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: groomBala ? Colors.green : Colors.red)),
              ]),
            );
          }).toList(),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // NAMAAKSHARA (Letter-based) TAB
  // ─────────────────────────────────────────────
  Widget _buildNamaaksharaTab() {
    final brideMatches = _findMatchingSyllables(_nBrideInput);
    final groomMatches = _findMatchingSyllables(_nGroomInput);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Bride Letter Input ──
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.female, color: kOrange, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('ವಧು ನಾಮಾಕ್ಷರ', style: TextStyle(color: kOrange, fontWeight: FontWeight.w900, fontSize: 16))),
            TextButton.icon(
              onPressed: () => _showSyllablePicker(isBride: true),
              icon: Icon(Icons.grid_view_rounded, size: 16, color: kOrange),
              label: Text('ಪಟ್ಟಿ', style: TextStyle(fontSize: 12, color: kOrange, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: kOrange.withOpacity(0.3)))),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'ಹೆಸರಿನ ಮೊದಲ ಅಕ್ಷರ ಟೈಪ್ ಮಾಡಿ',
              hintText: 'ಉದಾ: ಚ, ಮ, ಸ ...',
              prefixIcon: Icon(Icons.text_fields, color: kOrange),
              isDense: true,
            ),
            onChanged: (v) => setState(() { _nBrideInput = v; _nBrideNak = null; _nBridePada = null; _nResult = null; }),
          ),
          if (brideMatches.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('ಅಕ್ಷರ ಆಯ್ಕೆ ಮಾಡಿ:', style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: brideMatches.map((m) {
              final nakIdx = m['nakIdx'] as int;
              final padaIdx = m['padaIdx'] as int;
              final syl = m['syllable'] as String;
              final isSelected = _nBrideNak == nakIdx && _nBridePada == padaIdx;
              return GestureDetector(
                onTap: () => setState(() { _nBrideNak = nakIdx; _nBridePada = padaIdx; _nResult = null; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? kOrange : kCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? kOrange : kBorder, width: isSelected ? 2 : 1),
                  ),
                  child: Column(children: [
                    Text(syl, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : kText)),
                    Text(trAll(knNak[nakIdx]), style: TextStyle(fontSize: 9, color: isSelected ? Colors.white70 : kMuted)),
                  ]),
                ),
              );
            }).toList()),
          ],
          if (_nBrideNak != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kOrange.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.check_circle, color: kOrange, size: 16),
                const SizedBox(width: 8),
                Text('${trAll(knNak[_nBrideNak!])} — ${trAll(knRashi[_rashiFromNakPada(_nBrideNak!, _nBridePada ?? 0)])}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: kOrange, fontSize: 13)),
              ]),
            ),
          ],
        ])),
        const SizedBox(height: 12),

        // ── Groom Letter Input ──
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.male, color: kTeal, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('ವರ ನಾಮಾಕ್ಷರ', style: TextStyle(color: kTeal, fontWeight: FontWeight.w900, fontSize: 16))),
            TextButton.icon(
              onPressed: () => _showSyllablePicker(isBride: false),
              icon: Icon(Icons.grid_view_rounded, size: 16, color: kTeal),
              label: Text('ಪಟ್ಟಿ', style: TextStyle(fontSize: 12, color: kTeal, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: kTeal.withOpacity(0.3)))),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'ಹೆಸರಿನ ಮೊದಲ ಅಕ್ಷರ ಟೈಪ್ ಮಾಡಿ',
              hintText: 'ಉದಾ: ಕ, ರ, ಗ ...',
              prefixIcon: Icon(Icons.text_fields, color: kTeal),
              isDense: true,
            ),
            onChanged: (v) => setState(() { _nGroomInput = v; _nGroomNak = null; _nGroomPada = null; _nResult = null; }),
          ),
          if (groomMatches.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('ಅಕ್ಷರ ಆಯ್ಕೆ ಮಾಡಿ:', style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: groomMatches.map((m) {
              final nakIdx = m['nakIdx'] as int;
              final padaIdx = m['padaIdx'] as int;
              final syl = m['syllable'] as String;
              final isSelected = _nGroomNak == nakIdx && _nGroomPada == padaIdx;
              return GestureDetector(
                onTap: () => setState(() { _nGroomNak = nakIdx; _nGroomPada = padaIdx; _nResult = null; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? kTeal : kCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? kTeal : kBorder, width: isSelected ? 2 : 1),
                  ),
                  child: Column(children: [
                    Text(syl, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : kText)),
                    Text(trAll(knNak[nakIdx]), style: TextStyle(fontSize: 9, color: isSelected ? Colors.white70 : kMuted)),
                  ]),
                ),
              );
            }).toList()),
          ],
          if (_nGroomNak != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kTeal.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.check_circle, color: kTeal, size: 16),
                const SizedBox(width: 8),
                Text('${trAll(knNak[_nGroomNak!])} — ${trAll(knRashi[_rashiFromNakPada(_nGroomNak!, _nGroomPada ?? 0)])}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: kTeal, fontSize: 13)),
              ]),
            ),
          ],
        ])),
        const SizedBox(height: 16),

        // ── Calculate Button ──
        ElevatedButton.icon(
          onPressed: (_nBrideNak != null && _nGroomNak != null) ? _calculateNamaaksharaKoota : null,
          icon: const Icon(Icons.calculate),
          label: Text('🔤 ನಾಮಾಕ್ಷರ ಕೂಟ ನೋಡಿ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPurple1, foregroundColor: Colors.white,
            disabledBackgroundColor: kBorder,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // ── Results ──
        if (_nResult != null) ...[
          const SizedBox(height: 16),
          _sectionHeader(AppLocale.l('matchResult'), Icons.stars, kPurple1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _kootaMode = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _kootaMode == 0 ? kPurple1 : kCard,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                      border: Border.all(color: kPurple1),
                    ),
                    alignment: Alignment.center,
                    child: Text(AppLocale.l('ashtaKootaLabel'), style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13,
                      color: _kootaMode == 0 ? Colors.white : kPurple1,
                    )),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _kootaMode = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _kootaMode == 1 ? kPurple1 : kCard,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                      border: Border.all(color: kPurple1),
                    ),
                    alignment: Alignment.center,
                    child: Text(AppLocale.l('dvadashaKootaLabel'), style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13,
                      color: _kootaMode == 1 ? Colors.white : kPurple1,
                    )),
                  ),
                ),
              ),
            ]),
          ),
          _kootaMode == 0
            ? _buildAshtaKootaTable(_nResult!['ashtaKoota'])
            : _buildDvadashaKootaTable(_nResult!['dvadashaKoota']),
          const SizedBox(height: 16),

          // Guru Bala for Bride
          _sectionHeader('🔸 ವಧು ಗುರು ಬಲ (${trAll(knRashi[_nResult!['brideRashi'] as int])})', Icons.female, kOrange),
          ..._nGuruTransits.map((t) {
            final start = t['start'] as DateTime;
            final end = t['end'] as DateTime;
            final brideBala = t['brideBala'] as bool;
            final now = DateTime.now();
            final isCurrent = now.isAfter(start) && now.isBefore(end);
            final dateFmt = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: brideBala ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCurrent ? kOrange : (brideBala ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.15)), width: isCurrent ? 2 : 1),
              ),
              child: Row(children: [
                Icon(brideBala ? Icons.check_circle : Icons.cancel, size: 18, color: brideBala ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('ಗುರು ${trAll(t['rashiName'])}ದಲ್ಲಿ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isCurrent ? kOrange : kText)),
                    const SizedBox(width: 6),
                    Text('(${t['brideHouse']} ನೇ ಮನೆ)', style: TextStyle(fontSize: 11, color: kMuted)),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('ಈಗ', style: TextStyle(fontSize: 9, color: kOrange, fontWeight: FontWeight.bold))),
                    ],
                  ]),
                  Text(dateFmt, style: TextStyle(fontSize: 11, color: kMuted)),
                ])),
                Text(brideBala ? 'ಶುಭ' : 'ಅಶುಭ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brideBala ? Colors.green : Colors.red)),
              ]),
            );
          }).toList(),

          const SizedBox(height: 16),
          // Guru Bala for Groom
          _sectionHeader('🔹 ವರ ಗುರು ಬಲ (${trAll(knRashi[_nResult!['groomRashi'] as int])})', Icons.male, kTeal),
          ..._nGuruTransits.map((t) {
            final start = t['start'] as DateTime;
            final end = t['end'] as DateTime;
            final groomBala = t['groomBala'] as bool;
            final now = DateTime.now();
            final isCurrent = now.isAfter(start) && now.isBefore(end);
            final dateFmt = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: groomBala ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCurrent ? kTeal : (groomBala ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.15)), width: isCurrent ? 2 : 1),
              ),
              child: Row(children: [
                Icon(groomBala ? Icons.check_circle : Icons.cancel, size: 18, color: groomBala ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('ಗುರು ${trAll(t['rashiName'])}ದಲ್ಲಿ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isCurrent ? kTeal : kText)),
                    const SizedBox(width: 6),
                    Text('(${t['groomHouse']} ನೇ ಮನೆ)', style: TextStyle(fontSize: 11, color: kMuted)),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: kTeal.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('ಈಗ', style: TextStyle(fontSize: 9, color: kTeal, fontWeight: FontWeight.bold))),
                    ],
                  ]),
                  Text(dateFmt, style: TextStyle(fontSize: 11, color: kMuted)),
                ])),
                Text(groomBala ? 'ಶುಭ' : 'ಅಶುಭ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: groomBala ? Colors.green : Colors.red)),
              ]),
            );
          }).toList(),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: kPurple1,
            unselectedLabelColor: kMuted,
            indicatorColor: kPurple1,
            isScrollable: true,
            tabs: const [
              Tab(text: '📝 ಸಂಪೂರ್ಣ'),
              Tab(text: '⚡ ತ್ವರಿತ ಕೂಟ'),
              Tab(text: '🔤 ನಾಮಾಕ್ಷರ'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                OrientationBuilder(
                  builder: (context, orientation) {
                    final groomInput = _buildPersonInput(
                      title: AppLocale.l('groomDetails'), color: kTeal,
                      nameCtrl: _gNameCtrl, placeCtrl: _gPlaceCtrl, latCtrl: _gLatCtrl, lonCtrl: _gLonCtrl, tzCtrl: _gTzCtrl,
                      dob: _gDob, hour: _gHour, minute: _gMinute, ampm: _gAmpm,
                      geoLoading: _gGeoLoading, geoStatus: _gGeoStatus,
                      onDobChanged: (d) => setState(() => _gDob = d),
                      onTimeChanged: (h, m, a) => setState(() { _gHour = h; _gMinute = m; _gAmpm = a; }),
                      onGeoLoadingChanged: (v) => _gGeoLoading = v,
                      onGeoStatusChanged: (v) => _gGeoStatus = v,
                      onLoadSaved: () => _showProfilePicker(
                        nameCtrl: _gNameCtrl, placeCtrl: _gPlaceCtrl,
                        latCtrl: _gLatCtrl, lonCtrl: _gLonCtrl, tzCtrl: _gTzCtrl,
                        onDobChanged: (d) => setState(() => _gDob = d),
                        onTimeChanged: (h, m, a) => setState(() { _gHour = h; _gMinute = m; _gAmpm = a; }),
                        onGeoStatusChanged: (v) => setState(() => _gGeoStatus = v),
                      ),
                      onSave: () => _savePersonProfile(
                        nameCtrl: _gNameCtrl, placeCtrl: _gPlaceCtrl,
                        latCtrl: _gLatCtrl, lonCtrl: _gLonCtrl, tzCtrl: _gTzCtrl,
                        dob: _gDob, hour: _gHour, minute: _gMinute, ampm: _gAmpm,
                      ),
                      savedChips: _buildPersonChips(isVara: true, color: kTeal),
                      onAdd: () => _addPerson(isVara: true),
                    );

                    final brideInput = _buildPersonInput(
                      title: AppLocale.l('brideDetails'), color: kOrange,
                      nameCtrl: _bNameCtrl, placeCtrl: _bPlaceCtrl, latCtrl: _bLatCtrl, lonCtrl: _bLonCtrl, tzCtrl: _bTzCtrl,
                      dob: _bDob, hour: _bHour, minute: _bMinute, ampm: _bAmpm,
                      geoLoading: _bGeoLoading, geoStatus: _bGeoStatus,
                      onDobChanged: (d) => setState(() => _bDob = d),
                      onTimeChanged: (h, m, a) => setState(() { _bHour = h; _bMinute = m; _bAmpm = a; }),
                      onGeoLoadingChanged: (v) => _bGeoLoading = v,
                      onGeoStatusChanged: (v) => _bGeoStatus = v,
                      onLoadSaved: () => _showProfilePicker(
                        nameCtrl: _bNameCtrl, placeCtrl: _bPlaceCtrl,
                        latCtrl: _bLatCtrl, lonCtrl: _bLonCtrl, tzCtrl: _bTzCtrl,
                        onDobChanged: (d) => setState(() => _bDob = d),
                        onTimeChanged: (h, m, a) => setState(() { _bHour = h; _bMinute = m; _bAmpm = a; }),
                        onGeoStatusChanged: (v) => setState(() => _bGeoStatus = v),
                      ),
                      onSave: () => _savePersonProfile(
                        nameCtrl: _bNameCtrl, placeCtrl: _bPlaceCtrl,
                        latCtrl: _bLatCtrl, lonCtrl: _bLonCtrl, tzCtrl: _bTzCtrl,
                        dob: _bDob, hour: _bHour, minute: _bMinute, ampm: _bAmpm,
                      ),
                      savedChips: _buildPersonChips(isVara: false, color: kOrange),
                      onAdd: () => _addPerson(isVara: false),
                    );

                    final calcButton = SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _calculate,
                        icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.calculate),
                        label: Text(_loading ? '${AppLocale.l('calcInProgress')}' : AppLocale.l('checkMatch'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPurple1, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    );

                    if (orientation == Orientation.portrait) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          groomInput,
                          const SizedBox(height: 12),
                          brideInput,
                          const SizedBox(height: 16),
                          calcButton,
                          const SizedBox(height: 8),
                          _buildResults(),
                        ]),
                      );
                    } else {
                      // Build individual and comparison sections separately for landscape
                      Widget? groomSummary;
                      Widget? brideSummary;
                      Widget? comparisonSection;

                      if (_brideResult != null && _groomResult != null && _fullResult != null) {
                        final br = _brideResult!;
                        final gr = _groomResult!;
                        final fr = _fullResult!;
                        final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
                        final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

                        groomSummary = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sectionHeader('$gName — ${AppLocale.l('chart')}', Icons.male, kTeal),
                          _buildPersonSummary(gr, gName, _gDob, _gHour, _gMinute, _gAmpm, _gPlaceCtrl.text),
                        ]);

                        brideSummary = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sectionHeader('$bName — ${AppLocale.l('chart')}', Icons.female, kOrange),
                          _buildPersonSummary(br, bName, _bDob, _bHour, _bMinute, _bAmpm, _bPlaceCtrl.text),
                        ]);

                        comparisonSection = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sectionHeader(AppLocale.l('kujaDosha'), Icons.brightness_7, Colors.red.shade700),
                          _buildKujaDoshaSection(fr),
                          _sectionHeader(AppLocale.l('papaDosha'), Icons.shield, Colors.deepOrange),
                          _buildPapaDoshaSection(fr),
                          _sectionHeader(AppLocale.l('grahaMaitriAmsha'), Icons.handshake, kPurple2),
                          _buildGrahaMaitriSection(fr),
                          _sectionHeader('${AppLocale.l('shathaAshtaka')} & ${AppLocale.l('dvirdvadasha')}', Icons.compare_arrows, Colors.indigo),
                          _buildShathaAshtakaDvirdvadashaSection(fr),
                          _sectionHeader(AppLocale.l('matchResult'), Icons.stars, kPurple1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            child: Row(children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _kootaMode = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _kootaMode == 0 ? kPurple1 : kCard,
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                      border: Border.all(color: kPurple1),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(AppLocale.l('ashtaKootaLabel'), style: TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 13,
                                      color: _kootaMode == 0 ? Colors.white : kPurple1,
                                    )),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _kootaMode = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _kootaMode == 1 ? kPurple1 : kCard,
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                                      border: Border.all(color: kPurple1),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(AppLocale.l('dvadashaKootaLabel'), style: TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 13,
                                      color: _kootaMode == 1 ? Colors.white : kPurple1,
                                    )),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          _kootaMode == 0
                            ? _buildAshtaKootaTable(fr['ashtaKoota'])
                            : _buildDvadashaKootaTable(fr['dvadashaKoota']),
                          _sectionHeader(AppLocale.l('dashaSandhi'), Icons.swap_horiz, Colors.deepPurple),
                          _buildDashaSandhiSection(br, gr),
                          const SizedBox(height: 32),
                        ]);
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Inputs side by side
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: groomInput),
                                const SizedBox(width: 12),
                                Expanded(child: brideInput),
                              ],
                            ),
                            const SizedBox(height: 12),
                            calcButton,
                            const SizedBox(height: 12),
                            // Person summaries side by side
                            if (groomSummary != null && brideSummary != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: groomSummary),
                                  const SizedBox(width: 12),
                                  Expanded(child: brideSummary),
                                ],
                              ),
                            // Comparison sections full width
                            if (comparisonSection != null)
                              comparisonSection,
                          ],
                        ),
                      );
                    }
                  },
                ),
                _buildQuickKootaTab(),
                _buildNamaaksharaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontally swipeable chart slider with dot indicators
class _ChartSlider extends StatefulWidget {
  final KundaliResult result;
  const _ChartSlider({required this.result});

  @override
  State<_ChartSlider> createState() => _ChartSliderState();
}

class _ChartSliderState extends State<_ChartSlider> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final labels = [
      AppLocale.l('rashiKundali'),
      AppLocale.l('navamshaKundali'),
      AppLocale.l('bhavaKundali'),
      '${AppLocale.l('bhavaKundali')} (${trAll('ಚಂದ್ರ')})',
      '${AppLocale.l('bhavaKundali')} (${trAll('ಶುಕ್ರ')})',
    ];
    return Column(children: [
      Expanded(
        child: PageView(
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: KundaliChart(result: widget.result, varga: 1, isBhava: false, showSphutas: false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: KundaliChart(result: widget.result, varga: 9, isBhava: false, showSphutas: false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: KundaliChart(result: widget.result, varga: 1, isBhava: true, showSphutas: false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: KundaliChart(result: widget.result, varga: 1, isBhava: true, showSphutas: false, bhavaFromPlanet: 'ಚಂದ್ರ'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: KundaliChart(result: widget.result, varga: 1, isBhava: true, showSphutas: false, bhavaFromPlanet: 'ಶುಕ್ರ'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      // Label + dots
      Text(labels[_page], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kPurple2)),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: _page == i ? 18 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: _page == i ? kPurple2 : kBorder,
          borderRadius: BorderRadius.circular(4),
        ),
      ))),
    ]);
  }
}
